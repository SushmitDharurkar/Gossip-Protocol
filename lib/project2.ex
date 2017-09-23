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
  
        case algorithm do
          
          "gossip" -> 
                IO.puts "Using Gossip algorithm"
                actors = init_actors(numNodes)
                IO.inspect actors
                Enum.each(actors, fn x -> spawn(Client, :receive_main, [x]) end)
                init_gossip(actors, topology)
                print_rumour_count(actors)
  
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

  def init_actors(numNodes) do

    middleNode = trunc(numNodes/2)
    Enum.map(1..numNodes, fn x ->  case x do
                                      middleNode -> {:ok, actor} = Client.start_link("This is rumour")
                                      true -> {:ok, actor} = Client.start_link("")
                                   end 
                                   actor end)
  end

  def init_gossip(actors, topology) do

    # :ets.new(:topology, [:set, :public, :named_table])
    case topology do
      "full" -> 
            IO.puts "Using full topology"
            init_gossip_full(actors)
      "2D" ->
            IO.puts "Using 2D topology"
            init_gossip_2d(actors)
      "line" -> 
              IO.puts "Using line topology"
              neighbors = get_neighbors(actors)  # Gives map of host, neighbors 
              # IO.inspect neighbors
              init_gossip_line(actors, neighbors)
      "imp2D" ->
              IO.puts "Using imp2D topology"   
              init_gossip_imp2d(actors)           
       _ ->
         IO.puts "Invalid topology"   
         IO.puts "Enter full/2D/line/imp2D"
    end

  end

  def init_gossip_2d(actors) do
    
  end

  def init_gossip_line(actors, neighbors) do
    # Connect actors in a line and start sending
  
    for  {k, v}  <-  neighbors  do
      Client.send_message(k, v)
    end
  
    # :timer.sleep(1000)
    actors = checkActorsAlive(actors) 
    
    if (length(actors) > 1) do
      # IO.inspect actors, label:  "Actors "
      neighbors = Enum.filter(neighbors, fn ({k,_}) -> Enum.member?(actors, k) end) 
      init_gossip_line(actors, neighbors)
    end
  end

  def init_gossip_imp2d(actors) do
  end

  def init_gossip_full(actors) do
    Enum.each(actors, fn x -> Client.send_message(x, List.delete(actors, x)) end)
    # :timer.sleep(1000)
    actors = checkActorsAlive(actors)
    
    if (length(actors) > 1) do
      init_gossip_full(actors)
    end
  end

  def checkActorsAlive(actors) do
    current_actors = Enum.map(actors, fn x -> if(Process.alive?(x) && Client.get_count(x) < 10) do x end end) 
    List.delete(Enum.uniq(current_actors), nil)
  end

  def get_neighbors(actors) do
     # actors_with_index = %{pid1 => 0, pid2 => 1, pid3 => 2}
    actors_with_index = Stream.with_index(actors, 0) |> Enum.reduce(%{}, fn({v,k}, acc) -> Map.put(acc, v, k) end)
     
    first = Enum.at(actors,0)
    lastIndex = length(actors) - 1
    last = Enum.at(actors, lastIndex)
    Enum.reduce(actors, %{}, fn (x, acc) -> {:ok, currentIndex} = Map.fetch(actors_with_index, x)
                                          cond do
                                            x == first -> Map.put(acc, x, [Enum.at(actors, 1)])
                                            x == last -> Map.put(acc, x, [Enum.at(actors, lastIndex - 1)])
                                            true -> Map.put(acc, x, [Enum.at(actors, currentIndex - 1), Enum.at(actors, currentIndex + 1)])
                                          end end)  

  end

  def print_rumour_count(actors) do
     Enum.each(actors, fn x -> IO.inspect x 
                               IO.puts to_string(Client.get_rumour(x)) <> " Count: " <>to_string(Client.get_count(x)) 
                              end)
  end

end
