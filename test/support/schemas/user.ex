defmodule EctoStreamFactory.User do
  use Ecto.Schema

  schema "users" do
    field :name, :string
    field :age, :integer
    field :email, :string
  end

  def contact_info(%__MODULE__{name: name, email: email}) do
    "#{name} #{email}"
  end

  def adult?(%__MODULE__{age: age}) when age >= 18 do
    true
  end

  def adult?(%__MODULE__{age: _}) do
    false
  end
end
