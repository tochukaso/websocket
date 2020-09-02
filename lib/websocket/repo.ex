defmodule Websocket.Repo do
  use Ecto.Repo,
    otp_app: :websocket,
    adapter: Ecto.Adapters.Postgres
end
