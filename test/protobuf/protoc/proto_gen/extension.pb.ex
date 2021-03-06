defmodule Protobuf.Protoc.ExtTest.Foo do
  @moduledoc false
  use Protobuf, custom_field_options?: true, syntax: :proto2

  @type t :: %__MODULE__{
          a: String.t()
        }
  defstruct [:a]

  def full_name do
    "ext.Foo"
  end

  field :a, 1, optional: true, type: :string
end

defmodule Protobuf.Protoc.ExtTest.Dual do
  @moduledoc false
  use Protobuf, custom_field_options?: true, syntax: :proto2

  @type t :: %__MODULE__{
          a: String.t() | nil,
          b: Google.Protobuf.StringValue.t() | nil
        }
  defstruct [:a, :b]

  def full_name do
    "ext.Dual"
  end

  field :a, 1, optional: true, type: Google.Protobuf.StringValue, options: [extype: "String.t"]
  field :b, 2, optional: true, type: Google.Protobuf.StringValue
end
