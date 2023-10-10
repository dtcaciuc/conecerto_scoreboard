defmodule Conecerto.Scoreboard.Schema.Driver do
  use Ecto.Schema

  import Ecto.Changeset

  schema "drivers" do
    field :first_name, :string
    field :last_name, :string
    field :car_no, :integer
    field :car_model, :string
    field :car_class, :string
    # Omit groups association

    field :group_names, {:array, :string}, virtual: true

    has_many :runs, Conecerto.Scoreboard.Schema.Run, foreign_key: :car_no, references: :car_no
  end

  @all_fields [
    :first_name,
    :last_name,
    :car_no,
    :car_model,
    :car_class
  ]

  def changeset(class, params) do
    class
    |> cast(params, @all_fields)
    |> validate_required(@all_fields)
  end
end
