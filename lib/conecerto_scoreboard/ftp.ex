# defmodule Conecerto.Scoreboard.FTP do
#   @callback open(host :: String.t(), user :: String.t(), pass :: String.t()) ::
#               {:ok, pid()} | {:error, String.t()}
# 
#   @callback close(pid()) :: :ok
# 
#   @callback mkdir(path :: String.t()) :: :ok
#   @callback send_bin(pid(), data :: binary(), dest :: String.t()) :: :ok
#   @callback send_file(pid(), source :: String.t(), dest :: String.t()) :: :ok
# 
# end
# 
# defmodule Conecerto.Scoreboard.LiveFTP do
#   @behaviour Conecerto.Scoreboard.FTP
# 
#   def open(host, user, pass) do
#     with {:ok, pid} <- :ftp.open(String.to_charlist(host)),
#          :ok <- :ftp.user(pid, String.to_charlist(user), String.to_charlist(pass))
#     do
#       {:ok, pid}
#     else
#       {:error, :ehost} ->
#         {:error, "results host is unreachable"}
#       {:error, :euser} ->
#         {:error, "wrong results host username or password"}
#     end
#   end
# 
#   def close(pid), do: :ftp.close(pid)
# 
#   def mkdir(pid, path) do
#     :ftp.mkdir(pid, String.to_charlist(path))
#   end
# 
#   def send_bin(pid, data, dest) do
#     :ftp.send_bin(pid, data, String.to_charlist(filename))
#   end
# 
#   def send_file(pid, source, dest) do
#     :ftp.send(pid, String.to_charlist(source), String.to_charlist(dest))
#   end
# end
