defmodule Ext.TestBehaviorEventMessage do
  @moduledoc false
  use Protobuf, custom_field_options?: true, syntax: :proto3

  @type t :: %__MODULE__{
          f1: float | nil,
          f2: float | nil
        }
  defstruct [:f1, :f2]

  def full_name do
    "ext.TestBehaviorEventMessage"
  end

  def message_options do
    # credo:disable-for-next-line
    [%{test_behavior: :block}]
  end

  field :f1, 1, type: Google.Protobuf.DoubleValue, options: [extype: "float"]
  field :f2, 2, type: Google.Protobuf.DoubleValue, options: [extype: "float"]
end

defmodule Ext.NonTestBehaviorEventMessage.ArgsEntry do
  @moduledoc false
  use Protobuf, custom_field_options?: true, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  def full_name do
    "ext.NonTestBehaviorEventMessage.ArgsEntry"
  end

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Ext.NonTestBehaviorEventMessage do
  @moduledoc false
  use Protobuf, custom_field_options?: true, syntax: :proto3

  @type t :: %__MODULE__{
          args: %{String.t() => String.t()}
        }
  defstruct [:args]

  def full_name do
    "ext.NonTestBehaviorEventMessage"
  end

  field :args, 1, repeated: true, type: Ext.NonTestBehaviorEventMessage.ArgsEntry, map: true
end
