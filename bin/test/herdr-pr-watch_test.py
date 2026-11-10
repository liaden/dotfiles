import importlib.machinery
import importlib.util
import pathlib
import unittest

path = pathlib.Path(__file__).resolve().parent.parent / "herdr-pr-watch"
loader = importlib.machinery.SourceFileLoader("herdr_pr_watch", str(path))
spec = importlib.util.spec_from_loader("herdr_pr_watch", loader)
watch = importlib.util.module_from_spec(spec)
loader.exec_module(watch)


def snapshot(*workspaces, panes=None):
    return {"result": {"snapshot": {
        "workspaces": list(workspaces),
        "panes": panes if panes is not None else [
            {"pane_id": "w1:p1", "workspace_id": "w1", "cwd": "/old", "foreground_cwd": "/repo"},
            {"pane_id": "w2:p1", "workspace_id": "w2", "cwd": "/other"},
        ],
    }}}


PARKED = {"workspace_id": "w1", "label": "PROJ-42", "tokens": {"parked": "waiting on review"}}
ACTIVE = {"workspace_id": "w2", "label": "PROJ-7", "tokens": {}}


def pr(state="OPEN", review="REVIEW_REQUIRED", checks=(), reviews=0, number=12):
    return {"number": number, "state": state, "reviewDecision": review, "url": "https://pr/12",
            "statusCheckRollup": list(checks), "latestReviews": [{"state": "COMMENTED"}] * reviews}


def run(status="COMPLETED", conclusion="SUCCESS"):
    return {"__typename": "CheckRun", "status": status, "conclusion": conclusion}


def context(state):
    return {"__typename": "StatusContext", "state": state}


class ParkedWorkspaces(unittest.TestCase):
    def test_only_parked_workspaces_with_their_pane_folder(self):
        self.assertEqual(watch.parked_workspaces(snapshot(PARKED, ACTIVE)), [
            {"id": "w1", "label": "PROJ-42", "cwd": "/repo", "note": "waiting on review"}])

    def test_parked_workspace_without_panes_is_skipped(self):
        self.assertEqual(watch.parked_workspaces(snapshot(PARKED, panes=[])), [])


class Summarize(unittest.TestCase):
    def ci(self, *checks):
        return watch.summarize(pr(checks=checks))["ci"]

    def test_ci_states(self):
        self.assertEqual(self.ci(), "none")
        self.assertEqual(self.ci(run(), run(conclusion="SKIPPED")), "passed")
        self.assertEqual(self.ci(run(), run(status="IN_PROGRESS", conclusion="")), "running")
        self.assertEqual(self.ci(run(), context("PENDING")), "running")
        self.assertEqual(self.ci(run(), run(conclusion="FAILURE")), "failed")
        self.assertEqual(self.ci(run(), context("ERROR")), "failed")
        self.assertEqual(self.ci(run(conclusion="TIMED_OUT"), run(status="QUEUED", conclusion="")), "failed")

    def test_review_state_and_counts(self):
        summary = watch.summarize(pr(review="APPROVED", reviews=2))
        self.assertEqual((summary["review"], summary["reviews"], summary["state"], summary["number"]),
                         ("APPROVED", 2, "OPEN", 12))


class Changes(unittest.TestCase):
    def changes(self, before, after):
        return watch.changes(before and watch.summarize(before), watch.summarize(after))

    def test_first_sight_reports_nothing(self):
        self.assertEqual(self.changes(None, pr(review="APPROVED")), [])

    def test_approval_and_changes_requested_notify(self):
        self.assertEqual(self.changes(pr(), pr(review="APPROVED")), [("approved", True)])
        self.assertEqual(self.changes(pr(), pr(review="CHANGES_REQUESTED")),
                         [("changes requested", True)])

    def test_a_new_review_without_a_decision_notifies(self):
        self.assertEqual(self.changes(pr(reviews=1), pr(reviews=2)), [("new review", True)])

    def test_ci_failure_notifies_and_success_only_logs(self):
        self.assertEqual(self.changes(pr(checks=[run("IN_PROGRESS", "")]),
                                      pr(checks=[run(conclusion="FAILURE")])), [("CI failed", True)])
        self.assertEqual(self.changes(pr(checks=[run("IN_PROGRESS", "")]), pr(checks=[run()])),
                         [("CI passed", False)])

    def test_merge_only_logs(self):
        self.assertEqual(self.changes(pr(), pr(state="MERGED")), [("merged", False)])

    def test_nothing_changed(self):
        self.assertEqual(self.changes(pr(checks=[run()]), pr(checks=[run()])), [])


class Token(unittest.TestCase):
    def test_token_text(self):
        self.assertEqual(watch.token(watch.summarize(pr(checks=[run("QUEUED", "")]))),
                         "PR #12: awaiting review, CI running")
        self.assertEqual(watch.token(watch.summarize(pr(review="APPROVED", checks=[run()]))),
                         "PR #12: approved, CI passed")
        self.assertEqual(watch.token(watch.summarize(pr(review="", checks=[]))), "PR #12")
        self.assertEqual(watch.token(watch.summarize(pr(state="MERGED"))), "PR #12: merged")


class Plan(unittest.TestCase):
    def test_actions_for_a_changed_parked_workspace(self):
        state = {"/repo": watch.summarize(pr())}
        new_state, actions = watch.plan(snapshot(PARKED, ACTIVE), state,
                                        lambda cwd: pr(review="CHANGES_REQUESTED"))
        self.assertEqual(new_state, {"/repo": watch.summarize(pr(review="CHANGES_REQUESTED"))})
        self.assertEqual(actions, [
            {"kind": "token", "workspace": "w1", "text": "PR #12: changes requested"},
            {"kind": "feed", "title": "PROJ-42: changes requested", "body": "waiting on review",
             "meta": {"event": "pr", "workspace": "PROJ-42", "cwd": "/repo", "url": "https://pr/12"}},
            {"kind": "notify", "title": "PROJ-42: changes requested", "body": "https://pr/12"},
        ])

    def test_no_pr_means_no_actions_and_no_state(self):
        new_state, actions = watch.plan(snapshot(PARKED), {}, lambda cwd: None)
        self.assertEqual((new_state, actions), ({}, []))

    def test_unparked_workspaces_drop_out_of_state(self):
        new_state, _ = watch.plan(snapshot(ACTIVE), {"/repo": watch.summarize(pr())}, lambda cwd: pr())
        self.assertEqual(new_state, {})


if __name__ == "__main__":
    unittest.main()
