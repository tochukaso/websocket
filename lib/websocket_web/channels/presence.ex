defmodule WebsocketWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :websocket,
    pubsub_server: Websocket.PubSub

  def track_user_join(socket, user) do
    IO.inspect(user, label: "track_user_join")

    track(socket, user["user_id"], %{
      typing: false,
      user_name: user["user_name"],
      group_id: user["group_id"]
    })
  end
end
