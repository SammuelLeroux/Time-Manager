defmodule TimeManagerWeb.Router do
  alias Hex.API.User
  use TimeManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: ["http://localhost:3000", "https://13.37.225.23.nip.io"]
  end

  pipeline :authenticated do
    plug TimeManagerWeb.Plugs.VerifyToken
  end

  pipeline :gm_and_admin do
    plug TimeManagerWeb.Plugs.RoleChecker, ["general_manager", "admin"]
  end

  scope "/api", TimeManagerWeb do
    pipe_through :api

    # Handle preflight OPTIONS requests
    options "/*path", CORSPlug, :preflight
    post "/users/sign_in", UserController, :sign_in
    get "/auth/google/callback", GoogleAuthController, :index
    post "/auth/google", GoogleAuthController, :login
    post "/users", UserController, :create

    get "/newsletter", NewsletterController, :index
    get "/newsletter/:file_name", NewsletterController, :show
    post "/newsletter", NewsletterController, :save_release
  end

  # Routes protéges - authenticated
  scope "/api", TimeManagerWeb do
    pipe_through [:api, :authenticated]

    # USER
    # Get utilisateur - General Manager + Admin
    get "/users", UserController, :index
    # Get utilisateur - User ID + General Manager + Admin
    get "/users/:user_id", UserController, :show
    # Edit utilisateur - User ID + General Manager
    put "/users/:user_id", UserController, :update
    # Delete utilisateur - User ID + General Manager + Admin
    delete "/users/:user_id", UserController, :delete

    # TEAM
    # Récupérer tous les utilisateurs d'une team
    get "/teams/:team_id/users", TeamController, :list_users_by_team_id

    # CLOCK
    post "/clocks/:user_id", ClockController, :create_with_user_id
    # Récupérer les clocks d'un utilisateur avec son ID
    get "/clocks/:user_id", ClockController, :index_by_user

    # WORKING TIMES
    # Créer le working time d'un user avec son ID
    post "/workingtime/:user_id", WorkingTimeController, :create_with_user_id
    # Récupérer les working times d'un user avec son ID
    get "/workingtime/:user_id", WorkingTimeController, :index_with_filters
    # Récupérer un working time spécifique avec l'id de l'utilisateur et du working time
    get "/workingtime/:user_id/:id", WorkingTimeController, :show_with_user_id
    # Récupérer tous les working times d'une team
    get "/workingtime/teams/:team_id", WorkingTimeController, :get_team_working_times
    # Update un working time via son id
    put "/workingtime/:id", WorkingTimeController, :update
    # Delete un working time via son id
    delete "/workingtime/:id", WorkingTimeController, :delete

  end

  # Routes protégées - General Manager & Admin
  scope "/api", TimeManagerWeb do
    pipe_through [:api, :authenticated, :gm_and_admin]
    # Récupérer tous les working times avec des filtres
    get "/workingtime", WorkingTimeController, :index
    post "/teams", TeamController, :create
    get "/teams", TeamController, :index
    get "/teams/:id", TeamController, :show
    put "/teams/:id", TeamController, :update
    delete "/teams/:id", TeamController, :delete
  end

  scope "/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI, otp_app: :time_manager, swagger_file: "swagger.json"
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:time_manager, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: TimeManagerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

end
