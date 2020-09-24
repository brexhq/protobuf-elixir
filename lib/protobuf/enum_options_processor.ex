defmodule Protobuf.EnumOptionsProcessor do
  @moduledoc """
  Defines hooks to process custom enum options.
  """

  @typedoc """
  Keyword list of field options. Right now only [extype: mytype].
  """
  @type options :: Brex.Elixirpb.EnumOptions.t()

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
      Enum.all?(fields, fn
        %{name: name} -> String.starts_with?(name, prefix)
      end)

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

  def generate_mappings(mod, props, options) do
    transformers = validate_and_get_transformers_opts(options)

    field_props = Enum.map(props, fn {_fnum, field_props} -> field_props end)

    prefix =
      mod
      |> Protobuf.Protoc.Generator.Util.mod_to_name()
      |> cal_prefix(field_props)

    original_to_transformed =
      Enum.into(props, %{}, fn {fnum, %{name: name}} ->
        transformed_name = transform(name, prefix, transformers, :backward)
        transformed_name_atom = String.to_atom(transformed_name)
        {name, %{fnum: fnum, name: transformed_name, name_atom: transformed_name_atom}}
      end)

    atom_to_num =
      for {_, %{fnum: fnum, name_atom: tname_atom}} <- original_to_transformed,
          do: {tname_atom, fnum},
          into: %{}

    string_or_num_to_atom =
      for {_, %{fnum: fnum, name: tname, name_atom: tname_atom}} <- original_to_transformed,
          key <- [fnum, tname],
          do: {key, tname_atom},
          into: %{}

    accessor_funs =
      if :lowercase in transformers do
        Enum.map(original_to_transformed, fn {_, %{name_atom: tname_atom}} ->
          quote do
            def unquote(tname_atom)(), do: unquote(tname_atom)
          end
        end)
      else
        []
      end

    prefix_fun = [
      quote do
        def prefix(), do: unquote(prefix)
      end
    ]

    {atom_to_num, string_or_num_to_atom, accessor_funs ++ prefix_fun}
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
