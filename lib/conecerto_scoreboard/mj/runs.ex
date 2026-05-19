defmodule Conecerto.Scoreboard.MJ.Runs do
  require Logger

  def read_last_day(path) do
    rows =
      try do
        File.stream!(path)
        |> Conecerto.Scoreboard.MJ.CSVParser.parse_stream_reversed()
        |> Enum.reduce([], &parse_row/2)
      rescue
        _ in File.Error -> []
      end

    last_day =
      if Enum.count(rows) > 0 do
        rows
        |> Enum.map(& &1.day)
        |> Enum.max()
      else
        1
      end

    rows
    |> Enum.filter(&(&1.day == last_day))
    |> Enum.map(&Map.delete(&1, :day))
    |> put_run_numbers()
  end

  defp parse_row(
         %{"car_number" => car_no, "day" => day, "penalty" => penalty, "run_time" => run_time},
         runs
       ) do
    with {parsed_day, ""} <- Integer.parse(day),
         {parsed_car_no, ""} <- Integer.parse(car_no),
         {parsed_time, ""} <- Float.parse(run_time) do
      # MJ timing scoring interprets 0.0 as max time
      parsed_time =
        if parsed_time == 0.0 do
          999.999
        else
          parsed_time
        end

      [
        %{
          day: parsed_day,
          car_no: parsed_car_no,
          run_time: parsed_time,
          penalty: penalty
        }
        | runs
      ]
    else
      _ ->
        runs
    end
  end

  defp parse_row(row, runs) do
    Logger.warning("Could not read an incomplete run definition: #{inspect(row)}")
    runs
  end

  defp put_run_numbers(runs) do
    %{runs: runs} =
      for run <- runs, reduce: %{runs: [], run_counts: %{}} do
        %{runs: runs, run_counts: run_counts} ->
          {run_no, run_counts} =
            if run.penalty != "RRN" do
              Map.get_and_update(run_counts, run.car_no, fn value ->
                {value || 1, (value || 1) + 1}
              end)
            else
              {nil, run_counts}
            end

          %{runs: [Map.put(run, :run_no, run_no) | runs], run_counts: run_counts}
      end

    runs |> Enum.reverse()
  end
end
