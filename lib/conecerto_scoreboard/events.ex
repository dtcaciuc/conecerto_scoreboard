defmodule Conecerto.Scoreboard.Events do
  def get_event_name(nil, _date),
    do: nil

  def get_event_name(schedule_path, date) do
    events =
      try do
        schedule_path
        |> File.stream!()
        |> Conecerto.Scoreboard.MJ.CSVParser.parse_stream_reversed()
        |> Enum.reduce(%{}, &parse_schedule_row/2)
      rescue
        _ in File.Error -> %{}
      end

    events[date]
  end

  defp parse_schedule_row(%{"date" => date, "name" => name}, events),
    do: Map.put(events, date, name)
end
