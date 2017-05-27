---
layout: guide
title: Schema — Instrumentation
---

Instrumentation provides hooks for inserting custom code around field resolution and query execution.

## Field Instrumentation

Field instrumentation can be attached during schema definition:

```ruby
MySchema = GraphQL::Schema.define do
  instrument(:field, FieldTimerInstrumentation.new)
end
```

The instrumenter is an object which responds to `#instrument(type, field)`. `#instrument` should return a `GraphQL::Field` instance which will be used during query execution. `#instrument` is called with each type-field pair for _all_ Object types and Interface types in your schema.

Here's an example field instrumenter:

```ruby
class FieldTimerInstrumentation
  # If a field was flagged to be timed,
  # wrap its resolve proc with a timer.
  def instrument(type, field)
    if field.metadata[:timed]
      old_resolve_proc = field.resolve_proc
      new_resolve_proc = ->(obj, args, ctx) {
        Rails.logger.info("#{type.name}.#{field.name} START: #{Time.now.to_i}")
        resolved = old_resolve_proc.call(obj, args, ctx)
        Rails.logger.info("#{type.name}.#{field.name} END: #{Time.now.to_i}")
        resolved
      }

      # Return a copy of `field`, with a new resolve proc
      field.redefine do
        resolve(new_resolve_proc)
      end
    else
      field
    end
  end
end
```

It can be attached as shown above. You can use `redefine { ... }` to make a shallow copy of the  {{ "GraphQL::Field" | api_doc }} and extend its definition.

{{ "GraphQL::Field#lazy_resolve_proc" | api_doc }} can also be instrumented. This is called for objects registered with [lazy execution]({{ site.baseurl }}/schema/lazy_execution).

## Query Instrumentation

Query instrumentation can be attached during schema definition:

```ruby
MySchema = GraphQL::Schema.define do
  instrument(:query, QueryTimerInstrumentation)
end
```

The instrumenter must implement `#before_query(query)` and `#after_query(query)`. The return values of these methods are not used. They receive the {{ "GraphQL::Query" | api_doc }} instance.

```ruby
module MyQueryInstrumentation
  module_function

  # Log the time of the query
  def before_query(query)
    Rails.logger.info("Query begin: #{Time.now.to_i}")
  end

  def after_query(query)
    Rails.logger.info("Query end: #{Time.now.to_i}")
  end
end
```
