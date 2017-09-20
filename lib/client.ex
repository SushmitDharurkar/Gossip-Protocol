defmodule Client do
    use GenServer

    def start_link(rumour) do
        GenServer.start_link(Server, rumour)
    end

    def send_message(server, actors) do
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

    def receive_main(server) do
        receive do
            msg -> 
                receive_message(server, msg)
        end
        receive_main(server)
    end
end