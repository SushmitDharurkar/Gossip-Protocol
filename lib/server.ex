defmodule Server do
    use GenServer

    def init(rumour) do
        {:ok, %{"rumour" => rumour, "count" => 0}}
    end

    def handle_cast({:receive_message, rumour}, state) do
        {:ok, count} = Map.fetch(state, "count")
        state = Map.put(state, "count", count + 1)

        if(rumour != "" && Map.fetch(state, "rumour") == rumour) do
            {:noreply, state}
        else
            [{_, spread}] = :ets.lookup(:count, "spread")
            :ets.insert(:count, {"spread", spread + 1})
            {:noreply, Map.put(state, "rumour", rumour)}
        end
    end

    def handle_cast({:send_message, actors}, state) do
        {:ok, rumour} = Map.fetch(state, "rumour")
        if (rumour != "") do
            _ = GenServer.cast(Enum.random(actors), {:receive_message, rumour})
        end
        {:noreply, state}
    end

    def handle_call({:get_count, count}, _from, state) do
        {:reply, Map.fetch(state, count), state}
    end

    def handle_call({:get_rumour, rumour}, _from, state) do
        {:reply, Map.fetch(state, rumour), state}
    end
end
