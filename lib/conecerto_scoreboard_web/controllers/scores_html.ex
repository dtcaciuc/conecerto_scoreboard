defmodule Conecerto.ScoreboardWeb.ScoresHTML do
  use Conecerto.ScoreboardWeb, :html

  import Conecerto.ScoreboardWeb.Format

  embed_templates "scores_html/*"

  def scores(assigns) do
    ~H"""
    <div>
      <table class="border-collapse striped w-full">
        <thead>
          <th class="font-bold text-right min-w-4">P</th>
          <th class="font-bold text-left pl-2">Driver</th>
          <th class="font-bold text-right pl-2 max-sm:hidden">#</th>
          <th class="font-bold text-left pl-2 max-sm:hidden">Class</th>
          <th class="font-bold text-left pl-2 max-sm:hidden">Model</th>
          <th class="font-bold whitespace-nowrap text-right relative">
            <div class="absolute top-0 right-0">
              <%= @time_column_title %>
            </div>
          </th>
          <th class="font-bold whitespace-nowrap text-right pl-2" colspan="2">Raw Interval</th>
        </thead>
        <tbody>
          <%= for row <- @scores do %>
            <tr>
              <td class="text-right min-w-4">
                <%= row.pos %>
              </td>
              <td class="text-left mw-36 truncate pl-2">
                <%= row.driver_name %>
              </td>
              <td class="text-right pl-2 max-sm:hidden">
                <%= row.car_no %>
              </td>
              <td class="text-left whitespace-nowrap pl-2 max-sm:hidden">
                <%= row.car_class %>
              </td>
              <td class="text-left mw-36 truncate pl-2 max-sm:hidden">
                <%= row.car_model %>
              </td>
              <td class="text-right pl-2">
                <%= row |> get_in([Access.key!(@time_column_field)]) |> format_score() %>
              </td>

              <%= if row.pos == 1 do %>
                <td class="font-bold text-right pl-2">Top</td>
                <td class="font-bold text-right pl-2">Next</td>
              <% else %>
                <td class="text-right pl-2">
                  <%= row.raw_time_to_top |> format_score() %>
                </td>
                <td class="text-right pl-2">
                  <%= row.raw_time_to_next |> format_score() %>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
