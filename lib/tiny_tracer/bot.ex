defmodule TinyTracer.Bot do
  defstruct ~w[pos]a

  def new(pos \\ {0, 0, 0}), do: %__MODULE__{pos: pos}

  def move_to(bot, xyz), do: %__MODULE__{bot | pos: xyz}
end
