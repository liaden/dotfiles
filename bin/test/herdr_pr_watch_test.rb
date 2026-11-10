# frozen_string_literal: true

require "minitest/autorun"
load File.expand_path("../herdr-pr-watch", __dir__)

class HerdrPrWatchTest < Minitest::Test
  PARKED = { "workspace_id" => "w1", "label" => "PROJ-42",
             "tokens" => { "parked" => "waiting on review" } }.freeze
  ACTIVE = { "workspace_id" => "w2", "label" => "PROJ-7", "tokens" => {} }.freeze
  PANES = [
    { "pane_id" => "w1:p1", "workspace_id" => "w1", "cwd" => "/old", "foreground_cwd" => "/repo" },
    { "pane_id" => "w2:p1", "workspace_id" => "w2", "cwd" => "/other" }
  ].freeze
  RUNNING = { "__typename" => "CheckRun", "status" => "IN_PROGRESS", "conclusion" => "" }.freeze
  QUEUED = { "__typename" => "CheckRun", "status" => "QUEUED", "conclusion" => "" }.freeze

  def snapshot(*workspaces, panes: PANES)
    { "result" => { "snapshot" => { "workspaces" => workspaces, "panes" => panes } } }
  end

  def pr(state: "OPEN", review: "REVIEW_REQUIRED", checks: [], reviews: 0)
    { "number" => 12, "state" => state, "reviewDecision" => review, "url" => "https://pr/12",
      "statusCheckRollup" => checks, "latestReviews" => [{ "state" => "COMMENTED" }] * reviews }
  end

  def finished(conclusion = "SUCCESS")
    { "__typename" => "CheckRun", "status" => "COMPLETED", "conclusion" => conclusion }
  end

  def context(state) = { "__typename" => "StatusContext", "state" => state }
  def summary(...) = HerdrPrWatch.summarize(pr(...))
  def ci(*checks) = summary(checks:)[:ci]
  def changes(before, after) = HerdrPrWatch.changes(before, after)
  def token(...) = HerdrPrWatch.token(summary(...))

  def test_only_parked_workspaces_with_their_pane_folder
    assert_equal [{ id: "w1", label: "PROJ-42", cwd: "/repo", note: "waiting on review" }],
                 HerdrPrWatch.parked_workspaces(snapshot(PARKED, ACTIVE))
  end

  def test_parked_workspace_without_panes_is_skipped
    assert_empty HerdrPrWatch.parked_workspaces(snapshot(PARKED, panes: []))
  end

  def test_ci_states
    assert_equal "none", ci
    assert_equal "passed", ci(finished, finished("SKIPPED"))
    assert_equal "running", ci(finished, RUNNING)
    assert_equal "running", ci(finished, context("PENDING"))
    assert_equal "failed", ci(finished, finished("FAILURE"))
    assert_equal "failed", ci(finished, context("ERROR"))
    assert_equal "failed", ci(finished("TIMED_OUT"), QUEUED)
  end

  def test_review_state_and_counts
    assert_equal ["APPROVED", 2, "OPEN", 12],
                 summary(review: "APPROVED", reviews: 2).values_at(:review, :reviews, :state,
                                                                   :number)
  end

  def test_first_sight_reports_nothing
    assert_empty changes(nil, summary(review: "APPROVED"))
  end

  def test_approval_and_changes_requested_notify
    assert_equal [["approved", true]], changes(summary, summary(review: "APPROVED"))
    assert_equal [["changes requested", true]],
                 changes(summary, summary(review: "CHANGES_REQUESTED"))
  end

  def test_a_new_review_without_a_decision_notifies
    assert_equal [["new review", true]], changes(summary(reviews: 1), summary(reviews: 2))
  end

  def test_ci_failure_notifies_and_success_only_logs
    running = summary(checks: [RUNNING])

    assert_equal [["CI failed", true]], changes(running, summary(checks: [finished("FAILURE")]))
    assert_equal [["CI passed", false]], changes(running, summary(checks: [finished]))
  end

  def test_merge_only_logs
    assert_equal [["merged", false]], changes(summary, summary(state: "MERGED"))
  end

  def test_nothing_changed
    assert_empty changes(summary(checks: [finished]), summary(checks: [finished]))
  end

  def test_token_text
    assert_equal "PR #12: awaiting review, CI running", token(checks: [QUEUED])
    assert_equal "PR #12: approved, CI passed", token(review: "APPROVED", checks: [finished])
    assert_equal "PR #12", token(review: "")
    assert_equal "PR #12: merged", token(state: "MERGED")
  end

  def test_actions_for_a_changed_parked_workspace
    new_state, actions = HerdrPrWatch.plan(snapshot(PARKED, ACTIVE), { "/repo" => summary },
                                           ->(_cwd) { pr(review: "CHANGES_REQUESTED") })

    assert_equal({ "/repo" => summary(review: "CHANGES_REQUESTED") }, new_state)
    assert_equal [
      { kind: :token, workspace: "w1", text: "PR #12: changes requested" },
      { kind: :feed, title: "PROJ-42: changes requested", body: "waiting on review",
        meta: { event: "pr", workspace: "PROJ-42", cwd: "/repo", url: "https://pr/12" } },
      { kind: :notify, title: "PROJ-42: changes requested", body: "https://pr/12" }
    ], actions
  end

  def test_no_pr_means_no_actions_and_no_state
    assert_equal [{}, []], HerdrPrWatch.plan(snapshot(PARKED), {}, ->(_cwd) {})
  end

  def test_unparked_workspaces_drop_out_of_state
    new_state, = HerdrPrWatch.plan(snapshot(ACTIVE), { "/repo" => summary }, ->(_cwd) { pr })

    assert_empty new_state
  end

  def test_saved_state_round_trips_through_json
    saved = HerdrPrWatch.load_state(JSON.parse(JSON.generate({ "/repo" => summary })))
    _, actions = HerdrPrWatch.plan(snapshot(PARKED), saved, ->(_cwd) { pr })

    assert_equal([:token], actions.map { |action| action[:kind] })
  end
end
