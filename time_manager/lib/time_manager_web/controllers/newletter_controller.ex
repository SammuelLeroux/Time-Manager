defmodule TimeManagerWeb.NewsletterController do
  use TimeManagerWeb, :controller

  alias Plug.Upload

  @release_dir "assets/release"

  def index(conn, _params) do
    case File.ls(@release_dir) do
        {:ok, files} ->
        # Filtrer pour ne retourner que les fichiers Markdown
        md_files = Enum.filter(files, fn file -> String.ends_with?(file, ".md") end)

        # Créer un dictionnaire avec le nom du fichier comme clé et son contenu comme valeur
        file_contents = Enum.reduce(md_files, %{}, fn file, acc ->
            file_path = Path.join(@release_dir, file)

            case File.read(file_path) do
            {:ok, content} ->
                Map.put(acc, file, content)  # Ajouter le nom et le contenu au dictionnaire

            {:error, reason} ->
                Map.put(acc, file, "Error reading file: #{reason}")  # Gestion des erreurs de lecture
            end
        end)

        # Renvoyer les fichiers markdown sous forme de JSON
        conn
        |> put_status(:ok)
        |> json(%{files: file_contents})

        {:error, reason} ->
        # En cas d'erreur, renvoyer une réponse avec une erreur
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to list files", reason: reason})
    end
    end


  def show(conn, %{"file" => file_name}) do
    file_path = Path.join(@release_dir, "/#{file_name}.md")

    if File.exists?(file_path) do
      {:ok, content} = File.read(file_path)
      conn
      |> put_status(:ok)
      |> text(content)  # Envoyer le contenu brut du fichier
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "File not found"})
    end
  end

  @doc """
  `save_release/3` gère le callback de la connexion via un compte Google : SI utilisateur a deja un compte sur l'app on le connecte, sinon on lui crée un compte et on le connecte
  """

  def save_release(conn, %{"file" => %Upload{} = upload}) do
    uploads_path = Path.join(@release_dir, upload.filename)

    case File.cp(upload.path, uploads_path) do
      :ok ->
        conn
        |> put_status(:created)
        |> json(%{message: "File uploaded successfully", file: upload.filename})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to upload file", reason: reason})
    end
  end

end