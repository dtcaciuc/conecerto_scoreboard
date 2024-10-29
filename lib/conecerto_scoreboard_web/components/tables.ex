defmodule Conecerto.ScoreboardWeb.Tables do
  use Phoenix.Component

  import Conecerto.ScoreboardWeb.Format

  attr :scores, :list, required: true
  attr :time_column_field, :atom, required: true
  attr :time_column_title, :string, required: true

  def group_scores(assigns) do
    ~H"""
    <table class="border-collapse striped w-full">
      <thead>
        <th class="font-bold text-right min-w-4 pt-1">P</th>
        <th class="font-bold text-left pl-2 pt-1">Driver</th>
        <th class="font-bold text-right pl-2 pt-1 max-sm:hidden">#</th>
        <th class="font-bold text-left pl-2 pt-1 max-sm:hidden">Class</th>
        <th class="font-bold text-left pl-2 pt-1 max-sm:hidden">Model</th>
        <th class="font-bold whitespace-nowrap text-right relative pt-1">
          <div class="absolute top-0 right-0 pt-1">
            <%= @time_column_title %>
          </div>
        </th>
        <th class="font-bold whitespace-nowrap text-right pl-2 pt-1 pr-1" colspan="2">
          Raw Interval
        </th>
      </thead>
      <tbody>
        <%= for row <- @scores do %>
          <tr>
            <td class="text-right min-w-4">
              <%= row.pos %>
            </td>
            <td class="text-left max-w-36 truncate pl-2">
              <%= row.driver_name %>
            </td>
            <td class="text-right pl-2 max-sm:hidden">
              <%= row.car_no %>
            </td>
            <td class="text-left whitespace-nowrap pl-2 max-sm:hidden">
              <%= row.car_class %>
            </td>
            <td class="text-left max-w-36 truncate pl-2 max-sm:hidden">
              <%= row.car_model %>
            </td>
            <td class="text-right pl-2">
              <%= row |> get_in([Access.key!(@time_column_field)]) |> format_score() %>
            </td>

            <%= if row.pos == 1 do %>
              <th class="font-bold text-right pl-2">Top</th>
              <th class="font-bold text-right pl-2 pr-1">Next</th>
            <% else %>
              <td class="text-right pl-2">
                <%= row.raw_time_to_top |> format_score() %>
              </td>
              <td class="text-right pl-2 pr-1">
                <%= row.raw_time_to_next |> format_score() %>
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  attr :drivers, :list, required: true

  def runs(assigns) do
    ~H"""
    <table class="border-collapse striped w-full">
      <thead>
        <th class="font-bold text-left pl-2 pt-1">Driver</th>
        <th class="font-bold text-right pl-2 pt-1 max-sm:hidden">#</th>
        <th class="font-bold text-left pl-2 pt-1 max-sm:hidden">Class</th>
        <th class="font-bold text-left pl-2 pt-1 max-sm:hidden">Model</th>
        <th class="font-bold text-right pl-2 pt-1">Elapsed</th>
        <th class="font-bold text-left pl-2 pt-1">Pen.</th>
      </thead>
      <tbody>
        <%= for d <- @drivers do %>
          <tr>
            <td class="text-left pl-2 py-1 align-top">
              <%= d.driver_name %>
            </td>
            <td class="text-right pl-2 py-1 align-top max-sm:hidden">
              <%= d.car_no %>
            </td>
            <td class="text-left pl-2 py-1 align-top max-sm:hidden">
              <%= d.car_class %>
            </td>
            <td class="text-left pl-2 py-1 whitespace align-top max-sm:hidden">
              <%= d.car_model %>
            </td>
            <td class="text-right pl-2 py-1 whitespace-nowrap relative">
              <%= for r <- d.runs do %>
                <div class={run_time_class(r)}><%= r.run_time |> format_score() %></div>
              <% end %>
            </td>
            <td class="text-left pl-2 py-1 whitespace-nowrap">
              <%= for r <- d.runs do %>
                <div><%= r.penalty |> format_penalty() %></div>
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp run_time_class(run),
    do: [run.selected && "best-run", run.penalty in ["DNF", "RRN"] && "line-through"]

  attr :runs, :list, required: true

  def recent_runs(assigns) do
    ~H"""
    <div>
      <table class="border-collapse striped w-full">
        <thead>
          <th class="font-bold text-left pl-2">Driver</th>
          <th class="font-bold text-right pl-2 max-sm:hidden">#</th>
          <th class="font-bold text-left pl-2 max-sm:hidden">Class</th>
          <th class="font-bold text-left pl-2 max-sm:hidden">Model</th>
          <th class="font-bold text-right">Run</th>
          <th class="font-bold text-right pl-2">Elapsed</th>
          <th class="font-bold text-left pl-2">Pen.</th>
        </thead>
        <tbody>
          <%= for row <- @runs do %>
            <tr>
              <td class="text-left max-w-36 whitespace-nowrap text-ellipsis overflow-hidden pl-2">
                <%= row.driver_name %>
              </td>
              <td class="text-right pl-2 max-sm:hidden">
                <%= row.car_no %>
              </td>
              <td class="text-left pl-2 max-sm:hidden">
                <%= row.car_class %>
              </td>
              <td class="text-left max-w-36 whitespace-nowrap text-ellipsis overflow-hidden pl-2 max-sm:hidden">
                <%= row.car_model %>
              </td>
              <td class="text-right pl-2">
                <%= row.counted_run_no |> format_run_no() %>
              </td>
              <td class="text-right pl-2 whitespace-nowrap">
                <div><%= row.run_time |> format_score() %></div>
              </td>
              <td class="text-left pl-2 whitespace-nowrap">
                <div><%= row.penalty |> format_penalty() %></div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end
end
