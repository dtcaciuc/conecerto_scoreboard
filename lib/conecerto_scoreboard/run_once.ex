defmodule Conecerto.Scoreboard.RunOnce do
  use GenServer

  def start_link(fun) do
    GenServer.start_link(__MODULE__, fun)
  end

  @impl GenServer
  def init(fun) do
    fun.()
    :ignore
  end
end
