defmodule Protobuf.EnumOptionsProcessor do
  @moduledoc """
  Defines hooks to process custom enum options.
  """

  @typedoc """
  Keyword list of field options. Right now only [extype: mytype].
  """
  @type options :: Brex.Elixirpb.EnumOptions.t

  def validate_and_get_transformers(name, %Brex.Elixirpb.EnumOptions{} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.flat_map(fn
      {:lowercase, true} -> [{:lowercase, true}]
      {:deprefix, true} -> [{:deprefix, cal_prefix(name)}]
      {:atomize, true} -> [{:deprefix, cal_prefix(name)}, {:lowercase, true}]
      _ -> []
    end)
    |> Enum.sort()
    |> Enum.uniq()
  end

  def cal_prefix(name) do
    name |> Macro.underscore() |> Kernel.<>("_") |> String.upcase()
  end

  def generate_types(name, fields, options) do
    transformers = validate_and_get_transformers(name, options)

    # What if some fields aren't prefixed?
    fields
    |> Enum.map(fn f -> ":#{transform(f.name, transformers, :backward)}" end)
    |> Enum.join(" | ")
  end

  defp transform(value, transforms, :forward) do
    Enum.reduce(transforms, value, fn
      {:lowercase, _}, v -> String.upcase(v)
      {:deprefix, prefix}, v -> String.replace_prefix(v, "", prefix)
    end)
  end

  defp transform(value, transforms, :backward) do
    Enum.reduce(transforms, value, fn
      {:lowercase, _}, v -> String.downcase(v)
      {:deprefix, prefix}, v -> String.replace_prefix(v, prefix, "")
    end)
  end
end
