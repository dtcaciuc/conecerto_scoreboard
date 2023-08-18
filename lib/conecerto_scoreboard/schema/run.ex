defmodule Conecerto.Scoreboard.Schema.Run do
  use Ecto.Schema

  import Ecto.Changeset

  schema "runs" do
    field :car_no, :integer
    field :run_time, :float
    field :penalty, :string
  end

  def changeset(class, params) do
    class
    |> cast(params, [:run_time])
    |> validate_required([:run_time])
  end
end
