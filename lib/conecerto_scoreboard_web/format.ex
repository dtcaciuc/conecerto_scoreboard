defmodule Conecerto.ScoreboardWeb.Format do
  def format_score(v), do: :erlang.float_to_binary(v, decimals: 3)

  def format_penalty(""), do: "\u00A0"
  def format_penalty("DNF"), do: "DNF"
  def format_penalty("RRN"), do: "RRN"
  def format_penalty(v), do: "#{v}Δ"

  def format_run_no(-1), do: "-"
  def format_run_no(run_no), do: run_no
end
