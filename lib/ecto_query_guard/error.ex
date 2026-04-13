defmodule EctoQueryGuard.Error do
  @moduledoc """
  Raised when an executed query fails one or more runtime validation checks.
  """

  alias EctoQueryGuard

  defexception [:message, :operation, :errors, :runtime_opts_key]

  @type t :: %__MODULE__{
          message: String.t(),
          operation: EctoQueryGuard.operation(),
          errors: EctoQueryGuard.errors(),
          runtime_opts_key: atom()
        }

  @type exception_opt ::
          {:operation, EctoQueryGuard.operation()}
          | {:errors, EctoQueryGuard.errors()}
          | {:runtime_opts_key, atom()}

  @spec exception(list(exception_opt())) :: t()
  def exception(opts) do
    operation = Keyword.fetch!(opts, :operation)
    errors = Keyword.get(opts, :errors, ["runtime query check failed"])
    runtime_opts_key = Keyword.get(opts, :runtime_opts_key, :ecto_query_guard)

    %__MODULE__{
      operation: operation,
      errors: errors,
      runtime_opts_key: runtime_opts_key,
      message: message(operation, errors, runtime_opts_key)
    }
  end

  defp message(operation, errors, runtime_opts_key) do
    details = Enum.map_join(errors, "\n", &"- #{&1}")
    runtime_opts_key = Atom.to_string(runtime_opts_key)

    "Runtime query check failed for #{inspect(operation)}:\n" <>
      "#{details}\n" <>
      "Fix the query, pass `#{runtime_opts_key}: [enabled: false]`, or disable an individual " <>
      "check with `#{runtime_opts_key}: [validate_*: false]`."
  end
end
