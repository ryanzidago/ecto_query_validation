defmodule EctoQueryValidation.NamedJoinBindingsTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias EctoQueryValidation.NamedJoinBindings
  alias TestSupport.Post

  test "returns both root and join errors for unnamed joined queries" do
    query = join(Post, :inner, [post], other in Post, on: other.id == post.id)

    assert {:errors,
            [
              "root source is missing `from(as: ...)`",
              "join #1 is missing `join(..., as: ...)`"
            ]} = NamedJoinBindings.validate(:all, query, [], [])
  end

  test "returns ok for fully named joins" do
    query =
      Post
      |> from(as: :post)
      |> join(:inner, [post: post], other in Post, as: :other, on: other.id == post.id)

    assert :ok = NamedJoinBindings.validate(:all, query, [], [])
  end

  test "respects validate_named_bindings: false" do
    query = join(Post, :inner, [post], other in Post, on: other.id == post.id)

    assert :ok =
             NamedJoinBindings.validate(
               :all,
               query,
               [],
               validate_named_bindings: false
             )
  end
end
