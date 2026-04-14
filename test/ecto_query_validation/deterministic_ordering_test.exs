defmodule EctoQueryValidation.DeterministicOrderingTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias EctoQueryValidation.DeterministicOrdering
  alias TestSupport.Post

  test "fails limit(1) queries that do not order by the root primary key" do
    query =
      Post
      |> order_by([post], asc: post.inserted_at)
      |> limit(1)

    assert {:errors, [message]} = DeterministicOrdering.validate(:all, query, [], [])
    assert message =~ "must include root primary key field(s) `id`"
  end

  test "allows deterministic limit(1) queries" do
    query =
      Post
      |> order_by([post], asc: post.inserted_at, asc: post.id)
      |> limit(1)

    assert :ok = DeterministicOrdering.validate(:all, query, [], [])
  end

  test "can be enabled explicitly for non-limit reads" do
    query = order_by(Post, [post], asc: post.inserted_at)

    assert {:errors, [message]} =
             DeterministicOrdering.validate(
               :all,
               query,
               [],
               validate_deterministic_ordering: true
             )

    assert message =~ "validate_deterministic_ordering: true"
  end
end
