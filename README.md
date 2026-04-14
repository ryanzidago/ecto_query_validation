# Ecto Query Validation

`ecto_query_validation` extracts the Repo-level runtime query validation work
from Docklane PRs `#174` and `#175` into a standalone Hex package.

The package gives you:

- `EctoQueryValidation.Check`, the behaviour for runtime checks
- built-in checks for named join bindings, `update_all` timestamp updates, deterministic ordering, immutable update fields, and required filter fields
- no package-owned repo helper, config loader, or error policy

## Installation

Add the dependency to `mix.exs`:

```elixir
def deps do
  [
    {:ecto_query_validation, "~> 0.1.0"}
  ]
end
```

## Repo integration

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres

  @impl Ecto.Repo
  def prepare_query(operation, query, opts) do
    runtime_opts = Keyword.get(opts, :ecto_query_validation, [])

    checks = [
      {EctoQueryValidation.NamedJoinBindings, []},
      {EctoQueryValidation.RequiredFilterFields, fields: [:tenant_id]},
      {EctoQueryValidation.ImmutableUpdateFields, fields: [:id, :inserted_at, :tenant_id]}
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
end
```

`ecto_query_validation: [...]` is just a suggested host-app runtime opt key. The
package does not require that exact opt shape.

Per-query opt-outs can still look like this if the host app chooses:

```elixir
Repo.all(query, ecto_query_validation: [enabled: false])
Repo.one(query, ecto_query_validation: [validate_named_bindings: false])
```

## Built-in checks

- `EctoQueryValidation.NamedJoinBindings`
- `EctoQueryValidation.RequiredFilterFields`
- `EctoQueryValidation.UpdateAllSetsUpdatedAt`
- `EctoQueryValidation.DeterministicOrdering`
- `EctoQueryValidation.ImmutableUpdateFields`

## Local tooling

The repo includes Docklane-style local setup:

- `mise.toml` exports `CODEX_HOME` and `CLAUDE_CONFIG_DIR`
- `.miserc.toml` sets the default mise profile
- `.envrc.example` shows the equivalent shell exports
- `.gitignore` ignores local Codex, Claude, and worktree state

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ecto_query_validation>.
