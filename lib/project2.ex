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
  def main(args \\ []) do

    {_, input, _} = OptionParser.parse(args)
    IO.inspect input

    if length(input) == 3 do
      numNodes = String.to_integer(List.first(input))

      if numNodes > 1 do

        algorithm = List.last(input)
        {topology, _} = List.pop_at(input, 1)
  
        case topology do
          
          "full" -> 
                IO.puts "Using full topology"
          "2D" ->
                IO.puts "Using 2D topology"
          "line" -> 
                  IO.puts "Using full topology"
          "imp2D" ->
                  IO.puts "Using imp2D topology"              
           _ ->
             IO.puts "Invalid topology"   
             IO.puts "Enter full/2D/line/imp2D"
        end
  
        case algorithm do
          
          "gossip" -> 
                IO.puts "Using Gossip algorithm"
                actors = start_gossip_actors(numNodes)
                IO.inspect actors
                Enum.each(actors, fn x -> spawn(Client, :receive_main, [x]) end)
                init_gossip(actors)
                print_rumour(actors)
  
          "push-sum" ->
                IO.puts "Using push-sum algorithm"
           _ ->
             IO.puts "Invalid algorithm"   
             IO.puts "Enter gossip or push-sum"
        end
      end

    else
      IO.puts "Invalid input. Number of arguments should be 3"
      IO.puts "Example: ./project2 30 3D gossip"
    end
  end

  def start_gossip_actors(numNodes) do

    actors = Enum.map(2..numNodes, fn _ -> {:ok, actor} = Client.start_link("")
                                           actor  end)
    {:ok, actor} = Client.start_link("This is rumour")                                    
    [actor] ++ actors
  end

  def init_gossip(actors) do
    Enum.each(actors, fn x -> IO.inspect Client.send_message(x, List.delete(actors, x)) end)
    :timer.sleep(1000)
    actors = checkActorsAlive(actors)
    
    if (length(actors) > 1) do
      init_gossip(actors)
    end
  end

  def checkActorsAlive(actors) do
    # IO.puts "In checkActorsAlive"
    current_actors = Enum.map(actors, fn x -> if(Process.alive?(x) && Client.get_count(x) < 2) do x end end) 
    List.delete(Enum.uniq(current_actors), nil)
  end

  def print_rumour(actors) do
     Enum.each(actors, fn x -> IO.puts Client.get_rumour(x) end)
  end
end
