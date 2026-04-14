defmodule EctoQueryValidation.ImmutableUpdateFieldsTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias EctoQueryValidation.ImmutableUpdateFields
  alias TestSupport.Post

  test "fails updates to default immutable fields" do
    now = DateTime.utc_now(:microsecond)
    query = from(post in Post, update: [set: [inserted_at: ^now]])

    assert {:errors, [message]} = ImmutableUpdateFields.validate(:update_all, query, [], [])
    assert message =~ "must not update immutable field `inserted_at`"
  end

  test "supports repo-level custom immutable fields" do
    query = from(post in Post, update: [set: [tenant_id: "tenant-1"]])

    assert {:errors, [message]} =
             ImmutableUpdateFields.validate(
               :update_all,
               query,
               [fields: [:id, :inserted_at, :tenant_id]],
               []
             )

    assert message =~ "must not update immutable field `tenant_id`"
  end

  test "respects validate_immutable_update_fields: false" do
    now = DateTime.utc_now(:microsecond)
    query = from(post in Post, update: [set: [inserted_at: ^now]])

    assert :ok =
             ImmutableUpdateFields.validate(
               :update_all,
               query,
               [],
               validate_immutable_update_fields: false
             )
  end
end
