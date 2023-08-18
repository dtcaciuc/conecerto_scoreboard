defmodule Conecerto.Scoreboard.Schema.Group do
  use Ecto.Schema

  import Ecto.Changeset

  schema "groups" do
    field :name, :string
    field :driver_id, :integer

    # Omit drivers association
  end

  @all_fields [
    :name,
    :driver_id
  ]

  def changeset(class, params) do
    class
    |> cast(params, @all_fields)
    |> validate_required(@all_fields)
  end
end
