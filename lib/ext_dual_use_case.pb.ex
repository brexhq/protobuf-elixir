defmodule Ext.DualUseCase do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          with: String.t() | nil,
          without: Google.Protobuf.StringValue.t() | nil
        }
  defstruct [:with, :without]

  field :with, 1, type: Google.Protobuf.StringValue, options: [extype: "String.t"]
  field :without, 2, type: Google.Protobuf.StringValue
end
