"""The desk ledger, its failure vocabulary, the background runner and the
``ai_result_cache`` helpers."""

from __future__ import annotations

import threading
from datetime import timedelta

import httpx
import pytest

from core.time_utils import utcnow
from database.models import AiResultCache
from services import ai_desk, deepseek_client, suggestion_service
from services.llm import LLMBudgetExhausted, LLMError, LLMRateLimited


@pytest.fixture(autouse=True)
def _env(monkeypatch, tmp_path):
    monkeypatch.setattr(ai_desk, "DESK_BUDGET_PATH", tmp_path / "desk.json")
    monkeypatch.setenv("DEEPSEEK_API_KEY", "k")
    monkeypatch.setattr(deepseek_client.time, "sleep", lambda s: None)
    ai_desk.reset_desk_state()
    yield
    ai_desk.reset_desk_state()


def _status(monkeypatch, code):
    monkeypatch.setattr(
        suggestion_service, "_upstream_transport",
        lambda: httpx.MockTransport(lambda r: httpx.Response(code, json={})),
    )


def test_availability_reasons(monkeypatch):
    assert ai_desk.desk_availability() == {"available": True, "reason": "ok"}
    monkeypatch.setattr(deepseek_client, "spent_today", lambda p=None: ai_desk.DESK_DAILY_CEILING)
    assert ai_desk.desk_availability()["reason"] == "budget_exhausted"
    monkeypatch.delenv("DEEPSEEK_API_KEY")
    assert ai_desk.desk_availability()["reason"] == "not_configured"


def test_a_429_is_rate_limited_and_remembered(monkeypatch):
    _status(monkeypatch, 429)
    with pytest.raises(ai_desk.DeskUnavailable) as err:
        ai_desk.desk_complete("s", "m")
    assert err.value.reason == "rate_limited"
    assert ai_desk.desk_availability() == {"available": False, "reason": "rate_limited"}
    assert issubclass(LLMRateLimited, LLMError)


def test_other_failures_are_ai_failed(monkeypatch):
    _status(monkeypatch, 500)
    with pytest.raises(ai_desk.DeskUnavailable) as err:
        ai_desk.desk_complete("s", "m")
    assert err.value.reason == "ai_failed"
    assert ai_desk.desk_availability()["reason"] == "ai_failed"


def test_budget_and_not_configured_are_not_remembered_as_failures(monkeypatch):
    def raiser(exc):
        def _f(*a, **k):
            raise exc
        return _f

    monkeypatch.setattr(deepseek_client, "complete_json", raiser(LLMBudgetExhausted("x")))
    with pytest.raises(ai_desk.DeskUnavailable) as err:
        ai_desk.desk_complete("s", "m")
    assert err.value.reason == "budget_exhausted"
    assert ai_desk.desk_availability()["available"] is True


def test_background_runner_is_single_flight():
    gate, started = threading.Event(), threading.Event()

    def job():
        started.set()
        gate.wait(5)

    assert ai_desk.run_in_background("k1", job) is True
    assert started.wait(5)
    assert ai_desk.run_in_background("k1", lambda: None) is False
    assert ai_desk.run_in_background("k2", lambda: None) is True
    gate.set()


def test_cache_helpers(db_session):
    key = ai_desk.cache_key("a", "b")
    assert key == ai_desk.cache_key("a", "b") and key != ai_desk.cache_key("ab")
    assert len(key) == 64
    assert ai_desk.cache_get(db_session, key) is None
    ai_desk.cache_put(db_session, key, kind="t", payload="{}", model="m",
                      expires_at=utcnow() + timedelta(hours=1))
    assert ai_desk.cache_get(db_session, key).payload == "{}"
    ai_desk.cache_put(db_session, key, kind="t", payload='{"x":1}', model="m",
                      expires_at=utcnow() + timedelta(hours=1))
    assert db_session.query(AiResultCache).count() == 1
    old = ai_desk.cache_key("old")
    ai_desk.cache_put(db_session, old, kind="t", payload="{}", model="m",
                      expires_at=utcnow() - timedelta(days=8))
    assert ai_desk.cache_get(db_session, old) is None
    ai_desk.cache_put(db_session, ai_desk.cache_key("new"), kind="t", payload="{}", model="m",
                      expires_at=utcnow() + timedelta(days=1))
    assert db_session.get(AiResultCache, old) is None  # pruned on the next write
