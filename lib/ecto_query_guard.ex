defmodule EctoQueryGuard do
  @moduledoc """
  Runtime validation for executed `%Ecto.Query{}` values.

  The library exposes two main entry points:

  - `validate/4` runs the configured checks against a query.
  - `prepare_query/4` mirrors the `Ecto.Repo.prepare_query/3` hook and strips
    runtime-check-owned opts before Ecto sees them.

  ## Repo integration

      defmodule MyApp.Repo do
        use Ecto.Repo,
          otp_app: :my_app,
          adapter: Ecto.Adapters.Postgres

        @impl Ecto.Repo
        def prepare_query(operation, query, opts) do
          EctoQueryGuard.prepare_query(
            operation,
            query,
            opts,
            enabled: Application.get_env(:my_app, :ecto_query_guard, [])[:enabled] == true,
            check_options: [
              validate_required_filter_fields: [fields: [:tenant_id]]
            ]
          )
        end
      end

  Runtime-check opts are nested under `:ecto_query_guard` by default:

      Repo.all(query, ecto_query_guard: [enabled: false])
      Repo.one(query, ecto_query_guard: [validate_named_bindings: false])
  """

  alias EctoQueryGuard.DeterministicOrdering
  alias EctoQueryGuard.Error
  alias EctoQueryGuard.ImmutableUpdateFields
  alias EctoQueryGuard.NamedJoinBindings
  alias EctoQueryGuard.RequiredFilterFields
  alias EctoQueryGuard.UpdateAllSetsUpdatedAt

  @type operation :: :all | :update_all | :delete_all | :stream | :insert_all
  @type error :: String.t()
  @type errors :: nonempty_list(error())
  @type runtime_check_opt_key :: :enabled | atom()
  @type runtime_check_opt :: {runtime_check_opt_key(), term()}
  @type runtime_check_opts :: list(runtime_check_opt())

  @type config_opt ::
          {:checks, list(module())}
          | {:enabled, boolean()}
          | {:runtime_opts_key, atom()}
          | {:check_options, keyword(Keyword.t())}
          | {:error_module, module()}
  @type config :: list(config_opt())

  @default_checks [
    NamedJoinBindings,
    RequiredFilterFields,
    UpdateAllSetsUpdatedAt,
    DeterministicOrdering,
    ImmutableUpdateFields
  ]

  @doc """
  Returns the built-in checks shipped with the package.
  """
  @spec default_checks() :: list(module())
  def default_checks do
    @default_checks
  end

  @doc """
  Returns the supported nested runtime-check option keys for the active checks.
  """
  @spec opt_keys(config()) :: list(runtime_check_opt_key())
  def opt_keys(config \\ []) do
    [:enabled | Enum.map(active_checks(config), & &1.option_key())]
  end

  @doc """
  Runs the configured runtime checks against a query.
  """
  @spec validate(operation(), Ecto.Query.t(), runtime_check_opts(), config()) ::
          :ok | {:errors, errors()}
  def validate(operation, %Ecto.Query{} = query, opts \\ [], config \\ []) do
    errors =
      Enum.flat_map(active_checks(config), fn check ->
        case check.validate(operation, query, opts, check_options_for(check, config)) do
          :ok -> []
          {:errors, errors} -> errors
        end
      end)

    case errors do
      [] -> :ok
      errors -> {:errors, errors}
    end
  end

  @doc """
  Repo hook helper that validates the query, strips nested runtime opts, and
  returns the `{query, repo_opts}` tuple expected by `Ecto.Repo.prepare_query/3`.
  """
  @spec prepare_query(operation(), Ecto.Query.t(), Keyword.t(), config()) ::
          {Ecto.Query.t(), Keyword.t()}
  def prepare_query(operation, %Ecto.Query{} = query, opts, config \\ []) do
    runtime_opts = extract_runtime_opts(opts, config)
    repo_opts = Keyword.delete(opts, runtime_opts_key(config))

    if should_run_checks?(runtime_opts, repo_opts, config) do
      case validate(operation, query, runtime_opts, config) do
        :ok ->
          :ok

        {:errors, errors} ->
          raise error_module(config),
            operation: operation,
            errors: errors,
            runtime_opts_key: runtime_opts_key(config)
      end
    end

    {query, repo_opts}
  end

  defp active_checks(config) do
    Keyword.get(config, :checks, @default_checks)
  end

  defp runtime_opts_key(config) do
    Keyword.get(config, :runtime_opts_key, :ecto_query_guard)
  end

  defp error_module(config) do
    Keyword.get(config, :error_module, Error)
  end

  defp should_run_checks?(runtime_opts, repo_opts, config) do
    Keyword.get(config, :enabled, true) and
      Keyword.get(runtime_opts, :enabled, true) and
      Keyword.get(repo_opts, :ecto_query) != :preload
  end

  defp extract_runtime_opts(opts, config) do
    opts
    |> Keyword.get_values(runtime_opts_key(config))
    |> Enum.reduce([], fn runtime_opts, merged_runtime_opts ->
      validate_runtime_opts!(runtime_opts, config)
      Keyword.merge(merged_runtime_opts, runtime_opts)
    end)
  end

  defp validate_runtime_opts!(runtime_opts, config) do
    unless Keyword.keyword?(runtime_opts) do
      raise ArgumentError,
            "expected #{inspect(runtime_opts_key(config))} to be a keyword list, got: #{inspect(runtime_opts)}"
    end

    known_keys = opt_keys(config)

    unknown_keys =
      runtime_opts
      |> Keyword.keys()
      |> Enum.uniq()
      |> Enum.reject(&(&1 in known_keys))

    case unknown_keys do
      [] ->
        :ok

      keys ->
        raise ArgumentError,
              "unknown #{inspect(runtime_opts_key(config))} option(s): #{Enum.map_join(keys, ", ", &inspect/1)}"
    end
  end

  defp check_options_for(check, config) do
    config
    |> Keyword.get(:check_options, [])
    |> Keyword.get(check.option_key(), [])
  end
end
