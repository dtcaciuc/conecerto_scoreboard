defmodule Conecerto.Scoreboard.Explorer do
  require Phoenix.ConnTest
  require Logger

  def publish_once() do
    {:ok, _} = Application.ensure_all_started(:conecerto_scoreboard)
    :ok = Phoenix.PubSub.subscribe(Conecerto.Scoreboard.PubSub, "explorer")

    # Wait for database to populate
    receive do
      :uploaded ->
        Logger.info("Explorer published successfully")
        System.stop(0)
    after
      10_000 ->
        Logger.error("Explorer was not published - Did not load data before timeout")
        System.stop(1)
    end
  end
end
