defmodule TimeManager.Accounts.Team do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias TimeManager.Repo

  schema "teams" do
    field :number, :integer

    has_many :users, TimeManager.Accounts.User


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [])
    |> put_number()
  end

  defp put_number(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        last_number = get_last_team_number()
        change(changeset, number: last_number + 1)
      _ ->
        changeset
    end
  end

  defp get_last_team_number do
    query = from t in __MODULE__, select: max(t.number)
    Repo.one(query) || 0
  end
end
