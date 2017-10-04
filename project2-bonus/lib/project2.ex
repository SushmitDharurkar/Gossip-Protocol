defmodule Project2 do

  def main(args \\ []) do

    {_, input, _} = OptionParser.parse(args)
    numNodes = 0

    if length(input) == 4 do

      numNodes = String.to_integer(List.first(input))      

      if numNodes > 1 do

        failNodes = trunc(String.to_integer(List.last(input)) * numNodes * 0.01)
        input = List.delete_at(input, 3)
        algorithm = List.last(input)
        {topology, _} = List.pop_at(input, 1)
  
        case algorithm do
          
          "gossip" -> 
                IO.puts "Using Gossip algorithm"
                actors = init_actors(numNodes)
                init_gossip(actors, topology, numNodes, failNodes)
  
          "push-sum" ->
                IO.puts "Using push-sum algorithm"
           _ ->
             IO.puts "Invalid algorithm"   
             IO.puts "Enter gossip or push-sum"
        end
      end

    else
      IO.puts "Invalid input. Number of arguments should be 3"
      IO.puts "Example: ./project2 30 2D gossip"
    end
  end

  def init_actors(numNodes) do
    middleNode = trunc(numNodes/2)
    Enum.map(1..numNodes, fn x -> cond  do
                                      x == middleNode -> {:ok, actor} = Client.start_link("This is rumour")
                                      true -> {:ok, actor} = Client.start_link("")
                                   end 
                                   actor end)
  end

  def init_gossip(actors, topology, numNodes, failNodes) do

    :ets.new(:count, [:set, :public, :named_table])
    :ets.insert(:count, {"spread", 0})
    :ets.insert(:count, {"timeout", false})
    :ets.insert(:count, {"failed", MapSet.new([])})
    neighbors = %{}

    case topology do
      "full" -> 
            IO.puts "Using full topology"
            neighbors = get_full_neighbors(actors)
      "2D" ->
            IO.puts "Using 2D topology"
            neighbors = get_2d_neighbors(actors, topology)
      "line" -> 
            IO.puts "Using line topology"
            neighbors = get_line_neighbors(actors)  # Gives map of host, neighbors 
      "imp2D" ->
            IO.puts "Using imp2D topology"  
            neighbors = get_2d_neighbors(actors, topology)      
       _ ->
            IO.puts "Invalid topology"   
            IO.puts "Enter full/2D/line/imp2D"
    end

    set_neighbors(neighbors)
    # prev = System.monotonic_time(:milliseconds)

    remove_some_actors(actors, failNodes)
    spawn(__MODULE__, :set_timer, [])
    gossip(actors, neighbors, numNodes, failNodes)

    # IO.puts "Time required " <> to_string(System.monotonic_time(:milliseconds) - prev) <> " ms"
    [{_, failures}] = :ets.lookup(:count, "failed")
    IO.puts "Failed Nodes: " <> to_string(MapSet.size(failures))
  end

  def gossip(actors, neighbors, numNodes, failNodes) do

    [{_, timeout}] = :ets.lookup(:count, "timeout")
    # IO.puts "timeout is " <> to_string(timeout)
    
    if(timeout) do
      [{_, spread}] = :ets.lookup(:count, "spread")
      IO.inspect "Spread is " <> to_string(spread * 100/numNodes) <> " %"
    else
      for  {k, _}  <-  neighbors  do
        Client.send_message(k)
      end
  
      actors = check_actors_alive(actors)  
  
      if (length(actors) > 1 ) do
        neighbors = Enum.filter(neighbors, fn {k,_} -> Enum.member?(actors, k) end) 
        gossip(actors, neighbors, numNodes, failNodes) 
      else
        [{_, spread}] = :ets.lookup(:count, "spread")
        IO.inspect "Spread is " <> to_string(spread * 100/numNodes) <> " %"
      end
    end
  end

  def check_actors_alive(actors) do
    current_actors = Enum.map(actors, fn x -> if (Process.alive?(x) && Client.get_count(x) < 10  && Client.has_neighbors(x)) do x end end) 
    List.delete(Enum.uniq(current_actors), nil)
  end

  def get_full_neighbors(actors) do
    Enum.reduce(actors, %{}, fn (x, acc) ->  Map.put(acc, x, Enum.filter(actors, fn y -> y != x end)) end)  
  end

  def get_line_neighbors(actors) do
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

  def get_2d_neighbors(actors, topology) do

    actors_with_index = Stream.with_index(actors, 0) |> Enum.reduce(%{}, fn({v,k}, acc) -> Map.put(acc, k, v) end)
    numNodes = length(actors)
    xMax = trunc(:math.ceil(:math.sqrt(numNodes)))
    yMax = xMax

    yMulti = yMax
    xLimit = xMax - 1
    yLimit = yMax - 1

    final_neighbors = Enum.reduce(0..yLimit, %{}, fn(y, neighbors) ->
                          Enum.reduce(0..xLimit, neighbors, fn (x, neighbors) ->
                                                              i = y * yMulti + x
                                                              if (i < numNodes) do
                                                                adjacents = []
                                                                if (x > 0) do adjacents = Enum.into([i - 1], adjacents) end
                                                                if (x < xLimit && (i + 1) < numNodes) do adjacents = Enum.into([i+1], adjacents) end
                                                                if (y > 0) do adjacents = Enum.into([i - yMulti], adjacents) end
                                                                if (y < yLimit && (i + yMulti) < numNodes) do adjacents = Enum.into([i + yMulti], adjacents) end
                                                                {:ok, actor} = Map.fetch(actors_with_index, i)

                                                                # Add random neighbor
                                                                case topology do
                                                                  "imp2D" -> adjacents = Enum.into(get_random_node_imp2D(adjacents, numNodes), adjacents) # :rand.uniform(n) gives random number: 1 <= x <= n
                                                                  _ ->
                                                                end

                                                                neighbor_pids = Enum.map(adjacents, fn x -> 
                                                                                                      {:ok, n} = Map.fetch(actors_with_index, x)
                                                                                                      n end)
                                                                Map.put(neighbors, actor, neighbor_pids) 
                                                              else
                                                                Map.put(neighbors, "dummy", "dummy")
                                                              end 
                                                            end) 
                                                          end)
    Map.delete(final_neighbors, "dummy")
  end

  def set_neighbors(neighbors) do
    for  {k, v}  <-  neighbors  do
      Client.set_neighbors(k, v)
    end
  end

  def get_random_node_imp2D(neighbors, numNodes) do
    random_node_index =  :rand.uniform(numNodes) - 1
    if(Enum.member?(neighbors, random_node_index)) do
      get_random_node_imp2D(neighbors, numNodes)
    end
    [random_node_index]
  end

  def print_rumour_count(actors) do
     Enum.each(actors, fn x -> IO.inspect x 
                               IO.puts to_string(Client.get_rumour(x)) <> " Count: " <>to_string(Client.get_count(x)) 
                              end)
  end

  def set_timer() do
    :timer.sleep(5000)
    :ets.insert(:count, {"timeout", true})
  end

  def remove_some_actors(actors, noofFailNodes) do 

    Enum.each(Enum.take_random(actors, noofFailNodes), fn x -> [{_ , failed}] = :ets.lookup(:count, "failed")
                                                      :ets.insert(:count, {"failed", MapSet.put(failed, x)} ) end)
    """  
    # Start some actors which will improve the spread                                                
    :timer.sleep(1000)
    start_some_nodes = trunc(noofFailNodes * 0.9)

    [{_ , failed_nodes}] = :ets.lookup(:count, "failed")
    Enum.each(Enum.take_random(MapSet.to_list(failed_nodes), start_some_nodes), fn x ->  [{_ , failed}] = :ets.lookup(:count, "failed") 
                                                                            :ets.insert(:count, {"failed", MapSet.delete(failed, x)} ) end)
    [{ _, failed}] = :ets.lookup(:count, "failed")     
    # IO.inspect  "Failed nodes " <> to_string(length(MapSet.to_list(failed))) 
    """                                            
  end

end
