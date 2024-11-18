defmodule TimeManager.Repo.Migrations.CreateWorkingTimes do
  use Ecto.Migration

  def change do
    create table(:working_times) do
      add :start, :utc_datetime, null: false
      add :end, :utc_datetime, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:working_times, [:user_id])
    create unique_index(:working_times, [:user_id, :start, :end], name: :user_start_end_unique_index)

    # Ajout d'une contrainte de vérification
    create constraint(:working_times, :end_after_start, check: "\"end\" > start")
  end
end
