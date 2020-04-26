defmodule EctoStreamFactory.TestRepo.Migrations.CreateUsers do
  use Ecto.Migration

  @table "users"

  def change do
    create table(@table) do
      add :name, :text
      add :age, :integer
      add :email, :text
    end

    create unique_index(@table, :email)
  end
end
