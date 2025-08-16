defmodule Conecerto.ScoreboardWeb.ExplorerHTML do
  use Conecerto.ScoreboardWeb, :html

  embed_templates "explorer_html/*"

  # TODO common "asset_path" with brands?
  defp map_path(conn, map),
    do: with_base_path(conn, @endpoint.path(map.path))
end
