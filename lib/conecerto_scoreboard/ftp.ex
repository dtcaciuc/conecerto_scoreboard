defmodule Conecerto.Scoreboard.FTP do
  require Logger

  @behaviour Conecerto.Scoreboard.Uploader.Client

  def open(opts) do
    host = String.to_charlist(Keyword.fetch!(opts, :host))
    user = String.to_charlist(Keyword.fetch!(opts, :user))
    pass = String.to_charlist(Keyword.fetch!(opts, :pass))

    with {:ok, pid} <- :ftp.open(host),
         :ok <- :ftp.user(pid, user, pass),
         :ok <- :ftp.type(pid, :binary) do
      {:ok, %{pid: pid, root: Keyword.fetch!(opts, :root)}}
    else
      {:error, :ehost} ->
        {:error, "Host is unreachable"}

      {:error, :euser} ->
        {:error, "Wrong username or password"}
    end
  end

  def close(%{pid: pid}),
    do: :ftp.close(pid)

  def mkdir(%{pid: pid, root: root}, path) do
    abs_path = Path.join(root, path)
    Logger.info("#{__MODULE__} -  Making #{abs_path}")
    # Ignore mkdir result; if directory already exists it returns an error
    _ = :ftp.mkdir(pid, abs_path |> String.to_charlist())
    :ok
  end

  def send_bin(%{pid: pid, root: root}, contents, dest) do
    abs_dest = Path.join(root, dest)
    Logger.info("#{__MODULE__} - Sending #{abs_dest}")
    :ftp.send_bin(pid, contents, abs_dest |> String.to_charlist())
  end
end
