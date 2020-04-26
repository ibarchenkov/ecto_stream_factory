defmodule EctoStreamFactory do
  @moduledoc """
  Fill me
  """

  alias EctoStreamFactory.Factory

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use ExUnitProperties

      @repo Factory.get_repo(__MODULE__, opts)

      def build(generator_name, attrs \\ []) when is_atom(generator_name) do
        Factory.build(__MODULE__, generator_name, attrs)
      end

      def build_list(amount, generator_name, attrs \\ [])
          when is_integer(amount) and amount > 0 and is_atom(generator_name) do
        Factory.build_list(__MODULE__, amount, generator_name, attrs)
      end

      def insert(generator_name, attrs \\ [], opts \\ []) when is_atom(generator_name) do
        Factory.insert(__MODULE__, @repo, generator_name, attrs, opts)
      end

      def insert_list(amount, generator_name, attrs \\ [], opts \\ [])
          when is_atom(generator_name) do
        Factory.insert_list(__MODULE__, @repo, amount, generator_name, attrs, opts)
      end
    end
  end
end
