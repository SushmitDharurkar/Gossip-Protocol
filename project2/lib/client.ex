defmodule Client do
    use GenServer

    def start_link(x) do
        GenServer.start_link(Server, x)
    end

    def send_message(server) do
        GenServer.cast(server, {:send_message})
    end

    def send_message_push_sum(server) do
        GenServer.cast(server, {:send_message_push_sum})
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

    def get_neighbors(server) do
        GenServer.call(server, {:get_neighbors})
    end

    def get_diff(server) do
        GenServer.call(server, {:get_diff})
    end
end