# frozen_string_literal: true
require "spec_helper"

if testing_rails?
  describe GraphQL::Pagination::ActiveRecordRelationConnection do
    class Food < ActiveRecord::Base
    end

    if Food.count == 0 # Backwards-compat version of `.none?`
      ConnectionAssertions::NAMES.each { |n| Food.create!(name: n) }
    end

    class RelationConnectionWithTotalCount < GraphQL::Pagination::ActiveRecordRelationConnection
      def total_count
        if items.respond_to?(:unscope)
          items.unscope(:order).count(:all)
        else
          # rails 3
          items.count
        end
      end
    end

    let(:schema) {
      ConnectionAssertions.build_schema(
        connection_class: GraphQL::Pagination::ActiveRecordRelationConnection,
        total_count_connection_class: RelationConnectionWithTotalCount,
        get_items: -> {
          if Food.respond_to?(:scoped)
            Food.scoped # Rails 3-friendly version of .all
          else
            Food.all
          end
        }
      )
    }

    include ConnectionAssertions

    it "doesn't run pageInfo queries when not necessary" do
      results = nil
      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            __typename
          }
        }")
      end
      assert_equal "ItemConnection", results["data"]["items"]["__typename"]
      assert_equal "", log, "No queries are executed when no data is requested"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
          }
        }")
      end
      assert_equal true, results["data"]["items"]["pageInfo"]["hasNextPage"]
      assert_equal false, results["data"]["items"]["pageInfo"]["hasPreviousPage"]
      assert_equal 1, log.split("\n").size, "It runs only one query"
      assert_equal 1, log.squeeze.scan("SELECT 1 AS").size, "It's an exist query (#{log.inspect})"

      log = with_active_record_log do
        results = schema.execute("{
          items(last: 3) {
            pageInfo {
              hasNextPage
              hasPreviousPage
            }
          }
        }")
      end
      assert_equal true, results["data"]["items"]["pageInfo"]["hasPreviousPage"]
      assert_equal false, results["data"]["items"]["pageInfo"]["hasNextPage"]
      assert_equal 1, log.split("\n").size, "It runs only one query"
      assert_equal 1, log.scan("COUNT(").size, "It's a count query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            nodes {
              __typename
            }
          }
        }")
      end
      assert_equal ["Item", "Item", "Item"], results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal 1, log.split("\n").size, "It runs only one query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 11, maxPageSizeOverride: 11) {
            nodes {
              __typename
            }
            pageInfo {
              hasNextPage
            }
          }
        }")
      end
      assert_equal ["Item"] * 10, results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal 1, log.split("\n").size, "It runs only one query when less than total count is requested"
      assert_equal 0, log.scan("COUNT(").size, "It runs no count query"

      log = with_active_record_log do
        results = schema.execute("{
          items(first: 3) {
            nodes {
              __typename
            }
            pageInfo {
              hasNextPage
            }
          }
        }")
      end
      # This currently runs one query to load the nodes, then another one to count _just beyond_ the nodes.
      # A better implementation would load `first + 1` nodes and use that to set `has_next_page`.
      assert_equal ["Item", "Item", "Item"], results["data"]["items"]["nodes"].map { |i| i["__typename"] }
      assert_equal 2, log.split("\n").size, "It runs two queries -- TODO this could be better"
    end

    describe "already-loaded ActiveRecord relations" do
      ALREADY_LOADED_QUERY_STRING = "
      query($first: Int, $after: String, $last: Int, $before: String) {
            preloadedItems(first: $first, after: $after, last: $last, before: $before) {
              pageInfo {
                hasPreviousPage
                hasNextPage
                endCursor
              }
              nodes { __typename }
            }
          }
      "
      it "only runs one query for already-loaded unbounded queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING)
        end
        # The max_page_size of 6 is applied to the results
        assert_equal 6, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
      end

      it "only runs one query for already-loaded `last:...` queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { last: 1 })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
      end

      it "only runs one query for already-loaded `first:... / after:` queries" do
        results = nil
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { first: 1 })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"

        cursor = results["data"]["preloadedItems"]["pageInfo"]["endCursor"]
        log = with_active_record_log do
          results = schema.execute(ALREADY_LOADED_QUERY_STRING, variables: { first: 1, after: cursor })
        end
        assert_equal 1, results["data"]["preloadedItems"]["nodes"].size
        assert_equal 1, log.split("\n").size, "It runs only one query"
        decolorized_log = log.gsub(/\e\[([;\d]+)?m/, '').chomp
        assert_operator decolorized_log, :end_with?, 'SELECT "foods".* FROM "foods"', "it's an unbounded select from the resolver"
        assert_equal "[\"2\"]+nonce", results["data"]["preloadedItems"]["pageInfo"]["endCursor"], "it makes the right cursor"
      end

      let(:schema) {
        ConnectionAssertions.build_schema(
          connection_class: GraphQL::Pagination::ActiveRecordRelationConnection,
          total_count_connection_class: RelationConnectionWithTotalCount,
          get_items: -> {
            relation = if Food.respond_to?(:scoped)
              Food.scoped # Rails 3-friendly version of .all
            else
              Food.all
            end
            relation.load
            relation
          }
        )
      }

      include ConnectionAssertions
    end
  end
end
