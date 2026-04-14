defmodule EctoQueryValidation.Check do
  @moduledoc """
  Behaviour for individual query runtime checks.

  Checks receive the Ecto repo operation, the fully built `%Ecto.Query{}`,
  host-supplied static config, and runtime opts chosen by the host
  application.
  """

  alias EctoQueryValidation

  @callback option_key() :: atom()

  @callback validate(
              operation :: EctoQueryValidation.operation(),
              query :: Ecto.Query.t(),
              config :: Keyword.t(),
              runtime_opts :: EctoQueryValidation.runtime_check_opts()
            ) :: :ok | {:errors, EctoQueryValidation.errors()}
end
