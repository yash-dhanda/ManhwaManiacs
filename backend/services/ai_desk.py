"""The AI desk: background editorial work nobody asked for by name.

Two spending paths run on ``deepseek_client.complete_json``. **Asks** (a
person's explicit request: Ask, recaps) stay on ``SuggestionService`` and its
ledgers. The **desk** (the home editorial, similar ``why`` lines, suggested
tags) has a third ledger of its own, so background work can never eat a
reader's asks or the novel attribution budget.

Also here: the ``ai_result_cache`` helpers every stored AI answer goes
through, and a single-flight background runner so a request never waits for
the AI.
"""

from __future__ import annotations

import hashlib
import logging
import threading
import time
from collections.abc import Callable
from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import delete
from sqlalchemy.orm import Session

from core.config import SETTINGS_PATH
from core.time_utils import utcnow
from database.models import AiResultCache
from database.session import SessionLocal
from services import deepseek_client
from services.llm import (
    Completion,
    LLMBudgetExhausted,
    LLMError,
    LLMNotConfigured,
    LLMRateLimited,
)
from services.suggestion_service import _DeadlineTransport

logger = logging.getLogger(__name__)

DESK_DAILY_CEILING = 100
DESK_BUDGET_PATH = SETTINGS_PATH.parent / "deepseek-desk-usage.json"
#: The reasoning-token floor ``suggestion_service.MAX_TOKENS`` documents.
DESK_MAX_TOKENS = 20000
DESK_TEMPERATURE = 0.4
DESK_TIMEOUT_SECONDS = 90.0

#: A desk failure keeps the desk "unavailable" this long.
_FAILURE_MEMORY_SECONDS = 600.0
#: Cache rows expired for longer than this are deleted on the next write.
_PRUNE_AFTER = timedelta(days=7)

_LAST_FAILURE: tuple[str, float] | None = None
_FAILURE_LOCK = threading.Lock()


class DeskUnavailable(Exception):
    """The desk could not answer; ``reason`` is the ``ai.reason`` key."""

    def __init__(self, reason: str) -> None:
        super().__init__(reason)
        self.reason = reason


def reset_desk_state() -> None:
    """Forget the last failure and any running job (tests)."""
    global _LAST_FAILURE
    with _FAILURE_LOCK:
        _LAST_FAILURE = None
    with _RUNNING_LOCK:
        _RUNNING.clear()


def record_failure(reason: str) -> None:
    global _LAST_FAILURE
    with _FAILURE_LOCK:
        _LAST_FAILURE = (reason, time.monotonic())


def desk_availability() -> dict[str, Any]:
    """Whether the desk can write now. Local and free."""
    if not deepseek_client.is_configured():
        return {"available": False, "reason": "not_configured"}
    if deepseek_client.spent_today(DESK_BUDGET_PATH) >= DESK_DAILY_CEILING:
        return {"available": False, "reason": "budget_exhausted"}
    with _FAILURE_LOCK:
        failure = _LAST_FAILURE
    if failure and time.monotonic() - failure[1] < _FAILURE_MEMORY_SECONDS:
        return {"available": False, "reason": failure[0]}
    return {"available": True, "reason": "ok"}


def desk_complete(system: str, message: str) -> Completion:
    """One desk call on the desk ledger; raises ``DeskUnavailable``."""
    try:
        return deepseek_client.complete_json(
            message,
            system=system,
            max_tokens=DESK_MAX_TOKENS,
            temperature=DESK_TEMPERATURE,
            timeout=DESK_TIMEOUT_SECONDS,
            ceiling=DESK_DAILY_CEILING,
            budget_path=DESK_BUDGET_PATH,
            transport=_DeadlineTransport(DESK_TIMEOUT_SECONDS),
        )
    except LLMNotConfigured as exc:
        reason = "not_configured"
        raise DeskUnavailable(reason) from exc
    except LLMBudgetExhausted as exc:
        reason = "budget_exhausted"
        raise DeskUnavailable(reason) from exc
    except LLMRateLimited as exc:
        reason = "rate_limited"
        record_failure(reason)
        raise DeskUnavailable(reason) from exc
    except LLMError as exc:
        # Never log the upstream body; the client already redacts it.
        logger.warning("desk request failed: %s", type(exc).__name__)
        reason = "ai_failed"
        record_failure(reason)
        raise DeskUnavailable(reason) from exc


# --- background runner ------------------------------------------------------

_RUNNING: set[str] = set()
_RUNNING_LOCK = threading.Lock()


def run_in_background(key: str, job: Callable[[], None]) -> bool:
    """Run ``job`` on a daemon thread, one per ``key``. False if already running.

    The job opens its own ``SessionLocal()``; the request's session is closed
    when the response is sent.
    """
    with _RUNNING_LOCK:
        if key in _RUNNING:
            return False
        _RUNNING.add(key)

    def _run() -> None:
        try:
            job()
        except Exception:  # noqa: BLE001 - a background job never crashes the server
            logger.warning("desk job %s failed", key[:12], exc_info=True)
        finally:
            with _RUNNING_LOCK:
                _RUNNING.discard(key)

    threading.Thread(target=_run, name=f"desk-{key[:8]}", daemon=True).start()
    return True


def open_session() -> Session:
    """The session a background job uses (a seam for tests)."""
    return SessionLocal()


# --- ai_result_cache ----------------------------------------------------------


def cache_key(*parts: str) -> str:
    return hashlib.sha256("\x1f".join(parts).encode()).hexdigest()


def cache_get(db: Session, key: str) -> AiResultCache | None:
    row = db.get(AiResultCache, key)
    if row is None or row.expires_at <= utcnow():
        return None
    return row


def cache_put(
    db: Session,
    key: str,
    *,
    kind: str,
    payload: str,
    model: str,
    expires_at: datetime,
    profile_id: int | None = None,
    source_id: str | None = None,
    series_key: str | None = None,
) -> None:
    now = utcnow()
    # Pruned before the merge, as WorldCatalog._write does: a key being
    # refreshed may itself be past the window.
    db.execute(
        delete(AiResultCache).where(AiResultCache.expires_at < now - _PRUNE_AFTER)
    )
    db.merge(
        AiResultCache(
            key=key,
            kind=kind,
            profile_id=profile_id,
            source_id=source_id,
            series_key=series_key,
            payload=payload,
            model=model or "",
            generated_at=now,
            expires_at=expires_at,
        )
    )
    db.commit()
