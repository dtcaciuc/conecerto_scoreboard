defmodule Conecerto.Scoreboard.Repo.Migrations.AddRunsNo do
  use Ecto.Migration

  def change do
    alter table("runs") do
      add :run_no, :integer
    end
  end
end
