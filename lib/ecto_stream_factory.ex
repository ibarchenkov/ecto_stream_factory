defmodule EctoStreamFactory do
  @moduledoc """
  Fill me
  """

  defmacro __using__(opts) do
    repo = Keyword.fetch!(opts, :repo)

    quote do
      use ExUnitProperties

      def build(generator_name, attrs \\ []) do
        unquote(__MODULE__).build(__MODULE__, generator_name, attrs)
      end

      def build_list(count, generator_name, attrs \\ []) do
        unquote(__MODULE__).build_list(__MODULE__, count, generator_name, attrs)
      end

      def insert(generator_name, attrs \\ [], opts \\ []) do
        unquote(__MODULE__).insert(__MODULE__, unquote(repo), generator_name, attrs, opts)
      end

      def insert_list(count, generator_name, attrs \\ [], opts \\ []) do
        unquote(__MODULE__).insert_list(
          __MODULE__,
          unquote(repo),
          count,
          generator_name,
          attrs,
          opts
        )
      end
    end
  end

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
    |> Stream.with_index()
    |> Stream.map(&merge_attributes(&1, attrs))
  end

  defp merge_attributes({record, index}, attrs) do
    struct!(record, prepare_attributes(attrs, index))
  end

  defp prepare_attributes(attrs, index) do
    Enum.map(attrs, fn
      {key, fun} when is_function(fun, 1) ->
        {key, fun.(index)}

      {_key, _val} = result ->
        result
    end)
  end

  defp execute_attribute_function({key, fun}, index) when is_function(fun, 1) do
    {key, fun.(index)}
  end

  defp execute_attribute_function({_key, _val} = result, _index) do
    result
  end

  defp insert_record(record, repo, opts) do
    apply(repo, :insert!, [record, opts])
  end

  defp create_stream(module, generator_name) do
    apply(module, function_from_generator(generator_name), [])
  end

  defp function_from_generator(generator_name) do
    String.to_existing_atom(to_string(generator_name) <> "_generator")
  end
end
