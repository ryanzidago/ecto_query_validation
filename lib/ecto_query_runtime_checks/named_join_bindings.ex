defmodule EctoQueryRuntimeChecks.NamedJoinBindings do
  @moduledoc """
  Ensures joined queries name the root source and every join with `as:`.
  """

  @behaviour EctoQueryRuntimeChecks.Check

  alias EctoQueryRuntimeChecks
  alias EctoQueryRuntimeChecks.Check

  @impl Check
  def option_key, do: :validate_named_bindings

  @impl Check
  @spec validate(
          operation :: EctoQueryRuntimeChecks.operation(),
          query :: Ecto.Query.t(),
          runtime_opts :: EctoQueryRuntimeChecks.runtime_check_opts(),
          config :: Keyword.t()
        ) :: :ok | {:errors, EctoQueryRuntimeChecks.errors()}
  def validate(_operation, %Ecto.Query{} = query, runtime_opts, _config) do
    cond do
      not Keyword.get(runtime_opts, option_key(), true) ->
        :ok

      Enum.empty?(query.joins) ->
        :ok

      true ->
        case missing_bindings(query) do
          [] -> :ok
          errors -> {:errors, errors}
        end
    end
  end

  defp missing_bindings(%Ecto.Query{} = query) do
    root_error =
      if root_binding_missing?(query) do
        ["root source is missing `from(as: ...)`"]
      else
        []
      end

    join_errors =
      query.joins
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {join, index} ->
        if is_nil(join.as) do
          ["join ##{index} is missing `join(..., as: ...)`"]
        else
          []
        end
      end)

    root_error ++ join_errors
  end

  defp root_binding_missing?(%Ecto.Query{from: %{as: as}}) do
    is_nil(as)
  end
end
