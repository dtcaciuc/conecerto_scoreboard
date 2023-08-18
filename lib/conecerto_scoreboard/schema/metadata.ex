defmodule Conecerto.Scoreboard.Schema.Metadata do
  use Ecto.Schema

  alias __MODULE__

  import Ecto.Changeset

  schema "metadata" do
    field :key, :string
    field :value, :string
  end

  def build_timestamp() do
    now = NaiveDateTime.local_now() |> NaiveDateTime.to_string()

    %Metadata{}
    |> change(key: "last_updated_at", value: now)
  end
end
