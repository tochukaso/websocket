defmodule Websocket.Store do
  @moduledoc """
  Provides the structure of ExampleStore records for a minimal example of Mnesiac.
  """
  use Mnesiac.Store
  import Record, only: [defrecord: 3]

  @doc """
  Record definition for ExampleStore example record.
  """
  Record.defrecord(
    :notification,
    __MODULE__,
    user_id: nil,
    notification_time: nil,
    event: nil
  )

  @typedoc """
  ExampleStore example record field type definitions.
  """
  @type notification ::
          record(
            :notification,
            user_id: String.t(),
            notification_time: String.t(),
            event: String.t()
          )

  @impl true
  def store_options,
    do: [
      record_name: __MODULE__,
      attributes: example() |> example() |> Keyword.keys(),
      index: [:topic_id],
      ram_copies: [node()]
    ]
end
