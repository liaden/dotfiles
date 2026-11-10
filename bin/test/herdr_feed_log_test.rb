# frozen_string_literal: true

require "minitest/autorun"
load File.expand_path("../herdr-feed-log", __dir__)

class HerdrFeedLogTest < Minitest::Test
  def setup
    @added = []
    @reported = []
  end

  def snapshot(*panes, workspaces: [{ "workspace_id" => "w1", "label" => "PROJ-42" }])
    { "result" => { "snapshot" => { "panes" => panes, "workspaces" => workspaces } } }
  end

  def pane(status, agent: "claude", tokens: {})
    { "pane_id" => "w1:p1", "workspace_id" => "w1", "agent" => agent,
      "agent_status" => status, "cwd" => "/repo", "tokens" => tokens }
  end

  def events_after(before, after)
    HerdrFeedLog.transitions({ "w1:p1" => before }, snapshot(after)).last
  end

  def kinds(events) = events.map { |event| event[:event] }

  def poll(statuses, last_error, read)
    HerdrFeedLog.poll_once(statuses, last_error, read,
                           add: ->(*record) { @added << record },
                           report: ->(message) { @reported << message })
  end

  def down = -> { raise HerdrFeedLog::SnapshotError, "herdr is not running" }

  def test_first_sight_records_nothing
    statuses, events = HerdrFeedLog.transitions({}, snapshot(pane("blocked")))

    assert_equal({ "w1:p1" => "blocked" }, statuses)
    assert_empty events
  end

  def test_becoming_blocked_needs_you
    assert_equal ["needs-you"], kinds(events_after("working", pane("blocked")))
  end

  def test_working_to_idle_or_done_is_finished
    assert_equal ["finished"], kinds(events_after("working", pane("idle")))
    assert_equal ["finished"], kinds(events_after("working", pane("done")))
  end

  def test_blocked_to_idle_between_polls_is_finished
    assert_equal ["finished"], kinds(events_after("blocked", pane("idle")))
    assert_equal ["finished"], kinds(events_after("blocked", pane("done")))
  end

  def test_other_changes_record_nothing
    assert_empty events_after("blocked", pane("working"))
    assert_empty events_after("idle", pane("done"))
  end

  def test_panes_without_an_agent_are_ignored
    statuses, events = HerdrFeedLog.transitions({ "w1:p1" => "working" },
                                                snapshot(pane("idle", agent: nil)))

    assert_equal [{}, []], [statuses, events]
  end

  def test_closed_panes_drop_out
    statuses, = HerdrFeedLog.transitions({ "w1:p9" => "working" }, snapshot(pane("idle")))

    refute_includes statuses, "w1:p9"
  end

  def test_needs_you_record_names_workspace_and_task
    event = events_after("working",
                         pane("blocked", tokens: { "task" => "fix the login bug" })).first

    meta = { event: "needs-you", workspace: "PROJ-42", pane: "w1:p1",
             cwd: "/repo", agent: "claude" }

    assert_equal ["needs you: PROJ-42", "fix the login bug", meta], HerdrFeedLog.record(event)
  end

  def test_finished_record_without_task_has_empty_body
    title, body, meta = HerdrFeedLog.record(events_after("working", pane("done")).first)

    assert_equal ["finished: PROJ-42", "", "finished"], [title, body, meta[:event]]
  end

  def test_unknown_workspace_falls_back_to_its_id
    _, events = HerdrFeedLog.transitions({ "w1:p1" => "working" },
                                         snapshot(pane("blocked"), workspaces: []))

    assert_equal "needs you: w1", HerdrFeedLog.record(events.first).first
  end

  def test_an_outage_is_reported_once
    statuses, last_error, = poll({}, nil, down)
    _, _, wait = poll(statuses, last_error, down)

    assert_equal 1, @reported.size
    assert_equal HerdrFeedLog::RETRY_SECONDS, wait
  end

  def test_recovery_clears_the_error_and_records_events
    statuses, last_error, = poll({ "w1:p1" => "working" }, "herdr is not running",
                                 -> { snapshot(pane("blocked")) })

    assert_nil last_error
    assert_equal({ "w1:p1" => "blocked" }, statuses)
    assert_equal ["needs you: PROJ-42"], @added.map(&:first)
  end

  def test_an_outage_forgets_statuses
    statuses, = poll({ "w1:p1" => "working" }, nil, down)

    assert_empty statuses
  end
end
