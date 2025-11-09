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
            {@time_column_title}
          </div>
        </th>
        <th class="font-bold whitespace-nowrap text-right pl-2 pt-1" colspan="2">
          Raw Interval
        </th>
        <th class="font-bold text-right pl-2 pt-1 max-sm:hidden">Score</th>
        <th></th>
      </thead>
      <tbody>
        <%= for row <- @scores do %>
          <tr>
            <td class="text-right min-w-4">
              {row.pos}
            </td>
            <td class="text-left max-w-36 truncate pl-2">
              {row.driver_name}
            </td>
            <td class="text-right pl-2 max-sm:hidden">
              {row.car_no}
            </td>
            <td class="text-left whitespace-nowrap pl-2 max-sm:hidden">
              {row.car_class}
            </td>
            <td class="text-left max-w-36 truncate pl-2 max-sm:hidden">
              {row.car_model}
            </td>
            <td class="text-right pl-2">
              {row |> get_in([Access.key!(@time_column_field)]) |> format_score()}
            </td>
            <%= if row.pos == 1 do %>
              <th class="font-bold text-right pl-2">Top</th>
              <th class="font-bold text-right pl-2">Next</th>
            <% else %>
              <td class="text-right pl-2">
                {row.raw_time_to_top |> format_score()}
              </td>
              <td class="text-right pl-2">
                {row.raw_time_to_next |> format_score()}
              </td>
            <% end %>
            <td class="text-left text-right pl-2 max-sm:hidden">
              {row.score |> format_score()}
            </td>
            <td></td>
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
        <th class="font-bold text-right pl-2 pt-1">Run</th>
        <th class="font-bold text-right pl-2 pt-1">Elapsed</th>
        <th class="font-bold text-left pl-2 pt-1">Pen.</th>
      </thead>
      <tbody>
        <%= for d <- @drivers do %>
          <tr>
            <td class="text-left pl-2 py-1 align-top">
              {d.driver_name}
            </td>
            <td class="text-right pl-2 py-1 align-top max-sm:hidden">
              {d.car_no}
            </td>
            <td class="text-left pl-2 py-1 align-top max-sm:hidden">
              {d.car_class}
            </td>
            <td class="text-left pl-2 py-1 whitespace align-top max-sm:hidden">
              {d.car_model}
            </td>
            <td class="text-right pl-2 py-1 whitespace-nowrap">
              <%= for r <- d.runs do %>
                <div>{r.counted_run_no |> format_run_no()}</div>
              <% end %>
            </td>
            <td class="text-right pl-2 py-1 whitespace-nowrap">
              <%= for r <- d.runs do %>
                <div class={run_time_class(r)}>{r.run_time |> format_score()}</div>
              <% end %>
            </td>
            <td class="text-left pl-2 py-1 whitespace-nowrap">
              <%= for r <- d.runs do %>
                <div>{r.penalty |> format_penalty()}</div>
              <% end %>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  attr :drivers, :list, required: true

  def runs_compact(assigns) do
    ~H"""
    <table class="border-collapse striped w-full relative">
      <thead>
        <th class="font-bold text-left pl-2 pt-1">Driver</th>
        <th class="font-bold text-right pl-2 pt-1">#</th>
        <th class="font-bold text-left pl-2 pt-1">Class</th>
        <th class="font-bold text-left pl-2 pt-1">Car</th>
        <th class="font-bold text-right pr-2 pt-1">
          Elapsed/<span class="underline underline-offset-2">Best</span>, Penalty
        </th>
      </thead>
      <tbody>
        <%= for d <- @drivers do %>
          <tr class="break-inside-avoid">
            <td class="text-left pl-2 py-1 align-top text-nowrap whitespace-nowrap max-w-48 truncate">
              {d.driver_name}
            </td>
            <td class="text-right pl-2 py-1 align-top text-nowrap">
              {d.car_no}
            </td>
            <td class="text-left pl-2 py-1 align-top text-nowrap">
              {d.car_class}
            </td>
            <td class="text-left pl-2 py-1 align-top text-nowrap whitespace-nowrap max-w-48 truncate">
              {d.car_model}
            </td>
            <td class="text-right pl-8 pr-2 py-1 align-top">
              <div class="grid grid-cols-[repeat(3,_auto)] gap-x-8 gap-y-1 justify-start">
                <%= for r <- exclude_reruns(d.runs) do %>
                  <.run_result run={r} />
                <% end %>
              </div>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  defp exclude_reruns(runs),
    do: runs |> Enum.filter(&(&1.penalty != "RRN"))

  defp run_result(assigns) do
    ~H"""
    <div class="flex relative gap-x-2">
      <div class="absolute -left-4 body-text-muted">
        {@run.counted_run_no}›
      </div>
      <div class={["w-13" | run_time_class(@run)]}>
        {@run.run_time |> format_score()}
      </div>
      <div class="w-7 text-left">
        <%= if @run.penalty != "" do %>
          <div>{@run.penalty |> format_penalty()}</div>
        <% end %>
      </div>
    </div>
    """
  end

  defp run_time_class(run),
    do: [
      run.best && "underline underline-offset-2",
      run.penalty in ["DNF", "RRN"] && "line-through"
    ]

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
                {row.driver_name}
              </td>
              <td class="text-right pl-2 max-sm:hidden">
                {row.car_no}
              </td>
              <td class="text-left pl-2 max-sm:hidden">
                {row.car_class}
              </td>
              <td class="text-left max-w-36 whitespace-nowrap text-ellipsis overflow-hidden pl-2 max-sm:hidden">
                {row.car_model}
              </td>
              <td class="text-right pl-2">
                {row.counted_run_no |> format_run_no()}
              </td>
              <td class="text-right pl-2 whitespace-nowrap">
                <div>{row.run_time |> format_score()}</div>
              </td>
              <td class="text-left pl-2 whitespace-nowrap">
                <div>{row.penalty |> format_penalty()}</div>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  attr :drivers, :list, required: true

  def cones(assigns) do
    ~H"""
    <table class="border-collapse striped w-full">
      <thead>
        <th class="font-bold text-left pl-1 pt-1">Driver</th>
        <th class="font-bold text-right pl-2 pt-1 max-sm:hidden">#</th>
        <th class="font-bold text-left pl-2 pt-1 max-sm:hidden">Class</th>
        <th class="font-bold text-left pl-2 pt-1 max-sm:hidden">Model</th>
        <th class="font-bold text-right pl-2 pt-1 pr-1">Cones</th>
      </thead>
      <tbody>
        <%= for d <- @drivers do %>
          <tr>
            <td class="text-left pl-1 align-top">
              {d.driver_name}
            </td>
            <td class="text-right pl-2 align-top max-sm:hidden">
              {d.car_no}
            </td>
            <td class="text-left pl-2 align-top max-sm:hidden">
              {d.car_class}
            </td>
            <td class="text-left pl-2 whitespace align-top max-sm:hidden">
              {d.car_model}
            </td>
            <td class="text-right pl-2 whitespace-nowrap pr-1">
              {d.num_cones}
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end
