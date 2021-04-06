defmodule Websocket.SocketHandler do
  @behaviour :cowboy_websocket

  def init(request, _state) do
    state = %{registry_key: request.path}
    IO.puts("request.path" <> request.path)

    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    # IO.puts("state" <> state);
    # IO.puts(state);
    IO.inspect state
    Registry.MyWebsocketApp
    |> Registry.register(state.registry_key, {})

    Registry.MyWebsocketApp
    |> Registry.lookup(state.registry_key)
    |> IO.inspect()

    {:ok, state}
  end

  def websocket_handle({:text, json}, state) do
    # IO.puts("json" <> json);
    # IO.puts(:text);
    # IO.puts("hello?")
    # IO.puts("state" <> state);
    # IO.puts("hi");
    payload = Poison.decode!(json)
    message = payload["data"]["message"]
    IO.puts("message" <> message)

    Registry.MyWebsocketApp
    |> Registry.dispatch(state.registry_key, fn(entries) ->
      # get all processes that have same key
      # e.g. /ws/chat/3
      for {pid, _} <- entries do
        if pid != self() do
          # send the message to the process..
          IO.puts("wtf...")
          Process.send(pid, message, [])
        end
      end
    end)

    {:reply, {:text, message}, state}
  end


  def websocket_info(info, state) do
    # this is a callback that gets called when information is sent to the process...


    IO.puts("hi im websocket info")
    IO.puts("info" <> info);
    IO.inspect(self())
    {:reply, {:text, info}, state}
  end
end
