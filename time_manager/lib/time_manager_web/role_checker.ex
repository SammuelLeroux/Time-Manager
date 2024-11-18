defmodule TimeManagerWeb.Plugs.RoleChecker do
  import Plug.Conn
  alias TimeManagerWeb.Plugs.VerifyToken
  alias Joken.Signer

  @spec init([String.t()]) :: [String.t()]
  def init(roles), do: roles

  @spec call(Plug.Conn.t(), [String.t()]) :: Plug.Conn.t()

  def call(conn, required_roles) do

    case conn.assigns[:claims] do

      %{"role" => role} ->

        if role in required_roles do
          conn
        else
          conn
          |> send_resp(403, "Forbidden : Insufficient permissions")
        end

      _ ->
        conn
        |> send_resp(403, "Forbidden: Insufficient permissions")
        |> halt()
        
    end
  end
end
