defmodule Brex.Demoscene.Extensions.DataEnvironmentBehavior do
  @moduledoc false
  use Protobuf, custom_field_options?: true, enum: true, syntax: :proto2

  option enum: :atomize

  @type t :: integer | :invalid | :block | :mock

  field :DATA_ENVIRONMENT_BEHAVIOR_INVALID, 0
  field :DATA_ENVIRONMENT_BEHAVIOR_BLOCK, 1
  field :DATA_ENVIRONMENT_BEHAVIOR_MOCK, 2
end

defmodule Brex.Demoscene.Extensions.DemosceneOptions do
  @moduledoc false
  use Protobuf, custom_field_options?: true, syntax: :proto2

  @type t :: %__MODULE__{
          test_behavior: Brex.Demoscene.Extensions.DataEnvironmentBehavior.t()
        }
  defstruct [:test_behavior]

  def full_name do
    "brex.demoscene.extensions.DemosceneOptions"
  end

  field :test_behavior, 1,
    optional: true,
    type: Brex.Demoscene.Extensions.DataEnvironmentBehavior,
    enum: true
end

defmodule Brex.Demoscene.Extensions.PbExtension do
  @moduledoc false
  use Protobuf, syntax: :proto2

  extend Google.Protobuf.MessageOptions, :demoscene_options, 90909,
    optional: true,
    type: Brex.Demoscene.Extensions.DemosceneOptions
end
