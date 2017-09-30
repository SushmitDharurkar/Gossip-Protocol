defmodule Project2 do

  def main(args \\ []) do

    {_, input, _} = OptionParser.parse(args)
    IO.inspect input
    numNodes = 0

    if length(input) == 3 do

      numNodes = String.to_integer(List.first(input))      

      if numNodes > 1 do

        algorithm = List.last(input)
        {topology, _} = List.pop_at(input, 1)
  
        case algorithm do
          
          "gossip" -> 
                IO.puts "Using Gossip algorithm"
                actors = init_actors(numNodes)
                init_gossip(actors, topology, numNodes)
  
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
                                      _ -> {:ok, actor} = Client.start_link("")
                                   end 
                                   actor end)
  end

  def init_gossip(actors, topology, numNodes) do

    :ets.new(:count, [:set, :public, :named_table])
    :ets.insert(:count, {"spread", 0})
    
    case topology do
      "full" -> 
            IO.puts "Using full topology"
            prev = System.monotonic_time(:milliseconds)
            IO.inspect init_gossip_full(actors, numNodes), label: "Rumour reached to"
      "2D" ->
            IO.puts "Using 2D topology"
            neighbors = get_2d_neighbors(actors, topology)
            prev = System.monotonic_time(:milliseconds)
            IO.inspect init_gossip_2d(actors, neighbors, numNodes), label: "Rumour reached to"
      "line" -> 
              IO.puts "Using line topology"
              neighbors = get_line_neighbors(actors)  # Gives map of host, neighbors 
              prev = System.monotonic_time(:milliseconds)
              IO.inspect init_gossip_line(actors, neighbors, numNodes), label: "Rumour reached to"
              
      "imp2D" ->
              IO.puts "Using imp2D topology"  
              neighbors = get_2d_neighbors(actors, topology) 
              IO.inspect neighbors
              prev = System.monotonic_time(:milliseconds)
              init_gossip_imp2d(actors)           
       _ ->
         IO.puts "Invalid topology"   
         IO.puts "Enter full/2D/line/imp2D"
    end
    IO.puts "Time required " <> to_string(System.monotonic_time(:milliseconds) - prev) <> " ms"
  end

  def init_gossip_2d(actors, neighbors, numNodes) do
    init_gossip_line(actors, neighbors, numNodes)
  end

  def init_gossip_line(actors, neighbors, numNodes) do

    for  {k, v}  <-  neighbors  do
      Client.send_message(k, v)
    end

    actors = check_actors_alive(actors)  
    [{_, spread}] = :ets.lookup(:count, "spread")
    
    if ((spread/numNodes) < 0.9) do
      neighbors = Enum.filter(neighbors, fn ({k,_}) -> Enum.member?(actors, k) end) 
      spread = init_gossip_line(actors, neighbors, numNodes)
    end
    spread
  end

  def init_gossip_imp2d(actors) do
  end

  def init_gossip_full(actors ,numNodes) do
    Enum.each(actors, fn x -> Client.send_message(x, Enum.filter(actors, fn y -> y!=x end)) end)
    actors = check_actors_alive(actors)
    
    [{_, spread}] = :ets.lookup(:count, "spread")

    if ((spread/numNodes) < 0.9) do
      spread = init_gossip_full(actors, numNodes)
    end
    spread
  end

  def check_actors_alive(actors) do
    current_actors = Enum.map(actors, fn x -> if(Process.alive?(x) && Client.get_count(x) < 10) do x end end) 
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
    neighbors = %{}
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

                                                                case topology do
                                                                  "imp2D" -> adjacents = Enum.into([:rand.uniform(numNodes) - 1], adjacents) # :rand.uniform(n) gives random number: 1 <= x <= n
                                                                  _ ->
                                                                end
                                                                # Add random neighbor

                                                                neighbor_pids = Enum.map(adjacents, fn x -> 
                                                                                                      {:ok, n} = Map.fetch(actors_with_index, x)
                                                                                                      n end)
                                                                Map.put(neighbors, actor, neighbor_pids) 
                                                              else
                                                                Map.put(neighbors, "dummy", "dummy")
                                                              end end) end)
    Map.delete(final_neighbors, "dummy")
  end

  def print_rumour_count(actors) do
     Enum.each(actors, fn x -> IO.inspect x 
                               IO.puts to_string(Client.get_rumour(x)) <> " Count: " <>to_string(Client.get_count(x)) 
                              end)
  end
end
