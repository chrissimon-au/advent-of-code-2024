defmodule Day23 do
  @moduledoc """
  Documentation for `Day23`.
  """

  def get_edge(connection) do
    String.split(connection,"-")
    |> List.to_tuple
  end

  def make_graph(input) do
    g = Graph.new(type: :undirected)
    connections = String.split(String.trim(input), "\n")
    edges = Enum.map(connections, &get_edge/1)
    Graph.add_edges(g, edges)
  end

  def num_gamesets(g, start_char) do
    cliques = Graph.cliques(g)
      |> Enum.filter(fn c -> length(c) >= 3 end)

    games_in_maximal_clique = cliques
      |> Enum.filter( fn c-> length(c) > 3 end)
      |> Enum.flat_map(fn c -> Formulae.combinations(c, 3) end)

    games = Enum.concat(Enum.filter(cliques, fn c-> length(c) == 3 end), games_in_maximal_clique)
      |> Enum.filter(fn g -> Enum.any?(g, fn p -> String.starts_with?(p, start_char) end) end)
      |> Enum.map(&Enum.sort(&1))
      |> Enum.sort
      |> Enum.dedup
    length(games)
  end

  def get_password(_g) do
    ""
  end

end
