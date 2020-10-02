defmodule WebsocketWeb.CartChannel do
  use Phoenix.Channel
  alias Phoenix.Socket
  alias WebsocketWeb.Presence
  require Logger

  def join("cart:" <> goods_id, _message, socket) do
    IO.inspect(goods_id, label: "goods_id")
    send(self(), :after_join)
    {:ok, put_goods(socket, goods_id)}
  end

  @spec handle_info(:after_join, Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_info(:after_join, socket) do
    Logger.info("called :after_join")
    Presence.track_user_join(socket, extract_user(socket))
    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  def handle_in("change", message, socket) do
    Logger.info("Start video upload")

    put_goods(socket, message)

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  rescue
    error ->
      error
      |> inspect()
      |> Logger.error()

      System.stacktrace()
      |> Exception.format_stacktrace()
      |> Logger.error()

      {:reply, {:error}, socket}
  after
    Logger.info("Finished video upload")
  end

  defp extract_user(socket) do
    %{
      "user_id" => socket.assigns["user_id"],
      "user_name" => "username",
      "goods_id" => socket.assigns["goods_id"],
      "count" => socket.assigns["count"]
    }
  end

  defp put_goods(socket, message) when is_map(message) do
    socket
    |> assign("count", message["count"])
  end

  defp put_goods(socket, goods_id, count \\ 1) do
    socket
    |> assign("goods_id", goods_id)
    |> assign("count", count)
  end
end
