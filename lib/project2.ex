defmodule Project2 do
  @moduledoc """
  Documentation for Project2.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Project2.hello
      :world

  """
  def hello do
    :world
  end


  def main(args \\ []) do

    {_, input, _} = OptionParser.parse(args)

    IO.inspect input
    
  end
end
