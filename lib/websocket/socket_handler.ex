defmodule Websocket.SocketHandler do
  @behaviour :cowboy_websocket
  use AMQP

  @exchange "chatter_test_exchange"
  @queue "chatter_test_queue"
  @queue_error "#{@queue}_error"

  def init(request, _state) do
    state = %{registry_key: request.path}
    IO.puts("request.path" <> request.path)
    IO.inspect state

    # what if this goes in genserver instead?
    # a connection is a tcp connection to interact with RabbitMQ...
    {:ok, conn} = AMQP.Connection.open

    # channels are a lightweight conncetion that share a single TCP connection...
    {:ok, channel} = AMQP.Channel.open(conn)


    setup_queue(channel)
    # {:ok, _consumer_tag} = Basic.consume(channel, @queue)

    state = Map.put(state, :channel, channel);
    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    IO.puts("when do i get called...")

    Registry.MyWebsocketApp
    |> Registry.register(state.registry_key, {})

    Registry.MyWebsocketApp
    |> Registry.lookup(state.registry_key)
    |> IO.inspect()

    {:ok, state}
  end
  def websocket_handle({:text, json}, state) do
    IO.inspect state
    payload = Poison.decode!(json)
    message = payload["data"]["message"]
    IO.puts("message" <> message)

    # {:ok, conn} = AMQP.Connection.open
    # {:ok, channel} = AMQP.Channel.open(conn)

    pub_map = %{
      registry_key: state.registry_key,
      sender_pid: :erlang.pid_to_list(self()),
      message: message
    }

    # what if instead i send pub_map to genserver and genserver handles publishing instead of opening a channel here...
    AMQP.Basic.publish(state.channel, @exchange, "", Poison.encode!(pub_map));

    {:reply, {:text, message}, state}
  end


  def websocket_info(info, state) do
    # this is a callback that gets called when information is sent to the process...
    # IO.puts("hi im websocket info")
    # IO.puts("info" <> info);
    # IO.inspect(self())
    {:reply, {:text, info}, state}
  end

  def setup_queue(chan) do
    AMQP.Exchange.declare(chan, @exchange, :fanout, durable: true)

    {:ok, _} = Queue.declare(chan, @queue, durable: true)
    :ok = Queue.bind(chan, @queue, @exchange)
  end
end
