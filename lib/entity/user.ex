defmodule Websocket.Entity.User do
  alias Websocket.AWS.DynamoHelper
  @category "user"

  def put(id, item) do
    DynamoHelper.put_item(@category, id, item)
  end
end
