defmodule Wrappers do
  @moduledoc """
    defmodule Google.Protobuf.DoubleValue do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: float
          }
    defstruct [:value]

    field :value, 1, type: :double
  end

  defmodule Google.Protobuf.FloatValue do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: float
          }
    defstruct [:value]

    field :value, 1, type: :float
  end

  defmodule Google.Protobuf.Int64Value do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: integer
          }
    defstruct [:value]

    field :value, 1, type: :int64
  end

  defmodule Google.Protobuf.UInt64Value do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: non_neg_integer
          }
    defstruct [:value]

    field :value, 1, type: :uint64
  end

  defmodule Google.Protobuf.Int32Value do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: integer
          }
    defstruct [:value]

    field :value, 1, type: :int32
  end

  defmodule Google.Protobuf.UInt32Value do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: non_neg_integer
          }
    defstruct [:value]

    field :value, 1, type: :uint32
  end

  defmodule Google.Protobuf.BoolValue do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: boolean
          }
    defstruct [:value]

    field :value, 1, type: :bool
  end

  defmodule Google.Protobuf.StringValue do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: String.t()
          }
    defstruct [:value]

    field :value, 1, type: :string
  end

  defmodule Google.Protobuf.BytesValue do
    @moduledoc false
    use Protobuf, syntax: :proto3

    @type t :: %__MODULE__{
            value: String.t()
          }
    defstruct [:value]

    field :value, 1, type: :bytes
  end

  """
  require Protobuf.Decoder
  require Logger
  import Protobuf.Decoder, only: [decode_zigzag: 1]

  def validate_option!(Google.Protobuf.DoubleValue, "float"), do: :double
  def validate_option!(Google.Protobuf.FloatValue, "float"), do: :float
  def validate_option!(Google.Protobuf.Int64Value, "integer"), do: :int64
  def validate_option!(Google.Protobuf.UInt64Value, "non_neg_integer"), do: :uint64
  def validate_option!(Google.Protobuf.Int32Value, "integer"), do: :int32
  def validate_option!(Google.Protobuf.UInt32Value, "non_neg_integer"), do: :uint32
  def validate_option!(Google.Protobuf.BoolValue, "boolean"), do: :bool
  def validate_option!(Google.Protobuf.StringValue, "String.t"), do: :string
  def validate_option!(Google.Protobuf.StringValue, "String.t()"), do: :string
  def validate_option!(Google.Protobuf.BytesValue, "String.t"), do: :bytes
  def validate_option!(Google.Protobuf.BytesValue, "String.t()"), do: :bytes
  def validate_option!(type, extype) do
    raise "That's not right! you can't use #{extype} with #{type}"
  end

  def validate_option_string!("Google.Protobuf.DoubleValue", "float"), do: :double
  def validate_option_string!("Google.Protobuf.FloatValue", "float"), do: :float
  def validate_option_string!("Google.Protobuf.Int64Value", "integer"), do: :int64
  def validate_option_string!("Google.Protobuf.UInt64Value", "non_neg_integer"), do: :uint64
  def validate_option_string!("Google.Protobuf.Int32Value", "integer"), do: :int32
  def validate_option_string!("Google.Protobuf.UInt32Value", "non_neg_integer"), do: :uint32
  def validate_option_string!("Google.Protobuf.BoolValue", "boolean"), do: :bool
  def validate_option_string!("Google.Protobuf.StringValue", "String.t"), do: :string
  def validate_option_string!("Google.Protobuf.StringValue", "String.t()"), do: :string
  def validate_option_string!("Google.Protobuf.BytesValue", "String.t"), do: :bytes
  def validate_option_string!("Google.Protobuf.BytesValue", "String.t()"), do: :bytes
  def validate_option_string!(type, extype) do
    raise "That's not right! you can't use #{extype} with #{type}"
  end

  # I don't validate the value because the encoder will.
  def do_encode_type(type, v, extype) do
    atom_type = validate_option!(type, extype)
    fnum = type.__message_props__.field_props[1].encoded_fnum
    encoded = Protobuf.Encoder.encode_type(atom_type, v)
    [[fnum, encoded]]
  end

  def do_decode_type(type, val, extype) do
    atom_type = validate_option!(type, extype)
    [_tag, _wire, val | _rest] = Protobuf.Decoder.decode_raw(val)
    Protobuf.Decoder.decode_type_m(atom_type, :value, val)
  end

  # type is string here
  def do_type_to_spec(type, extype) do
    validate_option_string!(type, extype)
    extype <> " | nil"
  end

  def do_type_default(type, extype) do
    validate_option!(type, extype)
    nil
  end
end
