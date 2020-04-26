defmodule EctoStreamFactory.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :age, :integer
    field :email, :string
  end
end
