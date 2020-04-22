defmodule Protobuf.FieldOptionsProcessor do
  @moduledoc """
  Defines hooks to process custom field options.
  """

  @type options :: Keyword.t(String.t)
  @type type :: atom

  @callback type_to_spec(type_enum :: atom, type :: String.t(), repeated :: boolean, options) :: String.t()
  @callback type_default(type, options) :: any
  @callback new(type, value :: any, options) :: struct | any # TODO what type?
  @callback encode_type(type, v :: any, options) :: binary

  def validate_options_str!(:TYPE_MESSAGE, "Google.Protobuf.StringValue", [extype: "String.t()" = extype]), do: extype
  def validate_options_str!(:TYPE_MESSAGE, "Google.Protobuf.StringValue", [extype: "String.t" = extype]), do: extype
  def validate_options_str!(_, type, options) do
    raise "The custom field option is invalid. Options: #{inspect(options)} incompatible with type: #{type}"
  end

  def validate_options!(Google.Protobuf.StringValue, [extype: "String.t()"]), do: :string
  def validate_options!(Google.Protobuf.StringValue, [extype: "String.t"]), do: :string
  def validate_options!(type, options) do
    raise "The custom field option is invalid. Options: #{inspect(options)} incompatible with type: #{type}"
  end


  def type_to_spec(type_enum, type, repeated, options) do
    extype = validate_options_str!(type_enum, type, options)
    type_str = extype <> " | nil"
    if repeated do
      "[#{type_str}]"
    else
      type_str
    end
  end

  def type_default(type, options) do
    validate_options!(type, options)
    nil
  end

  # Note: Could do type check here if we wanted to.
  def new(type, value, options) do
    validate_options!(type, options)
    value
  end

  def encode_type(type, v, options) do
    extype = validate_options!(type, options)
    encoded = do_encode_type(type, v, extype)
    IO.iodata_to_binary(encoded)
  end

  defp do_encode_type(type, v, extype) do
    fnum = type.__message_props__.field_props[1].encoded_fnum
    encoded = Protobuf.Encoder.encode_type(extype, v)
    [[fnum, encoded]]
  end
end