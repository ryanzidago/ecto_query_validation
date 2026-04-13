defmodule EctoQueryGuard.Check do
  @moduledoc """
  Behaviour for individual query runtime checks.

  Checks receive the Ecto repo operation, the fully built `%Ecto.Query{}`, the
  nested runtime opts passed by the caller, and any static config supplied by
  the repo integration.
  """

  alias EctoQueryGuard

  @callback option_key() :: atom()

  @callback validate(
              operation :: EctoQueryGuard.operation(),
              query :: Ecto.Query.t(),
              runtime_opts :: EctoQueryGuard.runtime_check_opts(),
              config :: Keyword.t()
            ) :: :ok | {:errors, EctoQueryGuard.errors()}
end
