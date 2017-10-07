defmodule Server do
    use GenServer

    def init(x) do
        if is_list(x) do
            {:ok, %{"s" => List.first(x), "rumour" => List.last(x), "w" => 1, "s_old_2" => 1, "w_old_2" => 1, "diff1" => 1, "diff2" => 1, "neighbors" => []}}
        else
            {:ok, %{"rumour" => x, "count" => 0, "neighbors" => []}}
        end
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

    def handle_cast({:receive_message_push_sum, sender, s, w, rumour}, state) do
        {:ok, s_old} = Map.fetch(state, "s")
        {:ok, w_old} = Map.fetch(state, "w")
        {:ok, s_old_2} = Map.fetch(state, "s_old_2")
        {:ok, w_old_2} = Map.fetch(state, "w_old_2")
        {:ok, existing_rumour} = Map.fetch(state, "rumour")

        s_new = s_old + s
        w_new = w_old + w
       
        if(abs(s_new/w_new - s_old/w_old) < :math.pow(10, -10) && abs(s_old/w_old - s_old_2/w_old_2) < :math.pow(10, -10)) do
          GenServer.cast(sender, {:remove_neighbor, self()})
        else
          if(existing_rumour == "") do
            state = Map.put(state, "rumour", rumour)
            [{_, spread}] = :ets.lookup(:count, "spread")
            :ets.insert(:count, {"spread", spread + 1})
          end
          state = Map.put(state, "s", s_new)
          state = Map.put(state, "w", w_new)
          state = Map.put(state, "s_old_2", s_old)
          state = Map.put(state, "w_old_2", w_old)
          state = Map.put(state, "diff1", s_new/w_new - s_old/w_old)
          state = Map.put(state, "diff2", s_old/w_old - s_old_2/w_old_2)
        end
        {:noreply, state}
    end

    def handle_cast({:send_message}, state) do
        {:ok, rumour} = Map.fetch(state, "rumour")
        {:ok, neighbors} = Map.fetch(state, "neighbors")
        
        if (rumour != "" && length(neighbors) > 0) do    
            _ = GenServer.cast(Enum.random(neighbors), {:receive_message, rumour, self()})
        end
        {:noreply, state}
    end

    def handle_cast({:send_message_push_sum}, state) do
        {:ok, s} = Map.fetch(state, "s")
        {:ok, w} = Map.fetch(state, "w")
        {:ok, rumour} = Map.fetch(state, "rumour")
        {:ok, neighbors} = Map.fetch(state, "neighbors")
        if (rumour != "" && length(neighbors) > 0) do
          s = s/2
          w = w/2
          state = Map.put(state, "s", s)
          state = Map.put(state, "w", w)
          GenServer.cast(Enum.random(neighbors), {:receive_message_push_sum, self(), s, w, rumour})
        end
        {:noreply, state}
    end

    def handle_cast({:remove_neighbor, neighbor}, state) do
        {:ok, neighbors} = Map.fetch(state, "neighbors")
        {:noreply, Map.put(state, "neighbors", List.delete(neighbors, neighbor))}
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

    def handle_call({:get_neighbors}, _from, state) do
        {:reply, Map.fetch(state, "neighbors"), state}
    end

    def handle_call({:get_diff}, _from, state) do
        {:ok, diff1} = Map.fetch(state, "diff1")
        {:ok, diff2} = Map.fetch(state, "diff2")
        {:reply, [diff1] ++ [diff2], state}
    end
end
