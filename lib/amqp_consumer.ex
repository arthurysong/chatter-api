# this is a genserver that will connect to amqp queue and handle incoming messages....
# it should use the message that will include the registry key for the websocket channel to send the message to all related processes in the
# Registry.MyWebsocketApp
defmodule Websocket.AMQPConsumer do
  use GenServer
  use AMQP

  def start_link(initial_val) do
    GenServer.start_link(__MODULE__, initial_val)
  end

  @exchange    "chatter_test_exchange"
  @queue       "chatter_test_queue"
  @queue_error "#{@queue}_error"

  def init(_opts) do
    {:ok, conn} = Connection.open("amqp://guest:guest@localhost")
    {:ok, chan} = Channel.open(conn)
    setup_queue(chan)

    # Limit unacknowledged messages to 10
    :ok = Basic.qos(chan, prefetch_count: 10)

    IO.puts("genserver started and amqp connection init")
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, @queue)
    {:ok, chan}
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
    IO.puts("payload" <> payload)

    msg_map = Poison.decode!(payload)
    IO.inspect(msg_map)
    IO.puts(msg_map["registry_key"])
    Registry.MyWebsocketApp
    |> Registry.lookup(msg_map["registry_key"])
    |> IO.inspect()

    Registry.MyWebsocketApp
    |> Registry.dispatch(msg_map["registry_key"], fn(entries) ->
      # get all processes that have same key
      # e.g. /ws/chat/3
      for {pid, _} <- entries do
        if pid != :erlang.list_to_pid(msg_map["sender_pid"]) do
        # if pid != self() do
          # send the message to the process..
          IO.puts("wtf...")
          Process.send(pid, msg_map["message"], [])
        end
      end
    end)
    {:noreply, chan}
  end

  defp setup_queue(chan) do
    AMQP.Exchange.declare(chan, @exchange, :fanout, durable: true)

    {:ok, _} = Queue.declare(chan, @queue, durable: true)
    :ok = Queue.bind(chan, @queue, @exchange)
    # {:ok, _} = Queue.declare(chan, @queue, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    # {:ok, _} = Queue.declare(chan, @queue,
    #                          durable: true,
    #                          arguments: [
    #                            {"x-dead-letter-exchange", :longstr, ""},
    #                            {"x-dead-letter-routing-key", :longstr, @queue_error}
    #                          ]
    #                         )
    # :ok = Exchange.fanout(chan, @exchange, durable: true)
    # :ok = Queue.bind(chan, @queue, @exchange)
  end

  # defp consume(channel, tag, redelivered, payload) do
    # number = String.to_integer(payload)
    # IO.puts "consumed a #{payload}"
    # if number <= 10 do
    #   :ok = Basic.ack channel, tag
    #   IO.puts "Consumed a #{number}."
    # else
    #   :ok = Basic.reject channel, tag, requeue: false
    #   IO.puts "#{number} is too big and was rejected."
    # end

  # rescue
  #   # Requeue unless it's a redelivered message.
  #   # This means we will retry consuming a message once in case of exception
  #   # before we give up and have it moved to the error queue
  #   #
  #   # You might also want to catch :exit signal in production code.
  #   # Make sure you call ack, nack or reject otherwise comsumer will stop
  #   # receiving messages.
  #   exception ->
  #     :ok = Basic.reject channel, tag, requeue: not redelivered
  #     IO.puts "Error converting #{payload} to integer"
  # end
end
