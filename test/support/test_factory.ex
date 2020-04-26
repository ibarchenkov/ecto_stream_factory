defmodule EctoStreamFactory.TestFactory do
  use EctoStreamFactory, repo: EctoStreamFactory.Repo

  def user_generator do
    gen all name <- string(:alphanumeric, min_length: 1),
            age <- integer(18..80) do
      %EctoStreamFactory.User{
        name: name,
        age: age
      }
    end
  end
end
