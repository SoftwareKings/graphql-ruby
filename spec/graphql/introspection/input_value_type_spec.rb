require "spec_helper"


describe GraphQL::Introspection::InputValueType do
  let(:query_string) {%|
     {
       __type(name: "DairyProductInput") {
         name,
         description,
         kind,
         inputFields {
           name,
           type { name },
           defaultValue
           description
         }
       }
     }
  |}
  let(:result) { DummySchema.execute(query_string)}

  it "exposes metadata about input objects, giving extra quotes for strings" do
    expected = { "data" => {
        "__type" => {
          "name"=>"DairyProductInput",
          "description"=>"Properties for finding a dairy product",
          "kind"=>"INPUT_OBJECT",
          "inputFields"=>[
            {"name"=>"source", "type"=>{ "name" => "Non-Null"}, "defaultValue"=>nil,
             "description" => "Where it came from"},
            {"name"=>"originDairy", "type"=>{ "name" => "String"}, "defaultValue"=>"\"Sugar Hollow Dairy\"",
             "description" => "Dairy which produced it"},
            {"name"=>"fatContent", "type"=>{ "name" => "Float"}, "defaultValue"=>"0.3",
             "description" => "How much fat it has"},
            {"name"=>"organic", "type"=>{ "name" => "Boolean"}, "defaultValue"=>"false",
             "description" => nil}
          ]
        }
      }}
    assert_equal(expected, result)
  end

  let(:cheese_type) {
    DummySchema.execute(%|
      {
        __type(name: "Cheese") {
          fields {
            name
            args {
              name
              defaultValue
            }
          }
        }
      }
    |)
  }

  it "converts default values to GraphQL values" do
    field = cheese_type['data']['__type']['fields'].detect { |f| f['name'] == 'similarCheese' }
    arg = field['args'].detect { |a| a['name'] == 'source' }

    assert_equal('["COW"]', arg['defaultValue'])
  end
end
