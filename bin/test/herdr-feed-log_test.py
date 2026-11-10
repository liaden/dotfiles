import importlib.machinery
import importlib.util
import pathlib
import unittest

path = pathlib.Path(__file__).resolve().parent.parent / "herdr-feed-log"
loader = importlib.machinery.SourceFileLoader("herdr_feed_log", str(path))
spec = importlib.util.spec_from_loader("herdr_feed_log", loader)
feed_log = importlib.util.module_from_spec(spec)
loader.exec_module(feed_log)


def snapshot(*panes, workspaces=({"workspace_id": "w1", "label": "PROJ-42"},)):
    return {"result": {"snapshot": {"panes": list(panes), "workspaces": list(workspaces)}}}


def pane(status, pane_id="w1:p1", agent="claude", tokens=None):
    return {"pane_id": pane_id, "workspace_id": "w1", "agent": agent,
            "agent_status": status, "cwd": "/repo", "tokens": tokens or {}}


class Transitions(unittest.TestCase):
    def test_first_sight_records_nothing(self):
        statuses, events = feed_log.transitions({}, snapshot(pane("blocked")))
        self.assertEqual(statuses, {"w1:p1": "blocked"})
        self.assertEqual(events, [])

    def test_becoming_blocked_needs_you(self):
        _, events = feed_log.transitions({"w1:p1": "working"}, snapshot(pane("blocked")))
        self.assertEqual([e["event"] for e in events], ["needs-you"])

    def test_working_to_idle_or_done_is_finished(self):
        for status in ("idle", "done"):
            _, events = feed_log.transitions({"w1:p1": "working"}, snapshot(pane(status)))
            self.assertEqual([e["event"] for e in events], ["finished"], status)

    def test_blocked_to_working_records_nothing(self):
        _, events = feed_log.transitions({"w1:p1": "blocked"}, snapshot(pane("working")))
        self.assertEqual(events, [])

    def test_idle_to_done_records_nothing(self):
        _, events = feed_log.transitions({"w1:p1": "idle"}, snapshot(pane("done")))
        self.assertEqual(events, [])

    def test_panes_without_an_agent_are_ignored(self):
        statuses, events = feed_log.transitions(
            {"w1:p1": "working"}, snapshot(pane("idle", agent=None)))
        self.assertEqual((statuses, events), ({}, []))

    def test_closed_panes_drop_out(self):
        statuses, _ = feed_log.transitions({"w1:p9": "working"}, snapshot(pane("idle")))
        self.assertNotIn("w1:p9", statuses)


class Record(unittest.TestCase):
    def test_needs_you_record_names_workspace_and_task(self):
        snap = snapshot(pane("blocked", tokens={"task": "fix the login bug"}))
        _, events = feed_log.transitions({"w1:p1": "working"}, snap)
        self.assertEqual(feed_log.record(events[0]), (
            "needs you: PROJ-42",
            "fix the login bug",
            {"event": "needs-you", "workspace": "PROJ-42", "pane": "w1:p1",
             "cwd": "/repo", "agent": "claude"},
        ))

    def test_finished_record_without_task_has_empty_body(self):
        _, events = feed_log.transitions({"w1:p1": "working"}, snapshot(pane("done")))
        title, body, meta = feed_log.record(events[0])
        self.assertEqual((title, body, meta["event"]), ("finished: PROJ-42", "", "finished"))

    def test_unknown_workspace_falls_back_to_its_id(self):
        snap = snapshot(pane("blocked"), workspaces=())
        _, events = feed_log.transitions({"w1:p1": "working"}, snap)
        self.assertEqual(feed_log.record(events[0])[0], "needs you: w1")


class PollOnce(unittest.TestCase):
    def setUp(self):
        self.added, self.reported = [], []

    def poll(self, statuses, last_error, read):
        return feed_log.poll_once(statuses, last_error, read,
                                  lambda *r: self.added.append(r), self.reported.append)

    @staticmethod
    def down():
        raise OSError("herdr is not running")

    def test_an_outage_is_reported_once(self):
        statuses, last_error, _ = self.poll({}, None, self.down)
        statuses, last_error, wait = self.poll(statuses, last_error, self.down)
        self.assertEqual(len(self.reported), 1)
        self.assertEqual(wait, feed_log.RETRY_SECONDS)

    def test_recovery_clears_the_error_and_records_events(self):
        statuses, last_error, _ = self.poll({"w1:p1": "working"}, "herdr is not running",
                                            lambda: snapshot(pane("blocked")))
        self.assertIsNone(last_error)
        self.assertEqual(statuses, {"w1:p1": "blocked"})
        self.assertEqual([r[0] for r in self.added], ["needs you: PROJ-42"])

    def test_an_outage_forgets_statuses(self):
        statuses, _, _ = self.poll({"w1:p1": "working"}, None, self.down)
        self.assertEqual(statuses, {})


if __name__ == "__main__":
    unittest.main()
