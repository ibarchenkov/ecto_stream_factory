defmodule EctoStreamFactory.Post do
  use Ecto.Schema

  schema "posts" do
    field :body, :string

    belongs_to :author, EctoStreamFactory.User
  end
end
