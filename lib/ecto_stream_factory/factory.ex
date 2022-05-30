defmodule EctoStreamFactory.Factory do
  @moduledoc false

  def build(module, generator_name, attrs) do
    do_build(module, generator_name, attrs, &build_list/4)
  end

  def build!(module, generator_name, attrs) do
    do_build(module, generator_name, attrs, &build_list!/4)
  end

  defp do_build(module, generator_name, attrs, build_list_fun) do
    module
    |> build_list_fun.(1, generator_name, attrs)
    |> hd()
  end

  def build_list(module, count, generator_name, attrs) do
    do_build_list(module, count, generator_name, attrs, &create_records_stream/3)
  end

  def build_list!(module, count, generator_name, attrs) do
    do_build_list(module, count, generator_name, attrs, &create_records_stream!/3)
  end

  defp do_build_list(module, count, generator_name, attrs, create_records_stream_fun) do
    module
    |> create_records_stream_fun.(generator_name, attrs)
    |> Enum.take(count)
  end

  def insert(module, repo, generator_name, attrs, opts) do
    do_insert(module, repo, generator_name, attrs, opts, &insert_list/6)
  end

  def insert!(module, repo, generator_name, attrs, opts) do
    do_insert(module, repo, generator_name, attrs, opts, &insert_list!/6)
  end

  def do_insert(module, repo, generator_name, attrs, opts, insert_list_fun) do
    module
    |> insert_list_fun.(repo, 1, generator_name, attrs, opts)
    |> hd()
  end

  def insert_list(module, repo, count, generator_name, attrs, opts) do
    do_insert_list(module, repo, count, generator_name, attrs, opts, &create_records_stream/3)
  end

  def insert_list!(module, repo, count, generator_name, attrs, opts) do
    do_insert_list(module, repo, count, generator_name, attrs, opts, &create_records_stream!/3)
  end

  def do_insert_list(module, repo, count, generator_name, attrs, opts, create_records_stream_fun) do
    module
    |> create_records_stream_fun.(generator_name, attrs)
    |> Stream.map(&insert_record(&1, repo, opts))
    |> Enum.take(count)
  end

  defp create_records_stream(module, generator_name, attrs) do
    do_create_records_stream(module, generator_name, attrs, &merge_attributes/4)
  end

  defp create_records_stream!(module, generator_name, attrs) do
    do_create_records_stream(module, generator_name, attrs, &merge_attributes!/4)
  end

  defp do_create_records_stream(module, generator_name, attrs, merge_attrs_fun) do
    module
    |> create_stream(generator_name)
    |> Stream.with_index(1)
    |> Stream.map(&merge_attrs_fun.(&1, Map.new(attrs), module, generator_name))
  end

  defp merge_attributes({record, index}, attrs, _, _) when is_struct(record) do
    struct(record, prepare_attributes(attrs, index))
  end

  defp merge_attributes({map, index}, attrs, _, _) when is_map(map) do
    attrs = attrs |> prepare_attributes(index) |> Map.new()
    # refactor to `then/2` when we require Elixir 1.12
    Map.merge(map, attrs)
  end

  defp merge_attributes({maybe_keyword, index}, attrs, _, _) do
    if Keyword.keyword?(maybe_keyword) do
      Keyword.merge(maybe_keyword, prepare_attributes(attrs, index))
    else
      maybe_keyword
    end
  end

  defp merge_attributes!({record, index}, attrs, module, generator_name) when is_struct(record) do
    try do
      struct!(record, prepare_attributes(attrs, index))
    rescue
      err in KeyError ->
        raise EctoStreamFactory.MissingKeyError,
          module: module,
          generator_name: generator_name,
          key: err.key
    end
  end

  defp merge_attributes!({map, index}, attrs, module, generator_name) when is_map(map) do
    check_missing_key(map, attrs, &Map.has_key?/2, module, generator_name)

    merge_attributes({map, index}, attrs, module, generator_name)
  end

  defp merge_attributes!({maybe_keyword, index}, attrs, module, generator_name) do
    if Keyword.keyword?(maybe_keyword) do
      check_missing_key(maybe_keyword, attrs, &Keyword.has_key?/2, module, generator_name)
    end

    merge_attributes({maybe_keyword, index}, attrs, module, generator_name)
  end

  defp check_missing_key(map_or_keyword, attrs, has_key_fun, module, generator_name) do
    missing_key =
      attrs
      |> Map.keys()
      |> Enum.find_value(fn key ->
        if has_key_fun.(map_or_keyword, key) do
          false
        else
          key
        end
      end)

    if missing_key do
      raise EctoStreamFactory.MissingKeyError,
        module: module,
        generator_name: generator_name,
        key: missing_key
    end
  end

  defp prepare_attributes(attrs, index) do
    Enum.map(attrs, fn
      {key, fun} when is_function(fun, 1) ->
        {key, fun.(index)}

      {_key, _val} = result ->
        result
    end)
  end

  defp insert_record(record, repo, opts) do
    apply(repo, :insert!, [record, opts])
  end

  defp create_stream(module, generator_name) do
    function_name = function_from_generator_name(generator_name)

    if function_exported?(module, function_name, 0) do
      apply(module, function_name, [])
    else
      raise EctoStreamFactory.UndefinedGeneratorError,
        module: module,
        generator_name: generator_name
    end
  end

  def function_from_generator_name(generator_name) when is_atom(generator_name) do
    generator_name |> Atom.to_string() |> function_from_generator_name()
  end

  def function_from_generator_name(generator_name) when is_binary(generator_name) do
    generator_name |> Kernel.<>("_generator") |> String.to_atom()
  end

  def get_repo(module, opts) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} -> repo
      _ -> raise EctoStreamFactory.RepoNotSpecifiedError, module: module
    end
  end
end
