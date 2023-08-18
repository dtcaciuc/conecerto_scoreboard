defmodule Conecerto.Scoreboard.Schema.RecentRun do
  use Ecto.Schema

  @primary_key false
  schema "recent_runs" do
    field :global_run_no, :integer
    field :counted_run_no, :integer
    field :car_no, :integer
    field :driver_name, :string
    field :car_class, :string
    field :car_model, :string
    field :run_time, :float
    field :penalty, :string
    field :result, :string

    field :selected, :boolean, virtual: true
  end
end
