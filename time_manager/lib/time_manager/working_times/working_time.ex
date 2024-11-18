defmodule TimeManager.WorkingTimes.WorkingTime do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "working_times" do
    field :start, :utc_datetime
    field :end, :utc_datetime
    belongs_to :user, TimeManager.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(working_time, attrs) do
    working_time
    |> cast(attrs, [:start, :end, :user_id])
    |> validate_required([:start, :end, :user_id])
    |> validate_no_overlap()
  end

  defp validate_no_overlap(changeset) do
    case {get_field(changeset, :id), get_field(changeset, :start), get_field(changeset, :end), get_field(changeset, :user_id)} do
      {id, start, end_time, user_id} when not is_nil(start) and not is_nil(end_time) and not is_nil(user_id) ->
        query = from w in __MODULE__,
          where: w.user_id == ^user_id,
          where: (w.start < ^end_time and w.end > ^start)

        query = if is_nil(id) do
          query
        else
          from [w] in query, where: w.id != ^id
        end

        case TimeManager.Repo.exists?(query) do
          true -> add_error(changeset, :base, "Overlapping working time exists for this user")
          false -> changeset
        end
      _ ->
        changeset
    end
  end
end