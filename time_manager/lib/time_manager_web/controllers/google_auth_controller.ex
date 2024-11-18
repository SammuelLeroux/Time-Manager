defmodule TimeManagerWeb.GoogleAuthController do
  use TimeManagerWeb, :controller

  alias TimeManager.Accounts
  alias TimeManager.Accounts.User

  @doc """
  `login/3` gère le callback de la connexion via un compte Google : SI utilisateur a deja un compte sur l'app on le connecte, sinon on lui crée un compte et on le connecte
  """

  def login(conn, %{"code" => code, "username" => username, "email" => email}) do
    case Accounts.get_user_by_email(email)  do
      # Utilisateur a deja un compte, on le login
      %User{} = user ->
        token = TimeManagerWeb.Plugs.VerifyToken.get_created_token(user) # Créer un token pour sa session
        conn
        |> put_status(:ok)
        |> json(%{token: token})

      # Utilisateur n'a pas de compte, on le crée et on le login
      nil ->
        case Accounts.create_user(%{"username" => username, "email" => email, "password" => String.slice(code, 0, 12) , "role" => "employee", "is_google_user" => true}) do
          {:ok, user} ->
            token = TimeManagerWeb.Plugs.VerifyToken.get_created_token(user)
            conn
            |> put_status(:ok)
            |> json(%{token: token})

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Unable to create user", details: changeset})
        end
    end
  end

end