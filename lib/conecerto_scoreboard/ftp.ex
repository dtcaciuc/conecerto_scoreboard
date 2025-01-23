defmodule Conecerto.Scoreboard.FTP do
  require Logger

  @behaviour Conecerto.Scoreboard.Uploader.Client

  def open(opts) do
    host = String.to_charlist(Keyword.fetch!(opts, :host))
    user = String.to_charlist(Keyword.fetch!(opts, :user))
    pass = String.to_charlist(Keyword.fetch!(opts, :pass))

    root = Keyword.fetch!(opts, :root)

    # Root directory must be absolute against user home.
    root =
      if not String.starts_with?(root, "/") do
        "/" <> root
      else
        root
      end

    with {:ok, pid} <- :ftp.open(host),
         :ok <- :ftp.user(pid, user, pass),
         :ok <- :ftp.type(pid, :binary),
         :ok <- root_mkdir_p(pid, root) do
      {:ok, %{pid: pid, root: root}}
    else
      {:error, :ehost} ->
        {:error, "Host is unreachable"}

      {:error, :euser} ->
        {:error, "Wrong username or password"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def close(%{pid: pid}),
    do: :ftp.close(pid)

  def mkdir(%{pid: pid, root: root}, path) do
    do_mkdir(pid, Path.join(root, path))
  end

  def send_bin(%{pid: pid, root: root}, contents, dest) do
    abs_dest = Path.join(root, dest)
    Logger.info("#{__MODULE__} - Sending #{abs_dest}")
    :ftp.send_bin(pid, contents, abs_dest |> String.to_charlist())
  end

  defp root_mkdir_p(pid, path) do
    parts =
      path
      |> String.trim("/")
      |> Path.split()

    result =
      for part <- parts, reduce: {:ok, "/"} do
        {:ok, base_path} ->
          new_path = Path.join(base_path, part)
          {do_mkdir(pid, new_path), new_path}

        {:error, reason} ->
          {:error, reason}
      end

    case result do
      {:ok, _path} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_mkdir(pid, path) do
    with {:ok, false} <- exists?(pid, path),
         :ok <- Logger.info("#{__MODULE__} -  Making #{path}"),
         :ok <- :ftp.mkdir(pid, path |> String.to_charlist()) do
      :ok
    else
      {:ok, true} ->
        :ok

      {:error, reason} ->
        {:error, "Could not make #{path}: #{inspect(reason)}"}
    end
  end

  defp exists?(pid, path) do
    case :ftp.nlist(pid, path |> String.to_charlist()) do
      {:ok, _listing} -> {:ok, true}
      {:error, :epath} -> {:ok, false}
      {:error, reason} -> {:error, "Could not list #{path}: #{inspect(reason)}"}
    end
  end
end
