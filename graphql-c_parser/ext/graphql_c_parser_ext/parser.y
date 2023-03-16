%require "3.8"
%define api.pure full

%{
// C Declarations
#include <ruby.h>
#define YYSTYPE VALUE
int yylex(YYSTYPE *, VALUE);
void yyerror(VALUE, const char*);

static VALUE GraphQL_Language_Nodes_NONE;
static VALUE r_string_query;
#define SETUP_NODE_CLASS_VARIABLE(node_class_name) static VALUE GraphQL_Language_Nodes_##node_class_name;

SETUP_NODE_CLASS_VARIABLE(Argument)
SETUP_NODE_CLASS_VARIABLE(Directive)
SETUP_NODE_CLASS_VARIABLE(Document)
SETUP_NODE_CLASS_VARIABLE(Enum)
SETUP_NODE_CLASS_VARIABLE(Field)
SETUP_NODE_CLASS_VARIABLE(FragmentDefinition)
SETUP_NODE_CLASS_VARIABLE(FragmentSpread)
SETUP_NODE_CLASS_VARIABLE(InlineFragment)
SETUP_NODE_CLASS_VARIABLE(InputObject)
SETUP_NODE_CLASS_VARIABLE(ListType)
SETUP_NODE_CLASS_VARIABLE(NonNullType)
SETUP_NODE_CLASS_VARIABLE(NullValue)
SETUP_NODE_CLASS_VARIABLE(OperationDefinition)
SETUP_NODE_CLASS_VARIABLE(TypeName)
SETUP_NODE_CLASS_VARIABLE(VariableDefinition)
SETUP_NODE_CLASS_VARIABLE(VariableIdentifier)

SETUP_NODE_CLASS_VARIABLE(ScalarTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(ObjectTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(InterfaceTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(UnionTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(EnumTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(InputObjectTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(EnumValueDefinition)
SETUP_NODE_CLASS_VARIABLE(DirectiveDefinition)
SETUP_NODE_CLASS_VARIABLE(DirectiveLocation)
SETUP_NODE_CLASS_VARIABLE(FieldDefinition)
SETUP_NODE_CLASS_VARIABLE(InputValueDefinition)
SETUP_NODE_CLASS_VARIABLE(SchemaDefinition)

%}

%param {VALUE parser}

// YACC Declarations
%token AMP 200
%token BANG 201
%token COLON 202
%token DIRECTIVE 203
%token DIR_SIGN 204
%token ENUM 205
%token ELLIPSIS 206
%token EQUALS 207
%token EXTEND 208
%token FALSE_LITERAL 209
%token FLOAT 210
%token FRAGMENT 211
%token IDENTIFIER 212
%token INPUT 213
%token IMPLEMENTS 214
%token INT 215
%token INTERFACE 216
%token LBRACKET 217
%token LCURLY 218
%token LPAREN 219
%token MUTATION 220
%token NULL_LITERAL 221
%token ON 222
%token PIPE 223
%token QUERY 224
%token RBRACKET 225
%token RCURLY 226
%token REPEATABLE 227
%token RPAREN 228
%token SCALAR 229
%token SCHEMA 230
%token STRING 231
%token SUBSCRIPTION 232
%token TRUE_LITERAL 233
%token TYPE_LITERAL 234
%token UNION 235
%token VAR_SIGN 236

%%

  // YACC Rules
  start: document { rb_ivar_set(parser, rb_intern("result"), $1); }

  document: definitions_list {
    VALUE position_source = rb_ary_entry($1, 0);
    VALUE line, col;
    if (RB_TEST(position_source)) {
      line = rb_funcall(position_source, rb_intern("line"), 0);
      col = rb_funcall(position_source, rb_intern("col"), 0);
    } else {
      line = INT2FIX(1);
      col = INT2FIX(1);
    }
    $$ = rb_funcall(GraphQL_Language_Nodes_Document, rb_intern("from_a"), 3,
      line,
      col,
      $1
    );
  }

  definitions_list:
      definition                    { $$ = rb_ary_new_from_args(1, $1); }
    | definitions_list definition   { rb_ary_push($$, $2); }

  definition:
    executable_definition
    | type_system_definition
    /* TODO | type_system_extension */

  executable_definition:
      operation_definition
    | fragment_definition

  operation_definition:
      operation_type name variable_definitions_opt directives_list_opt selection_set {
        $$ = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3),
          rb_ary_entry($2, 3),
          $3,
          $4,
          $5
        );
      }
    | name variable_definitions_opt directives_list_opt selection_set {
        $$ = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          r_string_query,
          rb_ary_entry($1, 3),
          $2,
          $3,
          $4
        );
      }
    | operation_type variable_definitions_opt directives_list_opt selection_set {
        $$ = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3),
          Qnil,
          $2,
          $3,
          $4
        );
      }
    | LCURLY selection_list RCURLY {
        $$ = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          r_string_query,
          Qnil,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE,
          $2
        );
      }
    | LCURLY RCURLY {
        $$ = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          r_string_query,
          Qnil,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE
        );
      }

  operation_type:
      QUERY
    | MUTATION
    | SUBSCRIPTION

  variable_definitions_opt:
      /* none */                              { $$ = GraphQL_Language_Nodes_NONE; }
    | LPAREN variable_definitions_list RPAREN { $$ = $2; }

  variable_definitions_list:
      variable_definition                           { $$ = rb_ary_new_from_args(1, $1); }
    | variable_definitions_list variable_definition { rb_ary_push($$, $2); }

  variable_definition:
      VAR_SIGN name COLON type default_value_opt {
        $$ = rb_funcall(GraphQL_Language_Nodes_VariableDefinition, rb_intern("from_a"), 5,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($2, 3),
          $4,
          $5
        );
      }

  default_value_opt:
      /* none */            { $$ = Qnil; }
    | EQUALS literal_value  { $$ = $2; }

  selection_list:
      selection                 { $$ = rb_ary_new_from_args(1, $1); }
    | selection_list selection  { rb_ary_push($$, $2); }

  selection:
      field
    | fragment_spread
    | inline_fragment

  selection_set:
      LCURLY selection_list RCURLY { $$ = $2; }

  selection_set_opt:
      /* none */    { $$ = rb_ary_new(); }
    | selection_set

  field:
    name COLON name arguments_opt directives_list_opt selection_set_opt {
      $$ = rb_funcall(GraphQL_Language_Nodes_Field, rb_intern("from_a"), 7,
        rb_ary_entry($1, 1),
        rb_ary_entry($1, 2),
        rb_ary_entry($1, 3), // alias
        rb_ary_entry($3, 3), // name
        $4, // args
        $5, // directives
        $6 // subselections
      );
    }
    | name arguments_opt directives_list_opt selection_set_opt {
      $$ = rb_funcall(GraphQL_Language_Nodes_Field, rb_intern("from_a"), 7,
        rb_ary_entry($1, 1),
        rb_ary_entry($1, 2),
        Qnil, // alias
        rb_ary_entry($1, 3), // name
        $2, // args
        $3, // directives
        $4 // subselections
      );
    }

  arguments_opt:
      /* none */                    { $$ = Qnil; }
    | LPAREN arguments_list RPAREN  { $$ = $2; }

  arguments_list:
      argument                { $$ = rb_ary_new_from_args(1, $1); }
    | arguments_list argument { rb_ary_push($$, $2); }

  argument:
      name COLON input_value {
        $$ = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3),
          $3
        );
      }

  literal_value:
      FLOAT       { $$ = rb_funcall(rb_ary_entry($1, 3), rb_intern("to_f"), 0); }
    | INT         { $$ = rb_funcall(rb_ary_entry($1, 3), rb_intern("to_i"), 0); }
    | STRING      { $$ = rb_ary_entry($1, 3); }
    | TRUE_LITERAL        { $$ = Qtrue; }
    | FALSE_LITERAL       { $$ = Qfalse; }
    | null_value
    | enum_value
    | list_value
    | object_literal_value

  input_value:
    literal_value
    | variable
    | object_value

  null_value: NULL_LITERAL {
    $$ = rb_funcall(GraphQL_Language_Nodes_NullValue, rb_intern("from_a"), 3,
      rb_ary_entry($1, 1),
      rb_ary_entry($1, 2),
      rb_ary_entry($1, 3)
    );
  }

  variable: VAR_SIGN name {
    $$ = rb_funcall(GraphQL_Language_Nodes_VariableIdentifier, rb_intern("from_a"), 3,
      rb_ary_entry($1, 1),
      rb_ary_entry($1, 2),
      rb_ary_entry($2, 3)
    );
  }

  list_value:
      LBRACKET RBRACKET                 { $$ = GraphQL_Language_Nodes_NONE; }
    | LBRACKET list_value_list RBRACKET { $$ = $2; }

  list_value_list:
      input_value                 { $$ = rb_ary_new_from_args(1, $1); }
    | list_value_list input_value { rb_ary_push($$, $2); }

  enum_name: /* any identifier, but not "true", "false" or "null" */
      IDENTIFIER
    | FRAGMENT
    | REPEATABLE
    | ON
    | operation_type
    | schema_keyword

  enum_value: enum_name {
    $$ = rb_funcall(GraphQL_Language_Nodes_Enum, rb_intern("from_a"), 3,
      rb_ary_entry($1, 1),
      rb_ary_entry($1, 2),
      rb_ary_entry($1, 3)
    );
  }

  object_value:
    | LCURLY object_value_list_opt RCURLY {
      $$ = rb_funcall(GraphQL_Language_Nodes_InputObject, rb_intern("from_a"), 3,
        rb_ary_entry($1, 1),
        rb_ary_entry($1, 2),
        $2
      );
    }

  object_value_list_opt:
      /* nothing */     { $$ = GraphQL_Language_Nodes_NONE; }
    | object_value_list

  object_value_list:
      object_value_field                    { $$ = rb_ary_new_from_args(1, $1); }
    | object_value_list object_value_field  { rb_ary_push($$, $2); }

  object_value_field:
      name COLON input_value {
        $$ = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3),
          $3
        );
      }

  /* like the previous, but with literals only: */
  object_literal_value:
      LCURLY object_literal_value_list_opt RCURLY {
        $$ = rb_funcall(GraphQL_Language_Nodes_InputObject, rb_intern("from_a"), 3,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          $2
        );
      }

  object_literal_value_list_opt:
      /* nothing */             { $$ = GraphQL_Language_Nodes_NONE; }
    | object_literal_value_list

  object_literal_value_list:
      object_literal_value_field                            { $$ = rb_ary_new_from_args(1, $1); }
    | object_literal_value_list object_literal_value_field  { rb_ary_push($$, $2); }

  object_literal_value_field:
      name COLON literal_value {
        $$ = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3),
          $3
        );
      }


  directives_list_opt:
      /* none */      { $$ = GraphQL_Language_Nodes_NONE; }
    | directives_list

  directives_list:
      directive                 { $$ = rb_ary_new_from_args(1, $1); }
    | directives_list directive { rb_ary_push($$, $2); }

  directive: DIR_SIGN name arguments_opt {
    $$ = rb_funcall(GraphQL_Language_Nodes_Directive, rb_intern("from_a"), 4,
      rb_ary_entry($1, 1),
      rb_ary_entry($1, 2),
      rb_ary_entry($2, 3),
      $3
    );
  }

  name:
      name_without_on
    | ON

  operation_type:
      QUERY
    | MUTATION
    | SUBSCRIPTION

 schema_keyword:
      SCHEMA
    | SCALAR
    | TYPE_LITERAL
    | IMPLEMENTS
    | INTERFACE
    | UNION
    | ENUM
    | INPUT
    | DIRECTIVE

  name_without_on:
      IDENTIFIER
    | FRAGMENT
    | REPEATABLE
    | TRUE_LITERAL
    | FALSE_LITERAL
    | operation_type
    | schema_keyword


  fragment_spread:
      ELLIPSIS name_without_on directives_list_opt {
        $$ = rb_funcall(GraphQL_Language_Nodes_FragmentSpread, rb_intern("from_a"), 4,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($2, 3),
          $3
        );
      }

  inline_fragment:
      ELLIPSIS ON type directives_list_opt selection_set {
        $$ = rb_funcall(GraphQL_Language_Nodes_InlineFragment, rb_intern("from_a"), 5,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          $3,
          $4,
          $5
        );
      }
    | ELLIPSIS directives_list_opt selection_set {
        $$ = rb_funcall(GraphQL_Language_Nodes_InlineFragment, rb_intern("from_a"), 5,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          Qnil,
          $2,
          $3
        );
      }

  fragment_definition:
    FRAGMENT fragment_name_opt ON type directives_list_opt selection_set {
      $$ = rb_funcall(GraphQL_Language_Nodes_FragmentDefinition, rb_intern("from_a"), 6,
        rb_ary_entry($1, 1),
        rb_ary_entry($1, 2),
        $2,
        $4,
        $5,
        $6
      );
    }

  fragment_name_opt:
      /* none */ { $$ = Qnil; }
    | name_without_on { $$ = rb_ary_entry($1, 3); }

  type:
      nullable_type
    | nullable_type BANG      { $$ = rb_funcall(GraphQL_Language_Nodes_NonNullType, rb_intern("from_a"), 3, rb_funcall($1, rb_intern("line"), 0), rb_funcall($1, rb_intern("col"), 0), $1); }

  nullable_type:
      name                   {
        $$ = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3)
        );
      }
    | LBRACKET type RBRACKET {
        $$ = rb_funcall(GraphQL_Language_Nodes_ListType, rb_intern("from_a"), 3,
          rb_funcall($2, rb_intern("line"), 0),
          rb_funcall($2, rb_intern("col"), 0),
          $2
        );
      }

type_system_definition:
     schema_definition
   | type_definition
   | directive_definition

  schema_definition:
      SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY {
        $$ = rb_funcall(GraphQL_Language_Nodes_SchemaDefinition, rb_intern("from_a"), 6,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          $2,
          // TODO use static strings:
          rb_hash_aref($4, rb_str_new_cstr("query")),
          rb_hash_aref($4, rb_str_new_cstr("mutation")),
          rb_hash_aref($4, rb_str_new_cstr("subscription"))
        );
      }

  operation_type_definition_list:
      operation_type_definition
    | operation_type_definition_list operation_type_definition {
      rb_funcall($$, rb_intern("merge!"), 1, $1);
    }

  operation_type_definition:
      operation_type COLON name {
        $$ = rb_hash_new();
        rb_hash_aset($$, rb_ary_entry($1, 3), rb_ary_entry($3, 3));
      }

  type_definition:
      scalar_type_definition
    | object_type_definition
    | interface_type_definition
    | union_type_definition
    | enum_type_definition
    | input_object_type_definition

  description: STRING

  description_opt:
      /* none */
    | description

  scalar_type_definition:
      description_opt SCALAR name directives_list_opt {
        $$ = rb_funcall(GraphQL_Language_Nodes_ScalarTypeDefinition, rb_intern("from_a"), 5,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($3, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          $4
        );
      }

  object_type_definition:
      description_opt TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt {
        $$ = rb_funcall(GraphQL_Language_Nodes_ObjectTypeDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($3, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          $4,
          $5,
          $6
        );
      }

  implements_opt:
      /* none */ { $$ = GraphQL_Language_Nodes_NONE; }
    | implements

  implements:
      IMPLEMENTS AMP interfaces_list { $$ = $3; }
    | IMPLEMENTS interfaces_list { $$ = $2; }
    | IMPLEMENTS legacy_interfaces_list { $$ = $2; }

  interfaces_list:
      name {
        $$ = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3)
        );
      }
    | interfaces_list AMP name {
      rb_ary_push($$, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry($3, 1), rb_ary_entry($3, 2), rb_ary_entry($3, 3)));
    }

  legacy_interfaces_list:
      name {
        $$ = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3)
        );
      }
    | legacy_interfaces_list name {
      rb_ary_push($$, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry($2, 1), rb_ary_entry($2, 2), rb_ary_entry($2, 3)));
    }

  input_value_definition:
      description_opt name COLON type default_value_opt directives_list_opt {
        $$ = rb_funcall(GraphQL_Language_Nodes_InputValueDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($2, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          $4,
          $5,
          $6
        );
      }

  input_value_definition_list:
      input_value_definition                             { $$ = rb_ary_new_from_args(1, $1); }
    | input_value_definition_list input_value_definition { rb_ary_push($$, $1); }

  arguments_definitions_opt:
      /* none */ { $$ = GraphQL_Language_Nodes_NONE; }
    | LPAREN input_value_definition_list RPAREN { $$ = $2; }

  field_definition:
      description_opt name arguments_definitions_opt COLON type directives_list_opt {
        $$ = rb_funcall(GraphQL_Language_Nodes_FieldDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($2, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          $5,
          $3,
          $6
        );
      }

  field_definition_list_opt:
    /* none */ { $$ = GraphQL_Language_Nodes_NONE; }
    | LCURLY field_definition_list RCURLY { $$ = $2; }

  field_definition_list:
    /* none - this is not actually valid but graphql-ruby used to print this */ { $$ = GraphQL_Language_Nodes_NONE; }
    | field_definition                       { $$ = rb_ary_new_from_args(1, $1); }
    | field_definition_list field_definition { rb_ary_push($$, $2); }

  interface_type_definition:
      description_opt INTERFACE name implements_opt directives_list_opt field_definition_list_opt {
        $$ = rb_funcall(GraphQL_Language_Nodes_InterfaceTypeDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($3, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          $4,
          $5,
          $6
        );
      }

  union_members:
      name {
        $$ = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3)
        );
      }
    | union_members PIPE name {
        rb_ary_push($$, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry($3, 1), rb_ary_entry($3, 2), rb_ary_entry($3, 3)));
      }

  union_type_definition:
      description_opt UNION name directives_list_opt EQUALS union_members {
        $$ = rb_funcall(GraphQL_Language_Nodes_UnionTypeDefinition, rb_intern("from_a"),  6,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($3, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          $4,
          $5
        );
      }

  enum_type_definition:
      description_opt ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY {
        $$ = rb_funcall(GraphQL_Language_Nodes_EnumTypeDefinition, rb_intern("from_a"),  6,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($3, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          $4,
          $5
        );
      }

  enum_value_definition:
    description_opt enum_name directives_list_opt {
      $$ = rb_funcall(GraphQL_Language_Nodes_EnumValueDefinition, rb_intern("from_a"), 5,
        rb_ary_entry($2, 1),
        rb_ary_entry($2, 2),
        rb_ary_entry($2, 3),
        // TODO see get_description for reading a description from comments
        (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
        $3
      );
    }

  enum_value_definitions:
      enum_value_definition                        { $$ = rb_ary_new_from_args(1, $1); }
    | enum_value_definitions enum_value_definition {
      rb_ary_push($$, $2);
     }

  input_object_type_definition:
      description_opt INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY {
        $$ = rb_funcall(GraphQL_Language_Nodes_InputObjectTypeDefinition, rb_intern("from_a"), 6,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($3, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          $4,
          $6
        );
      }

  directive_definition:
      description_opt DIRECTIVE DIR_SIGN name arguments_definitions_opt directive_repeatable_opt ON directive_locations {
        $$ = rb_funcall(GraphQL_Language_Nodes_DirectiveDefinition, rb_intern("from_a"), 7,
          rb_ary_entry($2, 1),
          rb_ary_entry($2, 2),
          rb_ary_entry($4, 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST($1) ? rb_ary_entry($1, 3) : Qnil),
          (RB_TEST($6) ? Qtrue : Qfalse), // repeatable
          $5,
          $8
        );
      }

  directive_repeatable_opt:
    /* nothing */
    | REPEATABLE

  directive_locations:
      name                          { $$ = rb_ary_new_from_args(1, rb_funcall(GraphQL_Language_Nodes_DirectiveLocation, rb_intern("from_a"), 3, rb_ary_entry($1, 1), rb_ary_entry($1, 2), rb_ary_entry($1, 3))); }
    | directive_locations PIPE name { rb_ary_push($$, rb_funcall(GraphQL_Language_Nodes_DirectiveLocation, rb_intern("from_a"), 3, rb_ary_entry($3, 1), rb_ary_entry($3, 2), rb_ary_entry($3, 3))); }

%%

// Custom functions
int yylex (YYSTYPE *lvalp, VALUE parser) {
  int next_token_idx = FIX2INT(rb_ivar_get(parser, rb_intern("current_token")));
  VALUE tokens = rb_ivar_get(parser, rb_intern("tokens"));
  VALUE next_token = rb_ary_entry(tokens, next_token_idx);

  if (!RB_TEST(next_token)) {
    return YYEOF;
  }

  rb_ivar_set(parser, rb_intern("current_token"), INT2FIX(next_token_idx + 1));
  VALUE token_type_rb_int = rb_ary_entry(next_token, 5);
  int next_token_type = FIX2INT(token_type_rb_int);

  *lvalp = next_token;
  return next_token_type;
}

void yyerror(VALUE parser, const char *msg) {
  VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
  VALUE cParseError = rb_const_get_at(mGraphQL, rb_intern("ParseError"));
  // TODO add proper arguments to this error
  VALUE exception = rb_funcall(cParseError, rb_intern("new"), 4, rb_str_new_cstr(msg), Qnil, Qnil, Qnil);
  rb_p(exception);
  rb_exc_raise(exception);
}

#define INITIALIZE_NODE_CLASS_VARIABLE(node_class_name) GraphQL_Language_Nodes_##node_class_name = rb_const_get_at(mGraphQLLanguageNodes, rb_intern(#node_class_name));

void initialize_node_class_variables() {
  VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
  VALUE mGraphQLLanguage = rb_const_get_at(mGraphQL, rb_intern("Language"));
  VALUE mGraphQLLanguageNodes = rb_const_get_at(mGraphQLLanguage, rb_intern("Nodes"));
  GraphQL_Language_Nodes_NONE = rb_const_get_at(mGraphQLLanguageNodes, rb_intern("NONE"));
  r_string_query = rb_str_new_cstr("query");
  rb_global_variable(&r_string_query);
  rb_str_freeze(r_string_query);

  INITIALIZE_NODE_CLASS_VARIABLE(Argument)
  INITIALIZE_NODE_CLASS_VARIABLE(Directive)
  INITIALIZE_NODE_CLASS_VARIABLE(Document)
  INITIALIZE_NODE_CLASS_VARIABLE(Enum)
  INITIALIZE_NODE_CLASS_VARIABLE(Field)
  INITIALIZE_NODE_CLASS_VARIABLE(FragmentDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(FragmentSpread)
  INITIALIZE_NODE_CLASS_VARIABLE(InlineFragment)
  INITIALIZE_NODE_CLASS_VARIABLE(InputObject)
  INITIALIZE_NODE_CLASS_VARIABLE(ListType)
  INITIALIZE_NODE_CLASS_VARIABLE(NonNullType)
  INITIALIZE_NODE_CLASS_VARIABLE(NullValue)
  INITIALIZE_NODE_CLASS_VARIABLE(OperationDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(TypeName)
  INITIALIZE_NODE_CLASS_VARIABLE(VariableDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(VariableIdentifier)

  INITIALIZE_NODE_CLASS_VARIABLE(ScalarTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(ObjectTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InterfaceTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(UnionTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(EnumTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InputObjectTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(EnumValueDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(DirectiveDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(DirectiveLocation)
  INITIALIZE_NODE_CLASS_VARIABLE(FieldDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InputValueDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(SchemaDefinition)
}
