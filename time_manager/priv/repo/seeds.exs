# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TimeManager.Repo.insert!(%TimeManager.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias TimeManager.Repo
alias TimeManager.Accounts.User
alias TimeManager.Accounts.Team

team1 =
  %Team{}
  |> Team.changeset(%{})
  |> Repo.insert!()

team2 =
  %Team{}
  |> Team.changeset(%{})
  |> Repo.insert!()

unless Repo.get_by(User, email: "admin@dev.fr") do
  %User{}
  |> User.changeset(%{
    username: "admin",
    email: "admin@dev.fr",
    password: "password",
    role: "admin",
    team_id: nil
  })
  |> Repo.insert!()
end

unless Repo.get_by(User, email: "gmanager@dev.fr") do
  %User{}
  |> User.changeset(%{
    username: "gmanager",
    email: "gmanager@dev.fr",
    password: "password",
    role: "general_manager",
    team_id: nil
  })
  |> Repo.insert!()
end

unless Repo.get_by(User, email: "manager@dev.fr") do
  %User{}
  |> User.changeset(%{
    username: "manager",
    email: "manager@dev.fr",
    password: "password",
    role: "manager",
    team_id: team1.id
  })
  |> Repo.insert!()
end

unless Repo.get_by(User, email: "manager2@dev.fr") do
  %User{}
  |> User.changeset(%{
    username: "manager2",
    email: "manager2@dev.fr",
    password: "password",
    role: "manager",
    team_id: team2.id
  })
  |> Repo.insert!()
end

unless Repo.get_by(User, email: "employee@dev.fr") do
  %User{}
  |> User.changeset(%{
    username: "employee",
    email: "employee@dev.fr",
    password: "password",
    role: "employee",
    team_id: team1.id,
  })
  |> Repo.insert!()
end

unless Repo.get_by(User, email: "employee2@dev.fr") do
  %User{}
  |> User.changeset(%{
    username: "employee2",
    email: "employee2@dev.fr",
    password: "password",
    role: "employee",
    team_id: nil,
  })
  |> Repo.insert!()
end
