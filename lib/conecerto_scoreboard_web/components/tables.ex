defmodule Conecerto.ScoreboardWeb.Tables do
  use Phoenix.Component

  import Conecerto.ScoreboardWeb.Format

  attr :names, :list, required: true
  attr :divider, :string, default: nil

  def subgroup_nav(assigns) do
    ~H"""
    <div class="px-3 text-center z-10 text-lg">
      <%= for {name, i} <- Enum.with_index(@names) do %>
        {if @divider && i > 0, do: @divider}
        <a
          href={"#" <> String.replace(name, " ", "-")}
          class="whitespace-nowrap"
        >
          {name}
        </a>
      <% end %>
    </div>
    """
  end

  attr :scores, :list, required: true
  attr :time_column_field, :atom, required: true
  attr :time_column_title, :string, required: true

  def group_scores(assigns) do
    ~H"""
    <table class="border-collapse striped w-full">
      <.group_scores_head time_column_title={@time_column_title} />
      <.group_scores_body scores={@scores} time_column_field={@time_column_field} />
    </table>
    """
  end

  attr :groups, :list, required: true
  attr :time_column_field, :atom, required: true
  attr :time_column_title, :string, required: true

  def multi_group_scores(assigns) do
    ~H"""
    <table class="border-collapse striped w-full">
      <.group_scores_head time_column_title={@time_column_title} />
      <%= for group <- @groups do %>
        <.subgroup_heading_body :if={group.name} title={group.name} />
        <.group_scores_body scores={group.scores} time_column_field={@time_column_field} />
      <% end %>
    </table>
    """
  end

  attr :title, :string, required: true

  defp subgroup_heading_body(assigns) do
    ~H"""
    <tbody>
      <tr />
      <tr>
        <td colspan="10">
          <div class="text-xl text-center font-semibold self-center flex items-center mt-2 mb-1">
            <div class="border-b border-b-[--table-stripe-fill-color] flex-auto h-0"></div>
            <div class="mx-3 anchor-target-offset" id={@title |> String.replace(" ", "-")}>
              {@title}
            </div>
            <div class="border-b border-b-[--table-stripe-fill-color] flex-auto h-0"></div>
          </div>
        </td>
      </tr>
    </tbody>
    """
  end

  defp group_scores_head(assigns) do
    ~H"""
    <.table_head>
      <th class="font-bold text-right min-w-4">P</th>
      <th class="font-bold text-left pl-2 w-1/2 max-sm:w-2/3">Driver</th>
      <th class="font-bold text-right pl-2 max-sm:hidden">#</th>
      <th class="font-bold text-left pl-2 max-sm:hidden">Class</th>
      <th class="font-bold text-left pl-3 w-1/2 max-sm:hidden">Model</th>
      <th class="font-bold whitespace-nowrap text-right relative pt-1">
        {@time_column_title}
      </th>
      <th class="font-bold whitespace-nowrap text-right pl-2">Raw Gap</th>
      <th class="font-bold whitespace-nowrap text-right pl-2">Raw Int</th>
      <th class="font-bold text-right pl-2 max-sm:hidden">Score</th>
      <th></th>
    </.table_head>
    """
  end

  attr :scores, :list
  attr :time_column_field, :atom
  attr :title, :string, default: nil

  defp group_scores_body(assigns) do
    ~H"""
    <tbody>
      <tr :if={@title}>
        <td colspan="9" b>
          <div class="text-lg text-center font-semibold self-center flex items-center mt-2 mb-1">
            <div class="border-b border-b-[--table-stripe-fill-color] flex-auto h-0"></div>
            <div class="mx-3">{@title}</div>
            <div class="border-b border-b-[--table-stripe-fill-color] flex-auto h-0"></div>
          </div>
        </td>
      </tr>
      <tr :for={row <- @scores}>
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
        <td class="text-left max-w-36 truncate pl-3 max-sm:hidden">
          {row.car_model}
        </td>
        <td class="text-right pl-2">
          {row |> get_in([Access.key!(@time_column_field)]) |> format_score()}
        </td>
        <%= if row.pos == 1 do %>
          <td class="text-right pl-2">–</td>
          <td class="text-right pl-2">–</td>
        <% else %>
          <td class="text-right pl-2">
            {row.raw_time_to_top |> format_score()}
          </td>
          <td class="text-right pl-2">
            {row.raw_time_to_next |> format_score()}
          </td>
        <% end %>
        <td class="text-left text-right pl-3 max-sm:hidden">
          {row.score |> format_score()}
        </td>
        <td></td>
      </tr>
    </tbody>
    """
  end

  attr :class, :any, default: nil

  slot :inner_block, required: true

  def table_head(assigns) do
    ~H"""
    <thead class={["stick-to-page-header bg-[color:--header-fill-color] text-sm", @class]}>
      <tr class="[&>th]:py-1">
        {render_slot(@inner_block)}
      </tr>
    </thead>
    """
  end

  attr :driver_groups, :list, required: true
  attr :exclude_reruns?, :boolean, default: false

  def runs(assigns) do
    ~H"""
    <table class="border-collapse striped w-full">
      <.table_head class="z-[10]">
        <th class="font-bold text-left pl-2 pt-1">Driver / Car</th>
        <th class="font-bold text-right pl-2 pt-1 max-sm:hidden">#</th>
        <th class="font-bold text-left pl-1 pt-1 max-sm:hidden">Class</th>
        <th class="font-bold text-right pr-2 pt-1 flex justify-start">
          <span class="w-[5.25rem]">Elapsed</span><span class="ml-1.5 text-left">Pen</span>
        </th>
      </.table_head>
      <%= for {title, drivers} <- @driver_groups do %>
        <.subgroup_heading_body title={title} />
        <tbody>
          <tr :for={d <- drivers}>
            <td class={[
              "text-left pl-2 py-1 align-top text-nowrap whitespace-nowrap",
              "max-w-36 w-[50%] max-sm:w-[75%]"
            ]}>
              <div>
                <div class="truncate">
                  {d.driver_name}
                </div>
                <div class="pl-3 truncate">
                  <i>{d.car_model}</i>
                </div>
              </div>
            </td>
            <td class="text-right pl-2 py-1 align-top text-nowrap max-sm:hidden">
              {d.car_no}
            </td>
            <td class="text-left w-[10%] pl-1 py-1 align-top text-nowrap max-sm:hidden">
              {d.car_class}
            </td>
            <td class="text-right pl-8 pr-2 py-1 align-top min-w-[25%]">
              <div class={[
                "grid",
                "sm:grid-cols-[repeat(3,auto)]",
                "max-sm:grid-cols-[repeat(2,auto)]",
                "max-[384px]:grid-cols-[repeat(1,auto)]",
                "gap-x-8 gap-y-1 justify-start"
              ]}>
                <% driver_runs = if @exclude_reruns?, do: exclude_reruns(d.runs), else: d.runs %>
                <%= for r <- driver_runs do %>
                  <.run_result run={r} />
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      <% end %>
    </table>
    """
  end

  defp exclude_reruns(runs),
    do: runs |> Enum.filter(&(&1.penalty != "RRN"))

  def run_result(assigns) do
    ~H"""
    <div class={[
      "flex relative gap-x-1.5",
      @run.penalty == "RRN" && "body-text-muted"
    ]}>
      <div class="absolute -left-4 body-text-muted">
        {@run.counted_run_no |> format_run_no()}
      </div>
      <div class={["w-13", @run.best && "underline underline-offset-4"]}>
        {@run.run_time |> format_score()}
      </div>
      <div class="w-7 text-left">
        <%= if @run.penalty != "" do %>
          {@run.penalty |> format_penalty()}
        <% end %>
      </div>
    </div>
    """
  end

  attr :id, :string, default: nil
  attr :runs, :list, required: true
  attr :combine_model_column?, :boolean, default: false
  attr :show_selection?, :boolean, default: false

  def recent_runs(assigns) do
    ~H"""
    <div>
      <table
        id={@id}
        class="border-collapse striped w-full"
        phx-hook={@id != nil && "RecentRunsTable"}
      >
        <.table_head>
          <th class={["font-bold text-left pl-2", @combine_model_column? && "w-2/3"]}>Driver</th>
          <th class="font-bold text-right pl-2 max-sm:hidden">#</th>
          <th class="font-bold text-left pl-2 max-sm:hidden">Class</th>
          <th :if={not @combine_model_column?} class="font-bold text-left pl-2 max-sm:hidden">
            Model
          </th>
          <th class="font-bold text-right pl-2">Run</th>
          <th class="font-bold text-right text-transparent">⏵</th>
          <th class="font-bold text-right">Elapsed</th>
          <th class="font-bold text-left pl-1.5 pr-2">Pen</th>
        </.table_head>
        <tbody>
          <%= for row <- @runs do %>
            <tr class={@show_selection? && row.selected && "text-amber-300"}>
              <td class="text-left max-w-40 whitespace-nowrap text-ellipsis overflow-hidden pl-2 w-[35%] max-sm:w-[75%]">
                {row.driver_name}
                <div :if={@combine_model_column?} class="pl-3 truncate">
                  <i>{row.car_model}</i>
                </div>
              </td>
              <td class="text-right pl-2 max-sm:hidden">
                {row.car_no}
              </td>
              <td class="text-left pl-2 break-keep max-sm:hidden whitespace-nowrap">
                {row.car_class}
              </td>
              <td
                :if={not @combine_model_column?}
                class="text-left max-w-40 whitespace-nowrap text-ellipsis overflow-hidden pl-2 w-[35%] max-sm:hidden"
              >
                {row.car_model}
              </td>
              <td class="text-right pl-2 relative">
                {row.counted_run_no |> format_run_no()}
              </td>
              <td class="">
                <div :if={row.status == "running"} class="blinker">⏵</div>
              </td>
              <td class="text-right whitespace-nowrap">
                <div class="w-13">{row.run_time |> format_score()}</div>
              </td>
              <td class="text-left pl-1.5 pr-2 whitespace-nowrap">
                <div class="w-7">{row.penalty |> format_penalty()}</div>
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
    <div class={[
      "grid grid-flow-col",
      "grid-rows-2 max-[586px]:grid-rows-3 max-[384px]:grid-rows-6",
      "items-start gap-x-6"
    ]}>
      <%= for block <- chunk_drivers(@drivers, 6) do %>
        <table class="border-collapse striped">
          <tbody>
            <tr :for={d <- block}>
              <td class="text-left pl-1 max-w-36 whitespace-nowrap text-ellipsis overflow-hidden truncate">
                {d.driver_name}
              </td>
              <td class="text-right pl-5 pr-1">
                {d.num_cones}
              </td>
            </tr>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp chunk_drivers([], _max_chunks),
    do: []

  defp chunk_drivers(drivers, max_chunks) do
    n = ceil(Enum.count(drivers) / max_chunks)

    Enum.chunk_every(
      drivers,
      # Round up to even number of rows for each chunk so that
      # striped rows alternate correctly between each consequent pair.
      if rem(n, 2) != 0 do
        n + 1
      else
        n
      end
    )
  end
end
