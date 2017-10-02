defmodule Client do
    use GenServer

    def start_link(rumour) do
        GenServer.start_link(Server, rumour)
    end

    def send_message(server) do
        GenServer.cast(server, {:send_message})
    end

    def set_neighbors(server, neighbors) do
        GenServer.cast(server, {:set_neighbors, neighbors})
    end

    def get_count(server) do
        {:ok, count} = GenServer.call(server, {:get_count, "count"})
        count
    end

    def get_rumour(server) do
        {:ok, rumour} = GenServer.call(server, {:get_rumour, "rumour"})
        rumour
    end

    def has_neighbors(server) do
        {:ok, neighbors} = GenServer.call(server, {:get_neighbors})
        length(neighbors) > 0
    end
end