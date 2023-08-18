defmodule Conecerto.ScoreboardWeb.Format do
  def format_score(v), do: :erlang.float_to_binary(v, decimals: 3)

  def format_penalty(""), do: "\u00A0"
  def format_penalty("DNF"), do: "DNF"
  def format_penalty("RRN"), do: "RRN"
  def format_penalty("1"), do: "Δ"
  def format_penalty(v), do: "Δ×#{v}"
end
