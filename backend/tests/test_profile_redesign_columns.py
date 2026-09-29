"""Redesign profile columns: ``skin``, ``notify_enabled``, ``onboarding_step``,
``daily_goal_minutes`` (backend-00).

The skin follows the profile (stack-decision §2.4), so ``PATCH /profiles/{id}``
and every profile payload carry the four fields. Explicit ``null`` resets a
nullable field; an omitted field changes nothing. ``notify_enabled`` is the
per-profile master switch the update sweep honours.
"""

from __future__ import annotations

import json

import pytest

from database.models import FollowedSeries, ReadingProfile, UpdateNotification
from services import browse_service
from services.update_service import UpdateService


@pytest.fixture
def owner(make_user, make_profile, as_user):
    user = make_user("skinner")
    profile = make_profile(user.id, "Main")
    return user, profile, as_user(user.id, profile.id)


def _patch(client, headers, profile_id, body):
    return client.patch(f"/profiles/{profile_id}", json=body, headers=headers)


def _listed(client, headers, profile_id):
    rows = client.get("/profiles", headers=headers).json()
    return next(r for r in rows if r["id"] == profile_id)


def test_patch_skin_glass_round_trips(client, owner):
    _user, profile, headers = owner
    res = _patch(client, headers, profile.id, {"skin": "glass"})
    assert res.status_code == 200, res.text
    assert res.json()["skin"] == "glass"
    assert _listed(client, headers, profile.id)["skin"] == "glass"


def test_unknown_skin_is_422_and_changes_nothing(client, owner):
    _user, profile, headers = owner
    _patch(client, headers, profile.id, {"skin": "cinematic"})
    res = _patch(client, headers, profile.id, {"skin": "neon"})
    assert res.status_code == 422
    assert _listed(client, headers, profile.id)["skin"] == "cinematic"


def test_null_resets_skin_and_omitted_leaves_it(client, owner):
    _user, profile, headers = owner
    _patch(client, headers, profile.id, {"skin": "glass"})
    res = _patch(client, headers, profile.id, {})
    assert res.status_code == 200
    assert res.json()["skin"] == "glass"
    res = _patch(client, headers, profile.id, {"skin": None})
    assert res.status_code == 200
    assert res.json()["skin"] is None


def test_other_accounts_profile_is_404(client, make_user, make_profile, as_user, db_session):
    alice = make_user("alice")
    bob = make_user("bob")
    a_profile = make_profile(alice.id, "A")
    b_profile = make_profile(bob.id, "B")
    res = _patch(client, as_user(alice.id, a_profile.id), b_profile.id, {"skin": "glass"})
    assert res.status_code == 404
    assert res.json()["code"] == "profile_not_found"
    db_session.expire_all()
    assert db_session.get(ReadingProfile, b_profile.id).skin is None


def test_onboarding_step_values(client, owner):
    _user, profile, headers = owner
    res = _patch(client, headers, profile.id, {"onboarding_step": 3})
    assert res.status_code == 200
    assert res.json()["onboarding_step"] == 3
    assert _listed(client, headers, profile.id)["onboarding_step"] == 3
    res = _patch(client, headers, profile.id, {"onboarding_step": "done"})
    assert res.json()["onboarding_step"] == "done"
    assert _patch(client, headers, profile.id, {"onboarding_step": 8}).status_code == 422
    assert _patch(client, headers, profile.id, {"onboarding_step": "skip"}).status_code == 422
    res = _patch(client, headers, profile.id, {"onboarding_step": None})
    assert res.json()["onboarding_step"] is None

    created = client.post("/profiles", json={"name": "Fresh"}, headers=headers)
    assert created.status_code == 201, created.text
    body = created.json()
    assert body["onboarding_step"] is None
    assert body["skin"] is None
    assert body["daily_goal_minutes"] is None


def test_daily_goal_minutes(client, owner):
    _user, profile, headers = owner
    res = _patch(client, headers, profile.id, {"daily_goal_minutes": 15})
    assert res.status_code == 200
    assert res.json()["daily_goal_minutes"] == 15
    res = _patch(client, headers, profile.id, {"daily_goal_minutes": None})
    assert res.json()["daily_goal_minutes"] is None
    assert _patch(client, headers, profile.id, {"daily_goal_minutes": 12}).status_code == 422


def test_notify_enabled_defaults_true_and_can_be_switched_off(client, owner):
    _user, profile, headers = owner
    assert _listed(client, headers, profile.id)["notify_enabled"] is True
    res = _patch(client, headers, profile.id, {"notify_enabled": False})
    assert res.status_code == 200
    assert res.json()["notify_enabled"] is False
    assert _listed(client, headers, profile.id)["notify_enabled"] is False
    # null is "not sent" for the non-nullable switch
    res = _patch(client, headers, profile.id, {"notify_enabled": None})
    assert res.json()["notify_enabled"] is False


def test_sweep_honours_profile_notify_enabled(
    db_session, make_user, make_profile, seed_follow, monkeypatch
):
    monkeypatch.setattr(
        browse_service.BrowseService,
        "get_chapters",
        lambda self, source_id, series_key: [  # noqa: ARG005
            {"id": "c1", "number": 1.0, "title": "Chapter 1"},
            {"id": "c2", "number": 2.0, "title": "Chapter 2"},
        ],
    )
    user = make_user("household")
    loud = make_profile(user.id, "Loud")
    quiet = make_profile(user.id, "Quiet", sort_order=1)
    quiet.notify_enabled = False
    db_session.commit()

    known = json.dumps([{"key": "c1", "number": 1.0, "title": "Chapter 1"}])
    rows = {
        p.id: seed_follow(
            user.id, p.id, series_key="shared", known_chapters=known, notify=True
        )
        for p in (loud, quiet)
    }

    UpdateService(db_session).run_check(trigger="manual")

    by_profile = {
        p.id: db_session.query(UpdateNotification)
        .filter(UpdateNotification.profile_id == p.id)
        .count()
        for p in (loud, quiet)
    }
    assert by_profile == {loud.id: 1, quiet.id: 0}
    quiet_row = db_session.get(FollowedSeries, rows[quiet.id].id)
    db_session.refresh(quiet_row)
    assert [c["key"] for c in json.loads(quiet_row.known_chapters)] == ["c1", "c2"]
