defmodule Client do
    use GenServer

    def start_link(rumour) do
        GenServer.start_link(Server, rumour)
    end

    def send_message(server, actors) do
        # IO.inspect get_rumour(server)
        GenServer.cast(server, {:send_message, actors})
    end

    def receive_message(server, rumour) do
        GenServer.cast(server, {:receive_message, rumour})
    end

    def get_count(server) do
        {:ok, count} = GenServer.call(server, {:get_count, "count"})
        count
    end

    def get_rumour(server) do
        {:ok, rumour} = GenServer.call(server, {:get_rumour, "rumour"})
        rumour
    end
end