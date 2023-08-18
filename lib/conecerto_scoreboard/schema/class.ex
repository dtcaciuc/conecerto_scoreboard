defmodule Conecerto.Scoreboard.Schema.Class do
  use Ecto.Schema

  alias __MODULE__

  import Ecto.Changeset

  schema "classes" do
    field :name, :string
    field :pax, :float
    field :description, :string
  end

  @all_fields [
    :name,
    :pax,
    :description
  ]

  def build(params) do
    %Class{}
    |> changeset(params)
  end

  def changeset(class, params) do
    class
    |> cast(params, @all_fields)
    |> validate_required(@all_fields)
  end
end
