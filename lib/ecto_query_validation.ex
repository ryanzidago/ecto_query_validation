defmodule EctoQueryValidation do
  @moduledoc """
  Shared types and namespace for runtime Ecto query validation checks.

  The package intentionally does not prescribe how checks are wired into
  `Repo.prepare_query/3`, how configuration is loaded, or how violations are
  surfaced. Host applications own that orchestration layer.

  The package ships:

  - `EctoQueryValidation.Check`, the behaviour for runtime checks
  - built-in check modules under `EctoQueryValidation.*`

  ## Host app integration

      def prepare_query(operation, query, opts) do
        runtime_opts = Keyword.get(opts, :ecto_query_validation, [])

        checks = [
          {EctoQueryValidation.NamedJoinBindings, []},
          {EctoQueryValidation.RequiredFilterFields, fields: [:tenant_id]}
        ]

        errors =
          Enum.flat_map(checks, fn {check, config} ->
            case check.validate(operation, query, config, runtime_opts) do
              :ok -> []
              {:errors, errors} -> errors
            end
          end)

        case errors do
          [] -> {query, Keyword.delete(opts, :ecto_query_validation)}
          errors -> raise MyApp.EctoQueryValidationError, operation: operation, errors: errors
        end
      end
  """

  @type operation :: :all | :update_all | :delete_all | :stream | :insert_all
  @type error :: String.t()
  @type errors :: nonempty_list(error())
  @type runtime_check_opt_key :: :enabled | atom()
  @type runtime_check_opt :: {runtime_check_opt_key(), term()}
  @type runtime_check_opts :: list(runtime_check_opt())
end
