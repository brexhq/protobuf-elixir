defmodule Protobuf.DSL do
  @doc """
  Define a field in the message module.
  """
  defmacro field(name, fnum, options \\ []) do
    quote do
      @fields {unquote(name), unquote(fnum), unquote(options)}
    end
  end

  @doc """
  Define oneof in the message module.
  """
  defmacro oneof(name, index) do
    quote do
      @oneofs {unquote(name), unquote(index)}
    end
  end

  @doc """
  Define "extend" for a message(the first argument module).
  """
  defmacro extend(mod, name, fnum, options) do
    quote do
      @extends {unquote(mod), unquote(name), unquote(fnum), unquote(options)}
    end
  end

  @doc """
  Define extensions range in the message module to allow extensions for this module.
  """
  defmacro extensions(ranges) do
    quote do
      @extensions unquote(ranges)
    end
  end

  defmacro option([{option, value}]) do
    # option (brex.elixirpb.enum).deprefix = true;
    quote do
      @msg_options {unquote(option), unquote(value)}
    end
  end

  defmacro __before_compile__(env) do
    fields = Module.get_attribute(env.module, :fields)
    options = Module.get_attribute(env.module, :options)

    # When you compile .proto files into .pb.ex files, there's a
    # Brex-specific flag called "custom_field_options" that turns on or off
    # Brex's custom option handling. At first it was only being used for
    # field options, but now it's used for field, enum, and file options.
    custom_options = Keyword.get(options, :custom_field_options?)

    extension_props =
      Module.get_attribute(env.module, :extends)
      |> gen_extension_props()

    extensions = Module.get_attribute(env.module, :extensions)
    msg_options = Module.get_attribute(env.module, :msg_options)
    syntax = Keyword.get(options, :syntax, :proto2)
    oneofs = Module.get_attribute(env.module, :oneofs)
    msg_props = generate_msg_props(fields, oneofs, extensions, options, msg_options)
    default_fields = generate_default_fields(syntax, msg_props)
    default_struct = Map.put(default_fields, :__struct__, env.module)

    default_struct =
      if syntax == :proto2 and extensions do
        Map.put(default_struct, :__pb_extensions__, %{})
      else
        default_struct
      end

    quote do
      def __message_props__ do
        unquote(Macro.escape(msg_props))
      end

      unquote(def_enum_functions(msg_props, fields, env.module, custom_options))

      if unquote(Macro.escape(extension_props)) != nil do
        def __protobuf_info__(:extension_props) do
          unquote(Macro.escape(extension_props))
        end
      end

      def __protobuf_info__(_) do
        nil
      end

      if unquote(Macro.escape(extensions)) do
        unquote(def_extension_functions())
      end

      if unquote(syntax == :proto3) do
        def __default_struct__ do
          unquote(Macro.escape(default_struct))
        end
      else
        def __default_struct__ do
          unquote(Macro.escape(default_struct))
        end
      end
    end
  end

  defp def_enum_functions(
         %{syntax: syntax, enum?: true, field_props: props, options: enum_options},
         fields,
         module,
         custom_options
       ) do
    if syntax == :proto3 do
      unless props[0], do: raise("The first enum value must be zero in proto3")
    end

    {atom_to_num, num_to_atom, string_or_num_to_atom, extra_enum_defs} =
      if is_nil(enum_options) or is_nil(custom_options) do
        use_standard_mappings(props, fields, module)
      else
        Protobuf.EnumOptionsProcessor.generate_mappings(module, props, fields, enum_options)
      end

    Enum.map(atom_to_num, fn {name_atom, fnum} ->
      quote do
        def value(unquote(name_atom)), do: unquote(fnum)
      end
    end) ++
      [
        quote do
          def value(v) when is_integer(v), do: v
        end
      ] ++
      Enum.map(num_to_atom, fn {fnum, name_atom} ->
        quote do
          def key(unquote(fnum)), do: unquote(name_atom)
        end
      end) ++
      [
        quote do
          def mapping(), do: unquote(Macro.escape(atom_to_num))
        end,
        quote do
          def __reverse_mapping__(), do: unquote(Macro.escape(string_or_num_to_atom))
        end
      ] ++ extra_enum_defs
  end

  defp def_enum_functions(_, _, _, _), do: nil

  defp use_standard_mappings(props, fields, module) do
    atom_to_num = for {name_atom, fnum, _opts} <- fields, do: {name_atom, fnum}, into: %{}

    num_to_atom = for {fnum, %{name_atom: name_atom}} <- props, do: {fnum, name_atom}

    string_or_num_to_atom =
      for {fnum, %{name: name, name_atom: name_atom}} <- props,
          key <- [fnum, name],
          do: {key, name_atom},
          into: %{}

    prefix =
      module
      |> Protobuf.Protoc.Generator.Util.mod_to_name()
      |> Kernel.<>("_")
      |> String.upcase()

    is_prefixed? =
      Enum.all?(props, fn {_, %{name: name}} -> String.starts_with?(name, prefix) end)

    prefix_fun =
      quote do
        def prefix(), do: unquote(if is_prefixed?, do: prefix, else: "")
      end

    {atom_to_num, num_to_atom, string_or_num_to_atom, [prefix_fun]}
  end

  defp def_extension_functions() do
    quote do
      def put_extension(%__MODULE__{} = struct, extension_mod, field, value) do
        Protobuf.Extension.put(__MODULE__, struct, extension_mod, field, value)
      end

      def put_extension(%{} = map, extension_mod, field, value) do
        Protobuf.Extension.put(__MODULE__, map, extension_mod, field, value)
      end

      def get_extension(struct, extension_mod, field, default \\ nil) do
        Protobuf.Extension.get(struct, extension_mod, field, default)
      end
    end
  end

  defp generate_msg_props(fields, oneofs, extensions, options, msg_options) do
    syntax = Keyword.get(options, :syntax, :proto2)
    field_props = field_props_map(syntax, fields)

    repeated_fields =
      field_props
      |> Map.values()
      |> Enum.filter(fn props -> props.repeated? end)
      |> Enum.map(fn props -> Map.get(props, :name_atom) end)

    embedded_fields =
      field_props
      |> Map.values()
      |> Enum.filter(fn props -> props.embedded? && !props.map? end)
      |> Enum.map(fn props -> Map.get(props, :name_atom) end)

    %Protobuf.MessageProps{
      tags_map: tags_map(fields),
      ordered_tags: ordered_tags(fields),
      field_props: field_props,
      field_tags: field_tags(fields),
      repeated_fields: repeated_fields,
      embedded_fields: embedded_fields,
      syntax: syntax,
      oneof: Enum.reverse(oneofs),
      enum?: Keyword.get(options, :enum) == true,
      map?: Keyword.get(options, :map) == true,
      extension_range: extensions,
      options: if(msg_options == [], do: nil, else: msg_options)
    }
  end

  defp gen_extension_props([_ | _] = extends) do
    extensions =
      Map.new(extends, fn {extendee, name_atom, fnum, opts} ->
        # Only proto2 has extensions
        props = field_props(:proto2, name_atom, fnum, opts)

        props = %Protobuf.Extension.Props.Extension{
          extendee: extendee,
          field_props: props
        }

        {{extendee, fnum}, props}
      end)

    name_to_tag =
      Map.new(extends, fn {extendee, name_atom, fnum, _opts} ->
        {{extendee, name_atom}, {extendee, fnum}}
      end)

    %Protobuf.Extension.Props{extensions: extensions, name_to_tag: name_to_tag}
  end

  defp gen_extension_props(_) do
    nil
  end

  defp tags_map(fields) do
    fields
    |> Enum.map(fn {_, fnum, _} -> {fnum, fnum} end)
    |> Enum.into(%{})
  end

  defp ordered_tags(fields) do
    fields
    |> Enum.map(fn {_, fnum, _} -> fnum end)
    |> Enum.sort()
  end

  defp field_props_map(syntax, fields) do
    fields
    |> Enum.map(fn {name, fnum, opts} -> {fnum, field_props(syntax, name, fnum, opts)} end)
    |> Enum.into(%{})
  end

  defp field_tags(fields) do
    fields
    |> Enum.map(fn {name, fnum, _} -> {name, fnum} end)
    |> Enum.into(%{})
  end

  defp field_props(syntax, name, fnum, opts) do
    props = %Protobuf.FieldProps{
      fnum: fnum,
      name: to_string(name),
      name_atom: name
    }

    opts_map = Enum.into(opts, %{})
    # parse simple fields then calculate others in cal_*
    parts =
      opts
      |> parse_field_opts(opts_map)
      |> cal_label(syntax)
      |> cal_type()
      |> cal_json_name(props.name)
      |> cal_default(syntax)
      |> cal_embedded()
      |> cal_packed(syntax)
      |> cal_repeated(opts_map)
      |> cal_deprecated()

    struct(props, parts)
    |> cal_encoded_fnum()
  end

  defp parse_field_opts([{:optional, true} | t], acc) do
    parse_field_opts(t, Map.put(acc, :optional?, true))
  end

  defp parse_field_opts([{:required, true} | t], acc) do
    parse_field_opts(t, Map.put(acc, :required?, true))
  end

  defp parse_field_opts([{:enum, true} | t], acc) do
    parse_field_opts(t, Map.put(acc, :enum?, true))
  end

  defp parse_field_opts([{:map, true} | t], acc) do
    parse_field_opts(t, Map.put(acc, :map?, true))
  end

  defp parse_field_opts([{:default, default} | t], acc) do
    parse_field_opts(t, Map.put(acc, :default, default))
  end

  defp parse_field_opts([{:oneof, oneof} | t], acc) do
    parse_field_opts(t, Map.put(acc, :oneof, oneof))
  end

  defp parse_field_opts([{:json_name, json_name} | t], acc) do
    parse_field_opts(t, Map.put(acc, :json_name, json_name))
  end

  # skip unknown option
  defp parse_field_opts([{_, _} | t], acc) do
    parse_field_opts(t, acc)
  end

  defp parse_field_opts(_, acc), do: acc

  defp cal_label(%{required?: true}, :proto3) do
    raise Protobuf.InvalidError, message: "required can't be used in proto3"
  end

  defp cal_label(props, :proto3) do
    Map.put(props, :optional?, true)
  end

  defp cal_label(props, _), do: props

  defp cal_type(%{enum?: true, type: type} = props) do
    Map.merge(props, %{type: {:enum, type}, wire_type: Protobuf.Encoder.wire_type(:enum)})
  end

  defp cal_type(%{type: type} = props) do
    Map.merge(props, %{type: type, wire_type: Protobuf.Encoder.wire_type(type)})
  end

  defp cal_type(props), do: props

  # The compiler always emits a json name, but we omit it in the DSL when it
  # matches the name, to keep it uncluttered. Now we infer it back from name.
  defp cal_json_name(%{json_name: _} = props, _name), do: props
  defp cal_json_name(props, name), do: Map.put(props, :json_name, name)

  defp cal_default(%{default: default}, :proto3) when not is_nil(default) do
    raise Protobuf.InvalidError, message: "default can't be used in proto3"
  end

  defp cal_default(props, _), do: props

  defp cal_embedded(%{type: type} = props) when is_atom(type) do
    case to_string(type) do
      "Elixir." <> _ -> Map.put(props, :embedded?, !props[:enum?])
      _ -> props
    end
  end

  defp cal_embedded(props), do: props

  defp cal_packed(%{packed: true, repeated: repeated} = props, _) do
    cond do
      props[:embedded?] -> raise ":packed can't be used with :embedded field"
      repeated -> Map.put(props, :packed?, true)
      true -> raise ":packed must be used with :repeated"
    end
  end

  defp cal_packed(%{packed: false} = props, _) do
    Map.put(props, :packed?, false)
  end

  defp cal_packed(%{repeated: repeated, type: type} = props, :proto3) do
    packed = (props[:enum?] || !props[:embedded?]) && type_numeric?(type)

    if packed && !repeated do
      raise ":packed must be used with :repeated"
    else
      Map.put(props, :packed?, packed)
    end
  end

  defp cal_packed(props, _), do: Map.put(props, :packed?, false)

  defp cal_repeated(%{map?: true} = props, _), do: Map.put(props, :repeated?, false)
  defp cal_repeated(props, %{repeated: true}), do: Map.put(props, :repeated?, true)

  defp cal_repeated(_props, %{repeated: true, oneof: true}),
    do: raise(":oneof can't be used with repeated")

  defp cal_repeated(props, _), do: props

  defp cal_deprecated(%{deprecated: true} = props), do: Map.put(props, :deprecated?, true)
  defp cal_deprecated(props), do: props

  defp cal_encoded_fnum(%{fnum: fnum, packed?: true} = props) do
    encoded_fnum = Protobuf.Encoder.encode_fnum(fnum, Protobuf.Encoder.wire_type(:bytes))
    Map.put(props, :encoded_fnum, encoded_fnum)
  end

  defp cal_encoded_fnum(%{fnum: fnum, wire_type: wire} = props) when is_integer(wire) do
    encoded_fnum = Protobuf.Encoder.encode_fnum(fnum, wire)
    Map.put(props, :encoded_fnum, encoded_fnum)
  end

  defp cal_encoded_fnum(props) do
    props
  end

  defp generate_default_fields(syntax, msg_props) do
    fields =
      msg_props.field_props
      |> Map.values()
      |> Enum.reduce(%{}, fn props, acc ->
        if props.oneof do
          acc
        else
          Map.put(acc, props.name_atom, Protobuf.Builder.field_default(syntax, props))
        end
      end)

    Enum.reduce(msg_props.oneof, fields, fn {key, _}, acc ->
      Map.put(acc, key, nil)
    end)
  end

  defp type_numeric?(:int32), do: true
  defp type_numeric?(:int64), do: true
  defp type_numeric?(:uint32), do: true
  defp type_numeric?(:uint64), do: true
  defp type_numeric?(:sint32), do: true
  defp type_numeric?(:sint64), do: true
  defp type_numeric?(:bool), do: true
  defp type_numeric?({:enum, _}), do: true
  defp type_numeric?(:fixed32), do: true
  defp type_numeric?(:sfixed32), do: true
  defp type_numeric?(:fixed64), do: true
  defp type_numeric?(:sfixed64), do: true
  defp type_numeric?(:float), do: true
  defp type_numeric?(:double), do: true
  defp type_numeric?(_), do: false
end
