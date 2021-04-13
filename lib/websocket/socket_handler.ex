defmodule Websocket.SocketHandler do
  @behaviour :cowboy_websocket

  def init(request, _state) do
    state = %{registry_key: request.path}
    resp = HTTPoison.get! "https://httpbin.org/ip"
    body = Poison.decode!(resp.body);
    state = Map.put(state, :machine_ip, body["origin"])
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
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
    data = payload["data"]
    # user = data["user"]
    # message = payload["data"]["message"]
    # IO.puts("message" <> message)
    # IO.inspect data
    data = Map.put(data, :machine_ip, state.machine_ip)

    encode = Poison.encode!(data)

    pub_map = %{
      registry_key: state.registry_key,
      sender_pid: :erlang.pid_to_list(self()),

      message: encode
    }

    GenServer.cast(:amqp, {:publish, pub_map})
    {:reply, {:text, encode}, state}
  end


  def websocket_info(info, state) do
    # this is a callback that gets called when information is sent to the process...
    {:reply, {:text, info}, state}
  end
end
