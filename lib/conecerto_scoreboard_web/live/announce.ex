defmodule Conecerto.ScoreboardWeb.Announce do
  use Phoenix.LiveView

  import Conecerto.ScoreboardWeb.Format

  alias Conecerto.Scoreboard

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = Conecerto.ScoreboardWeb.Endpoint.subscribe("mj")
      {:ok, assign(socket, load_data()), layout: false}
    else
      {:ok, assign(socket, empty_data()), layout: false}
    end
  end

  @impl true
  def handle_info(:mj_update, socket) do
    {:noreply, assign(socket, load_data())}
  end

  defp load_data() do
    case Scoreboard.list_recent_runs(5) |> Enum.reverse() do
      [last | rest] ->
        recent_runs =
          [last | rest]
          |> Enum.reverse()
          |> select_car(last.car_no)

        last_driver_runs =
          Scoreboard.list_car_runs(last.car_no)
          |> select_counted_run(last.counted_run_no)

        group_scores =
          Scoreboard.list_recent_groups(6)
          |> Enum.map(fn name ->
            scores =
              name
              |> Scoreboard.list_group_scores()
              |> Scoreboard.announce_run(last.car_no)

            %{name: name, scores: scores}
          end)

        %{
          root_font_size: Scoreboard.config(:announce_font_size),
          recent_runs: recent_runs,
          last_driver: %{
            name: last.driver_name,
            runs: last_driver_runs
          },
          raw_scores: Scoreboard.announce_run(Scoreboard.list_raw_scores(), last.car_no),
          pax_scores: Scoreboard.announce_run(Scoreboard.list_pax_scores(), last.car_no),
          group_scores: group_scores
        }

      _ ->
        empty_data()
    end
  end

  defp empty_data() do
    %{
      root_font_size: Scoreboard.config(:announce_font_size),
      recent_runs: [],
      last_driver: nil,
      raw_scores: %{top10: [], rest: []},
      pax_scores: %{top10: [], rest: []},
      group_scores: []
    }
  end

  defp select_car(rows, car_no) do
    Enum.map(rows, fn row -> %{row | selected: row.car_no == car_no} end)
  end

  defp select_counted_run(runs, run_no) do
    Enum.map(runs, fn run -> %{run | selected: run.counted_run_no == run_no} end)
  end

  def announce_scores(assigns) do
    ~H"""
    <div>
      <div class="text-2xl text-center mb-2 font-bold">
        <%= @view_title %>
      </div>
      <table class="border-collapse striped w-full">
        <thead>
          <th class="font-bold text-right">P</th>
          <th class="font-bold text-left pl-2">Driver</th>
          <th class="font-bold whitespace-nowrap text-right"><%= @time_column_title %></th>
          <th class="font-bold whitespace-nowrap text-right pl-2" colspan="2">Raw Interval</th>
        </thead>
        <.announce_scores_page rows={@scores.top10} time_column_field={@time_column_field} />
        <%= if Enum.count(@scores.rest) > 0 do %>
          <.announce_scores_hr />
          <.announce_scores_page rows={@scores.rest} time_column_field={@time_column_field} />
        <% end %>
      </table>
    </div>
    """
  end

  def announce_scores_page(assigns) do
    ~H"""
    <tbody>
      <%= for row <- @rows do %>
        <tr class={if row.selected, do: "text-amber-300"}>
          <td class="text-right">
            <%= row.pos %>
          </td>
          <td class="text-left mw-36 truncate pl-2">
            <%= row.driver_name %>
          </td>
          <td class="text-right pl-2">
            <%= row |> get_in([Access.key!(@time_column_field)]) |> format_score() %>
          </td>
          <%= if row.pos == 1 do %>
            <td class="font-bold text-right">Top</td>
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
    """
  end

  def announce_scores_hr(assigns) do
    ~H"""
    <tbody>
      <tr>
        <td class="text-center" colspan="7">
          —
        </td>
      </tr>
    </tbody>
    """
  end
end
