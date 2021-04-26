**EctoStreamFactory** helps to utilize [StreamData generators](https://hexdocs.pm/stream_data/ExUnitProperties.html#gen/1)
as [Ecto factories](https://hexdocs.pm/ecto/test-factories.html).

You can define one factory and use it in the following scenarios:
* Regular unit/integration/acceptance tests
* Property-based tests
* Load/stress/performance tests
* Database seeding

[HexDocs](https://hexdocs.pm/ecto_stream_factory)

You can read about property-based testing in Fred Hebert's [book](https://pragprog.com/book/fhproper/property-based-testing-with-proper-erlang-and-elixir).

## Installation

Add EctoStreamFactory dependency to `mix.exs`:

```elixir
def deps do
  [
    {:ecto_stream_factory, "~> 0.1", only: [:test, :dev]}
  ]
end
```

Add `:stream_data` to your `.formatter.exs`:

```elixir
[
  import_deps: [:stream_data]
]
```

Create a factory module in `test/support/factory.ex`. Generator functions should have "_generator" suffix:

```elixir
defmodule MyApp.Factory do
  use EctoStreamFactory, repo: MyApp.Repo

  def user_generator do
    gen all name <- string(:alphanumeric, min_length: 1),
            age <- integer(15..80),
            email <- email_generator() do
      %MyApp.User{name: name, age: age, email: email}
    end
  end

  def post_generator do
    gen all author <- user_generator(),
            body <- string(:alphanumeric, min_length: 10) do
      %MyApp.Post{author: author, body: body}
    end
  end

  def email_generator do
    gen all username <- string(:alphanumeric, min_length: 1),
            domain <- member_of(~w(gmail.com protonmail.com yandex.com)) do
      "#{username}#{System.unique_integer([:positive, :monotonic])}@#{domain}"
    end
  end
end
```

Make sure that `mix.exs` is configured to compile the factory for required environments:

```elixir
def project do
  [
    elixirc_paths: elixirc_paths(Mix.env())
  ]
end

defp elixirc_paths(env) when env in [:test, :dev], do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```

Optionally import the factory in `.iex.exs` to simplify its usage inside `iex -S mix` console on your development machine:

```elixir
import MyApp.Factory
```

For a vanilla Elixir project you can import the factory in every test module with [ExUnti.CaseTemplate](https://hexdocs.pm/ex_unit/ExUnit.CaseTemplate.html).
Create a file `test/support/case.ex` and add:
```elixir
defmodule MyApp.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import MyApp.Factory
    end
  end
end
```
Then in your test files replase `use ExUnit.Case` with `use MyApp.Case`

For a Phoenix project you can import the factory in `support/data_case.ex`, `support/conn_case.ex`, `support/channel_case`:

```elixir
defmodule MyAppWeb.ConnCase do
  using do
    quote do
      ...
      import MyApp.Factory
    end
  end
end
```

## Usage in regular tests

```elixir
iex> build(:email)
"S1@protonmail.com"

iex> build(:user)
%User{id: nil, name: "a", age: 33, email: "I2@yandex.com"}

iex> build(:user, name: "Bob")
%User{id: nil, name: "Bob", age: 28, email: "S3@gmail.com"}

iex> build(:post, text: "Hello world")
%Post{id: nil, text: "Hello world", author: %User{id: nil, name: "b", age: 28, email: "l4@gmail.com"}}

iex> build_list(2, :user, name: fn n -> "user#{n}" end)
[%User{id: nil, name: "user1", age: 51, email: "n5@gmail.com"}, %User{id: nil, name: "user2", age: 40, email: "O6@yandex.com"}]

iex> insert!(:user)
%User{id: 1, name: "b", age: 23, email: "az7@gmail.com"}

iex> insert!(:user, gender: "female")
** (EctoStreamFactory.MissingKeyError) MyApp.Factory.user_generator does not generate :gender field.

iex> insert(:user, [email: "az7@gmail.com"], on_conflict: :nothing)
%User{id: nil, name: "c", age: 44, email: "az7@gmail.com"}

iex> insert(:post, author: build(:user, name: "Jane"))
%Post{id: 1, text: "kjfwi245lfh", author: %User{id: 2, name: "Jane", age: 34, email: "jhg8@yandex.com"}}

iex> insert_list(2, :user, age: 18)
[%User{id: 3, name: "bc", age: 18, email: "kl9@protonmail.com"}, %User{id: 4, name: "bd", age: 18, email: "hj10@yandex.com"}]
```

## Usage in property-based tests

```elixir
defmodule MyAppTest do
  use MyApp.Case, async: true
  use ExUnitProperties

  describe "user properties" do
    property "contact info contains user name and email" do
      check all user <- user_generator() do
        info = MyApp.User.contact_info(user) 
        assert String.starts_with?(info, user.name)
        assert info =~ user.email
      end
    end

    property "adult users older than 18" do
      check all user <- user_generator() do
        assert MyApp.User.adult?(user) == user.age >= 18
      end
    end
  end
end
```

## Usage in seeding the database

In `priv/repo/seeds.exs`

```elixir
import MyApp.Factory

insert_list(100, :post)
```
Then run it with `mix run priv/repo/seeds.exs`

## Advanced cases
### How to conditionally generate values based on the result of previous generators?

```elixir
def user_generator do
  gen all language_code <- member_of(~w(ru en)),
          last_name <- user_last_name(language_code) do
    %User{
      language_code: language_code,
      last_name: last_name
    }
  end
end

defp user_last_name("ru"), do: member_of(~w(Ivanov Petrov))
defp user_last_name("en"), do: member_of(~w(Smith Brown))
```

### How to modify the output of a generator inside another generator?

```elixir
def admin_generator do
  gen all admin <-
            bind(user_generator(), fn user ->
              Map.put(user, :type, "admin")
            end) do
    admin
  end
end
```
