defmodule Conecerto.ScoreboardWeb.Tv do
  use Conecerto.ScoreboardWeb, :live_view

  import Conecerto.ScoreboardWeb.Format

  alias Conecerto.Scoreboard
  alias Conecerto.ScoreboardWeb.Brands

  @impl true
  def mount(_params, _session, socket) do
    group_by_class? = Scoreboard.config(:group_by_class?)

    if connected?(socket) do
      :ok = Conecerto.ScoreboardWeb.Endpoint.subscribe("mj")

      Process.send_after(self(), :refresh, Scoreboard.config(:tv_refresh_interval))

      # Currently, 100px of footer with ads takes away 5 rows of scores.
      {page_size, group_page_size} =
        if Brands.any?() do
          {25, 10}
        else
          {30, 15}
        end

      groups = Scoreboard.paginate_groups(list_groups(group_by_class?))
      group_scores = load_group(groups, group_page_size)

      socket =
        socket
        |> assign(page_size: page_size)
        |> assign(group_page_size: group_page_size)

      {:ok,
       assign(socket,
         root_font_size: Scoreboard.config(:tv_font_size),
         raw_scores: Scoreboard.paginate(Scoreboard.list_raw_scores(), page_size),
         pax_scores: Scoreboard.paginate(Scoreboard.list_pax_scores(), page_size),
         groups: groups,
         group_scores: group_scores,
         group_by_class?: group_by_class?,
         recent_runs: Scoreboard.list_recent_runs()
       ), layout: {Conecerto.ScoreboardWeb.Layouts, :tv}}
    else
      {:ok,
       assign(socket,
         root_font_size: Scoreboard.config(:tv_font_size),
         raw_scores: Scoreboard.empty_page(),
         pax_scores: Scoreboard.empty_page(),
         groups: Scoreboard.empty_page(),
         group_scores: Scoreboard.empty_page(),
         group_by_class?: group_by_class?,
         recent_runs: []
       ), layout: {Conecerto.ScoreboardWeb.Layouts, :tv}}
    end
  end

  defp list_groups(true = _group_by_class?) do
    # Combine class groups into a single "Classes" group
    [
      "Classes"
      | Scoreboard.list_groups()
        |> Enum.filter(&(not &1.car_class?))
        |> Enum.map(& &1.name)
    ]
  end

  defp list_groups(false = _group_by_class?) do
    Scoreboard.list_groups() |> Enum.map(& &1.name)
  end

  defp load_group(%{current: nil}, _page_size),
    do: Scoreboard.empty_page()

  defp load_group(%{current: "Classes" = name}, page_size) do
    Scoreboard.paginate(Scoreboard.list_group_scores(name), page_size + 11, sticky_top10?: false)
  end

  defp load_group(%{current: name}, page_size) do
    Scoreboard.paginate(Scoreboard.list_group_scores(name), page_size)
  end

  defp split_by_class(page) do
    page
    |> Enum.filter(&(&1 != :separator))
    |> Enum.chunk_by(& &1.car_class)
    |> Enum.map(fn
      [head | _rest] = chunk when head.pos != 1 ->
        # Insert ellipsis if new page starts with a partial class
        # continuing from the previous page.
        [:ellipsis | chunk]

      other ->
        other
    end)
    |> Enum.intersperse([:separator])
  end

  defp prepend_separator(rows),
    do: [:separator | rows]

  @impl true
  def handle_info(:mj_update, socket) do
    # Immediately refresh recent runs;
    # Let paging views reload data on their own pace.
    {:noreply, assign(socket, recent_runs: Scoreboard.list_recent_runs())}
  end

  @impl true
  def handle_info(:refresh, %{assigns: assigns} = socket) do
    raw_scores =
      if assigns.raw_scores.rest == [] do
        Scoreboard.paginate(Scoreboard.list_raw_scores(), assigns.page_size)
      else
        Scoreboard.next_page(assigns.raw_scores)
      end

    pax_scores =
      if assigns.pax_scores.rest == [] do
        Scoreboard.paginate(Scoreboard.list_pax_scores(), assigns.page_size)
      else
        Scoreboard.next_page(assigns.pax_scores)
      end

    {groups, group_scores} =
      if assigns.group_scores.rest == [] do
        groups =
          if assigns.groups.rest == [] do
            Scoreboard.paginate_groups(list_groups(assigns.group_by_class?))
          else
            Scoreboard.next_page(assigns.groups)
          end

        {groups, load_group(groups, assigns.group_page_size)}
      else
        {assigns.groups, Scoreboard.next_page(assigns.group_scores)}
      end

    Process.send_after(self(), :refresh, Scoreboard.config(:tv_refresh_interval))

    {:noreply,
     assign(socket,
       raw_scores: raw_scores,
       pax_scores: pax_scores,
       groups: groups,
       group_scores: group_scores
     )}
  end

  def paged_scores(assigns) do
    ~H"""
    <div>
      <.paged_scores_title title={@view_title} scores={@scores} />
      <table class="border-collapse striped w-full">
        <.paged_scores_header time_column_title={@time_column_title} />
        <.paged_scores_page rows={@scores.top10} time_column_field={@time_column_field} />
        <%= if @scores.current do %>
          <.paged_scores_page
            rows={prepend_separator(@scores.current.entries)}
            time_column_field={@time_column_field}
          />
        <% end %>
      </table>
    </div>
    """
  end

  # Special case of paged_scores for classes used as groups without the sticky "top 10".
  def paged_class_scores(assigns) do
    ~H"""
    <div>
      <.paged_scores_title title="Classes" scores={@scores} />
      <table class="border-collapse striped w-full">
        <.paged_scores_header time_column_title="PAX Best" />
        <%= for rows <- split_by_class(@scores.current.entries) do %>
          <.paged_scores_page rows={rows} time_column_field={:pax_time} />
        <% end %>
      </table>
    </div>
    """
  end

  def paged_scores_page(assigns) do
    ~H"""
    <tbody>
      <%= for row <- @rows do %>
        <.paged_scores_row row={row} time_column_field={@time_column_field} />
      <% end %>
    </tbody>
    """
  end

  def paged_scores_header(assigns) do
    ~H"""
    <thead>
      <th class="font-bold text-right pt-0">P</th>
      <th class="font-bold text-left pl-2 pt-0">Driver</th>
      <th class="font-bold text-right pl-2 pt-0">#</th>
      <th class="font-bold text-left pl-2 pt-0">Class</th>
      <th class="font-bold text-left pl-2 pt-0">Model</th>
      <th class="font-bold whitespace-nowrap text-right relative pt-0">
        <div class="absolute top-0 right-0 pt-0">
          {@time_column_title}
        </div>
      </th>
      <th class="font-bold whitespace-nowrap text-right pl-2 pt-0" colspan="2">Raw Interval</th>
    </thead>
    """
  end

  def paged_scores_row(%{row: :ellipsis} = assigns) do
    ~H"""
    <tr>
      <td class="font-bold text-right pt-0"></td>
      <td class="font-bold text-left pl-2 pt-0">…</td>
      <td class="font-bold text-right pl-2 pt-0"></td>
      <td class="font-bold text-left pl-2 pt-0">…</td>
      <td class="font-bold text-left pl-2 pt-0">…</td>
      <td class="font-bold whitespace-nowrap text-right relative pt-0">…</td>
      <th class="font-bold text-right">Top</th>
      <th class="font-bold text-right pl-2">Next</th>
    </tr>
    """
  end

  def paged_scores_row(%{row: :separator} = assigns) do
    ~H"""
    <tr>
      <td class="text-center" colspan="8">
        —
      </td>
    </tr>
    """
  end

  def paged_scores_row(assigns) do
    ~H"""
    <tr>
      <td class="text-right">
        {@row.pos}
      </td>
      <td class="text-left max-w-36 truncate pl-2">
        {@row.driver_name}
      </td>
      <td class="text-right pl-2">
        {@row.car_no}
      </td>
      <td class="text-left pl-2">
        {@row.car_class}
      </td>
      <td class="text-left max-w-36 truncate pl-2">
        {@row.car_model}
      </td>
      <td class="text-right pl-2">
        {@row |> get_in([Access.key!(@time_column_field)]) |> format_score()}
      </td>

      <%= if @row.pos == 1 do %>
        <th class="text-right">Top</th>
        <th class="text-right pl-2">Next</th>
      <% else %>
        <td class="text-right pl-2">
          {@row.raw_time_to_top |> format_score()}
        </td>
        <td class="text-right pl-2">
          {@row.raw_time_to_next |> format_score()}
        </td>
      <% end %>
    </tr>
    """
  end

  defp brand_logo(%{brand: nil} = assigns), do: ~H""

  defp brand_logo(assigns) do
    ~H"""
    <img src={brand_path(@brand)} class={@class} />
    """
  end

  defp paged_scores_title(assigns) do
    ~H"""
    <div class="text-2xl text-center mb-2 font-bold">
      {@title}
      <%= if @scores.current != nil and @scores.num_pages > 1 do %>
        ({@scores.current.num}/{@scores.num_pages})
      <% end %>
    </div>
    """
  end

  defp grid_style(true = _brands?), do: "grid-template-rows: auto fit-content(100px)"
  defp grid_style(false = _brands?), do: ""

  defp justify_sponsors(nil = _organizer), do: "justify-center"
  defp justify_sponsors(_organizer), do: "justify-right"

  defp brand_path(brand),
    do: @endpoint.path(brand.path)
end
