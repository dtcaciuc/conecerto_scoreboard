defmodule Conecerto.Scoreboard.ConfigUtils do
  def parse_float!(s) do
    case Float.parse(s) do
      {f, ""} -> f
      _ -> raise "#{s} is not a valid floating point number"
    end
  end

  def parse_explorer_page!(s) do
    if Enum.member?(~w(event pax raw groups runs cones), s) do
      s
    else
      raise "#{s} is not a valid explorer page"
    end
  end

  def generate_secret_key_base() do
    for _ <- 1..64, into: "" do
      <<Enum.random(~c"0123456789abcdef")>>
    end
  end
end
