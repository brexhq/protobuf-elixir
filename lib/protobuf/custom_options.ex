defmodule Protobuf.CustomOptions do
  import Protobuf.Decoder
  require Logger

  def encode_type(type, v, [extype: extype], %{encoded_fnum: fnum}) do
    encoded = do_it(type, v, extype)
    [[fnum, encoded]] |> IO.iodata_to_binary()
  end

  def do_it(Google.Protobuf.StringValue, v, "String.t") when is_binary(v) do
    Protobuf.Encoder.encode_type(:string, v)
  end

  def decode_type(val, type, extype: extype) do
    [tag, wire, val | _rest] = Protobuf.Decoder.decode_raw(val)
    do_it_it(type, val, extype)
  end

  def do_it_it(Google.Protobuf.StringValue, val, "String.t") do
    Protobuf.Decoder.decode_type_m(:string, :value, val)
  end

  def fmt_type(f, [extype: extype]) do
    format_the_type(f.type, extype)
  end

  def format_the_type("Google.Protobuf.StringValue", "String.t") do
    "String.t | nil"
  end
end
