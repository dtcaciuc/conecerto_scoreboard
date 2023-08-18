defmodule Conecerto.Scoreboard.Schema.PaxScore do
  use Ecto.Schema

  @primary_key false
  schema "pax_scores" do
    field :pos, :integer
    field :car_no, :integer
    field :driver_name, :string
    field :car_class, :string
    field :car_model, :string
    field :pax_time, :float
    field :raw_time_to_top, :float
    field :raw_time_to_next, :float

    field :selected, :boolean, virtual: true
  end
end
