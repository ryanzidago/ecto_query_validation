defmodule EctoQueryValidation.DeterministicOrdering do
  @moduledoc """
  Ensures high-risk read queries have a deterministic root ordering.

  The check runs automatically for `limit(1)` queries and can be explicitly
  enabled for other reads with `validate_deterministic_ordering: true`.
  """

  @behaviour EctoQueryValidation.Check

  alias EctoQueryValidation
  alias EctoQueryValidation.Check

  @impl Check
  def option_key, do: :validate_deterministic_ordering

  @impl Check
  @spec validate(
          operation :: EctoQueryValidation.operation(),
          query :: Ecto.Query.t(),
          check_opts :: Keyword.t(),
          runtime_opts :: EctoQueryValidation.runtime_check_opts()
        ) :: :ok | {:errors, EctoQueryValidation.errors()}
  def validate(operation, %Ecto.Query{} = query, _check_opts, runtime_opts) do
    primary_key_fields = primary_key_fields(query)

    cond do
      operation != :all ->
        :ok

      existence_probe?(query) ->
        :ok

      not should_validate?(query, runtime_opts) ->
        :ok

      Enum.empty?(primary_key_fields) ->
        :ok

      true ->
        case ordering_error(query, runtime_opts) do
          nil -> :ok
          error -> {:errors, [error]}
        end
    end
  end

  defp should_validate?(%Ecto.Query{} = query, runtime_opts) do
    case Keyword.fetch(runtime_opts, option_key()) do
      {:ok, enabled?} -> enabled?
      :error -> limit_one?(query)
    end
  end

  defp ordering_error(%Ecto.Query{} = query, runtime_opts) do
    primary_key_fields = primary_key_fields(query)
    ordered_root_fields = ordered_root_fields(query)
    query_description = query_description(query, runtime_opts)
    primary_key_fields_label = format_fields(primary_key_fields)

    cond do
      Enum.empty?(query.order_bys) ->
        "#{query_description} must define `order_by` that includes root primary key field(s) " <>
          "#{primary_key_fields_label} to guarantee deterministic results"

      Enum.all?(primary_key_fields, &(&1 in ordered_root_fields)) ->
        nil

      true ->
        "#{query_description} must include root primary key field(s) #{primary_key_fields_label} " <>
          "in `order_by` to guarantee deterministic results. Current root order_by fields: " <>
          "#{format_fields(ordered_root_fields)}"
    end
  end

  defp query_description(%Ecto.Query{} = query, runtime_opts) do
    schema = inspect(schema_module(query))

    cond do
      limit_one?(query) ->
        "limit(1) query for #{schema}"

      Keyword.get(runtime_opts, option_key(), false) ->
        "query for #{schema} with `#{option_key()}: true`"

      true ->
        "query for #{schema}"
    end
  end

  defp primary_key_fields(%Ecto.Query{} = query) do
    schema = schema_module(query)

    if function_exported?(schema, :__schema__, 1) do
      schema.__schema__(:primary_key)
    else
      []
    end
  end

  defp ordered_root_fields(%Ecto.Query{} = query) do
    query.order_bys
    |> Enum.flat_map(&ordered_root_fields_in_expr/1)
    |> Enum.uniq()
  end

  defp ordered_root_fields_in_expr(%Ecto.Query.ByExpr{} = by_expr) do
    Enum.flat_map(by_expr.expr, fn {_direction, expression} ->
      case root_field(expression) do
        nil -> []
        field -> [field]
      end
    end)
  end

  defp root_field({{:., _dot_meta, [{:&, _binding_meta, [0]}, field]}, _call_meta, []})
       when is_atom(field) do
    field
  end

  defp root_field(_expression) do
    nil
  end

  defp limit_one?(%Ecto.Query{limit: %Ecto.Query.LimitExpr{with_ties: true}}) do
    false
  end

  defp limit_one?(%Ecto.Query{limit: %Ecto.Query.LimitExpr{}} = query) do
    limit_value(query.limit) == 1
  end

  defp limit_one?(%Ecto.Query{}) do
    false
  end

  defp existence_probe?(
         %Ecto.Query{
           order_bys: [],
           limit: %Ecto.Query.LimitExpr{},
           select: %Ecto.Query.SelectExpr{expr: 1}
         } = query
       ) do
    limit_value(query.limit) == 1
  end

  defp existence_probe?(%Ecto.Query{}) do
    false
  end

  defp limit_value(%Ecto.Query.LimitExpr{expr: value, params: []}) when is_integer(value) do
    value
  end

  defp limit_value(%Ecto.Query.LimitExpr{expr: {:^, _expr_meta, [index]}} = limit_expr)
       when is_integer(index) do
    case Enum.at(limit_expr.params, index) do
      {value, _type} when is_integer(value) -> value
      _other -> nil
    end
  end

  defp limit_value(%Ecto.Query.LimitExpr{}) do
    nil
  end

  defp format_fields([]), do: "`none`"

  defp format_fields(fields) do
    Enum.map_join(fields, ", ", &"`#{&1}`")
  end

  defp schema_module(%Ecto.Query{from: %{source: {_source, schema}}}) when is_atom(schema) do
    schema
  end

  defp schema_module(%Ecto.Query{}) do
    nil
  end
end
