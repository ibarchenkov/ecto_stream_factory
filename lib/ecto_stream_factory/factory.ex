defmodule EctoStreamFactory.Factory do
  @moduledoc false

  def build(module, generator_name, attrs) do
    module
    |> build_list(1, generator_name, attrs)
    |> hd()
  end

  def build_list(module, count, generator_name, attrs) do
    module
    |> create_records_stream(generator_name, attrs)
    |> Enum.take(count)
  end

  def insert(module, repo, generator_name, attrs, opts) do
    module
    |> insert_list(repo, 1, generator_name, attrs, opts)
    |> hd()
  end

  def insert_list(module, repo, count, generator_name, attrs, opts) do
    module
    |> create_records_stream(generator_name, attrs)
    |> Stream.map(&insert_record(&1, repo, opts))
    |> Enum.take(count)
  end

  defp create_records_stream(module, generator_name, attrs) do
    module
    |> create_stream(generator_name)
    |> Stream.with_index(1)
    |> Stream.map(&merge_attributes(&1, attrs))
  end

  defp merge_attributes({record, index}, attrs) when is_struct(record) do
    struct(record, prepare_attributes(attrs, index))
  end

  defp merge_attributes({map, index}, attrs) when is_map(map) do
    attrs = attrs |> prepare_attributes(index) |> Map.new()
    Map.merge(map, attrs)
  end

  defp merge_attributes({maybe_keyword, index}, attrs) do
    if Keyword.keyword?(maybe_keyword) do
      Keyword.merge(maybe_keyword, prepare_attributes(attrs, index))
    else
      maybe_keyword
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
        module: module_to_string(module),
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
      _ -> raise EctoStreamFactory.RepoNotSpecifiedError, module: module_to_string(module)
    end
  end

  defp module_to_string(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
