defmodule Websocket.SocketHandler do
  @behaviour :cowboy_websocket
  use AMQP

  @exchange "websocket_test_exchange"
  @queue "websocket_test_queue"
  @queue_error "#{@queue}_error"

  def init(request, _state) do
    state = %{registry_key: request.path}
    IO.puts("request.path" <> request.path)
    IO.inspect state

    {:ok, conn} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(conn)

    setup_queue(channel)
    {:ok, _consumer_tag} = Basic.consume(channel, @queue)

    state = Map.put(state, :channel, channel);

    # AMQP.Basic.consume(state.channel, "messages", nil, no_ack: true)
    # defmodule Receive do
    #   def wait_for_messages do
    #     receive do
    #       {:basic_deliver, payload, _meta} ->
    #         IO.puts " [x] Received #{payload}"
    #         wait_for_messages()
    #     end
    #   end
    # end

    # Receive.wait_for_messages()
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    # IO.puts("state" <> state);
    # IO.puts(state);

    # AMQP.Basic.consume(state.channel, "messages", nil, no_ack: true)
    # defmodule Receive do
    #   def wait_for_messages do
    #     receive do
    #       {:basic_deliver, payload, _meta} ->
    #         IO.puts " [x] Received #{payload}"
    #         wait_for_messages()
    #     end
    #   end
    # end

    receive do
      {:basic_deliver, payload, _meta} ->
        IO.puts " [x] Received #{payload}"
        # wait_for_messages()
    end

    # Receive.wait_for_messages()
    IO.puts("when do i get called...")

    Registry.MyWebsocketApp
    |> Registry.register(state.registry_key, {})

    Registry.MyWebsocketApp
    |> Registry.lookup(state.registry_key)
    |> IO.inspect()

    {:ok, state}
  end

  # def handle_info({:basic_deliver, payload, %{delivery_tag: _tag, redelivered: _redelivered}}, chan) do
  #   # You might want to run payload consumption in separate Tasks in production
  #   IO.puts("payload" <> payload)
  #   # consume(chan, tag, redelivered, payload)
  #   {:noreply, chan}
  # end

  def websocket_handle({:text, json}, state) do
    # IO.puts("json" <> json);
    # IO.puts(:text);
    # IO.puts("hello?")
    # IO.puts("state" <> state);
    IO.inspect state
    # IO.puts("hi");
    payload = Poison.decode!(json)
    message = payload["data"]["message"]
    IO.puts("message" <> message)
    # this is all that should be here...?
    AMQP.Basic.publish(state.channel, @exchange, "", message);



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

  def setup_queue(chan) do
    AMQP.Exchange.declare(chan, @exchange, :fanout)

    {:ok, _} = Queue.declare(chan, @queue)
    :ok = Queue.bind(chan, @queue, @exchange)
  end
end
