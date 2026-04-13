defmodule EctoQueryRuntimeChecks.RequiredFilterFieldsTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias EctoQueryRuntimeChecks.RequiredFilterFields
  alias TestSupport.Post

  test "fails when configured root fields are not filtered" do
    query = from(post in Post)

    assert {:errors, errors} =
             RequiredFilterFields.validate(
               :all,
               query,
               [],
               fields: [:tenant_id, :workspace_id]
             )

    assert errors == [
             "query for TestSupport.Post must filter root field `tenant_id`",
             "query for TestSupport.Post must filter root field `workspace_id`"
           ]
  end

  test "allows queries that filter every configured field" do
    query =
      from(
        post in Post,
        where:
          post.tenant_id == ^"tenant-1" and
            post.workspace_id == ^"workspace-1"
      )

    assert :ok =
             RequiredFilterFields.validate(
               :all,
               query,
               [],
               fields: [:tenant_id, :workspace_id]
             )
  end

  test "respects validate_required_filter_fields: false" do
    query = from(post in Post)

    assert :ok =
             RequiredFilterFields.validate(
               :all,
               query,
               [validate_required_filter_fields: false],
               fields: [:tenant_id]
             )
  end
end
