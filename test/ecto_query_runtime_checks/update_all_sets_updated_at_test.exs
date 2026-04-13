defmodule EctoQueryRuntimeChecks.UpdateAllSetsUpdatedAtTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias EctoQueryRuntimeChecks.UpdateAllSetsUpdatedAt
  alias TestSupport.Note
  alias TestSupport.Post

  test "fails update_all queries that do not set updated_at" do
    query = from(post in Post, update: [set: [title: "Renamed"]])

    assert {:errors, [message]} = UpdateAllSetsUpdatedAt.validate(:update_all, query, [], [])
    assert message =~ "must set `updated_at`"
  end

  test "allows update_all queries that set updated_at" do
    now = DateTime.utc_now(:microsecond)
    query = from(post in Post, update: [set: [title: "Renamed", updated_at: ^now]])

    assert :ok = UpdateAllSetsUpdatedAt.validate(:update_all, query, [], [])
  end

  test "skips schemas without updated_at" do
    query = from(note in Note, update: [set: [body: "Renamed"]])

    assert :ok = UpdateAllSetsUpdatedAt.validate(:update_all, query, [], [])
  end
end
