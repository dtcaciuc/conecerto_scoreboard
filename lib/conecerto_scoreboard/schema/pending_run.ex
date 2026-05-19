defmodule Conecerto.Scoreboard.Schema.PendingRun do
  use Ecto.Schema

  schema "pending_runs" do
    field :car_no, :integer
    field :run_no, :integer
    field :running?, :boolean
    field :penalty, :string
  end
end
