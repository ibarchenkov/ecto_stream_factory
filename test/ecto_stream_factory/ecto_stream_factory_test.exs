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
      assert is_integer(map.field2)
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

  describe "build!/2" do
    test "without attributes" do
      user = build!(:user)

      assert user.name
    end

    test "with valid struct attributes" do
      user = build!(:user, name: "Saša", email: "sasa@example.com")

      assert user.name == "Saša"
      assert user.email == "sasa@example.com"
    end

    test "with invalid struct attributes" do
      assert_raise EctoStreamFactory.MissingKeyError, fn ->
        build!(:user, name: "Aston", foo: "bar")
      end
    end

    test "with valid map attributes" do
      map = build!(:map, field1: "foo")

      assert map.field1 == "foo"
    end

    test "with invalid map attributes" do
      assert_raise EctoStreamFactory.MissingKeyError,
                   "EctoStreamFactory.TestFactory.map_generator does not generate :field3 field.\n",
                   fn ->
                     build!(:map, field1: "foo", field3: "bar")
                   end
    end

    test "with valid keyword list attributes" do
      keyword = build!(:keyword, field1: "foo")

      assert Keyword.get(keyword, :field1) == "foo"
    end

    test "with invalid keyword list attributes" do
      assert_raise EctoStreamFactory.MissingKeyError,
                   ~r/keyword_generator does not generate :field4/,
                   fn ->
                     build!(:keyword, field4: "foo")
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

  describe "build_list!/2" do
    test "with valid attrs" do
      [u1, u2] = build_list!(2, :user, name: "Chris")

      assert u1.name == "Chris"
      assert u2.name == "Chris"
    end

    test "with invalid attrs" do
      assert_raise EctoStreamFactory.MissingKeyError, fn ->
        build_list!(2, :user, foo: "bar")
      end
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

  describe "insert!/3" do
    test "with valid attrs" do
      u = insert(:user, name: "Bram")

      assert Repo.get!(User, u.id).name == "Bram"
    end

    test "with invalid attrs" do
      assert_raise EctoStreamFactory.MissingKeyError, fn ->
        insert!(:user, foo: "bar")
      end
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

  describe "insert_list!/4" do
    test "with valid attrs" do
      [u1, u2] = insert_list(2, :user, name: "Ben")
      assert u1.name == "Ben"
      assert u2.name == "Ben"
    end

    test "with invalid attrs" do
      assert_raise EctoStreamFactory.MissingKeyError, fn ->
        insert_list!(2, :user, foo: "bar")
      end
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
