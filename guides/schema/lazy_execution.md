---
layout: guide
title: Schema — Lazy Execution
---

With lazy execution, you can optimize access to external services (such as databases) by making batched calls. Building a lazy loader has three steps:

- Define a lazy-loading class with _one_ method for loading & returning a value
- Connect it to your schema with {{ "GraphQL::Schema#lazy_resolve" | api_doc }}
- In `resolve` functions, return instances of the lazy-loading class

[`graphql-batch`](https://github.com/shopify/graphql-batch) provides a powerful, flexible toolkit for lazy resolution with GraphQL.


Lazy resolution can be [instrumented]({{ site.baseurl }}/schema/instrumentation).

## Example: Batched Find

Here's a way to find many objects by ID using one database call, preventing N+1 queries.

1. Lazy-loading class which finds models by ID.

```ruby
class LazyFindPerson
  def initialize(query_ctx, person_id)
    @person_id = person_id
    # Initialize the loading state for this query,
    # or get the previously-initiated state
    @lazy_state = query_ctx[:lazy_find_person] ||= {
      pending_ids: Set.new,
      loaded_ids: {},
    }
    # Register this ID to be loaded later:
    @lazy_state[:pending_ids] << person_id
  end

  # Return the loaded record, hitting the database if needed
  def person
    # Check if the record was already loaded:
    loaded_record = @lazy_state[:loaded_ids][@person_id]
    if loaded_record
      # The pending IDs were already loaded,
      # so return the result of that previous load
      loaded_record
    else
      # The record hasn't been loaded yet, so
      # hit the database with all pending IDs
      pending_ids = @lazy_state[:pending_ids].to_a
      people = Person.where(id: pending_ids)
      people.each { |person| @lazy_state[:loaded_ids][person.id] = person }
      @lazy_state[:pending_ids].clear
      # Now, get the matching person from the loaded result:
      @lazy_state[:loaded_ids][@person_id]
    end
  end
```

2. Connect the lazy resolve method

```ruby
MySchema = GraphQL::Schema.define do
  # ...
  lazy_resolve(LazyFindPerson, :person)
end
```

3. Return lazy objects from `resolve`

```ruby
field :author, PersonType do
  resolve ->(obj, args, ctx) {
    LazyFindPerson.new(ctx, obj.author_id)
  }
end
```

Now, calls to `author` will use batched database access. For example, this query:

```graphql
{
  p1: post(id: 1) { author { name } }
  p2: post(id: 2) { author { name } }
  p3: post(id: 3) { author { name } }
}
```

Will only make one query to load the `author` values.

The example above is simple and has some shortcomings. Consider the `graphql-batch` gem for a robust solution to batched resolution.
