defmodule EctoQueryValidation.Check do
  @moduledoc """
  Behaviour for individual query runtime checks.

  Checks receive the Ecto repo operation, the fully built `%Ecto.Query{}`,
  runtime opts chosen by the host application, and any host-supplied static
  config for that check.
  """

  alias EctoQueryValidation

  @callback option_key() :: atom()

  @callback validate(
              operation :: EctoQueryValidation.operation(),
              query :: Ecto.Query.t(),
              runtime_opts :: EctoQueryValidation.runtime_check_opts(),
              config :: Keyword.t()
            ) :: :ok | {:errors, EctoQueryValidation.errors()}
end
