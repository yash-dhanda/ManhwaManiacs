"""``GET /ai/recap`` and ``GET /ai/recap/availability`` (backend/05 G)."""

from __future__ import annotations

import json

import pytest

from database.models import AiResultCache, NovelChapterCache, NovelSeriesCast
from services import recap_service
from tests import _ai_stubs
from tests._ai_stubs import MATURE, NOVEL, SRC, seed_series, sse_events

PROSE = {
    "paragraphs": [
        "The hero woke in the past and knew what would come next for the city.",
        "He warned the guild but nobody listened to the boy from the future at all.",
        "A rival appeared at the gate and the two circled each other warily today.",
        "By nightfall the walls held and the hero finally slept for the first time.",
    ],
    "cast": [{"name": "Kim", "note": "the regressor"}],
}
DECK = {
    "left_off": "The walls held. The hero finally rested.",
    "happened": ["He woke in the past.", "He warned the guild.", "A rival came.", "The walls held."],
    "cast": [{"name": "Kim", "note": "the regressor"}],
    "threads": ["Who is the rival?", "Why did he regress?"],
}


@pytest.fixture(autouse=True)
def paid(monkeypatch, tmp_path, session_factory):
    p = _ai_stubs.install(monkeypatch, tmp_path, session_factory)
    p.answer = PROSE
    return p


@pytest.fixture
def acct(make_user, make_profile):
    user = make_user("recapper")
    profile = make_profile(user.id, "Main", mature_content_enabled=True)
    return user.id, profile.id


@pytest.fixture
def series(db_session, acct):
    seed_series(db_session, *acct)


def url(kind="recap", to="c143", **extra):
    q = {"source": SRC, "series": "s", "to": to, **extra}
    return f"/ai/{kind}?" + "&".join(f"{k}={v}" for k, v in q.items())


def get(client, as_user, acct, *args, **kw):
    return client.get(url(*args, **kw), headers=as_user(*acct))


def test_prose_framing(client, as_user, acct, series):
    r = get(client, as_user, acct)
    assert r.status_code == 200
    assert r.headers["content-type"] == "text/event-stream; charset=utf-8"
    assert r.headers["cache-control"] == "no-cache, no-transform"
    assert r.headers["x-accel-buffering"] == "no"
    ev = sse_events(r.text)
    names = [n for n, _ in ev]
    assert names[0] == "meta" and names[-1] == "done"
    assert set(names[1:-1]) == {"delta"}
    meta, done = ev[0][1], ev[-1][1]
    assert meta["range"] == {"from_key": "c131", "to_key": "c142", "from_number": 131, "to_number": 142}
    assert meta["cast"] == [{"name": "Kim", "note": "the regressor"}] and meta["sourced_from"] == "ocr"
    deltas = [d["text"] for n, d in ev if n == "delta"]
    assert "".join(deltas) == "\n\n".join(PROSE["paragraphs"])
    assert all(len(t.split()) <= 8 for t in deltas)
    assert done["covered_through"] == 142 and done["model"] == "deepseek-test" and done["generated_at"]


def test_deck_framing(client, as_user, acct, series, paid):
    paid.answer = DECK
    ev = sse_events(get(client, as_user, acct, shape="deck").text)
    names = [n for n, _ in ev]
    assert names[0] == "phase" and ev[0][1] == {"phase": "writing"}
    assert [d["kind"] for n, d in ev if n == "section"] == ["left_off", "happened", "cast", "threads"]
    assert [d["title"] for n, d in ev if n == "section"] == [
        "Where you left off", "What happened", "Who's who", "Open threads"]
    assert names[1:5] == ["section"] * 4 and names[-1] == "done"
    kinds = [d["kind"] for n, d in ev if n == "delta"]
    order = ["left_off", "happened", "cast", "threads"]
    assert kinds == sorted(kinds, key=order.index)
    happened = "".join(d["text"] for n, d in ev if n == "delta" and d["kind"] == "happened")
    assert happened == "".join(f"{h}\n" for h in DECK["happened"])
    assert "".join(d["text"] for n, d in ev if n == "delta" and d["kind"] == "cast") == "Kim: the regressor\n"
    done = ev[-1][1]
    assert done["range"] == [131, 142] and done["covered_through"] == 142
    assert done["cast"] == [{"name": "Kim", "note": "the regressor"}]
    assert done["sourced_from"] == "ocr" and done["model"] and done["generated_at"]
    assert done["available"] is True and done["reason"] == "ok"


def test_chapter_scope_is_one_last_time_section(client, as_user, acct, series, paid):
    paid.answer = {"last_time": "He rested after the siege."}
    ev = sse_events(get(client, as_user, acct, shape="deck", scope="chapter").text)
    assert [d["kind"] for n, d in ev if n == "section"] == ["last_time"]
    assert [d["title"] for n, d in ev if n == "section"] == ["Last time"]
    assert "".join(d["text"] for n, d in ev if n == "delta") == "He rested after the siege."
    assert ev[-1][1]["range"] == [142, 142]
    r = get(client, as_user, acct, shape="prose", scope="chapter")
    assert r.status_code == 422


def test_never_past_covered_through(client, as_user, acct, series, paid):
    get(client, as_user, acct)
    message = paid.seen[0]["message"]
    for n in range(131, 143):
        assert f"MARK{n} " in message
    for n in (143, 144, 145):
        assert f"MARK{n}" not in message
    assert "MARK130" not in message
    assert "nothing after chapter 142" in paid.seen[0]["system"]
    # a recap cached for 131..142 is not served for a range that ends at 141
    r = get(client, as_user, acct, to="c142")
    done = sse_events(r.text)[-1][1]
    assert done["covered_through"] == 141 and len(paid.seen) == 2
    assert "MARK142" not in paid.seen[1]["message"]


@pytest.mark.parametrize("case", ["first_chapter", "no_dialogue", "not_configured", "budget_exhausted"])
def test_no_stream_answers_json(client, as_user, acct, series, monkeypatch, tmp_path, session_factory, case):
    if case == "first_chapter":
        r = get(client, as_user, acct, to="c131")
    elif case == "no_dialogue":
        with session_factory() as s:
            from database.models import ChapterOcr
            s.query(ChapterOcr).delete()
            s.commit()
        r = get(client, as_user, acct)
    elif case == "not_configured":
        monkeypatch.delenv("DEEPSEEK_API_KEY")
        r = get(client, as_user, acct)
    else:
        (tmp_path / "s.json").write_text(json.dumps(
            {"date": __import__("services.deepseek_client", fromlist=["x"])._today(),
             "requests": __import__("services.suggestion_service", fromlist=["x"]).DAILY_CEILING}))
        r = get(client, as_user, acct)
    assert r.status_code == 200
    assert "text/event-stream" not in r.headers["content-type"]
    assert r.json() == {"available": False, "reason": case}


def test_fourth_miss_inside_a_minute_is_rate_limited(client, as_user, acct, db_session, paid):
    for i in range(4):
        seed_series(db_session, *acct, key=f"s{i}", title=f"T{i}")
    got = [client.get(url(series=f"s{i}"), headers=as_user(*acct)) for i in range(4)]
    assert [r.headers["content-type"].startswith("text/event-stream") for r in got] == [True] * 3 + [False]
    assert got[3].json() == {"available": False, "reason": "rate_limited"}
    assert 1 <= int(got[3].headers["retry-after"]) <= 61
    assert len(paid.seen) == 3


def test_cached_recap_costs_nothing(client, as_user, acct, series, paid, tmp_path):
    first = sse_events(get(client, as_user, acct).text)
    ledger = json.loads((tmp_path / "s.json").read_text())["requests"]
    assert ledger == 1
    second = sse_events(get(client, as_user, acct).text)
    assert len(paid.seen) == 1 and json.loads((tmp_path / "s.json").read_text())["requests"] == 1
    assert [d for n, d in first if n == "delta"] == [d for n, d in second if n == "delta"]
    assert first[-1][1]["generated_at"] == second[-1][1]["generated_at"]
    # cached recaps do not spend the per-account recap slots
    for _ in range(5):
        assert get(client, as_user, acct).headers["content-type"].startswith("text/event-stream")
    info = client.get(url("recap/availability"), headers=as_user(*acct)).json()
    assert info["cached"] is True and info["available"] is True


def test_failure_is_one_error_event_and_caches_nothing(client, as_user, acct, series, paid, db_session):
    paid.status = 500
    ev = sse_events(get(client, as_user, acct).text)
    assert [n for n, _ in ev] == ["error"] and ev[0][1]["code"] == "ai_failed"
    assert db_session.query(AiResultCache).filter_by(kind="recap").count() == 0


def test_malformed_answer_is_ai_failed(client, as_user, acct, series, paid, db_session):
    paid.answer = {"paragraphs": []}
    ev = sse_events(get(client, as_user, acct).text)
    assert ev[0][1]["code"] == "ai_failed"
    assert db_session.query(AiResultCache).filter_by(kind="recap").count() == 0


def test_rate_limited_provider_maps_to_rate_limited(client, as_user, acct, series, paid, monkeypatch):
    from services import deepseek_client
    monkeypatch.setattr(deepseek_client.time, "sleep", lambda s: None)
    paid.status = 429
    ev = sse_events(get(client, as_user, acct).text)
    assert ev[0][1] == {"code": "rate_limited", "message": ev[0][1]["message"], "retry_after": 30}


def test_keep_alive_comments_while_waiting(client, as_user, acct, series, paid, monkeypatch):
    monkeypatch.setattr(recap_service, "KEEP_ALIVE_SECONDS", 0.05)
    paid.delay = 0.4
    r = get(client, as_user, acct)
    assert ": keep-alive\n\n" in r.text
    assert sse_events(r.text)[-1][0] == "done"


def test_a_recap_closed_during_generation_is_cached(client, as_user, acct, series, paid, db_session):
    """The writer thread outlives the response."""
    outcome = None
    from services.recap_service import RecapService
    from services.followed_series_service import FollowedSeriesService
    from services.suggestion_service import SuggestionService
    from tests._fakes import FakeBrowse
    lib = FollowedSeriesService(db_session, FakeBrowse({}), user_id=acct[0], profile_id=acct[1])
    svc = RecapService(db_session, lib, SuggestionService(db_session, lib, is_admin=True))
    outcome = svc.recap(SRC, "s", "c143", shape="prose", scope="series")
    del outcome  # never iterated: the client left
    import time
    for _ in range(100):
        if db_session.query(AiResultCache).filter_by(kind="recap").count():
            break
        time.sleep(0.05)
    assert db_session.query(AiResultCache).filter_by(kind="recap").count() == 1


def test_gate_404s_a_mature_series_and_never_calls_the_ai(client, as_user, make_user, make_profile, db_session, paid):
    user = make_user("gated")
    profile = make_profile(user.id, "Kid", mature_content_enabled=False)
    seed_series(db_session, user.id, profile.id, key="hot", rating="mature")
    h = as_user(user.id, profile.id)
    for kind in ("recap", "recap/availability"):
        r = client.get(f"/ai/{kind}?source={SRC}&series=hot&to=c143", headers=h)
        assert r.status_code == 404 and r.json()["code"] == "series_not_found"
    r = client.get(f"/ai/recap?source={MATURE}&series=hot&to=c143", headers=h)
    assert r.status_code == 404 and r.json()["code"] == "source_not_found"
    assert paid.seen == []


def test_availability_matches_the_backend_04_object_and_makes_no_call(client, as_user, acct, series, paid):
    body = client.get(url("recap/availability"), headers=as_user(*acct)).json()
    assert body["available"] is True and body["reason"] == "ok" and body["cached"] is False
    assert body["range"]["to_number"] == 142 and body["est_seconds"] > 0
    chap = client.get(url("recap/availability", scope="chapter"), headers=as_user(*acct)).json()
    assert chap["range"]["from_key"] == chap["range"]["to_key"] == "c142" and chap["est_seconds"] == 20
    assert paid.seen == []


def test_novel_recap_reads_cached_paragraphs_and_the_cast(client, as_user, acct, db_session, paid):
    uid, pid = acct
    seed_series(db_session, uid, pid, key="n", source=NOVEL, read=range(1, 6), ocr=range(0), title="Nov")
    for n in range(1, 6):
        db_session.add(NovelChapterCache(source_id=NOVEL, series_key="n", chapter_key=f"c{n}",
                                         paragraphs=json.dumps([f"NOV{n} said the knight."])))
    db_session.add(NovelSeriesCast(source_id=NOVEL, series_key="n", display_name="Sir Bram",
                                   normalized_name="sir bram", line_count=9))
    db_session.commit()
    paid.answer = {"paragraphs": ["One.", "Two.", "Three."], "cast": [{"name": "Other", "note": "x"}]}
    r = client.get(f"/ai/recap?source={NOVEL}&series=n&to=c6", headers=as_user(*acct))
    ev = sse_events(r.text)
    assert ev[0][1]["sourced_from"] == "text"
    assert ev[0][1]["cast"] == [{"name": "Sir Bram", "note": ""}]
    assert "NOV5 said" in paid.seen[0]["message"] and "Sir Bram" in paid.seen[0]["message"]
