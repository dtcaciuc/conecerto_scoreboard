defmodule Conecerto.Scoreboard do
  import Ecto.Query

  alias Conecerto.Scoreboard.Repo
  alias Conecerto.Scoreboard.Schema
  alias Conecerto.Scoreboard.Schema.Class
  alias Conecerto.Scoreboard.Schema.Driver
  alias Conecerto.Scoreboard.Schema.Group
  alias Conecerto.Scoreboard.Schema.Run

  def config(key) do
    Application.fetch_env!(:conecerto_scoreboard, __MODULE__)[key]
  end

  def last_updated_at() do
    q =
      from(m in Schema.Metadata,
        where: m.key == "last_updated_at",
        select: m.value
      )

    case Repo.one(q) do
      nil ->
        "never"

      timestamp ->
        timestamp
    end
  end

  def load_data(classes, drivers, runs) do
    {drivers, groups} = groups_from_drivers(drivers)

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:delete_classes, Class)
    |> Ecto.Multi.delete_all(:delete_drivers, Driver)
    |> Ecto.Multi.delete_all(:delete_groups, Group)
    |> Ecto.Multi.delete_all(:delete_run, Run)
    |> Ecto.Multi.insert_all(:classes, Class, classes)
    |> Ecto.Multi.insert_all(:drivers, Driver, drivers)
    |> Ecto.Multi.insert_all(:groups, Group, groups)
    |> Ecto.Multi.insert_all(:runs, Run, runs)
    |> Ecto.Multi.insert(
      :last_updated_at,
      Schema.Metadata.build_timestamp(),
      on_conflict: :replace_all
    )
    |> Repo.transaction()
  end

  defp groups_from_drivers(drivers) do
    groups =
      drivers
      |> Enum.flat_map(fn driver ->
        Enum.map(driver.group_names, fn name ->
          %{name: name, driver_id: driver.id}
        end)
      end)
      |> Enum.reverse()

    {Enum.map(drivers, &Map.delete(&1, :group_names)), groups}
  end

  def list_raw_scores() do
    Schema.RawScore
    |> Repo.all()
    |> put_raw_scores()
  end

  def list_pax_scores() do
    Schema.PaxScore
    |> Repo.all()
    |> put_pax_scores()
  end

  def list_groups() do
    Repo.all(
      from(g in Schema.GroupScore,
        distinct: true,
        select: %{
          name: g.group_name,
          car_class?: g.group_name == g.car_class
        },
        order_by: g.group_name
      )
    )
  end

  def list_recent_groups(num_groups \\ 6) do
    q =
      from(r in Run,
        join: d in Driver,
        on: r.car_no == d.car_no,
        join: g in Group,
        on: d.id == g.driver_id,
        order_by: [{:desc, r.id}, {:asc, g.name}],
        select: g.name,
        distinct: true,
        limit: ^num_groups
      )

    Repo.all(q)
  end

  def list_group_scores("Classes") do
    Repo.all(
      from(g in Schema.GroupScore,
        where: g.group_name == g.car_class,
        order_by: [g.group_name, :pos]
      )
    )
    |> Enum.chunk_while([], &chunk_scores_by_group/2, &emit_group/1)
    |> Enum.map(& &1.scores)
    # Insert separators before splitting in pages
    # to correctly account for the extra rows.
    |> Enum.intersperse([:separator])
    |> Enum.concat()
  end

  def list_group_scores(name) do
    from(g in Schema.GroupScore,
      where: g.group_name == ^name,
      order_by: [:pos]
    )
    |> Repo.all()
    |> put_pax_scores()
  end

  def list_all_group_scores() do
    Repo.all(
      from(g in Schema.GroupScore,
        order_by: [g.group_name != g.car_class, g.group_name, :pos]
      )
    )
    |> Enum.chunk_while([], &chunk_scores_by_group/2, &emit_group/1)
  end

  defp chunk_scores_by_group(score, []) do
    {:cont, [score]}
  end

  defp chunk_scores_by_group(score, [last | _rest] = acc) do
    if score.group_name == last.group_name do
      {:cont, [score | acc]}
    else
      emit_group(acc, [score])
    end
  end

  defp emit_group([]) do
    {:cont, []}
  end

  defp emit_group([last | _rest] = scores, acc \\ []) do
    scores = scores |> Enum.reverse() |> put_pax_scores()
    {:cont, %{name: last.group_name, scores: scores}, acc}
  end

  def list_recent_runs(num_runs \\ 10) do
    from(r in Schema.RecentRun,
      order_by: [{:desc, :global_run_no}],
      limit: ^num_runs
    )
    |> Repo.all()
    |> Enum.reverse()
  end

  def announce_run(scores, car_no) do
    {scores, selected_pos} =
      Enum.map_reduce(scores, nil, fn row, selected_pos ->
        if selected_pos == nil && row.car_no == car_no do
          {%{row | selected: true}, row.pos}
        else
          {row, selected_pos}
        end
      end)

    {top10, rest} = Enum.split(scores, 10)

    rest =
      if selected_pos != nil && selected_pos > 12 do
        # +/- 1 driver window shifted lower than first 3 entries
        Enum.filter(rest, fn row ->
          row.pos >= selected_pos - 1 && row.pos <= selected_pos + 1
        end)
      else
        Enum.take(rest, 3)
      end

    %{top10: top10, rest: rest}
  end

  def empty_page() do
    %{
      top10: [],
      current: nil,
      rest: [],
      num_pages: 0
    }
  end

  def paginate(scores, page_size, opts \\ []) do
    {sticky_top10?, _} = Keyword.pop(opts, :sticky_top10?, true)

    {top10, rest} =
      if sticky_top10? do
        Enum.split(scores, 10)
      else
        {nil, scores}
      end

    pages =
      rest
      |> Enum.chunk_every(page_size)
      |> Enum.with_index()
      |> Enum.map(fn {entries, page_num} ->
        %{entries: entries, num: page_num + 1}
      end)
      |> Enum.to_list()

    next_page(%{
      top10: top10,
      current: nil,
      rest: pages,
      num_pages: Enum.count(pages)
    })
  end

  def paginate_groups(groups) do
    next_page(%{
      current: nil,
      rest: groups,
      num_pages: Enum.count(groups)
    })
  end

  def next_page(%{rest: []} = paginated) do
    %{paginated | current: nil, rest: []}
  end

  def next_page(%{rest: [current | rest]} = paginated) do
    %{paginated | current: current, rest: rest}
  end

  def list_car_runs(car_no) do
    from(r in Schema.RecentRun,
      where: r.car_no == ^car_no,
      order_by: [{:asc, :global_run_no}]
    )
    |> Repo.all()
    |> put_best_run()
  end

  def get_last_run_driver() do
    q = from(r in Run, order_by: [{:desc, :id}], limit: 1)

    case Repo.one(q) do
      nil ->
        nil

      last_run ->
        Repo.one(
          from(d in Driver,
            where: d.car_no == ^last_run.car_no,
            preload: [:runs]
          )
        )
    end
  end

  def list_drivers_and_runs() do
    q =
      from(r in Schema.RecentRun,
        order_by: [
          {:asc, :driver_name},
          {:asc, :car_no},
          {:asc, :global_run_no}
        ]
      )

    Repo.all(q)
    |> Enum.chunk_while([], &chunk_runs_by_driver/2, fn
      [] ->
        {:cont, []}

      [last | _rest] = acc ->
        {:cont,
         %{
           driver_name: last.driver_name,
           car_no: last.car_no,
           car_class: last.car_class,
           car_model: last.car_model,
           runs: Enum.reverse(acc)
         }, []}
    end)
    |> Enum.map(fn driver ->
      %{driver | runs: put_best_run(driver.runs)}
    end)
  end

  defp chunk_runs_by_driver(run, [] = _acc) do
    {:cont, [run]}
  end

  defp chunk_runs_by_driver(run, [last | _rest] = acc) do
    if run.car_no != last.car_no do
      {:cont,
       %{
         driver_name: last.driver_name,
         car_no: last.car_no,
         car_class: last.car_class,
         car_model: last.car_model,
         runs: Enum.reverse(acc)
       }, [run]}
    else
      {:cont, [run | acc]}
    end
  end

  defp put_best_run(runs) do
    fastest_run = Enum.min_by(runs, &effective_run_time/1)

    Enum.map(runs, fn run ->
      %{run | best: run.counted_run_no == fastest_run.counted_run_no}
    end)
  end

  # Don't count reruns
  defp effective_run_time(%{counted_run_no: -1}), do: 9999.999

  defp effective_run_time(%{run_time: run_time, penalty: ""}), do: run_time

  defp effective_run_time(%{run_time: run_time, penalty: penalty}) do
    case Integer.parse(penalty) do
      {num_cones, ""} ->
        run_time + num_cones * 2.0

      _ ->
        9999.999
    end
  end

  def list_total_cones() do
    list_drivers_and_runs()
    |> Enum.map(&Map.put(&1, :num_cones, count_cones(&1.runs)))
    |> Enum.sort_by(& &1.num_cones, :desc)
    |> Enum.filter(&(&1.num_cones > 0))
  end

  defp count_cones(runs) do
    runs
    |> Enum.map(fn
      %{counted_run_no: -1} ->
        0

      %{penalty: ""} ->
        0

      %{penalty: penalty} ->
        case Integer.parse(penalty) do
          {num_cones, ""} ->
            num_cones

          _ ->
            0
        end
    end)
    |> Enum.sum()
  end

  defp put_raw_scores([]), do: []

  defp put_raw_scores(results) do
    best_time = Enum.min_by(results, & &1.raw_time).raw_time
    Enum.map(results, fn r -> %{r | score: 100.0 * best_time / r.raw_time} end)
  end

  defp put_pax_scores([]), do: []

  defp put_pax_scores(results) do
    best_time = Enum.min_by(results, & &1.pax_time).pax_time
    Enum.map(results, fn r -> %{r | score: 100.0 * best_time / r.pax_time} end)
  end
end
