defmodule Conecerto.ScoreboardWeb.BrandsTest do
  use ExUnit.Case

  alias Conecerto.ScoreboardWeb.Brands

  test "handle no brands directory" do
    pid = start_supervised!({Brands, [asset_dir: nil, name: nil]})

    assert not GenServer.call(pid, :any?)
    assert nil == GenServer.call(pid, :get_organizer)
    assert [] = GenServer.call(pid, :get_sponsors)
  end

  @tag :tmp_dir
  test "handle empty brands directory", %{tmp_dir: tmp_dir} do
    pid = start_supervised!({Brands, [asset_dir: tmp_dir, name: nil]})

    assert not GenServer.call(pid, :any?)
    assert nil == GenServer.call(pid, :get_organizer)
    assert [] = GenServer.call(pid, :get_sponsors)
  end

  @tag :tmp_dir
  test "handle one or more sponsors", %{tmp_dir: tmp_dir} do
    s1_path = Path.join(tmp_dir, "a-sponsor.jpg")
    s2_path = Path.join(tmp_dir, "b-sponsor.png")

    File.write!(s1_path, "")
    File.write!(s2_path, "")
    File.write!(Path.join(tmp_dir, "c-sponsor.notanimage"), "")

    pid = start_supervised!({Brands, [asset_dir: tmp_dir, name: nil]})

    assert GenServer.call(pid, :any?)
    assert nil == GenServer.call(pid, :get_organizer)
    assert [s1, s2] = GenServer.call(pid, :get_sponsors)

    assert s1.path == s1_path
    assert String.starts_with?(s1.url, "/brands/a-sponsor.jpg?v=")

    assert s2.path == s2_path
    assert String.starts_with?(s2.url, "/brands/b-sponsor.png?v=")
  end

  @tag :tmp_dir
  test "handle organizer", %{tmp_dir: tmp_dir} do
    org_path = Path.join(tmp_dir, "organizer.jpg")
    File.write!(org_path, "")

    pid = start_supervised!({Brands, [asset_dir: tmp_dir, name: nil]})

    assert GenServer.call(pid, :any?)
    assert %{path: path, url: url} = GenServer.call(pid, :get_organizer)
    assert [] = GenServer.call(pid, :get_sponsors)

    assert path == org_path
    assert String.starts_with?(url, "/brands/organizer.jpg?v=")
  end
end
