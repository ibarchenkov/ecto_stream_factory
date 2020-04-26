defmodule EctoStreamFactoryTest do
  use ExUnit.Case, async: true

  import EctoStreamFactory.TestFactory
  import Ecto.Query, only: [order_by: 2]
  alias EctoStreamFactory.Repo
  alias EctoStreamFactory.User

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "build/2" do
    test "without attrs" do
      user = build(:user)

      assert is_nil(user.id)
      assert String.length(user.name) >= 1
      assert 18 <= user.age and user.age <= 80
    end

    test "with custom attrs" do
      user = build(:user, id: &(&1 + 1), age: 10)

      assert user.id == 1
      assert user.age == 10
    end

    test "when trying to set a non-existent attr" do
      assert_raise KeyError, fn ->
        build(:user, foo: "bar")
      end
    end

    test "when trying to build a non-existent record" do
      assert_raise EctoStreamFactory.UndefinedGeneratorError, ~r/def nil_generator/, fn ->
        build(nil)
      end
    end

    test "when generator_name is not an atom" do
      assert_raise FunctionClauseError, fn ->
        build("user")
      end
    end
  end

  describe "build_list/2" do
    test "amount should be a positive integer" do
      assert_raise FunctionClauseError, fn ->
        build_list(-1, :user)
      end

      assert_raise FunctionClauseError, fn ->
        build_list(3.14, :user)
      end
    end

    test "with custom attrs" do
      [u1, u2] = build_list(2, :user, name: &"user#{&1 + 1}")

      assert u1.name == "user1"
      assert u2.name == "user2"
    end
  end

  describe "insert/3" do
    test "without attrs" do
      u = insert(:user)

      assert Repo.get!(User, u.id) == u
    end

    test "with repo opts upsert works" do
      email = "user@example.com"
      insert(:user, email: email)

      assert_raise Ecto.ConstraintError, ~r/email_index/, fn ->
        insert(:user, email: email)
      end

      insert(:user, [email: email], on_conflict: :nothing)
    end
  end

  describe "insert_list/4" do
    test "upsert works for list" do
      insert_list(2, :user, email: &"user#{&1}@example.com")

      insert_list(3, :user, [email: &"user#{&1}@example.com"], on_conflict: :nothing)

      assert [
               %{email: "user0@example.com"},
               %{email: "user1@example.com"},
               %{email: "user2@example.com"}
             ] = User |> order_by(:email) |> Repo.all()
    end
  end
end
