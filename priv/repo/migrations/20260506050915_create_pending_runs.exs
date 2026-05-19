defmodule Conecerto.Scoreboard.Repo.Migrations.CreatePendingRuns do
  use Ecto.Migration

  def change do
    create table("pending_runs") do
      add :car_no, :integer, null: false
      add :run_no, :integer
      add :running?, :boolean, default: false
      add :penalty, :string, default: ""
    end
  end
end
