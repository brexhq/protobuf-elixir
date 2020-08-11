defmodule Protobuf.Verifier do
  @moduledoc """
  Checks whether the values passed into a Message.new() call are valid.

  The structure of this code is based on Protobuf.Encoder
  """

  import Protobuf.WireTypes
  alias Protobuf.{MessageProps, FieldProps, FieldOptionsProcessor}

  @spec verify(struct) :: :ok | {:error, String.t()}
  def verify(%mod{} = struct), do: do_verify(struct, mod.__message_props__())

  @spec verify(atom, struct | map) :: :ok | {:error, String.t()}
  def verify(mod, msg) do
    case msg do
      %{__struct__: ^mod} ->
        verify(msg)

      _ ->
        if is_map(msg) and Map.has_key?(msg, :__struct__) and mod != msg.__struct__ do
          {:error, "got #{msg.__struct__} but expected #{mod}"}
        else
          verify(mod.new!(msg))
        end
    end
  end

  @spec do_verify(struct, MessageProps.t()) :: :ok | {:error, String.t()}
  defp do_verify(struct, %{field_props: field_props} = props) do
    syntax = props.syntax

    with {:ok, oneofs} <- oneof_actual_vals(props, struct),
         :ok <- verify_fields(Map.values(field_props), syntax, struct, oneofs) do
      if syntax == :proto2 do
        verify_extensions(struct)
      else
        :ok
      end
    else
      :ok -> :ok
      {:error, message} -> {:error, message}
    end
  end

  defp verify_fields(fields, syntax, struct, oneofs) do
    Enum.map(fields, fn %{name_atom: name, oneof: oneof} = prop ->
      val =
        if oneof do
          oneofs[name]
        else
          case struct do
            %{^name => v} -> v
            _ -> nil
          end
        end

      if skip_field?(syntax, val, prop) || skip_enum?(prop, val) do
        :ok
      else
        verify_field(class_field(prop), val, prop)
        |> wrap_error(struct, prop)
      end
    end)
    |> first_non_ok_value_if_present()
  end

  defp wrap_error(:ok, _struct, _prop), do: :ok

  defp wrap_error({:error, msg}, struct, prop) do
    wrapped_msg =
      "Got error when verifying the values of #{inspect(struct.__struct__)}##{prop.name_atom}: #{
        msg
      }"

    {:error, wrapped_msg}
  end

  def skip_field?(_syntax, val, %{type: type, options: options} = prop) when not is_nil(options),
    do: FieldOptionsProcessor.skip_verify?(type, val, prop, options)

  def skip_field?(_, [], _), do: true
  def skip_field?(_, v, _) when map_size(v) == 0, do: true
  def skip_field?(:proto2, _, %{optional?: true}), do: true
  def skip_field?(:proto3, nil, _), do: true
  def skip_field?(_, _, _), do: false

  @spec verify_field(atom, any, FieldProps.t()) :: :ok | {:error, String.t()}
  defp verify_field(
         :normal,
         val,
         %{type: type, repeated?: is_repeated} = prop
       ) do
    repeated_or_not(val, is_repeated, fn v ->
      if is_nil(prop.options) do
        verify_type(type, v)
      else
        FieldOptionsProcessor.verify_type(type, v, prop.options)
      end
    end)
    |> first_non_ok_value_if_present()
  end

  # The guard ensures that val's type matches the is_repeated or is_map parameters
  defp verify_field(
         :embedded,
         val,
         %{repeated?: is_repeated, map?: is_map, type: type} = prop
       )
       when (is_repeated and is_list(val)) or (is_map and is_map(val)) or
              (not is_repeated and not is_map) do
    repeated = is_repeated or is_map

    repeated_or_not(val, repeated, fn v ->
      v = if is_map, do: struct(prop.type, %{key: elem(v, 0), value: elem(v, 1)}), else: v

      if is_nil(prop.options) do
        verify(type, v)
      else
        FieldOptionsProcessor.verify_type(type, v, prop.options)
      end
    end)
    |> first_non_ok_value_if_present()
  end

  # A catchall for params that don't match the verify_field(:embedded) guard above
  defp verify_field(:embedded, val, prop),
    do:
      {:error,
       "Got a value: #{inspect(val)} that isn't a map or list for the repeated or map field #{
         prop.name_atom
       }"}

  defp repeated_or_not(val, true = _repeated, func), do: Enum.map(val, func)
  defp repeated_or_not(val, false = _repeated, func), do: [func.(val)]

  # NOTE: This can aggregate all of the errors if we want
  defp first_non_ok_value_if_present([]), do: :ok
  defp first_non_ok_value_if_present([:ok | rest]), do: first_non_ok_value_if_present(rest)
  defp first_non_ok_value_if_present([non_ok_value | _rest]), do: non_ok_value

  @spec class_field(map) :: atom
  defp class_field(%{wire_type: wire_delimited(), embedded?: true}), do: :embedded
  defp class_field(_), do: :normal

  @spec verify_type(atom, any) :: :ok
  def verify_type(:string, n) when is_binary(n), do: :ok
  def verify_type(:bool, true), do: :ok
  def verify_type(:bool, false), do: :ok
  def verify_type(:float, :infinity), do: :ok
  def verify_type(:float, :negative_infinity), do: :ok
  def verify_type(:float, :nan), do: :ok
  def verify_type(:float, n) when is_number(n), do: :ok
  def verify_type(:double, :infinity), do: :ok
  def verify_type(:double, :negative_infinity), do: :ok
  def verify_type(:double, :nan), do: :ok
  def verify_type(:double, n) when is_number(n), do: :ok
  def verify_type(:bytes, n) when is_binary(n), do: :ok
  def verify_type(:int32, n) when is_integer(n) and n >= -0x80000000 and n <= 0x7FFFFFFF, do: :ok

  def verify_type(:int64, n)
      when is_integer(n) and n >= -0x8000000000000000 and n <= 0x7FFFFFFFFFFFFFFF,
      do: :ok

  def verify_type(:uint32, n) when is_integer(n) and n >= 0 and n <= 0xFFFFFFFF, do: :ok
  def verify_type(:uint64, n) when is_integer(n) and n >= 0 and n <= 0xFFFFFFFFFFFFFFFF, do: :ok
  def verify_type(:sint32, n) when is_integer(n) and n >= -0x80000000 and n <= 0x7FFFFFFF, do: :ok

  def verify_type(:sint64, n)
      when is_integer(n) and n >= -0x8000000000000000 and n <= 0x7FFFFFFFFFFFFFFF,
      do: :ok

  def verify_type(:fixed64, n) when is_integer(n) and n >= 0 and n <= 0xFFFFFFFFFFFFFFFF, do: :ok

  def verify_type(:sfixed64, n)
      when is_integer(n) and n >= -0x8000000000000000 and n <= 0x7FFFFFFFFFFFFFFF,
      do: :ok

  def verify_type(:fixed32, n) when is_integer(n) and n >= 0 and n <= 0xFFFFFFFF, do: :ok

  def verify_type(:sfixed32, n) when is_integer(n) and n >= -0x80000000 and n <= 0x7FFFFFFF,
    do: :ok

  def verify_type({:enum, type}, n) when is_atom(n) do
    if type.mapping() |> Map.has_key?(n) do
      :ok
    else
      {:error, "#{inspect(n)} is not a valid value in enum #{type}"}
    end
  end

  def verify_type({:enum, type}, n) when is_integer(n) do
    if type.__reverse_mapping__() |> Map.has_key?(n) do
      :ok
    else
      {:error, "#{inspect(n)} is not a valid value in enum #{type}"}
    end
  end

  # Enum failure case
  def verify_type({:enum, type}, n) do
    {:error, "#{inspect(n)} is invalid for type #{type}"}
  end

  # General failure case
  def verify_type(type, n) do
    {:error, "#{inspect(n)} is invalid for type #{type}"}
  end

  defp skip_enum?(%{type: type, options: options} = prop, value) when not is_nil(options) do
    FieldOptionsProcessor.skip_verify?(type, value, prop, options)
  end

  defp skip_enum?(%{type: _type}, nil), do: true
  defp skip_enum?(%{type: _type}, _value), do: false

  defp oneof_actual_vals(
         %{field_tags: field_tags, field_props: field_props, oneof: oneof},
         struct
       ) do
    result =
      Enum.reduce_while(oneof, %{}, fn {field, index}, acc ->
        case Map.get(struct, field, nil) do
          {f, val} ->
            %{oneof: oneof} = field_props[field_tags[f]]

            if oneof != index do
              {:halt, {:error, ":#{f} doesn't belong to #{inspect(struct.__struct__)}##{field}"}}
            else
              {:cont, Map.put(acc, f, val)}
            end

          nil ->
            {:cont, acc}

          _ ->
            {:halt,
             {:error,
              "#{inspect(struct.__struct__)}##{field} has the wrong structure: the value of a oneof field should be nil or {key, val} where key = atom of a field name inside the oneof and val = its value"}}
        end
      end)

    case result do
      {:error, message} -> {:error, message}
      successful_result -> {:ok, successful_result}
    end
  end

  defp verify_extensions(%mod{__pb_extensions__: pb_exts}) when is_map(pb_exts) do
    Enum.map(pb_exts, fn {{ext_mod, key}, val} ->
      case Protobuf.Extension.get_extension_props(mod, ext_mod, key) do
        %{field_props: prop} ->
          if !skip_field?(:proto2, val, prop) || !skip_enum?(prop, val) do
            verify_field(class_field(prop), val, prop)
          end

        _ ->
          :ok
      end
    end)
    |> first_non_ok_value_if_present()
  end

  defp verify_extensions(_), do: :ok
end