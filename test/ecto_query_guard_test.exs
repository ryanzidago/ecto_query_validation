defmodule EctoQueryGuardTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias EctoQueryGuard
  alias EctoQueryGuard.Error
  alias EctoQueryGuard.NamedJoinBindings
  alias TestSupport.Post

  describe "opt_keys/1" do
    test "returns keys for the configured checks" do
      assert EctoQueryGuard.opt_keys(checks: [NamedJoinBindings]) == [
               :enabled,
               :validate_named_bindings
             ]
    end
  end

  describe "prepare_query/4" do
    test "strips nested runtime opts from repo opts" do
      query = from(post in Post, as: :post)

      assert {^query, [timeout: 15_000]} =
               EctoQueryGuard.prepare_query(
                 :all,
                 query,
                 [timeout: 15_000, ecto_query_guard: [enabled: false]],
                 checks: [NamedJoinBindings]
               )
    end

    test "merges repeated nested runtime opts" do
      query =
        Post
        |> from(as: :post)
        |> join(:inner, [post: post], other in Post, on: other.id == post.id)

      assert {^query, []} =
               EctoQueryGuard.prepare_query(
                 :all,
                 query,
                 [
                   ecto_query_guard: [validate_named_bindings: true],
                   ecto_query_guard: [enabled: false]
                 ],
                 checks: [NamedJoinBindings]
               )
    end

    test "raises a runtime check error when validation fails" do
      query = join(Post, :inner, [post], other in Post, on: other.id == post.id)

      assert_raise Error, ~r/Runtime query check failed for :all/, fn ->
        EctoQueryGuard.prepare_query(
          :all,
          query,
          [],
          checks: [NamedJoinBindings]
        )
      end
    end

    test "skips checks for preload-generated internal queries" do
      query = join(Post, :inner, [post], other in Post, on: other.id == post.id)

      assert {^query, [ecto_query: :preload]} =
               EctoQueryGuard.prepare_query(
                 :all,
                 query,
                 [ecto_query: :preload],
                 checks: [NamedJoinBindings]
               )
    end

    test "raises on malformed nested runtime opts" do
      query = from(post in Post, as: :post)

      assert_raise ArgumentError,
                   ~r/expected :ecto_query_guard to be a keyword list/,
                   fn ->
                     EctoQueryGuard.prepare_query(
                       :all,
                       query,
                       [ecto_query_guard: :invalid],
                       checks: [NamedJoinBindings]
                     )
                   end
    end

    test "raises on unknown nested runtime opts" do
      query = from(post in Post, as: :post)

      assert_raise ArgumentError, ~r/unknown :ecto_query_guard option/, fn ->
        EctoQueryGuard.prepare_query(
          :all,
          query,
          [ecto_query_guard: [unknown: true]],
          checks: [NamedJoinBindings]
        )
      end
    end

    test "supports a custom nested runtime opt key" do
      query = from(post in Post, as: :post)

      assert {^query, []} =
               EctoQueryGuard.prepare_query(
                 :all,
                 query,
                 [runtime_checks: [enabled: false]],
                 checks: [NamedJoinBindings],
                 runtime_opts_key: :runtime_checks
               )
    end
  end
end
