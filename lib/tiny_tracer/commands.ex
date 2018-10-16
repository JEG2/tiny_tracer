defmodule TinyTracer.Commands do
  defmodule Halt do
    defstruct ~w[]a

    def new, do: %__MODULE__{ }
  end

  defmodule SMove do
    defstruct ~w[lld]a

    def new(lld), do: %__MODULE__{lld: lld}
  end

  defmodule Fill do
    defstruct ~w[nd]a

    def new(nd), do: %__MODULE__{nd: nd}
  end

  defmodule Void do
    defstruct ~w[nd]a

    def new(nd), do: %__MODULE__{nd: nd}
  end
end
