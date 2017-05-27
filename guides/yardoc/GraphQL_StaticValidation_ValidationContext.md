---
layout: doc_stub
search: true
title: GraphQL::StaticValidation::ValidationContext
url: http://www.rubydoc.info/gems/graphql/GraphQL/StaticValidation/ValidationContext
rubydoc_url: http://www.rubydoc.info/gems/graphql/GraphQL/StaticValidation/ValidationContext
---

Class: GraphQL::StaticValidation::ValidationContext < Object
The validation context gets passed to each validator. 
It exposes a GraphQL::Language::Visitor where validators may add
hooks. (Language::Visitor#visit is called in Validator#validate) 
It provides access to the schema & fragments which validators may
read from. 
It holds a list of errors which each validator may add to. 
It also provides limited access to the TypeStack instance, which
tracks state as you climb in and out of different fields. 
Extended by:
Forwardable
Instance methods:
argument_definition, directive_definition, each_irep_node,
field_definition, initialize, object_types, on_dependency_resolve,
parent_type_definition, path, type_definition, valid_literal?

