defmodule Websocket.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    import Supervisor.Spec, warn: false

    children = [
      # Starts a worker by calling: Websocket.Worker.start_link(arg)
      # {Websocket.Worker, arg}
      {
        Plug.Cowboy, scheme: :http, plug: Websocket.Router, options: [
          port: 4000,
          dispatch: dispatch()
        ]
      },
      {Websocket.Counter, 0},
      Registry.child_spec(
        keys: :duplicate,
        name: Registry.MyWebsocketApp
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Websocket.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_, [
        {"/ws/[...]", Websocket.SocketHandler, []},
        {:_, Plug.Cowboy.Handler, {Websocket.Router, []}}
      ]}
    ]
  end
end
