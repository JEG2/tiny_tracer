defmodule TinyTracer.DependencyMapping do
  alias TinyTracer.Coord

  defstruct ~w[resolution filled layers]a

  def from_model(model) do
    %__MODULE__{
      resolution: model.resolution,
      filled: model.matrix,
      layers: build_layers(model.matrix, [ ], model.resolution)
    }
  end

  defp build_layers([ ], layers, _resolution), do: layers
  defp build_layers(voxels, [ ], resolution) do
    {layer, new_voxels} = Enum.split_with(voxels, fn {_x, y, _z} -> y == 0 end)
    build_layers(new_voxels, [MapSet.new(layer)], resolution)
  end
  defp build_layers(voxels, [last_layer | _other_layers] = layers, resolution) do
    grounded =
      last_layer
      |> Enum.flat_map(fn voxel -> Coord.adjacent(voxel, resolution) end)
      |> MapSet.new
    {layer, new_voxels} = Enum.split_with(voxels, fn voxel ->
      MapSet.member?(grounded, voxel)
    end)
    build_layers(new_voxels, [MapSet.new(layer) | layers], resolution)
  end

  def empty?(%__MODULE__{layers: layers}), do: layers == [ ]

  def current_layer(%__MODULE__{layers: layers}), do: List.first(layers)

  def remove(
    %__MODULE__{filled: filled, layers: [current | rest]} = mapping,
    xyz
  ) do
    new_layers =
      if current == MapSet.new([xyz]) do
        rest
      else
        [MapSet.delete(current, xyz) | rest]
      end
    %__MODULE__{
      mapping |
      filled: MapSet.delete(filled, xyz),
      layers: new_layers
    }
  end
end
