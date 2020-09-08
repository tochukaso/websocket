defmodule Websocket.AWS.Sqs do
  @moduledoc """
  AWS SQSとの連携用部品
  """

  alias ExAws.SQS

  def add_message(messages, message_group_id) do
    sqs_queue_url()
    |> SQS.send_message(
      Poison.encode!(messages),
      message_group_id: message_group_id
    )
    |> ExAws.request!()
  end

  def add_login_user(user_name, group_id) do
    add_message(
      %{
        "user_name" => user_name,
        "group_id" => group_id
      },
      group_id
    )
  end

  defp sqs_queue_url, do: config(:sqs_queuer_url)
  defp config(atom), do: Application.fetch_env!(:websocket, :controller)[atom]
end
