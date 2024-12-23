defmodule Day23Test do
  use ExUnit.Case
  doctest Day23

  test "constructs a graph" do
    g = Day23.make_graph("kh-tc");
    assert Graph.num_vertices(g) == 2
    assert Graph.num_edges(g) == 1
    assert Enum.sort(Graph.vertices(g)) == Enum.sort(["kh", "tc"])
  end
end
