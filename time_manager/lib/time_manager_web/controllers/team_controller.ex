defmodule TimeManagerWeb.TeamController do
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts
  alias TimeManager.Accounts.Team

  action_fallback TimeManagerWeb.FallbackController

  # General Manager & Admin OK
  def index(conn, _params) do
    teams = Accounts.list_teams()
    render(conn, :index, teams: teams)
  end

  # General Manager & Admin OK
  def create(conn, %{"team" => team_params}) do
    with {:ok, %Team{} = team} <- Accounts.create_team(team_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/teams/#{team}")
      |> render(:show, team: team)
    end
  end

  # General Manager & Admin OK
  def show(conn, %{"id" => id}) do
    team = Accounts.get_team!(id)
    render(conn, :show, team: team)
  end

  # General Manager & Admin OK
  def update(conn, %{"id" => id, "team" => team_params}) do
    team = Accounts.get_team!(id)

    with {:ok, %Team{} = team} <- Accounts.update_team(team, team_params) do
      render(conn, :show, team: team)
    end
  end

  # General Manager & Admin OK
  def delete(conn, %{"id" => id}) do
    team = Accounts.get_team!(id)

    Accounts.nilify_team_users(team)

    with {:ok, %Team{}} <- Accounts.delete_team(team) do
      send_resp(conn, :no_content, "")
    end
  end

  # Permissions OK
  def list_users_by_team_id(conn, %{"team_id" => team_id}) do

    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    case role do

      "manager" ->
        manager = Accounts.get_user!(token)
        if to_string(manager.team_id) == to_string(team_id) do
          users = Accounts.list_users_by_team_id(team_id)
          render(conn, TimeManagerWeb.UserJSON, "index.json", users: users)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Access denied. You can only view users from your own team."})
        end

      role when role in ["general_manager", "admin"] ->
        users = Accounts.list_users_by_team_id(team_id)
        render(conn, TimeManagerWeb.UserJSON, "index.json", users: users)

      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Acces denied. Only managers and general manegers are allowed to view team users."})
      end

    end

end
