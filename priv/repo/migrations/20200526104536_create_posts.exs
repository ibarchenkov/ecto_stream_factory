defmodule EctoStreamFactory.TestRepo.Migrations.CreatePosts do
  use Ecto.Migration

  @table "posts"

  def change do
    create table(@table) do
      add :author_id, references(:users, on_delete: :delete_all), null: false
      add :body, :text, null: false
    end

    create index(@table, :author_id)
  end
end
