defmodule Conecerto.Scoreboard.Uploader.Client do
  @opaque client() :: map()

  @callback open(
              host: String.t(),
              root: String.t(),
              user: String.t(),
              pass: String.t()
            ) ::
              {:ok, client()} | {:error, String.t()}
  @callback close(client :: client()) :: :ok

  @callback mkdir(client :: client(), path :: String.t()) :: :ok
  @callback send_bin(client :: client(), contents :: charlist(), dest :: String.t()) :: :ok
end
