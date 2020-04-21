defmodule Google.Protobuf.Timestamp do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          seconds: integer,
          nanos: integer
        }
  defstruct [:seconds, :nanos]

  field :seconds, 1, type: :int64
  field :nanos, 2, type: :int32
end

defmodule Google.Type.Date do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          year: integer,
          month: integer,
          day: integer
        }
  defstruct [:year, :month, :day]

  field :year, 1, type: :int32
  field :month, 2, type: :int32
  field :day, 3, type: :int32
end

defmodule MyTimeStamp do

  def validate_option!(Google.Protobuf.Timestamp, "NaiveDateTime.t"), do: :double
  def validate_option!(Google.Protobuf.Timestamp, "NaiveDateTime.t()"), do: :double
  def validate_option!(Google.Protobuf.Timestamp, "DateTime.t"), do: :float
  def validate_option!(Google.Protobuf.Timestamp, "DateTime.t()"), do: :float
  def validate_option!(type, extype) do
    raise "That's not right! you can't use #{extype} with #{type}"
  end

  def validate_option_string!("Google.Protobuf.Timestamp", "NaiveDateTime.t"), do: :double
  def validate_option_string!("Google.Protobuf.Timestamp", "NaiveDateTime.t()"), do: :double
  def validate_option_string!("Google.Protobuf.Timestamp", "DateTime.t"), do: :float
  def validate_option_string!("Google.Protobuf.Timestamp", "DateTime.t()"), do: :float
  def validate_option_string!(type, extype) do
    raise "That's not right! you can't use #{extype} with #{type}, use DateTime.t or NaiveDateTime.t"
  end
  # I don't validate the value because the encoder will.
  def do_encode_type(_type, v, "DateTime.t" <> _parens) do
    unix =
      v
      |> DateTime.to_unix(:nanosecond)

    seconds = System.convert_time_unit(unix, :nanosecond, :second)
    nanos = unix - System.convert_time_unit(seconds, :second, :nanosecond)

    %Google.Protobuf.Timestamp{
      seconds: seconds,
      nanos: nanos
    }
    |> Protobuf.encode()
  end

  def do_encode_type(type, v, ("NaiveDateTime.t" <> _parens) = extype) do
    validate_option!(type, extype)
    date_time = DateTime.from_naive!(v, "Etc/UTC")

    do_encode_type(type, date_time, "DateTime.t")
  end

  def do_decode_type(type, val, "DateTime.t" <> _parens = extype) do
    validate_option!(type, extype)

    protobuf_timestamp = Protobuf.decode(val, type)

    protobuf_timestamp.seconds
    |> System.convert_time_unit(:second, :nanosecond)
    |> Kernel.+(protobuf_timestamp.nanos)
    |> DateTime.from_unix!(:nanosecond)
  end

  def do_decode_type(type, val, "NaiveDateTime.t" <> _parens = extype) do
    validate_option!(type, extype)

    type
    |> do_decode_type(val, "DateTime.t")
    |> DateTime.to_naive()
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
