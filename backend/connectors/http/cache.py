"""TTL cache for connector metadata."""

from __future__ import annotations

import threading
import time
from collections.abc import Callable
from typing import Generic, TypeVar

T = TypeVar("T")

#: Entries one cache keeps before the oldest are dropped. Generous on purpose:
#: the caches hold per-series or per-list-page values, and a bound that bit in
#: ordinary use would turn them into a refetch on every request. It exists so
#: a connector shared for the life of the process cannot grow without limit.
DEFAULT_MAX_ENTRIES = 1024


class TTLCache(Generic[T]):
    def __init__(
        self, ttl_seconds: float, max_entries: int | None = DEFAULT_MAX_ENTRIES
    ) -> None:
        self._ttl = ttl_seconds
        self._max_entries = max_entries
        self._entries: dict[str, tuple[float, T]] = {}
        # An expired entry used to leave only when its own key was read again,
        # so keys that are never asked for twice (list pages, retired series)
        # stayed for the life of the process. ``set`` now sweeps them, at most
        # once per TTL, so the cost stays out of the hot path.
        self._next_sweep = time.monotonic() + ttl_seconds
        self._lock = threading.Lock()

    def get(self, key: str) -> T | None:
        entry = self._entries.get(key)
        if entry is None:
            return None
        expires_at, value = entry
        if time.monotonic() > expires_at:
            # Removed under the lock the sweep and eviction in ``set`` hold, so
            # they never see the dict change under them. Only the entry that
            # was read is dropped: a writer may have replaced it since.
            with self._lock:
                if self._entries.get(key) is entry:
                    del self._entries[key]
            return None
        return value

    def set(self, key: str, value: T) -> None:
        now = time.monotonic()
        with self._lock:
            # Re-inserted rather than overwritten so dict order stays
            # oldest-write-first, which is what eviction below relies on.
            self._entries.pop(key, None)
            self._entries[key] = (now + self._ttl, value)
            if now >= self._next_sweep:
                self._next_sweep = now + self._ttl
                for stale in [
                    k for k, (exp, _) in list(self._entries.items()) if now > exp
                ]:
                    self._entries.pop(stale, None)
            if self._max_entries is not None:
                while len(self._entries) > self._max_entries:
                    self._entries.pop(next(iter(self._entries)), None)

    def pop(self, key: str) -> None:
        """Drop a cached entry so the next lookup refetches."""
        with self._lock:
            self._entries.pop(key, None)

    def get_or_set(self, key: str, factory: Callable[[], T]) -> T:
        cached = self.get(key)
        if cached is not None:
            return cached
        value = factory()
        self.set(key, value)
        return value

    def clear(self) -> None:
        with self._lock:
            self._entries.clear()
