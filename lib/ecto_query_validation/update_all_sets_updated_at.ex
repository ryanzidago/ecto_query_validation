defmodule EctoQueryValidation.UpdateAllSetsUpdatedAt do
  @moduledoc """
  Ensures `update_all` queries set `updated_at` when the target schema defines it.
  """

  @behaviour EctoQueryValidation.Check

  alias EctoQueryValidation
  alias EctoQueryValidation.Check

  @impl Check
  def option_key, do: :validate_update_all_updated_at

  @impl Check
  @spec validate(
          operation :: EctoQueryValidation.operation(),
          query :: Ecto.Query.t(),
          check_opts :: Keyword.t(),
          runtime_opts :: EctoQueryValidation.runtime_check_opts()
        ) :: :ok | {:errors, EctoQueryValidation.errors()}
  def validate(operation, %Ecto.Query{} = query, _check_opts, runtime_opts) do
    cond do
      operation != :update_all ->
        :ok

      not Keyword.get(runtime_opts, option_key(), true) ->
        :ok

      not schema_defines_updated_at?(query) ->
        :ok

      updated_at_set?(query) ->
        :ok

      true ->
        {:errors, [missing_updated_at_message(query)]}
    end
  end

  defp schema_defines_updated_at?(%Ecto.Query{} = query) do
    schema = schema_module(query)
    function_exported?(schema, :__schema__, 1) and :updated_at in schema.__schema__(:fields)
  end

  defp updated_at_set?(%Ecto.Query{} = query) do
    Enum.any?(query.updates, &updated_at_set_in_expr?/1)
  end

  defp updated_at_set_in_expr?(%Ecto.Query.QueryExpr{} = query_expr) do
    query_expr.expr
    |> Keyword.get_values(:set)
    |> Enum.any?(&Keyword.has_key?(&1, :updated_at))
  end

  defp missing_updated_at_message(%Ecto.Query{} = query) do
    "update_all query for #{inspect(schema_module(query))} must set `updated_at` in its update clause because the schema defines that field"
  end

  defp schema_module(%Ecto.Query{from: %{source: {_source, schema}}}) when is_atom(schema) do
    schema
  end

  defp schema_module(%Ecto.Query{}) do
    nil
  end
end
