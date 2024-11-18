defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller

  alias TimeManager.WorkingTimes
  alias TimeManager.WorkingTimes.WorkingTime
  alias TimeManager.Accounts

  action_fallback TimeManagerWeb.FallbackController

  # OK
  def create_with_user_id(conn, %{"user_id" => user_id, "working_time" => working_time_params}) do

    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    cond do

      role in ["admin", "general_manager"] ->
        params_with_user = Map.put(working_time_params, "user_id", user_id)
        case WorkingTimes.create_working_time(params_with_user) do
          {:ok, %WorkingTime{} = working_time} ->
            conn
            |> put_status(:created)
            |> put_resp_header("location", ~p"/api/workingtime/#{working_time}")
            |> render(:show, working_time: working_time)

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> put_view(json: TimeManagerWeb.ChangesetJSON)
            |> render(:error, changeset: changeset)
        end

      role == "manager" ->
        manager = Accounts.get_user!(token)
        user = Accounts.get_user!(user_id)

        if manager.team_id == user.team_id do
          params_with_user = Map.put(working_time_params, "user_id", user_id)
          case WorkingTimes.create_working_time(params_with_user) do
            {:ok, %WorkingTime{} = working_time} ->
              conn
              |> put_status(:created)
              |> put_resp_header("location", ~p"/api/workingtime/#{working_time}")
              |> render(:show, working_time: working_time)

            {:error, %Ecto.Changeset{} = changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> put_view(json: TimeManagerWeb.ChangesetJSON)
              |> render(:error, changeset: changeset)
          end

        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Acces denied. You can only create working times for users in your team."})
        end

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Access denied."})

    end
  end

  #TODO
  def show_with_user_id(conn, %{"user_id" => user_id, "id" => id}) do

    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    cond do
      role in ["admin", "general_manager"] ->
        fetch_and_render_working_time(conn, id, user_id)

      role == "manager" ->
        manager = Accounts.get_user!(token)
        user = Accounts.get_user!(user_id)

      if manager.team_id == user.team_id do
        fetch_and_render_working_time(conn, id, user_id)
      else
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Acces denied. You can only view working times of users from your team"})
      end

      role == "employee" and to_string(token) == to_string(user_id) ->
        fetch_and_render_working_time(conn, id, user_id)

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Acces denied."})

    end
  end

  defp fetch_and_render_working_time(conn, id, user_id) do
    case WorkingTimes.get_working_time_by_user(id, user_id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Working Time not found for this user"})

      working_time ->
        render(conn, :show, working_time: working_time)
    end
  end

  # OK
  def index_with_filters(conn, %{"user_id" => user_id} = params) do

    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    cond do
      role in ["admin", "general_manager"] ->
        fetch_and_render_working_times(conn, user_id, params)

      role == "manager" ->
        manager = Accounts.get_user!(token)
        user = Accounts.get_user!(user_id)

        if manager.team_id == user.team_id do
          fetch_and_render_working_times(conn, user_id, params)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Acces denied. You can only view working times for user from your team."})
        end

      role == "employee" and to_string(token) == to_string(user_id) ->
        fetch_and_render_working_times(conn, user_id, params)

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Acces denied."})

    end
  end

  defp fetch_and_render_working_times(conn, user_id, params) do
    working_times =
      case {Map.get(params, "start"), Map.get(params, "end")} do
        {nil, nil} ->
          WorkingTimes.get_working_times_by_user(user_id)

        {start, end_time} when start != nil and end_time != nil ->
          WorkingTimes.get_working_times_by_user_and_dates(user_id, start, end_time)

        _ ->
          []
      end

    render(conn, :index, working_times: working_times)
  end

  #OSEF
  def index(conn, _params) do
    working_times = WorkingTimes.list_working_times()
    render(conn, :index, working_times: working_times)
  end

  # OSEF
  def create(conn, %{"working_time" => working_time_params}) do
    case WorkingTimes.create_working_time(working_time_params) do
      {:ok, %WorkingTime{} = working_time} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", ~p"/api/workingtime/#{working_time}")
        |> render(:show, working_time: working_time)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: TimeManagerWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  # OSEF
  def show(conn, %{"id" => id}) do
    working_time = WorkingTimes.get_working_time!(id)
    render(conn, :show, working_time: working_time)
  end

  # OK
  def update(conn, %{"id" => id, "working_time" => working_time_params}) do
    working_time = WorkingTimes.get_working_time!(id)
    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    cond do
      role in ["admin", "general_manager"] ->
        process_working_time_update(conn, working_time, working_time_params)

      role == "manager" ->
        manager = Accounts.get_user!(token)
        user = Accounts.get_user!(working_time.user_id)

        if manager.team_id == user.team_id do
          process_working_time_update(conn, working_time, working_time_params)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Acces denied. You can only update working time from users from your team"})
        end

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Acces denied."})

    end

  end

  defp process_working_time_update(conn, working_time, working_time_params) do
    case WorkingTimes.update_working_time(working_time, working_time_params) do
      {:ok, %WorkingTime{} = working_time} ->
        render(conn, :show, working_time: working_time)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: TimeManagerWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  # TODO
  def delete(conn, %{"id" => id}) do
    working_time = WorkingTimes.get_working_time!(id)
    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    cond do

      role in ["admin", "general_manager"] ->
        process_working_time_delete(conn, working_time)

      role == "manager" ->
        manager = Accounts.get_user!(token)
        user = Accounts.get_user!(working_time.user_id)

        if manager.team_id == user.team_id do
          process_working_time_delete(conn, working_time)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Acces denied. You can only delete working times of users in your team"})
        end

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Acces denied."})

    end

  end

  defp process_working_time_delete(conn, working_time) do

    case WorkingTimes.delete_working_time(working_time) do
      {:ok, %WorkingTime{}} ->
       conn
       |> put_status(:ok)
       |> json(%{message: "Working time deleted successfully."})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: TimeManagerWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)

    end

  end

  def get_team_working_times(conn, %{"team_id" => team_id}) do
    team_id = String.to_integer(team_id)
    fetch_and_render_team_working_times(conn, team_id)
  end

  defp fetch_and_render_team_working_times(conn, team_id) do
    users = Accounts.list_users_by_team_id(team_id)

    team_working_times =
      Enum.reduce(users, %{}, fn user, acc ->
        working_times = WorkingTimes.get_working_times_by_user(user.id)
        Map.put(acc, user.id, working_times)
      end)

    render(conn, :index, working_times: team_working_times)
  end

end
