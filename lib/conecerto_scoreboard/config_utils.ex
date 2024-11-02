defmodule Conecerto.Scoreboard.ConfigUtils do
  def parse_float!(s) do
    case Float.parse(s) do
      {f, ""} -> f
      _ -> raise "#{s} is not a valid floating point number"
    end
  end

  def generate_secret_key_base() do
    for _ <- 1..64, into: "" do
      <<Enum.random(~c"0123456789abcdef")>>
    end
  end
end
