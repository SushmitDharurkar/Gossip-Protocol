defmodule Server do
    use GenServer

    def init(rumour) do
        {:ok, %{"rumour" => rumour, "count" => 0, "neighbors" => []}}
    end

    def handle_cast({:receive_message, rumour}, state) do
        {:ok, count} = Map.fetch(state, "count")
        state = Map.put(state, "count", count + 1)

        {:ok, existing_rumour} = Map.fetch(state, "rumour")
        
        if(existing_rumour != "") do
            {:noreply, state}
        else
            [{_, spread}] = :ets.lookup(:count, "spread")
            :ets.insert(:count, {"spread", spread + 1})
            {:noreply, Map.put(state, "rumour", rumour)}
        end
    end

    def handle_cast({:send_message}, state) do
        {:ok, rumour} = Map.fetch(state, "rumour")
        {:ok, neighbors} = Map.fetch(state, "neighbors")
        
        if (rumour != "" && length(neighbors) > 0) do
            _ = GenServer.cast(Enum.random(neighbors), {:receive_message, rumour})
        end
        {:noreply, state}
    end

    def handle_cast({:remove_neighbor, neighbor}, state) do
        {:ok, neighbors} = Map.fetch(state, "neighbors")
        {:noreply, Map.put(state, "neighbors", neighbors)}
    end

    def handle_cast({:set_neighbors, neighbors}, state) do
        {:noreply, Map.put(state, "neighbors", neighbors)}
    end

    def handle_call({:get_count, count}, _from, state) do
        {:reply, Map.fetch(state, count), state}
    end

    def handle_call({:get_rumour, rumour}, _from, state) do
        {:reply, Map.fetch(state, rumour), state}
    end
end
