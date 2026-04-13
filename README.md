# Ecto Query Runtime Checks

`ecto_query_guard` extracts the Repo-level runtime query validation work
from Docklane PRs `#174` and `#175` into a standalone Hex package.

The package gives you:

- a reusable `EctoQueryGuard.prepare_query/4` helper for `Repo.prepare_query/3`
- built-in checks for named join bindings, `update_all` timestamp updates, deterministic ordering, immutable update fields, and required filter fields
- nested per-query opts under `:ecto_query_guard`
- a small extension point for custom checks

## Installation

Add the dependency to `mix.exs`:

```elixir
def deps do
  [
    {:ecto_query_guard, "~> 0.1.0"}
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
    EctoQueryGuard.prepare_query(
      operation,
      query,
      opts,
      enabled: Application.get_env(:my_app, :ecto_query_guard, [])[:enabled] == true,
      check_options: [
        validate_required_filter_fields: [fields: [:tenant_id]],
        validate_immutable_update_fields: [fields: [:id, :inserted_at, :tenant_id]]
      ]
    )
  end
end
```

Per-query opt-outs stay nested:

```elixir
Repo.all(query, ecto_query_guard: [enabled: false])
Repo.one(query, ecto_query_guard: [validate_named_bindings: false])
```

## Built-in checks

- `EctoQueryGuard.NamedJoinBindings`
- `EctoQueryGuard.RequiredFilterFields`
- `EctoQueryGuard.UpdateAllSetsUpdatedAt`
- `EctoQueryGuard.DeterministicOrdering`
- `EctoQueryGuard.ImmutableUpdateFields`

## Local tooling

The repo includes Docklane-style local setup:

- `mise.toml` exports `CODEX_HOME` and `CLAUDE_CONFIG_DIR`
- `.miserc.toml` sets the default mise profile
- `.envrc.example` shows the equivalent shell exports
- `.gitignore` ignores local Codex, Claude, and worktree state

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ecto_query_guard>.
