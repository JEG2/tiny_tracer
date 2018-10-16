defmodule TinyTracer.Trace do
  alias TinyTracer.{Bot, Coord, DependencyMapping, Pathfinder}
  alias TinyTracer.Commands.{Fill, Halt, SMove, Void}

  defstruct bots: [Bot.new], commands: [ ]

  def from_dependency_mapping(mapping) do
    build_each_layer(%__MODULE__{ }, mapping)
  end

  def reverse(trace) do
    new_commands =
      trace.commands
      |> Enum.reverse
      |> Enum.drop(1)
      |> Enum.map(fn
        %SMove{lld: {dx, dy, dz}} -> SMove.new({-dx, -dy, -dz})
        %Void{nd: dx_dy_dz} -> Fill.new(dx_dy_dz)
      end)
      |> Kernel.++([Halt.new])
    %__MODULE__{trace | commands: new_commands}
  end

  def combine(disassembly_trace, assembly_trace) do
    new_commands =
      disassembly_trace.commands
      |> Enum.take(length(disassembly_trace.commands) - 1)
      |> Kernel.++(assembly_trace.commands)
    %__MODULE__{disassembly_trace | commands: new_commands}
  end

  defp build_each_layer(trace, mapping) do
    if DependencyMapping.empty?(mapping) do
      finish_trace(trace, mapping)
    else
      {new_trace, new_mapping} =
        build_layer(trace, mapping, DependencyMapping.current_layer(mapping))
      build_each_layer(new_trace, new_mapping)
    end
  end

  defp build_layer(trace, mapping, layer) do
    if MapSet.size(layer) == 0 do
      {trace, mapping}
    else
      voxel = Coord.closest(trace.bots |> hd |> Map.fetch!(:pos), layer)
      {new_trace, new_mapping} = remove_voxel(trace, mapping, layer, voxel)
      build_layer(new_trace, new_mapping, MapSet.delete(layer, voxel))
    end
  end

  defp remove_voxel(trace, mapping, layer, voxel) do
    bot = hd(trace.bots)
    path = find_best_path(bot.pos, mapping, layer, voxel)
    new_commands = add_on_moves(trace.commands, path)
    new_bot = if path == [ ], do: bot, else: Bot.move_to(bot, List.last(path))
    {
      %__MODULE__{
        trace |
        bots: [new_bot],
        commands: [Void.new(Coord.to_d(new_bot.pos, voxel)) | new_commands]
      },
      DependencyMapping.remove(mapping, voxel)
    }
  end

  def find_best_path(from, mapping, layer, voxel) do
    if voxel in Coord.near(from, mapping.resolution) do
      [ ]
    else
      voxel
      |> Coord.near(mapping.resolution)
      |> Enum.reject(fn xyz -> MapSet.member?(mapping.filled, xyz) end)
      |> Enum.map(fn to -> Pathfinder.path(from, to, mapping) end)
      |> Enum.reject(fn path -> is_nil(path) end)
      |> Enum.sort_by(fn path ->
        path
        |> List.last
        |> Coord.near(mapping.resolution)
        |> Enum.count(fn xyz -> MapSet.member?(layer, xyz) end)
        |> Kernel.-
      end)
      |> hd
    end
  end

  defp add_on_moves(commands, [ ]), do: commands
  defp add_on_moves(commands, path) do
    path
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce(commands, fn [from, to], c ->
      [SMove.new(Coord.to_d(from, to)) | c]
    end)
  end

  defp finish_trace(trace, mapping) do
    bot = hd(trace.bots)
    path = Pathfinder.path(bot.pos, {0, 0, 0}, mapping)
    final_commands = [Halt.new | add_on_moves(trace.commands, path)]
    %__MODULE__{trace | commands: Enum.reverse(final_commands)}
  end
end
