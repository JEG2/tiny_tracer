defmodule TinyTracer.TraceFile do
  alias TinyTracer.Commands.{Fill, Halt, SMove, Void}

  def path_from_problem(path) do
    trace_file_name =
      path
      |> Path.basename(".mdl")
      |> String.replace(~r{_(?:src|tgt)\z}, "")
      |> Kernel.<>(".nbt")
    traces_directory = "priv/traces"
    Path.join(traces_directory, trace_file_name)
  end

  def write(path, commands) do
    File.open!(path, ~w[write]a, fn device ->
      Enum.each(commands, fn command ->
        encoded = encode_command(command)
        IO.binwrite(device, encoded)
      end)
    end)
  end

  defp encode_command(%Halt{ }), do: <<0b11111111>>
  defp encode_command(%SMove{lld: lld}) do
    {lld_a, lld_i} = ld_to_a_and_i(lld, 15)
    << 0b00::size(2), lld_a::size(2), 0b0100::size(4),
       0b000::size(3), lld_i::size(5) >>
  end
  defp encode_command(%Fill{nd: dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b011::size(3)>>
  end
  defp encode_command(%Void{nd: dx_dy_dz}) do
    nd = dx_dy_dz_to_nd(dx_dy_dz)
    <<nd::size(5), 0b010::size(3)>>
  end

  defp ld_to_a_and_i({x, 0, 0}, offset), do: {0b01, x + offset}
  defp ld_to_a_and_i({0, y, 0}, offset), do: {0b10, y + offset}
  defp ld_to_a_and_i({0, 0, z}, offset), do: {0b11, z + offset}

  defp dx_dy_dz_to_nd({dx, dy, dz}) do
    (dx + 1) * 9 + (dy + 1) * 3 + (dz + 1)
  end
end
