defmodule TimeManager.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias TimeManager.Repo
  alias TimeManager.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Gets a user by username and email.

  Returns nil if no user is found.

  ## Examples

      iex> get_user_by_username_and_email("johndoe", "john@example.com")
      %User{}

      iex> get_user_by_username_and_email("nonexistent", "non@existent.com")
      nil

  """
  def get_user_by_username_and_email(username, email) do
    User
    |> Ecto.Query.where(username: ^username, email: ^email)
    |> Repo.one()
  end

  @doc """
  Gets a user by email.

  Returns nil if no user is found.

  ## Examples

      iex> get_user_by_email("john@example.com")
      %User{}

      iex> get_user_by_email("non@existent.com")
      nil

  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by username.

  Returns nil if no user is found.

  ## Examples

      iex> get_user_by_username("John Doe")
      %User{}

      iex> get_user_by_username("Non existent")
      nil

  """
  def get_user_by_username(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Authenticates a user.

  Returns {:ok, user} if the user exists and the password is correct.
  Returns {:error, :unauthorized} otherwise.

  ## Examples

      iex> authenticate_user("john@example.com", "correctpassword")
      {:ok, %User{}}

      iex> authenticate_user("john@example.com", "incorrectpassword")
      {:error, :unauthorized}

  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)
    case user do
      nil ->
        Bcrypt.no_user_verify()
        {:error, :unauthorized}
      user ->
        if Bcrypt.verify_pass(password, user.password) do
          {:ok, user}
        else
          {:error, :unauthorized}
        end
    end
  end

  alias TimeManager.Accounts.Team

  @doc """
  Returns the list of teams.

  ## Examples

      iex> list_teams()
      [%Team{}, ...]

  """
  def list_teams do
    Repo.all(Team)
  end

  @doc """
  Gets a single team.

  Raises `Ecto.NoResultsError` if the Team does not exist.

  ## Examples

      iex> get_team!(123)
      %Team{}

      iex> get_team!(456)
      ** (Ecto.NoResultsError)

  """
  def get_team!(id), do: Repo.get!(Team, id)

  @doc """
  Creates a team.

  ## Examples

      iex> create_team(%{field: value})
      {:ok, %Team{}}

      iex> create_team(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a team.

  ## Examples

      iex> update_team(team, %{field: new_value})
      {:ok, %Team{}}

      iex> update_team(team, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a team.

  ## Examples

      iex> delete_team(team)
      {:ok, %Team{}}

      iex> delete_team(team)
      {:error, %Ecto.Changeset{}}

  """
  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team changes.

  ## Examples

      iex> change_team(team)
      %Ecto.Changeset{data: %Team{}}

  """
  def change_team(%Team{} = team, attrs \\ %{}) do
    Team.changeset(team, attrs)
  end

  def list_users_by_team_id(team_id) do
    from(u in User, where: u.team_id == ^team_id)
    |> Repo.all()
  end

  def nilify_team_users(%Team{id: team_id}) do
    from(u in User, where: u.team_id == ^team_id)
    |> Repo.update_all(set: [team_id: nil])
  end

end
