defmodule Protobuf.CustomOptions do
  #one problem with this approach is that there may be other calling sites we need to modify that we don't know
  import Protobuf.Decoder
  require Logger

  @behaviour Protobuf.FieldOptionsProcessor

  @impl true
  def encode_type(type, v, [extype: extype]) do
    encoded = do_encode_type(type, v, extype)
    IO.iodata_to_binary(encoded)
  end

  def do_encode_type(Google.Protobuf.StringValue = type, v, "String.t") when is_binary(v) do
    fnum = type.__message_props__.field_props[1].encoded_fnum
    encoded = Protobuf.Encoder.encode_type(:string, v)
    [[fnum, encoded]]
  end

  @impl true
  def decode_type(val, type, extype: extype) do
    [_tag, _wire, val | _rest] = Protobuf.Decoder.decode_raw(val)
    do_decode_type(type, val, extype)
  end

  def do_decode_type(Google.Protobuf.StringValue, val, "String.t") do
    Protobuf.Decoder.decode_type_m(:string, :value, val)
  end

  @impl true
  def type_to_spec(_type_enum, type, _repeated, [extype: extype]) do
    do_type_to_spec(type, extype)
  end

  def do_type_to_spec("Google.Protobuf.StringValue", "String.t") do
    "String.t | nil"
  end

  @impl true
  def type_default(type, [extype: extype]) do
    do_type_default(type, extype)
  end

  def do_type_default(Google.Protobuf.StringValue, "String.t") do
    nil
  end

  @impl true
  def get_field_options(options) do
    options
    |> Google.Protobuf.FieldOptions.get_extension(Brex.Elixirpb.PbExtension, :field)
    |> case do
      nil -> nil
      elixir_field_options ->
        elixir_field_options
        |> Map.from_struct()
        |> Enum.into([])
    end
  end
end
