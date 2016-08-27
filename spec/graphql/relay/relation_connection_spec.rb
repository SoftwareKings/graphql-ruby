require 'spec_helper'

describe GraphQL::Relay::RelationConnection do
  def get_names(result)
    ships = result["data"]["empire"]["bases"]["edges"]
    names = ships.map { |e| e["node"]["name"] }
  end

  def get_page_info(result)
    result["data"]["empire"]["bases"]["pageInfo"]
  end

  def get_first_cursor(result)
    result["data"]["empire"]["bases"]["edges"].first["cursor"]
  end

  def get_last_cursor(result)
    result["data"]["empire"]["bases"]["edges"].last["cursor"]
  end

  describe "results" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String,  $nameIncludes: String){
        empire {
          bases(first: $first, after: $after, last: $last, before: $before, nameIncludes: $nameIncludes) {
            ... basesConnection
          }
        }
      }

      fragment basesConnection on BasesConnectionWithTotalCount {
        totalCount,
        edges {
          cursor
          node {
            name
          }
        },
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
      }
    |}

    it 'limits the result' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(2, get_names(result).length)
      assert_equal(true, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ==", get_page_info(result)["startCursor"])
      assert_equal("Mg==", get_page_info(result)["endCursor"])
      assert_equal("MQ==", get_first_cursor(result))
      assert_equal("Mg==", get_last_cursor(result))

      result = star_wars_query(query_string, "first" => 3)
      assert_equal(3, get_names(result).length)
      assert_equal(false, get_page_info(result)["hasNextPage"])
      assert_equal(false, get_page_info(result)["hasPreviousPage"])
      assert_equal("MQ==", get_page_info(result)["startCursor"])
      assert_equal("Mw==", get_page_info(result)["endCursor"])
      assert_equal("MQ==", get_first_cursor(result))
      assert_equal("Mw==", get_last_cursor(result))
    end

    it 'provides custom fields on the connection type' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(
        Base.where(faction_id: 2).count,
        result["data"]["empire"]["bases"]["totalCount"]
      )
    end

    it 'slices the result' do
      result = star_wars_query(query_string, "first" => 2)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "after" => last_cursor, "first" => 2)
      assert_equal(["Headquarters"], get_names(result))

      last_cursor = get_last_cursor(result)

      result = star_wars_query(query_string, "before" => last_cursor, "last" => 1)
      assert_equal(["Shield Generator"], get_names(result))

      result = star_wars_query(query_string, "before" => last_cursor, "last" => 2)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

      result = star_wars_query(query_string, "before" => last_cursor, "last" => 10)
      assert_equal(["Death Star", "Shield Generator"], get_names(result))

    end

    it "applies custom arguments" do
      result = star_wars_query(query_string, "first" => 1, "nameIncludes" => "ea")
      assert_equal(["Death Star"], get_names(result))

      after = get_last_cursor(result)

      result = star_wars_query(query_string, "first" => 2, "nameIncludes" => "ea", "after" => after )
      assert_equal(["Headquarters"], get_names(result))
      before = get_last_cursor(result)

      result = star_wars_query(query_string, "last" => 1, "nameIncludes" => "ea", "before" => before)
      assert_equal(["Death Star"], get_names(result))
    end

    it 'works without first/last/after/before' do
      result = star_wars_query(query_string)

      assert_equal(3, result["data"]["empire"]["bases"]["edges"].length)
    end

    describe "applying max_page_size" do
      let(:query_string) {%|
        query getBases($first: Int, $after: String, $last: Int, $before: String){
          empire {
            bases: basesWithMaxLimitRelation(first: $first, after: $after, last: $last, before: $before) {
              ... basesConnection
            }
          }
        }

        fragment basesConnection on BaseConnection {
          edges {
            cursor
            node {
              name
            }
          },
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      |}

      it "applies to queries by `first`" do
        result = star_wars_query(query_string, "first" => 100)
        assert_equal(2, result["data"]["empire"]["bases"]["edges"].size)
        assert_equal(true, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"])

        # Max page size is applied _without_ `first`, also
        result = star_wars_query(query_string)
        assert_equal(2, result["data"]["empire"]["bases"]["edges"].size)
        assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasNextPage"], "hasNextPage is false when first is not specified")
      end

      it "applies to queries by `last`" do
        last_cursor = "Ng=="
        second_to_last_two_names = ["Death Star", "Shield Generator"]
        result = star_wars_query(query_string, "last" => 100, "before" => last_cursor)
        assert_equal(second_to_last_two_names, get_names(result))
        assert_equal(true, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"])

        result = star_wars_query(query_string, "before" => last_cursor)
        assert_equal(second_to_last_two_names, get_names(result))
        assert_equal(false, result["data"]["empire"]["bases"]["pageInfo"]["hasPreviousPage"], "hasPreviousPage is false when last is not specified")

        third_cursor = "Mw=="
        first_and_second_names = ["Yavin", "Echo Base"]
        result = star_wars_query(query_string, "last" => 100, "before" => third_cursor)
        assert_equal(first_and_second_names, get_names(result))

        result = star_wars_query(query_string, "before" => third_cursor)
        assert_equal(first_and_second_names, get_names(result))
      end
    end
  end

  describe "without a block" do
    let(:query_string) {%|
      {
        empire {
          basesClone(first: 10) {
            edges {
              node {
                name
              }
            }
          }
        }
    }|}
    it "uses default resolve" do
      result = star_wars_query(query_string)
      bases = result["data"]["empire"]["basesClone"]["edges"]
      assert_equal(3, bases.length)
    end
  end

  describe "custom ordering" do
    let(:query_string) {%|
      query getBases {
        empire {
          basesByName(first: 30) { ... basesFields }
          bases(first: 30) { ... basesFields2 }
        }
      }
      fragment basesFields on BaseConnection {
        edges {
          node {
            name
          }
        }
      }
      fragment basesFields2 on BasesConnectionWithTotalCount {
        edges {
          node {
            name
          }
        }
      }
    |}

    def get_names(result, field_name)
      bases = result["data"]["empire"][field_name]["edges"]
      base_names = bases.map { |b| b["node"]["name"] }
    end

    it "applies the default value" do
      result = star_wars_query(query_string)
      bases_by_id   = ["Death Star", "Shield Generator", "Headquarters"]
      bases_by_name = ["Death Star", "Headquarters", "Shield Generator"]

      assert_equal(bases_by_id, get_names(result, "bases"))
      assert_equal(bases_by_name, get_names(result, "basesByName"))
    end
  end

  describe "with a Sequel::Dataset" do
    def get_names(result)
      ships = result["data"]["empire"]["basesAsSequelDataset"]["edges"]
      names = ships.map { |e| e["node"]["name"] }
    end

    def get_page_info(result)
      result["data"]["empire"]["basesAsSequelDataset"]["pageInfo"]
    end

    def get_first_cursor(result)
      result["data"]["empire"]["basesAsSequelDataset"]["edges"].first["cursor"]
    end

    def get_last_cursor(result)
      result["data"]["empire"]["basesAsSequelDataset"]["edges"].last["cursor"]
    end

    describe "results" do
      let(:query_string) {%|
        query getShips($first: Int, $after: String, $last: Int, $before: String,  $nameIncludes: String){
          empire {
            basesAsSequelDataset(first: $first, after: $after, last: $last, before: $before, nameIncludes: $nameIncludes) {
              ... basesConnection
            }
          }
        }

        fragment basesConnection on BasesConnectionWithTotalCount {
          totalCount,
          edges {
            cursor
            node {
              name
            }
          },
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      |}

      it 'limits the result' do
        result = star_wars_query(query_string, "first" => 2)
        assert_equal(2, get_names(result).length)
        assert_equal(true, get_page_info(result)["hasNextPage"])
        assert_equal(false, get_page_info(result)["hasPreviousPage"])
        assert_equal("MQ==", get_page_info(result)["startCursor"])
        assert_equal("Mg==", get_page_info(result)["endCursor"])
        assert_equal("MQ==", get_first_cursor(result))
        assert_equal("Mg==", get_last_cursor(result))

        result = star_wars_query(query_string, "first" => 3)
        assert_equal(3, get_names(result).length)
        assert_equal(false, get_page_info(result)["hasNextPage"])
        assert_equal(false, get_page_info(result)["hasPreviousPage"])
        assert_equal("MQ==", get_page_info(result)["startCursor"])
        assert_equal("Mw==", get_page_info(result)["endCursor"])
        assert_equal("MQ==", get_first_cursor(result))
        assert_equal("Mw==", get_last_cursor(result))
      end

      it 'provides custom fields on the connection type' do
        result = star_wars_query(query_string, "first" => 2)
        assert_equal(
          Base.where(faction_id: 2).count,
          result["data"]["empire"]["basesAsSequelDataset"]["totalCount"]
        )
      end

      it 'slices the result' do
        result = star_wars_query(query_string, "first" => 2)
        assert_equal(["Death Star", "Shield Generator"], get_names(result))

        # After the last result, find the next 2:
        last_cursor = get_last_cursor(result)

        result = star_wars_query(query_string, "after" => last_cursor, "first" => 2)
        assert_equal(["Headquarters"], get_names(result))

        last_cursor = get_last_cursor(result)

        result = star_wars_query(query_string, "before" => last_cursor, "last" => 1)
        assert_equal(["Shield Generator"], get_names(result))

        result = star_wars_query(query_string, "before" => last_cursor, "last" => 2)
        assert_equal(["Death Star", "Shield Generator"], get_names(result))

        result = star_wars_query(query_string, "before" => last_cursor, "last" => 10)
        assert_equal(["Death Star", "Shield Generator"], get_names(result))

      end

      it "applies custom arguments" do
        result = star_wars_query(query_string, "first" => 1, "nameIncludes" => "ea")
        assert_equal(["Death Star"], get_names(result))

        after = get_last_cursor(result)

        result = star_wars_query(query_string, "first" => 2, "nameIncludes" => "ea", "after" => after )
        assert_equal(["Headquarters"], get_names(result))
        before = get_last_cursor(result)

        result = star_wars_query(query_string, "last" => 1, "nameIncludes" => "ea", "before" => before)
        assert_equal(["Death Star"], get_names(result))
      end
    end
  end
end
