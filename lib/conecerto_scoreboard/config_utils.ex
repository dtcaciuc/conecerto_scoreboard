defmodule Conecerto.Scoreboard.ConfigUtils do
  def parse_bool!(s) do
    case String.downcase(s) do
      "y" -> true
      "yes" -> true
      "true" -> true
      "1" -> true
      "n" -> false
      "no" -> false
      "false" -> false
      "0" -> false
      _ -> raise "#{s} is not a valid boolean value"
    end
  end

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
