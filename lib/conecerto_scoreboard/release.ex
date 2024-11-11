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
  def make_zip(release) do
    build_path = Mix.Project.build_path()

    dir_path =
      if release.path == Path.join([build_path, "rel", Atom.to_string(release.name)]) do
        build_path
      else
        release.path
      end

    out_path = Path.join(dir_path, "#{release.name}-#{release.version}.zip")

    info(release, [:green, "* building ", :reset, out_path])

    lib_dirs =
      Enum.reduce(release.applications, [], fn {name, app_config}, acc ->
        vsn = Keyword.fetch!(app_config, :vsn)
        [Path.join("lib", "#{name}-#{vsn}") | acc]
      end)

    erts_dir =
      case release.erts_source do
        nil -> []
        _ -> ["erts-#{release.erts_version}"]
      end

    release_files =
      for basename <- File.ls!(Path.join(release.path, "releases")),
          not File.dir?(Path.join([release.path, "releases", basename])),
          do: Path.join("releases", basename)

    dirs =
      ["bin", Path.join("releases", release.version)] ++
        erts_dir ++ lib_dirs ++ release_files

    files =
      dirs
      |> Enum.filter(&File.exists?(Path.join(release.path, &1)))
      |> Kernel.++(release.overlays)
      |> Enum.map(&String.to_charlist(&1))

    File.rm(out_path)
    {:ok, _filename} = :zip.zip(String.to_charlist(out_path), files, cwd: release.path)

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
