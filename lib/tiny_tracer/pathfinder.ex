defmodule TinyTracer.Pathfinder do
  alias TinyTracer.Coord

  def path(to, to, _mapping), do: [to]
  def path(from, to, mapping) do
    {:ok, seen} = Agent.start_link(fn -> MapSet.new([from]) end)
    path = walk_path(mapping, [[from]], MapSet.new, to, seen)
    Agent.stop(seen)
    path
  end

  defp walk_path(_mapping, [ ], _unavailable, _to, _seen), do: nil
  defp walk_path(
    mapping,
    [[current | _voxels] = path | paths],
    unavailable,
    to,
    seen
  ) do
    steps =
      current
      |> moves(mapping, unavailable)
      |> Enum.reject(fn move ->
        Agent.get(seen, fn s -> MapSet.member?(s, move) end)
      end)
    if Enum.member?(steps, to) do
      Enum.reverse([to | path])
    else
      new_paths = Enum.map(steps, fn step -> [step | path] end)
      Agent.update(seen, fn s -> steps |> MapSet.new |> MapSet.union(s) end)
      walk_path(
        mapping,
        paths ++ new_paths,
        MapSet.union(unavailable, MapSet.new(steps)),
        to,
        seen
      )
    end
  end

  defp moves({x, y, z}, mapping, unavailable) do
    [
      {-1, 0, 0},
      {1, 0, 0},
      {0, -1, 0},
      {0, 1, 0},
      {0, 0, -1},
      {0, 0, 1}
    ]
    |> Enum.flat_map(fn {dx, dy, dz} ->
      Enum.reduce_while(1..15, [ ], fn i, voxels ->
        xyz = {x + dx * i, y + dy * i, z + dz * i}
        if Coord.valid?(xyz, mapping.resolution) and
           not MapSet.member?(mapping.filled, xyz) and
           not MapSet.member?(unavailable, xyz) do
          {:cont, [xyz | voxels]}
        else
          {:halt, voxels}
        end
      end)
    end)
  end
end
