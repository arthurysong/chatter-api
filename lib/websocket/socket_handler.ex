defmodule Websocket.SocketHandler do
  @behaviour :cowboy_websocket

  def init(request, _state) do
    state = %{registry_key: request.path}
    # IO.puts("request.path" <> request.path)
    # IO.inspect state
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    # IO.puts("when do i get called...")

    Registry.MyWebsocketApp
    |> Registry.register(state.registry_key, {})

    # Registry.MyWebsocketApp
    # |> Registry.lookup(state.registry_key)
    # |> IO.inspect()

    {:ok, state}
  end
  def websocket_handle({:text, json}, state) do
    IO.inspect state
    payload = Poison.decode!(json)
    message = payload["data"]["message"]
    IO.puts("message" <> message)

    pub_map = %{
      registry_key: state.registry_key,
      sender_pid: :erlang.pid_to_list(self()),
      message: message
    }

    GenServer.cast(:amqp, {:publish, pub_map})

    {:reply, {:text, message}, state}
  end


  def websocket_info(info, state) do
    # this is a callback that gets called when information is sent to the process...
    {:reply, {:text, info}, state}
  end
end
