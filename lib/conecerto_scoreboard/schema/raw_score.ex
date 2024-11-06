defmodule Conecerto.Scoreboard.Schema.RawScore do
  use Ecto.Schema

  @primary_key false
  schema "raw_scores" do
    field :pos, :integer
    field :car_no, :integer
    field :driver_name, :string
    field :car_class, :string
    field :car_model, :string
    field :raw_time, :float
    field :raw_time_to_top, :float
    field :raw_time_to_next, :float

    field :score, :float, virtual: true
    field :selected, :boolean, virtual: true
  end
end
