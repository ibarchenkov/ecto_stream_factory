defmodule EctoStreamFactoryTest do
  use ExUnit.Case, async: true

  import EctoStreamFactory.TestFactory
  import Ecto.Query, only: [order_by: 2]
  alias EctoStreamFactory.Repo
  alias EctoStreamFactory.User
  use ExUnitProperties

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "build/2" do
    test "without overwrites" do
      user = build(:user)

      assert is_nil(user.id)
      assert String.length(user.name) >= 1
      assert 18 <= user.age and user.age <= 80
    end

    test "with keyword overwrites" do
      user = build(:user, id: & &1, age: 10)

      assert user.id == 1
      assert user.age == 10
    end

    test "with map overwrites" do
      user = build(:user, %{id: 13})

      assert user.id == 13
    end

    test "it silently ignores non-existent struct attributes" do
      user = build(:user, foo: "bar")
      assert user
    end

    test "when trying to build a non-existent record" do
      assert_raise EctoStreamFactory.UndefinedGeneratorError, ~r/def nil_generator/, fn ->
        build(nil)
      end
    end

    test "when generator_name is a string" do
      user = build("user", %{age: 13})
      assert user.age == 13
    end

    test "when generator_name is an integer" do
      assert_raise FunctionClauseError, fn ->
        build(1)
      end
    end

    test "merges plain maps" do
      map = build(:map, field1: "foo")
      assert map.field1 == "foo"
    end

    test "merges keyword lists" do
      keyword = build(:keyword, field3: 14)
      assert Keyword.get(keyword, :field3) == 14
    end

    test "returns plain data as is" do
      email = build(:email)
      assert email =~ "@"
    end

    test "with associations" do
      post = build(:post)
      assert is_nil(post.author_id)
      assert String.length(post.author.name) >= 1
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
      [u1, u2] = build_list(2, :user, name: &"user#{&1}")

      assert u1.name == "user1"
      assert u2.name == "user2"
    end

    test "for plain data" do
      [e1, e2] = build_list(2, :email)

      assert e1 =~ "@"
      assert e2 =~ "@"
    end
  end

  describe "insert/3" do
    test "without attrs" do
      u = insert(:user)

      assert Repo.get!(User, u.id) == u
    end

    test "when trying to insert a map" do
      assert_raise FunctionClauseError, fn ->
        insert(:map)
      end
    end

    test "with repo opts upsert works" do
      email = "user@example.com"
      insert(:user, email: email)

      assert_raise Ecto.ConstraintError, ~r/email_index/, fn ->
        insert(:user, email: email)
      end

      insert(:user, [email: email], on_conflict: :nothing, returning: true)
    end
  end

  describe "insert_list/4" do
    test "upsert works for list" do
      insert_list(2, :user, email: &"user#{&1}@example.com")

      insert_list(3, :user, [email: &"user#{&1}@example.com"], on_conflict: :nothing)

      assert [
               %{email: "user1@example.com"},
               %{email: "user2@example.com"},
               %{email: "user3@example.com"}
             ] = User |> order_by(:email) |> Repo.all()
    end
  end

  describe "user properties" do
    property "contact info contains user name and email" do
      check all user <- user_generator() do
        info = User.contact_info(user)
        assert String.starts_with?(info, user.name)
        assert info =~ user.email
      end
    end

    property "adult users older than 18" do
      check all user <- user_generator() do
        assert User.adult?(user) == user.age >= 18
      end
    end
  end
end
