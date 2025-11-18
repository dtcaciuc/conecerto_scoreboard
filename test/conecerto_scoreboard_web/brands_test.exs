defmodule Conecerto.ScoreboardWeb.BrandsTest do
  use ExUnit.Case

  alias Conecerto.ScoreboardWeb.Brands

  test "handle no brands directory" do
    pid = start_supervised!({Brands, [dir: nil, load_delay: 50, name: nil]})
    :timer.sleep(100)

    assert %{organizer: nil, sponsors: []} = GenServer.call(pid, :get)
  end

  @tag :tmp_dir
  test "handle empty brands directory", %{tmp_dir: tmp_dir} do
    pid = start_supervised!({Brands, [dir: tmp_dir, load_delay: 50, name: nil]})
    :timer.sleep(100)

    assert %{organizer: nil, sponsors: []} = GenServer.call(pid, :get)
  end

  @tag :tmp_dir
  test "handle one or more sponsors", %{tmp_dir: tmp_dir} do
    name1 = "a-sponsor.jpg"
    name2 = "b-sponsor.png"

    File.write!(Path.join(tmp_dir, name1), "")
    File.write!(Path.join(tmp_dir, name2), "")
    File.write!(Path.join(tmp_dir, "c-sponsor.notanimage"), "")

    pid = start_supervised!({Brands, [dir: tmp_dir, load_delay: 50, name: nil]})
    :timer.sleep(100)

    assert %{organizer: nil, sponsors: [s1, s2]} = GenServer.call(pid, :get)

    assert s1.name == name1
    assert String.starts_with?(s1.path, "/brands/a-sponsor.jpg?v=")

    assert s2.name == name2
    assert String.starts_with?(s2.path, "/brands/b-sponsor.png?v=")
  end

  @tag :tmp_dir
  test "handle organizer", %{tmp_dir: tmp_dir} do
    name = "organizer.jpg"
    File.write!(Path.join(tmp_dir, name), "")

    pid = start_supervised!({Brands, [dir: tmp_dir, load_delay: 50, name: nil]})
    :timer.sleep(100)

    assert %{organizer: organizer, sponsors: []} = GenServer.call(pid, :get)
    assert %{name: ^name, path: path} = organizer

    assert String.starts_with?(path, "/brands/organizer.jpg?v=")
  end

  @tag :tmp_dir
  test "reading optional URLs", %{tmp_dir: tmp_dir} do
    File.write!(Path.join(tmp_dir, "organizer.jpg"), "")
    File.write!(Path.join(tmp_dir, "a-sponsor.jpg"), "")
    File.write!(Path.join(tmp_dir, "urls.csv"), "name,url\norganizer,http://organizer.local")

    pid = start_supervised!({Brands, [dir: tmp_dir, load_delay: 50, name: nil]})
    :timer.sleep(100)

    assert %{organizer: organizer, sponsors: sponsors} = GenServer.call(pid, :get)

    assert %{url: "http://organizer.local"} = organizer
    assert [%{url: nil}] = sponsors
  end
end
