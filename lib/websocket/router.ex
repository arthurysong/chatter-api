# ./lib/webhook_processor/endpoint.ex
defmodule Websocket.Router do
  @moduledoc """
  A Plug responsible for logging request info, parsing request body's as JSON,
  matching routes, and dispatching responses.
  """

  use Plug.Router
  require Websocket.Counter


  # This module is a Plug, that also implements it's own plug pipeline, below:

  # Using Plug.Logger for logging request information
  plug(Plug.Logger)
  plug Corsica, origins: "*"
  # responsible for matching routes
  plug(:match)
  # Using Poison for JSON decoding
  # Note, order of plugs is important, by placing this _after_ the 'match' plug,
  # we will only parse the request AFTER there is a route match.
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  # responsible for dispatching responses
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, Poison.encode!(%{response: "allo world"}))
  end

  get "/counter" do
    # IO.puts(Websocket.Counter.value())
    send_resp(conn, 200, Poison.encode!(%{response: Websocket.Counter.value()}))
  end

  post "/counter" do
    IO.puts(Websocket.Counter.increment())
    send_resp(conn, 200, Poison.encode!(%{response: "ok" }))
  end

  get "/db_host" do
    send_resp(conn, 200, Poison.encode!(
      # this fetches the env varialbe at runtime
      %{response: Application.fetch_env!(:websocket, :db_host)}))
  end

  # A simple route to test that the server is up
  # Note, all routes must return a connection as per the Plug spec.
  get "/ping" do
    send_resp(conn, 200, "pong!")
  end

  # A catchall route, 'match' will match no matter the request method,
  # so a response is always returned, even if there is no route to match.
  match _ do
    send_resp(conn, 404, "oops... Nothing here :(")
  end
end
