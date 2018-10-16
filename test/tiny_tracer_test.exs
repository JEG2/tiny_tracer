defmodule TinyTracerTest do
  use ExUnit.Case
  doctest TinyTracer

  test "greets the world" do
    assert TinyTracer.hello() == :world
  end
end
