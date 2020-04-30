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

  @doc """
  Instantiates an `Ecto.Schema` struct from a StreamData [gen/1](`ExUnitProperties.gen/1`) macro.

  ## Examples

      defmodule Factory do
        use EctoStreamFactory, repo: Repo

        def user_generator do
          gen all name <- string(:alphanumeric, min_length: 1),
                  age <- integer(18..80) do
            %User{name: name, age: age}
          end
        end
      end

      iex> Factory.build(:user)
      %User{id: nil, name: "a", age: 33}

      # generated attributes can be overwritten
      iex> Factory.build(:user, name: "foo")
      %User{id: nil, name: "foo", age: 49}
  """
  @callback build(generator_name :: atom(), attrs :: Keyword.t()) :: Ecto.Schema.t()

  @doc ~S"""
  Same as `c:build/2`, but instantiates a list of structs.

  Accepts one-arity functions to generate sequential values.

  ## Examples

      iex> Factory.build_list(2, :user, name: fn n -> "user#{n + 1}" end)
      [%User{id: nil, name: "user1"}, %User{id: nil, name: "user2"}]
  """
  @callback build_list(amount :: pos_integer(), generator_name :: atom(), attrs :: Keyword.t()) ::
              nonempty_list(Ecto.Schema.t())

  @doc """
  Same as `c:build/2`, but also inserts a struct into the database.

  Accepts and forwards all the options directly to `c:Ecto.Repo.insert/2`

  ## Examples

      iex> Factory.insert(:user, [email: "duplicated@example.com"], on_conflict: :nothing)
      %User{id: 2, email: "duplicated@example.com"}
  """
  @callback insert(generator_name :: atom(), attrs :: Keyword.t(), opts :: Keyword.t()) ::
              Ecto.Schema.t()

  @doc """
  Same as `c:insert/3`, but inserts a list of structs.

  ## Examples

      iex> Factory.insert_list(3, :user, role: "admin")
      [%User{id: 3, role: "admin"}, %User{id: 4, role: "admin"}, %User{id: 5, role: "admin"}]
  """
  @callback insert_list(
              amount :: pos_integer(),
              generator_name :: atom(),
              attrs :: Keyword.t(),
              opts :: Keyword.t()
            ) :: Ecto.Schema.t()
end
