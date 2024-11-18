defmodule TimeManager.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :number, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:teams, [:number])

  end
end
