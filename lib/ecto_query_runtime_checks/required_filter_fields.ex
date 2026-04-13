defmodule EctoQueryRuntimeChecks.RequiredFilterFields do
  @moduledoc """
  Ensures schema-backed queries filter configured root fields.

  Configure the required fields with:

      check_options: [
        validate_required_filter_fields: [fields: [:tenant_id, :workspace_id]]
      ]
  """

  @behaviour EctoQueryRuntimeChecks.Check

  alias EctoQueryRuntimeChecks
  alias EctoQueryRuntimeChecks.Check

  @checked_operations [:all, :update_all, :delete_all, :stream]

  @impl Check
  def option_key, do: :validate_required_filter_fields

  @impl Check
  @spec validate(
          operation :: EctoQueryRuntimeChecks.operation(),
          query :: Ecto.Query.t(),
          runtime_opts :: EctoQueryRuntimeChecks.runtime_check_opts(),
          config :: Keyword.t()
        ) :: :ok | {:errors, EctoQueryRuntimeChecks.errors()}
  def validate(operation, %Ecto.Query{} = query, runtime_opts, config) do
    cond do
      operation not in @checked_operations ->
        :ok

      not Keyword.get(runtime_opts, option_key(), true) ->
        :ok

      true ->
        case missing_filter_fields(query, config) do
          [] -> :ok
          fields -> {:errors, Enum.map(fields, &missing_filter_field_message(query, &1))}
        end
    end
  end

  defp missing_filter_fields(%Ecto.Query{} = query, config) do
    filtered_fields = filtered_root_fields(query)

    query
    |> required_filter_fields(config)
    |> Enum.reject(&MapSet.member?(filtered_fields, &1))
  end

  defp required_filter_fields(%Ecto.Query{} = query, config) do
    schema = schema_module(query)

    if function_exported?(schema, :__schema__, 1) do
      schema_fields = schema.__schema__(:fields)

      config
      |> Keyword.get(:fields, [])
      |> Enum.filter(&(&1 in schema_fields))
    else
      []
    end
  end

  defp filtered_root_fields(%Ecto.Query{} = query) do
    Enum.reduce(query.wheres, MapSet.new(), fn where_expr, fields ->
      MapSet.union(fields, filtered_root_fields_in_expr(where_expr.expr))
    end)
  end

  defp filtered_root_fields_in_expr({:and, _meta, [left, right]}) do
    left
    |> filtered_root_fields_in_expr()
    |> MapSet.union(filtered_root_fields_in_expr(right))
  end

  defp filtered_root_fields_in_expr({:or, _meta, [left, right]}) do
    left
    |> filtered_root_fields_in_expr()
    |> MapSet.intersection(filtered_root_fields_in_expr(right))
  end

  defp filtered_root_fields_in_expr({operator, _meta, [left, right]})
       when operator in [:==, :in] do
    [left, right]
    |> Enum.flat_map(fn expression ->
      case root_field(expression) do
        nil -> []
        field -> [field]
      end
    end)
    |> MapSet.new()
  end

  defp filtered_root_fields_in_expr(_other) do
    MapSet.new()
  end

  defp missing_filter_field_message(%Ecto.Query{} = query, field) do
    "query for #{inspect(schema_module(query))} must filter root field `#{field}`"
  end

  defp root_field({{:., _dot_meta, [{:&, _binding_meta, [0]}, field]}, _call_meta, []})
       when is_atom(field) do
    field
  end

  defp root_field(_expression) do
    nil
  end

  defp schema_module(%Ecto.Query{from: %{source: {_source, schema}}}) when is_atom(schema) do
    schema
  end

  defp schema_module(%Ecto.Query{}) do
    nil
  end
end
