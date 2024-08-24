defmodule Conecerto.Scoreboard.Datetime do
  def today_str() do
    now = NaiveDateTime.local_now()
    "#{now.year}_#{pad_date_zero(now.month)}_#{pad_date_zero(now.day)}"
  end

  defp pad_date_zero(d) do
    d |> Integer.to_string() |> String.pad_leading(2, "0")
  end
end
