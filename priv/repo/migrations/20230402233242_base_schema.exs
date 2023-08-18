defmodule Conecerto.Scoreboard.Repo.Migrations.BaseSchema do
  use Ecto.Migration

  def up do
    create table("classes") do
      add :name, :string, primary_key: true
      add :pax, :float, null: false
      add :description, :string
    end

    create table("drivers") do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :car_no, :integer, null: false
      add :car_model, :string, null: false
      add :car_class, :string, null: false
    end

    create table("groups") do
      add :name, :string, primary_key: true
      add :driver_id, :integer, null: false
    end

    create table("runs") do
      add :car_no, :integer, null: false
      add :run_time, :float
      add :penalty, :text
    end

    create table("metadata") do
      add :key, :string, null: false
      add :value, :string
    end

    create index("drivers", [:car_no], unique: true)
    create index("metadata", [:key], unique: true)

    execute """
    CREATE VIEW raw_scores AS
    WITH
        _scores AS (
                SELECT
                        drivers.car_no AS car_no,
                        last_name || ', ' || first_name AS driver_name,
                        classes.name AS car_class,
                        drivers.car_model AS car_model,
                        min(run_time + penalty * 2) AS raw_time
                FROM drivers
                INNER JOIN runs ON runs.car_no = drivers.car_no
                INNER JOIN classes ON classes.name = drivers.car_class
                WHERE runs.penalty NOT IN ('DNF', 'RRN')
                GROUP BY drivers.id
    )
    SELECT
        row_number() OVER (ORDER BY raw_time) AS pos,
        _scores.car_no AS car_no,
        _scores.driver_name AS driver_name,
        _scores.car_class AS car_class,
        _scores.car_model AS car_model,
        _scores.raw_time AS raw_time,
        raw_time - (SELECT MIN(raw_time) FROM _scores) AS raw_time_to_top,
        raw_time - LAG(raw_time, 1) OVER (ORDER BY raw_time) AS raw_time_to_next
    FROM
        _scores;
    """

    execute """
    CREATE VIEW pax_scores AS
    WITH
        _scores AS (
                SELECT
                        drivers.car_no AS car_no,
                        last_name || ', ' || first_name AS driver_name,
                        classes.name AS car_class,
                        drivers.car_model AS car_model,
                        classes.pax AS pax,
                        min((run_time + penalty * 2) * classes.pax) AS pax_time
                FROM drivers
                INNER JOIN runs ON runs.car_no = drivers.car_no
                INNER JOIN classes ON classes.name = drivers.car_class
                WHERE runs.penalty NOT IN ('DNF', 'RRN')
                GROUP BY drivers.id
                )
    SELECT
        row_number() OVER (ORDER BY pax_time) AS pos,
        _scores.car_no AS car_no,
        _scores.driver_name AS driver_name,
        _scores.car_class AS car_class,
        _scores.car_model AS car_model,
        _scores.pax_time AS pax_time,
        (pax_time - (SELECT MIN(pax_time) FROM _scores)) / pax AS raw_time_to_top,
        (pax_time - LAG(pax_time, 1) OVER (ORDER BY pax_time)) / pax AS raw_time_to_next
    FROM
        _scores;
    """

    execute """
    CREATE VIEW group_scores AS
    WITH
    	_scores AS (
    		SELECT
    			drivers.car_no AS car_no,
    			last_name || ', ' || first_name AS driver_name,
    			groups.name as group_name,
    			classes.name AS car_class,
    			drivers.car_model AS car_model,
    			classes.pax AS pax,
    			min(run_time + penalty * 2) as raw_time,
    			min((run_time + penalty * 2) * pax) AS pax_time
    		FROM drivers
    		INNER JOIN runs ON runs.car_no = drivers.car_no
    		INNER JOIN classes ON classes.name = drivers.car_class
    		INNER JOIN groups ON groups.driver_id = drivers.id
    		WHERE runs.penalty NOT IN ('DNF', 'RRN')
    		GROUP BY groups.name, drivers.id
    	)
    SELECT
    	row_number() OVER (PARTITION BY _scores.group_name ORDER BY pax_time) AS pos,
    	_scores.car_no AS car_no,
    	_scores.driver_name AS driver_name,
    	_scores.group_name AS group_name,
    	_scores.car_class AS car_class,
    	_scores.car_model AS car_model,
    	_scores.raw_time AS raw_time,
    	_scores.pax_time AS pax_time,
    	(pax_time - min_pax_time) / pax AS raw_time_to_top,
    	(pax_time - LAG(pax_time, 1) OVER (PARTITION BY _scores.group_name ORDER BY pax_time)) / pax AS raw_time_to_next
    FROM
    	_scores
    	INNER JOIN (SELECT group_name, MIN(pax_time) AS min_pax_time FROM _scores GROUP BY group_name) AS _min_pax_times
    		ON _scores.group_name = _min_pax_times.group_name;
    """

    execute """
    CREATE VIEW recent_runs AS
    WITH
        -- Runs with global run #
        numbered AS (
                SELECT
                        ROWID as global_run_no,
                        car_no,
                        run_time,
                        penalty,
                        CASE penalty
                                WHEN '' THEN printf('%.3f', run_time)
                                ELSE printf('%.3f', run_time) || '+' || penalty
                        END AS result
                FROM runs
                ),
        -- Runs groupped by car/driver and assigned
        -- local run # excluding reruns.
        counted AS (
                SELECT
                        global_run_no,
                        ROW_NUMBER() OVER (PARTITION BY car_no) run_no
                FROM numbered
                WHERE penalty != 'RRN'
                )
    SELECT
        IFNULL(last_name || ', ' || first_name, 'Unknown') AS driver_name,
        IFNULL(classes.name, '?') AS car_class,
        IFNULL(drivers.car_model, '?') AS car_model,
        numbered.car_no AS car_no,
        numbered.run_time AS run_time,
        numbered.penalty AS penalty,
        numbered.result AS result,
        numbered.global_run_no AS global_run_no,
        coalesce(counted.run_no, -1) AS counted_run_no
    FROM
        numbered
    LEFT JOIN counted ON
        numbered.global_run_no = counted.global_run_no
    LEFT JOIN drivers ON
        numbered.car_no = drivers.car_no
    LEFT JOIN classes ON
        classes.name = drivers.car_class;
    """
  end

  def down do
    execute "DROP VIEW raw_scores;"
    execute "DROP VIEW pax_scores;"
    execute "DROP VIEW group_scores;"
    execute "DROP VIEW recent_runs;"
    execute "DROP TABLE metadata;"
    execute "DROP TABLE runs;"
    execute "DROP TABLE groups;"
    execute "DROP TABLE drivers;"
    execute "DROP TABLE classes;"
  end
end
