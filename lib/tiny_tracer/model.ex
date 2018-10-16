defmodule TinyTracer.Model do
  defstruct ~w[resolution matrix]a

  def from_file(path) do
    path
    |> File.stream!(~w[read]a, 1)
    |> parse_model
  end

  defp parse_model(stream) do
    [<<r::integer>>] = Enum.take(stream, 1)
    matrix =
      stream
      |> Stream.drop(1)
      |> Stream.flat_map(fn <<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1>> ->
        [h, g, f, e, d, c, b, a]
      end)
      |> Stream.with_index
      |> Stream.filter(fn {voxel, _i} -> voxel == 1 end)
      |> Stream.map(fn {_voxel, i} ->
        without_x = rem(i, r * r)
        {div(i, r * r), div(without_x, r), rem(without_x, r)}
      end)
      |> MapSet.new
    %__MODULE__{resolution: r, matrix: matrix}
  end
end
