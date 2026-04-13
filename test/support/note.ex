defmodule TestSupport.Note do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "notes" do
    field(:body, :string)
  end
end
