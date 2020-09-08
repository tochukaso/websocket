defmodule Websocket.AWS.DynamoHelper do
  alias ExAws.Dynamo
  alias ExAws.Dynamo.Decoder
  require Logger

  @type category :: binary
  @type id :: binary
  @type conditions :: map
  @all_items_limit 1000

  def get_all_items(category) do
    [category: "#{category}"]
    |> make_search_conditions()
    |> get_all_items([])
  end

  defp get_all_items(search_conditions, existing_search_result) do
    search_result =
      get_table_name()
      |> Dynamo.query(search_conditions)
      |> ExAws.request!()

    merged_search_result =
      search_result
      |> merge_search_result(existing_search_result)

    if Map.has_key?(search_result, "LastEvaluatedKey") do
      search_conditions
      |> merge_last_evaluated_key(search_result)
      |> get_all_items(merged_search_result)
    else
      merged_search_result
    end
  end

  def get_item(category, id) do
    params = %{
      "category" => category,
      "id" => id
    }

    get_table_name()
    |> Dynamo.get_item(params)
    |> ExAws.request!()
    |> Decoder.decode()
    |> to_flat_map()
  end

  def get_items(category, conditions) do
    {attribute_values, filter_conditions} = make_conditions(conditions)

    category
    |> get_items(attribute_values, filter_conditions)
  end

  def get_items(category, conditions, filter_expression) do
    extract_conditions =
      conditions
      |> Map.put("category", category)

    extract_conditions
    |> Enum.to_list()
    |> make_search_conditions(filter_expression: filter_expression)
    |> get_items_recursive([])
  end

  defp get_items_recursive(search_conditions, existing_search_result) do
    search_result =
      get_table_name()
      |> Dynamo.query(search_conditions)
      |> ExAws.request!()

    merged_search_result =
      search_result
      |> merge_search_result(existing_search_result)

    if Map.has_key?(search_result, "LastEvaluatedKey") do
      search_conditions
      |> merge_last_evaluated_key(search_result)
      |> get_items_recursive(merged_search_result)
    else
      merged_search_result
    end
  end

  def put_item(category, id, data) do
    item =
      data
      |> Map.put("category", category)
      |> Map.put("id", id)

    get_table_name()
    |> Dynamo.put_item(item)
    |> ExAws.request!()

    item
  end

  def update_item(category, id, data) do
    expression_setting =
      data
      |> update_expression()

    get_table_name()
    |> Dynamo.update_item(
      %{}
      |> Map.put("category", category)
      |> Map.put("id", id),
      expression_attribute_values: expression_setting.attribute_values,
      update_expression: expression_setting.update,
      return_values: "ALL_NEW"
    )
    |> ExAws.request!()
  end

  def delete_item(category, id) do
    params = %{
      "category" => category,
      "id" => id
    }

    get_table_name()
    |> Dynamo.delete_item(params)
    |> ExAws.request!()
  end

  defp merge_search_result(current_serch_result, existing_search_result) do
    existing_search_result ++ fetch_search_result(current_serch_result)
  end

  defp fetch_search_result(search_result) do
    search_result
    |> Map.fetch!("Items")
    |> Enum.map(fn item -> Decoder.decode(item) end)
  end

  defp make_search_conditions(expression_attribute_values, opts \\ []) do
    [
      limit: @all_items_limit,
      expression_attribute_values: expression_attribute_values,
      key_condition_expression: "category = :category"
    ] ++ opts
  end

  defp merge_last_evaluated_key(search_conditions, search_result) do
    search_conditions ++
      [exclusive_start_key: Map.fetch!(search_result, "LastEvaluatedKey")]
  end

  defp make_conditions(conditions) do
    {
      attribute_conditions,
      filter_expressions
    } =
      conditions
      |> Enum.reduce({%{}, []}, fn {k, val}, acc ->
        if is_list(val) do
          add_list_condition(acc, k, val)
        else
          add_unit_condition(acc, k, val)
        end
      end)

    {
      attribute_conditions,
      Enum.join(filter_expressions, " and ")
    }
  end

  defp add_list_condition({conditions, filter_expressions}, _k, vals) when vals == [] do
    {conditions, filter_expressions}
  end

  defp add_list_condition({conditions, filter_expressions}, k, vals) do
    expression_values =
      vals
      |> Enum.with_index()
      |> Enum.reduce({%{}, []}, fn val, {acc_m, acc_v} ->
        {
          acc_m
          |> Map.put("#{k}#{elem(val, 1)}", elem(val, 0)),
          acc_v ++ [":#{k}#{elem(val, 1)}"]
        }
      end)

    {
      conditions
      |> Map.merge(elem(expression_values, 0)),
      filter_expressions ++
        ["#{k} IN(" <> Enum.join(elem(expression_values, 1), ",") <> ")"]
    }
  end

  defp add_unit_condition({conditions, filter_expressions}, k, val) do
    {
      conditions
      |> Map.put(k, val),
      filter_expressions ++ ["#{k} = :#{k}"]
    }
  end

  defp update_expression(expression) do
    update =
      "SET " <>
        (expression
         |> Map.keys()
         |> Enum.map(fn key ->
           "#{key} = :#{key}"
         end)
         |> Enum.join(","))

    %{
      attribute_values: expression,
      update: update
    }
  end

  defp to_flat_map(%{"Item" => item}), do: item
  defp to_flat_map(map), do: map

  defp get_table_name, do: config(:dynamodb_table)
  defp config(atom), do: Application.fetch_env!(:websocket, :controller)[atom]
end
