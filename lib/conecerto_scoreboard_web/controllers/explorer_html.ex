defmodule Conecerto.ScoreboardWeb.ExplorerHTML do
  use Conecerto.ScoreboardWeb, :html

  embed_templates "explorer_html/*"

  defp collated_section(assigns) do
    ~H"""
    <table class="w-full">
      <thead>
        <tr>
          <th>
            <div class="grid grid-cols-3 mb-2">
              <div>
                <%= if @organizer do %>
                  <Conecerto.ScoreboardWeb.Layouts.organizer_logo conn={@conn} organizer={@organizer} />
                <% else %>
                  <div class="text-xl text-left">{@event_name}</div>
                <% end %>
              </div>
              <div class="text-2xl text-center font-semibold">{@title}</div>
              <div class="text-right">
                <%= if @organizer do %>
                  <div class="text-xl">{@event_name}</div>
                  <div>{@event_date}</div>
                <% else %>
                  <div class="text-xl">{@event_date}</div>
                <% end %>
              </div>
            </div>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>
            {render_slot(@inner_block)}
          </td>
        </tr>
      </tbody>
      <tfoot>
        <tr>
          <th class="pt-2">
            <Conecerto.ScoreboardWeb.Layouts.sponsor_logos
              conn={@conn}
              sponsors={@sponsors}
              show_title={false}
            />
          </th>
        </tr>
      </tfoot>
    </table>
    """
  end

  # TODO common "asset_path" with brands?
  defp map_path(conn, map),
    do: with_base_path(conn, @endpoint.path(map.path))
end
