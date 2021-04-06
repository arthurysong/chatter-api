defmodule Websocket.AnotherApplication do
  use Application

  def start(_type, _args) do
    IO.puts("started another application");
    children = [
      {Stack, [:hello]}
    ]
    # children = [%{
    #   id: Stack,
    #   start: {Stack, :start_link, [[:hello]]}
    # }]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
