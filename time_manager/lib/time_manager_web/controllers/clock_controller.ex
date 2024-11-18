defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller

  alias TimeManager.Clocks
  alias TimeManager.Clocks.Clock
  alias TimeManager.Accounts

  action_fallback TimeManagerWeb.FallbackController

  # OSEF
  def index(conn, _params) do
    clocks = Clocks.list_clocks()
    render(conn, :index, clocks: clocks)
  end

  # TODO
  def index_by_user(conn, %{"user_id" => user_id}) do

    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    cond do

      # Utilisateur concerné
      to_string(token) == to_string(user_id) ->
        clocks = Clocks.list_clocks_by_user(user_id)
        render(conn, :index, clocks: clocks)

      # Général manager ou admin
      role in ["admin", "general_manager"] ->
        clocks = Clocks.list_clocks_by_user(user_id)
        render(conn, :index, clocks: clocks)

      role == "manager" ->
        manager = Accounts.get_user!(token)
        user = Accounts.get_user!(user_id)

        if manager.team_id == user.team_id do
          clocks = Clocks.list_clocks_by_user(user_id)
          render(conn, :index, clocks: clocks)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Acces denied. You can only view clocks of users from your team"})
        end


    true ->
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Acces denied."})

    end
  end

  # OSEF
  def create(conn, %{"clock" => clock_params}) do
    with {:ok, %Clock{} = clock} <- Clocks.create_clock(clock_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/clocks/#{clock}")
      |> render(:show, clock: clock)
    end
  end

  # OK
  def create_with_user_id(conn, %{"user_id" => user_id, "clock" => clock_params}) do

    # Récupère l'id de l'utilisateur dans le token
    token = conn.assigns[:claims]["user_id"]

    # Comparaison de l'id dans le token et dans la requête
    if to_string(token) == to_string(user_id) do
      case Clocks.create_clock_for_user(user_id, clock_params) do
        {:ok, %Clock{} = clock} ->
          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/clocks/#{clock}")
          |> render(:show, clock: clock)

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> put_view(TimeManagerWeb.ChangesetView)
          |> render("error.json", changeset: changeset)
      end

    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden: You are not allowed to create a clock for another user."})
    end
  end

  # OSEF
  def show(conn, %{"id" => id}) do
    clock = Clocks.get_clock!(id)
    render(conn, :show, clock: clock)
  end

  # OSEF
  def update(conn, %{"id" => id, "clock" => clock_params}) do
    clock = Clocks.get_clock!(id)

    with {:ok, %Clock{} = clock} <- Clocks.update_clock(clock, clock_params) do
      render(conn, :show, clock: clock)
    end
  end

  # OSEF
  def delete(conn, %{"id" => id}) do
    clock = Clocks.get_clock!(id)

    with {:ok, %Clock{}} <- Clocks.delete_clock(clock) do
      send_resp(conn, :no_content, "")
    end
  end

end
