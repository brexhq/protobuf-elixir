defmodule Protobuf.Protoc.Generator.Enum do
  @moduledoc false
  alias Protobuf.Protoc.Generator.Util

  def generate_list(ctx, descs) do
    Enum.map(descs, fn desc -> generate(ctx, desc) end)
  end

  def generate(%{namespace: ns} = ctx, desc) do
    enum_options = cal_options(ctx, desc)
    name = Util.trans_name(desc.name)
    fields = Enum.map(desc.value, fn f -> generate_field(f) end)
    msg_name = Util.mod_name(ctx, ns ++ [name])
    generate_desc = if ctx.gen_descriptors?, do: desc, else: nil
    type = generate_type(enum_options, desc)

    Protobuf.Protoc.Template.enum(msg_name, msg_opts(ctx, desc), fields, type, generate_desc)
  end

  def generate_type(enum_options, desc) when not is_nil(enum_options) do
    field_values = Protobuf.EnumOptionsProcessor.generate_types(desc.name, desc.value, enum_options)

    "@type t :: integer | " <> field_values
  end
  def generate_type(_enum_options, %{value: fields}) do
    field_values =
      fields
      |> Enum.map(fn f -> ":#{f.name}" end)
      |> Enum.join(" | ")

    "@type t :: integer | " <> field_values
  end

  def generate_field(f) do
    ":#{f.name}, #{f.number}"
  end

  def cal_options(%{custom_field_options?: true}, desc) do
    Google.Protobuf.EnumOptions.get_extension(desc.options, Brex.Elixirpb.PbExtension, :enum)
  end
  def cal_options(_ctx, _desc), do: nil

  defp msg_opts(%{syntax: syntax, custom_field_options?: custom_field_options}, _desc) do
    opts = %{syntax: syntax, enum: true}

    opts =
      if custom_field_options do
        Map.put(opts, :custom_field_options?, true)
      else
        opts
      end
    str = Util.options_to_str(opts)
    ", " <> str
  end
end
