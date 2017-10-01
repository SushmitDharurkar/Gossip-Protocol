defmodule GossipSimulatorTest do
  use ExUnit.Case
  doctest GossipSimulator

  test "greets the world" do
    assert GossipSimulator.hello() == :world
  end
end
