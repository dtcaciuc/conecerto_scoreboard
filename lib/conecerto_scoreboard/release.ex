defmodule Conecerto.Scoreboard.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :conecerto_scoreboard

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  # Alteration of Mix.Tasks.Release.make_tar to create zip files instead of tarballs.
  # Simplified to always include erts.
  def make_zip(release) do
    build_path = Mix.Project.build_path()

    dir_path =
      if release.path == Path.join([build_path, "rel", Atom.to_string(release.name)]) do
        build_path
      else
        release.path
      end

    {_os_family, os_name} = :os.type()
    out_path = Path.join(dir_path, "#{release.name}-#{release.version}-#{os_name}.zip")

    info(release, [:green, "* building ", :reset, out_path])

    if release.erts_source == nil do
      raise "Excluding erts from the release zip file is not supported"
    end

    files =
      File.ls!(release.path)
      |> Enum.filter(&(not String.starts_with?(&1, ".")))
      |> Enum.map(&String.to_charlist(&1))

    File.rm(out_path)

    {:ok, _filename} =
      :zip.zip(String.to_charlist(out_path), files, cwd: String.to_charlist(release.path))

    release
  end

  defp info(release, message) do
    if !release.options[:quiet] do
      Mix.shell().info(message)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
