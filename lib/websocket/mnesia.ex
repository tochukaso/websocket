defmodule Websocket.Mnesia do
  alias :mnesia, as: Mnesia

  @notification :notification

  def init_master() do
    Mnesia.stop()

    node_list = [node()]

    IO.inspect(node_list, label: "nodes")

    :mnesia.create_schema([node()])
    :mnesia.start()
    :mnesia.create_table(@notification,
      attributes: [:user_id, :notification_time]
    )

    Mnesia.create_schema(node_list)

    Mnesia.start()

    Mnesia.create_table(@notification,
      attributes: [:user_id, :notification_time, disc_copies: node_list]
    )

    Mnesia.wait_for_tables([@notification], 5_000)
  end

  def add_self_to_cluster(master_node) do
    Node.connect(master_node)

    Mnesia.start()

    :rpc.call(master_node, Websocket.Mnesia, :add_child_to_cluster, [node()])

    Mnesia.add_table_copy(@notification, node(), :disc_copies)

    Mnesia.wait_for_tables([@notification], 5_000)
  end

  def add_child_to_cluster(child_node) do
    Mnesia.change_config(:extra_db_nodes, [child_node])

    Mnesia.change_table_copy_type(:schema, child_node, :disc_copies)
  end
end
