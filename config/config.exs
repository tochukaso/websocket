# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :websocket, WebsocketWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zu0A/5vsoi2YqQYrBgRGmEVyyZFYhp29iz0FwWQEM/9SNABIwWlQ2Y8RjScafN3f",
  render_errors: [view: WebsocketWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Websocket.PubSub,
  live_view: [signing_salt: "Sy665Hp8"],
  sqs_queuer_url: "https://sqs.ap-northeast-1.amazonaws.com/747030685203/websocket-sqs.fifo"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :websocket, :controller,
  sqs_queuer_url: "https://sqs.ap-northeast-1.amazonaws.com/747030685203/websocket-sqs.fifo"

config :ex_aws,
  access_key_id: [
    {:system, "AWS_ACCESS_KEY_ID"},
    {:awscli, "default", 30},
    :instance_role
  ],
  secret_access_key: [
    {:system, "AWS_SECRET_ACCESS_KEY"},
    {:awscli, "default", 30},
    :instance_role
  ],
  region: System.get_env("AWS_REGION")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
