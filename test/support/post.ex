defmodule TestSupport.Post do
  use Ecto.Schema

  schema "posts" do
    field(:title, :string)
    field(:tenant_id, :string)
    field(:workspace_id, :string)
    timestamps()
  end
end
