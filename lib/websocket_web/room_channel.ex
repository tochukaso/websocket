defmodule WebsocketWeb.RoomChannel do
  use Phoenix.Channel
  alias Phoenix.Socket
  alias Websocket.AWS.Sqs
  alias WebsocketWeb.Presence
  require Logger
  @notification :notification

  def join("room:lobby" <> group_id, _message, socket) do
    IO.inspect(group_id, label: "group_id")
    # send(self(), :after_join)
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "authorized"}}
  end

  def handle_info(:after_join, socket) do
    Logger.info("called :after_join")
    Presence.track_user_join(socket, extract_user(socket))
    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  defp extract_user(socket) do
    %{
      "user_id" => socket.assigns["user_id"],
      "user_name" => socket.assigns["user_name"],
      "group_id" => socket.assigns["group_id"]
    }
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    Logger.info("Start new message.")
    IO.inspect(socket, label: "socket")

    response = %{
      body: body,
      writer: socket.assigns["user_name"],
      date: time()
    }

    :mnesia.dirty_write({@notification, socket.assigns["user_name"], time()})

    result =
      :mnesia.dirty_read(@notification, socket.assigns["user_name"])
      |> get_notification_time_from_result()

    Logger.info("notification_time: #{result}")
    # Sqs.add_message(
    #  response,
    #  socket.assigns["group_id"]
    # )

    broadcast!(socket, "new_msg", %{body: response})
    {:noreply, socket}
  rescue
    error ->
      error
      |> inspect()
      |> Logger.error()

      {:error, %{reason: "unexpected error was occurred"}}
  after
    Logger.info("Finished new message.")
  end

  defp get_notification_time_from_result(result) when result == [] do
    nil
  end

  defp get_notification_time_from_result(result) do
    result
    |> hd()
    |> elem(2)
  end

  def handle_in("login", body, socket) do
    IO.inspect(body, label: "login")
    broadcast!(socket, "user_name", %{body: body["user_name"]})
    login(socket, body)

    # Sqs.add_login_user(body["user_name"], body["group_id"])
    send(self(), :after_join)
    {:noreply, login(socket, body)}
  rescue
    error ->
      error
      |> inspect()
      |> Logger.error()

      {:error, %{reason: "unexpected error was occurred"}}
  after
    Logger.info("Finished new message.")
  end

  def do_user_update(socket, user, %{typing: typing}) do
    Presence.update(socket, user["user_id"], %{
      typing: typing,
      user_name: user["user_name"],
      user_id: user["user_id"],
      group_id: user["group_id"]
    })
  end

  defp login(socket, body) do
    socket
    |> assign("user_name", body["user_name"])
    |> assign("group_id", body["group_id"])
  end

  defp time() do
    Timex.now()
    |> Timex.shift(hours: 9)
    |> Timex.format!("%T", :strftime)
  end
end
