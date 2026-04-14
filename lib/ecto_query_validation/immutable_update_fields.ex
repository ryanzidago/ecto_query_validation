defmodule EctoQueryValidation.ImmutableUpdateFields do
  @moduledoc """
  Rejects `update_all` queries that attempt to mutate configured root fields.

  Configure extra immutable fields with:

      check_options: [
        validate_immutable_update_fields: [fields: [:tenant_id, :workspace_id]]
      ]
  """

  @behaviour EctoQueryValidation.Check

  alias EctoQueryValidation
  alias EctoQueryValidation.Check

  @default_immutable_fields [:id, :inserted_at]

  @impl Check
  def option_key, do: :validate_immutable_update_fields

  @impl Check
  @spec validate(
          operation :: EctoQueryValidation.operation(),
          query :: Ecto.Query.t(),
          runtime_opts :: EctoQueryValidation.runtime_check_opts(),
          config :: Keyword.t()
        ) :: :ok | {:errors, EctoQueryValidation.errors()}
  def validate(operation, %Ecto.Query{} = query, runtime_opts, config) do
    cond do
      operation != :update_all ->
        :ok

      not Keyword.get(runtime_opts, option_key(), true) ->
        :ok

      true ->
        case immutable_update_errors(query, config) do
          [] -> :ok
          errors -> {:errors, errors}
        end
    end
  end

  defp immutable_update_errors(%Ecto.Query{} = query, config) do
    updated_fields = updated_fields(query)
    schema = schema_module(query)

    query
    |> immutable_fields_for_schema(config)
    |> Enum.filter(&(&1 in updated_fields))
    |> Enum.map(&immutable_field_message(schema, &1))
  end

  defp immutable_fields_for_schema(%Ecto.Query{} = query, config) do
    schema = schema_module(query)

    if function_exported?(schema, :__schema__, 1) do
      schema_fields = schema.__schema__(:fields)

      config
      |> Keyword.get(:fields, @default_immutable_fields)
      |> Enum.filter(&(&1 in schema_fields))
    else
      []
    end
  end

  defp updated_fields(%Ecto.Query{} = query) do
    query.updates
    |> Enum.flat_map(&updated_fields_in_expr/1)
    |> Enum.uniq()
  end

  defp updated_fields_in_expr(%Ecto.Query.QueryExpr{} = query_expr) do
    Enum.flat_map(query_expr.expr, fn
      {_operator, fields} when is_list(fields) -> Keyword.keys(fields)
      _other -> []
    end)
  end

  defp immutable_field_message(schema, field) do
    "update_all query for #{inspect(schema)} must not update immutable field `#{field}`"
  end

  defp schema_module(%Ecto.Query{from: %{source: {_source, schema}}}) when is_atom(schema) do
    schema
  end

  defp schema_module(%Ecto.Query{}) do
    nil
  end
end
