defmodule Protobuf.FieldOptionsProcessor do
  @type options :: any

  @type type :: any

  @type val :: any

  @type type_enum :: any

  @callback encode_type(type, val, options) :: iodata

  @callback decode_type(val, type, options) :: any

  @callback type_default(type, options) :: any

  @callback type_to_spec(type_enum, type, repeated :: boolean, options) :: String.t

  @callback get_field_options(orginal_options :: any) :: options

  def get_field_options(_options), do: nil

  def encode_type(type, v, _options) do
    Protobuf.Encoder.encode(type, v, [])
  end

  def decode_type(val, type, _options) do
    Protobuf.Decoder.decode(val, type)
  end

  def type_to_spec(type_enum, type, repeated, _options) do
    Protobuf.TypeUtil.enum_to_spec(type_enum, type, repeated)
  end

  def type_default(type, _options) do
    Protobuf.Builder.type_default(type)
  end
end
