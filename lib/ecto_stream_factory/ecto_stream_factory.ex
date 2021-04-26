defmodule EctoStreamFactory do
  @moduledoc """
  Defines a factory that can be used in tests and database seeds files.

  ## Examples

      defmodule MyApp.Factory do
        use EctoStreamFactory, repo: MyApp.Repo

        def user_generator do
          gen all name <- string(:alphanumeric, min_length: 1),
                  age <- integer(15..80) do
            %User{name: name, age: age}
          end
        end

        def post_generator do
          gen all author <- user_generator(),
                  body <- string(:alphanumeric, min_length: 10) do
            %Post{author: author, body: body}
          end
        end
      end
  """

  alias EctoStreamFactory.Factory
  alias Ecto.Schema

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use ExUnitProperties

      @repo Factory.get_repo(__MODULE__, opts)

      defguardp is_valid_generator_name(value) when is_atom(value) or is_binary(value)
      defguardp is_valid_amount(value) when is_integer(value) and value > 0

      def build(generator_name, attrs \\ []) when is_valid_generator_name(generator_name) do
        Factory.build(__MODULE__, generator_name, attrs)
      end

      def build!(generator_name, attrs \\ []) when is_valid_generator_name(generator_name) do
        Factory.build!(__MODULE__, generator_name, attrs)
      end

      def build_list(amount, generator_name, attrs \\ [])
          when is_valid_generator_name(generator_name) and
                 is_valid_amount(amount) do
        Factory.build_list(__MODULE__, amount, generator_name, attrs)
      end

      def build_list!(amount, generator_name, attrs \\ [])
          when is_valid_generator_name(generator_name) and
                 is_valid_amount(amount) do
        Factory.build_list!(__MODULE__, amount, generator_name, attrs)
      end

      def insert(generator_name, attrs \\ [], opts \\ [])
          when is_valid_generator_name(generator_name) do
        Factory.insert(__MODULE__, @repo, generator_name, attrs, opts)
      end

      def insert!(generator_name, attrs \\ [], opts \\ [])
          when is_valid_generator_name(generator_name) do
        Factory.insert!(__MODULE__, @repo, generator_name, attrs, opts)
      end

      def insert_list(amount, generator_name, attrs \\ [], opts \\ [])
          when is_valid_generator_name(generator_name) and is_valid_amount(amount) do
        Factory.insert_list(__MODULE__, @repo, amount, generator_name, attrs, opts)
      end

      def insert_list!(amount, generator_name, attrs \\ [], opts \\ [])
          when is_valid_generator_name(generator_name) and is_valid_amount(amount) do
        Factory.insert_list!(__MODULE__, @repo, amount, generator_name, attrs, opts)
      end
    end
  end

  @type generator_name() :: atom() | String.t()

  @typedoc """
    Keyword list or map where values can be of any literal types or one arity functions that generate sequential data.
  """
  @type overwrites() ::
          [{atom, term() | (non_neg_integer() -> term())}]
          | %{required(atom) => term() | (non_neg_integer() -> term())}

  @type amount() :: pos_integer()

  @typedoc """
    Same as options for `c:Ecto.Repo.insert/2`.
  """
  @type insert_opts() :: Keyword.t()

  @doc """
  Takes a single instance from a StreamData [gen/1](`ExUnitProperties.gen/1`) generator.

  If the generator returs a struct, map or keyword list, it also merges the result with `overwrites`.

  ## Examples

      iex> Factory.build(:user)
      %User{id: nil, name: "a", age: 33}

      iex> Factory.build(:user, name: "foo")
      %User{id: nil, name: "foo", age: 49}
  """
  @callback build(generator_name(), overwrites()) :: term()

  @doc """
  Same as `c:build/2`, but raises an error if some key in `overwrites` does not exist in the generated struct, map or keyword list.

  ## Examples

      iex> Factory.build!(:user)
      %User{id: nil, name: "b", age: 28}

      iex> Factory.build!(:user, name: "foo", weight: 101)
      ** (EctoStreamFactory.MissingKeyError) MyApp.Factory.user_generator does not generate :weight field.
  """
  @callback build!(generator_name(), overwrites()) :: term()

  @doc ~S"""
  Same as `c:build/2`, but instantiates a list of structs.

  ## Examples

      iex> Factory.build_list(2, :user, name: fn n -> "user#{n}" end)
      [%User{id: nil, name: "user1"}, %User{id: nil, name: "user2"}]
  """
  @callback build_list(amount(), generator_name(), overwrites) :: nonempty_list(term())

  @doc ~S"""
  Same as `c:build_list/3`, but raises an error if some key in `overwites` does not exist in the generated entities.
  """
  @callback build_list!(amount(), generator_name(), overwrites) :: nonempty_list(term())

  @doc """
  Similar to `c:build/2`, but expects a generator to return an Ecto.Schema struct to insert it into the database.

  ## Examples

      iex> Factory.insert(:user, [email: "duplicated@example.com"], on_conflict: :nothing)
      %User{id: 2, email: "duplicated@example.com"}
  """
  @callback insert(generator_name(), overwrites(), insert_opts()) :: Schema.t()

  @doc """
  Same as `c:insert/3`, but raises an error if some key in `overwites` does not exist in the generated struct.
  """
  @callback insert!(generator_name(), overwrites(), insert_opts()) :: Schema.t()

  @doc """
  Same as `c:insert/3`, but inserts a list of structs.

  ## Examples

      iex> Factory.insert_list(3, :user, role: "admin")
      [%User{id: 3, role: "admin"}, %User{id: 4, role: "admin"}, %User{id: 5, role: "admin"}]
  """
  @callback insert_list(amount(), generator_name(), overwrites(), insert_opts()) ::
              nonempty_list(Schema.t())

  @doc ~S"""
  Same as `c:insert_list/4`, but raises an error if some key in `overwites` does not exist in the generated structs.
  """
  @callback insert_list!(amount(), generator_name(), overwrites(), insert_opts()) ::
              nonempty_list(Schema.t())
end
