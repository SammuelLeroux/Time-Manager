defmodule TimeManagerWeb.UserController do
  use TimeManagerWeb, :controller
  use PhoenixSwagger

  alias TimeManager.Accounts
  alias TimeManager.Accounts.User

  action_fallback TimeManagerWeb.FallbackController

  def sign_in(conn, %{"username" => username, "password" => password}) do
    case authenticate_user(username, password) do
      {:ok, user} ->
        token = TimeManagerWeb.Plugs.VerifyToken.get_created_token(user)
        json(conn, %{token: token})
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  defp authenticate_user(username, password) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:error, "Invalid username or password"}

      user ->
        if check_password(user, password) do
          {:ok, user}
        else
          {:error, "Invalid username or password"}
        end
    end
  end

  defp check_password(user, password) do
    Bcrypt.verify_pass(password, user.password)
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user}")
      |> render(:show, user: user)
    end
  end

  def update(conn, %{"user_id" => user_id, "user" => user_params}) do
    user = Accounts.get_user!(user_id)
    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]
    is_google_user = conn.assigns[:claims]["is_google_user"]

    if to_string(token) == to_string(user_id) or role in ["admin", "general_manager"] or to_string(is_google_user) == "false" do
      # Remove role and team id from body if user is not admin or general manager
      user_params =
        if role in ["admin", "general_manager"] do
          user_params
        else
          Map.drop(user_params, ["role", "team_id"])
        end

      # Password verification only when user modifies their own password
      if to_string(token) == to_string(user_id) and Map.has_key?(user_params, "password") do
        case user_params do
          %{"current_password" => current_password} = params when is_binary(current_password) ->
            if check_password(user, current_password) do
              params = Map.drop(params, ["current_password"])
              perform_update(conn, user, params)
            else
              conn
              |> put_status(:unauthorized)
              |> json(%{error: "Current password is incorrect"})
            end
          _ ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "Current password is required to change password"})
        end
      else
        # Normal behavior for other cases
        user_params =
          if role == "admin" or to_string(token) == to_string(user_id) do
            user_params
          else
            Map.drop(user_params, ["password"])
          end

        perform_update(conn, user, user_params)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Cannot modify another user's settings"})
    end
  end

  defp perform_update(conn, user, params) do
    with {:ok, %User{} = user} <- Accounts.update_user(user, params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, params) do
    user_id = params["user_id"]
    user = Accounts.get_user!(user_id)
    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    cond do
      # Admin and General Manager can delete without verification
      role in ["admin", "general_manager"] ->
        perform_delete(conn, user)

      # User deleting their own account
      to_string(token) == to_string(user_id) ->
        case params do
          %{"current_password" => password} ->
            if check_password(user, password) do
              perform_delete(conn, user)
            else
              conn
              |> put_status(:unauthorized)
              |> json(%{error: "Current password is incorrect"})
            end
          _ ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "Current password is required to delete your account"})
        end

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You are not authorized to delete this user"})
    end
  end

  defp perform_delete(conn, user) do
    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end

  def show(conn, %{"user_id" => user_id}) do
    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    if to_string(token) == to_string(user_id) or role in ["admin", "general_manager"] do
      user = Accounts.get_user!(user_id)
      render(conn, :show, user: user)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Access denied"})
    end
  end

  def index(conn, %{"username" => username}) do
    token = conn.assigns[:claims]["user_id"]
    role = conn.assigns[:claims]["role"]

    case Accounts.get_user_by_username(username) do
      nil ->
        send_resp(conn, :not_found, "User not found")
      user ->
        if to_string(token) == to_string(user.id) or role in ["admin", "general_manager"] do
          render(conn, :show, user: user)
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Access denied"})
        end
    end
  end

  def index(conn, _params) do
    role = conn.assigns[:claims]["role"]

    if role in ["admin", "general_manager"] do
      users = Accounts.list_users()
      render(conn, :index, users: users)
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Access denied"})
    end
  end

  swagger_path :show do
    get("/api/users/{id}")
    summary("Get a user by ID")
    description("Returns a user based on the provided ID")
    parameter :id, :path, :integer, "User ID", required: true
    response 200, "Success", Schema.ref(:User)
    response 404, "User not found"
  end

  def swagger_definitions do
    %{
      User: swagger_schema do
        title "User"
        description "A user of the application"
        properties do
          id :integer, "User ID"
          username :string, "Username", required: true
          email :string, "Email address", required: true
          role :string, "User role", required: true, enum: ["employee", "manager", "general_manager"]
        end
      end
    }
  end
end