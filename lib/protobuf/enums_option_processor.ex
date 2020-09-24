defmodule Protobuf.EnumOptionsProcessor do
  @moduledoc """
  Defines hooks to process custom enum options.
  """

  @typedoc """
  Keyword list of field options. Right now only [extype: mytype].
  """
  @type options :: Brex.Elixirpb.EnumOptions.t

  def validate_and_get_transformers_opts(opts) do
    opts
    |> Enum.flat_map(fn
      {:enum, :lowercase} -> [:lowercase]
      {:enum, :deprefix} -> [:deprefix]
      {:enum, :atomize} -> [:deprefix, :lowercase]
      _ -> []
    end)
    |> Enum.sort()
    |> Enum.uniq()
  end

  def validate_and_get_transformers(%Brex.Elixirpb.EnumOptions{} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.flat_map(fn
      {:lowercase, true} -> [:lowercase]
      {:deprefix, true} -> [:deprefix]
      {:atomize, true} -> [:deprefix, :lowercase]
      _ -> []
    end)
    |> Enum.sort()
    |> Enum.uniq()
  end

  def cal_prefix(mod, fields) do
    prefix = mod |> Macro.underscore() |> Kernel.<>("_") |> String.upcase()

    is_prefixed? =
      Enum.all?(fields, fn %{name: name} -> String.starts_with?(name, prefix) end)

      IO.inspect(:stderr, {prefix, is_prefixed?}, label: :prefix)

    if is_prefixed?, do: prefix, else: ""
  end

  def cal_prefix_atom(mod, fields) do
    prefix = mod |> Protobuf.Protoc.Generator.Util.mod_to_name() |> Kernel.<>("_") |> String.upcase()

    is_prefixed? =
      Enum.all?(fields, fn {_num, %{name: name}} -> IO.inspect({name, prefix}, label: :pls) ; String.starts_with?(name, prefix) end)

      IO.inspect(:stderr, {prefix, is_prefixed?}, label: :prefix)

    if is_prefixed?, do: prefix, else: ""
  end

  def generate_types(mod, fields, options) do
    transformers = validate_and_get_transformers(options)

    prefix = cal_prefix(mod, fields)

    fields
    |> Enum.map(fn f -> ":#{transform(f.name, prefix, transformers, :backward)}" end)
    |> Enum.join(" | ")
  end

  def options_str(options) do
    options
    |> validate_and_get_transformers()
    |> Enum.map(&Protobuf.Protoc.Generator.Util.options_to_str([{:enum, &1}]))
  end

  def generate_mappings(mod, props, fields, options) do
    transformers = validate_and_get_transformers_opts(options)
    prefix = cal_prefix_atom(mod, props)

    atom_to_num = for {fnum, %{name: name, name_atom: name_atom}} <- props, do: {transform(name, prefix, transformers, :backward) |> String.to_atom(), fnum}, into: %{}

    string_or_num_to_atom =
      for {fnum, %{name: name, name_atom: name_atom}} <- props,
          key <- [fnum, name],
          do: {key, transform(name, prefix, transformers, :backward) |> String.to_atom()},
          into: %{}

    {atom_to_num, string_or_num_to_atom}
  end

  defp transform(value, prefix, transforms, :forward) do
    Enum.reduce(transforms, value, fn
      :lowercase, v -> String.upcase(v)
      :deprefix, v -> String.replace_prefix(v, "", prefix)
    end)
  end

  defp transform(value, prefix, transforms, :backward) do
    Enum.reduce(transforms, value, fn
      :lowercase, v -> String.downcase(v)
      :deprefix, v -> String.replace_prefix(v, prefix, "")
    end)
  end
end
