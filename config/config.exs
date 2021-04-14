import Config
config :websocket, :db_host, "db.local"
import_config "#{config_env()}.exs"

# raise error if no APP_ID was set...
app_id = System.get_env("APP_ID") || raise ("""
  environment variable APP_ID is missing.
  please set APP_ID on system.
""")

port = System.get_env("PORT") || raise("""
  environment variable PORT is missing.
  please set PORT on system
""")

amqp_url = System.get_env("RMQ_URL") || raise("""
  environment variable RMQ_URL is missing.
  please set RMQ_URL on system
""")

config :mix_docker, image: "chatter/demo"
