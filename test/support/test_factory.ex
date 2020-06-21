defmodule EctoStreamFactory.TestFactory do
  use EctoStreamFactory, repo: EctoStreamFactory.Repo

  def user_generator do
    gen all name <- string(:alphanumeric, min_length: 1),
            email <- email_generator(),
            age <- integer(15..80) do
      %EctoStreamFactory.User{name: name, email: email, age: age}
    end
  end

  def post_generator do
    gen all author <- user_generator(),
            body <- string(:alphanumeric, min_length: 10) do
      %EctoStreamFactory.Post{author: author, body: body}
    end
  end

  def email_generator do
    gen all username <- string(:alphanumeric, min_length: 1),
            domain <- member_of(~w(gmail.com outlook.com yahoo.com)) do
      "#{username}#{System.unique_integer([:positive, :monotonic])}@#{domain}"
    end
  end

  def map_generator do
    gen all field1 <- string(:alphanumeric, min_length: 1),
            field2 <- integer() do
      %{fiel1: field1, field2: field2}
    end
  end

  def keyword_generator do
    gen all field1 <- string(:alphanumeric, min_length: 1),
            field2 <- integer() do
      [fiel1: field1, field2: field2]
    end
  end

  def list_generator do
    gen all field1 <- string(:alphanumeric, min_length: 1),
            field2 <- integer() do
      [field1, field2]
    end
  end
end
