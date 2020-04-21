defmodule Protobuf.CustomOptions do
  #one problem with this approach is that there may be other calling sites we need to modify that we don't know

  @behaviour Protobuf.FieldOptionsProcessor

  @type options :: Keyword.t(String.t())


  def get_mod(Google.Protobuf.Timestamp), do: MyTimeStamp
  def get_mod(Google.Protobuf.DoubleValue), do: Wrappers
  def get_mod(Google.Protobuf.FloatValue), do: Wrappers
  def get_mod(Google.Protobuf.Int64Value), do: Wrappers
  def get_mod(Google.Protobuf.UInt64Value), do: Wrappers
  def get_mod(Google.Protobuf.Int32Value), do: Wrappers
  def get_mod(Google.Protobuf.UInt32Value), do: Wrappers
  def get_mod(Google.Protobuf.BoolValue), do: Wrappers
  def get_mod(Google.Protobuf.StringValue), do: Wrappers
  def get_mod(Google.Protobuf.BytesValue), do: Wrappers
  def get_mod(str) do
    raise "Sorry #{str} is unsupported"
  end

  def get_mod_string("Google.Protobuf.Timestamp"), do: MyTimeStamp
  def get_mod_string("Google.Protobuf.DoubleValue"), do: Wrappers
  def get_mod_string("Google.Protobuf.FloatValue"), do: Wrappers
  def get_mod_string("Google.Protobuf.Int64Value"), do: Wrappers
  def get_mod_string("Google.Protobuf.UInt64Value"), do: Wrappers
  def get_mod_string("Google.Protobuf.Int32Value"), do: Wrappers
  def get_mod_string("Google.Protobuf.UInt32Value"), do: Wrappers
  def get_mod_string("Google.Protobuf.BoolValue"), do: Wrappers
  def get_mod_string("Google.Protobuf.StringValue"), do: Wrappers
  def get_mod_string("Google.Protobuf.BytesValue"), do: Wrappers
  def get_mod_string(str) do
    raise "Sorry #{str} is unsupported"
  end

  @impl true
  def encode_type(type, v, [extype: extype]) do
    encoded = get_mod(type).do_encode_type(type, v, extype)
    IO.iodata_to_binary(encoded)
  end

  @impl true
  def decode_type(val, type, extype: extype) do
    get_mod(type).do_decode_type(type, val, extype)
  end

  @impl true
  def type_to_spec(_type_enum, type, _repeated, [extype: extype]) do
    get_mod_string(type).do_type_to_spec(type, extype)
  end

  @impl true
  def type_default(type, [extype: extype]) do
    get_mod(type).do_type_default(type, extype)
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
