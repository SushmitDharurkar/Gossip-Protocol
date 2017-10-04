defmodule Server do
    use GenServer

    def init(rumour) do
        {:ok, %{"rumour" => rumour, "count" => 0, "neighbors" => [], "neighbors_backup" => [],"inactive" => false}}
    end

    def handle_cast({:receive_message, rumour, sender}, state) do
        {:ok, count} = Map.fetch(state, "count")
        state = Map.put(state, "count", count + 1)

        if (count > 10) do
           _ = GenServer.cast(sender, {:remove_neighbor, self()})
           {:noreply, state}
        else
            {:ok, existing_rumour} = Map.fetch(state, "rumour")
            
            if(existing_rumour != "") do
                {:noreply, state}
            else
                [{_, spread}] = :ets.lookup(:count, "spread")
                :ets.insert(:count, {"spread", spread + 1})
                {:noreply, Map.put(state, "rumour", rumour)}
            end
        end
    end

    def handle_cast({:send_message}, state) do
        {:ok, rumour} = Map.fetch(state, "rumour")
        {:ok, neighbors} = Map.fetch(state, "neighbors")
                
        if (rumour != "" ) do   
            # Filter out the neighbors which are failed
            [{_, failed}] = :ets.lookup(:count, "failed")
            {_, original_neighbors} = Map.fetch(state, "neighbors_backup")
            neighbors = Enum.filter(original_neighbors, fn x -> !MapSet.member?(failed, x) end) 

            if length(neighbors) > 0 do
                _ = GenServer.cast(Enum.random(neighbors), {:receive_message, rumour, self()})
            end
        end

        state = Map.put(state, "neighbors", neighbors)
        {:noreply, state}
    end

    def handle_cast({:set_neighbors, neighbors}, state) do
        state = Map.put(state, "neighbors_backup", neighbors)
        {:noreply, Map.put(state, "neighbors", neighbors)}
    end

    def handle_call({:get_count, count}, _from, state) do
        {:reply, Map.fetch(state, count), state}
    end

    def handle_call({:get_rumour, rumour}, _from, state) do
        {:reply, Map.fetch(state, rumour), state}
    end

    def handle_call({:get_inactive_status}, _from, state) do
        {:ok, is_inactive} = Map.fetch(state, "inactive")
        IO.puts "Is inactive status? " <> to_string(is_inactive) 
        {:reply, is_inactive, state}
    end

    def handle_call({:get_neighbors}, _from, state) do
        {:reply, Map.fetch(state, "neighbors"), state}
    end

    def handle_call({:make_inactive}, _from, state) do
        {:reply, Map.put(state, "inactive", true), state}
    end

    def handle_cast({:remove_neighbor, neighbor},  state) do
        # IO.inspect neighbor, label: "Removing neighbor"
        {:ok, neighbors} = Map.fetch(state, "neighbors")
        updated_neighbors = List.delete(neighbors, neighbor)
        state = Map.put(state, "neighbors_backup", updated_neighbors)
        {:noreply, Map.put(state, "neighbors", updated_neighbors)}
    end
end
