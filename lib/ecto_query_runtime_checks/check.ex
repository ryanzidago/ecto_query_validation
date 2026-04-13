defmodule EctoQueryRuntimeChecks.Check do
  @moduledoc """
  Behaviour for individual query runtime checks.

  Checks receive the Ecto repo operation, the fully built `%Ecto.Query{}`, the
  nested runtime opts passed by the caller, and any static config supplied by
  the repo integration.
  """

  alias EctoQueryRuntimeChecks

  @callback option_key() :: atom()

  @callback validate(
              operation :: EctoQueryRuntimeChecks.operation(),
              query :: Ecto.Query.t(),
              runtime_opts :: EctoQueryRuntimeChecks.runtime_check_opts(),
              config :: Keyword.t()
            ) :: :ok | {:errors, EctoQueryRuntimeChecks.errors()}
end
