# this is a genserver that will connect to amqp queue and handle incoming messages....
# it should use the message that will include the registry key for the websocket channel to send the message to all related processes in the
# Registry.MyWebsocketApp
defmodule Websocket.AMQPConsumer do
  use GenServer
  use AMQP

  def start_link(initial_val) do
    GenServer.start_link(__MODULE__, initial_val, name: :amqp)
  end

  @exchange    "chatter_test_exchange"
  @queue       "chatter_test_queue"
  # @queue_error "#{@queue}_error"

  IO.puts(@queue)

  def init(_opts) do
    IO.puts("queue" <> @queue)
    IO.puts(System.get_env("APP_ID"))
    # a connection is a tcp connection to interact with RabbitMQ...
    # {:ok, conn} = Connection.open("amqp://guest:guest@localhost")
    IO.puts("host" <> Application.fetch_env!(:websocket, :rabbitmq_host))
    # {:ok, conn} = Connection.open("amqp://test:test@" <> Application.fetch_env!(:websocket, :rabbitmq_host))
    # {:ok, conn} = Connection.open("amqp://test:test@internal-rabbitmq-1546572793.us-west-1.elb.amazonaws.com")

    # this is our load balancer...
    {:ok, conn} = Connection.open("amqp://test:test@rmq-791691136.us-west-1.elb.amazonaws.com:5672")
    # {:ok, conn} = Connection.open("amqp://test:test@13.57.218.23")

    # this one is the amazon mq
    # {:ok, conn} = Connection.open("amqps://test:testtest1234@b-ca5a495a-273b-4dcf-ae65-96126769fda1.mq.us-west-1.amazonaws.com:5671")
    # channels are a lightweight conncetion that share a single TCP connection...
    {:ok, chan} = Channel.open(conn)
    setup_queue(chan)

    # Limit unacknowledged messages to 10
    :ok = Basic.qos(chan, prefetch_count: 10)

    # IO.puts("genserver started and amqp connection init")

    # queue_uniq = @queue <> List.to_string(:erlang.pid_to_list(self()))
    queue_uniq = @queue <> System.get_env("APP_ID")
    IO.puts("queue_uniq" <> queue_uniq)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, queue_uniq)
    {:ok, chan}
  end

  def handle_call({:get_state}, _from, chan) do
    # IO.puts("handling call in genserver")
    {:reply, :erlang.pid_to_list(self()), chan}
  end

  def handle_cast({:publish, pub_map}, chan) do
    # IO.puts("handling publish cast")
    # IO.inspect(pub_map)
    AMQP.Basic.publish(chan, @exchange, "", Poison.encode!(pub_map));

    {:noreply, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: _redelivered}}, chan) do
    # You might want to run payload consumption in separate Tasks in production
    # consume(chan, tag, redelivered, payload)
    :ok = Basic.ack chan, tag
    IO.puts("consumed")
    # IO.puts("payload" <> payload)
    msg_map = Poison.decode!(payload)
    # IO.inspect :erlang.list_to_pid(msg_map["sender_pid"])
    # IO.inspect(self())

    Registry.MyWebsocketApp
    |> Registry.dispatch(msg_map["registry_key"], fn(entries) ->
      # get all processes that have same key
      # e.g. /ws/chat/3
      for {pid, _} <- entries do
        if pid != :erlang.list_to_pid(msg_map["sender_pid"]) do
          Process.send(pid, msg_map["message"], [])
        end
      end
    end)
    {:noreply, chan}
  end

  defp setup_queue(chan) do
    AMQP.Exchange.declare(chan, @exchange, :fanout, durable: true)

    queue_uniq = @queue <> System.get_env("APP_ID")

    {:ok, _} = Queue.declare(chan, queue_uniq, durable: true)
    :ok = Queue.bind(chan, queue_uniq, @exchange)
  end
end
