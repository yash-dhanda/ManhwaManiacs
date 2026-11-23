"""``TTLCache`` must not keep entries nobody will ask for again."""

from __future__ import annotations

import connectors.http.cache as cache_module
from connectors.http.cache import TTLCache


class _Clock:
    def __init__(self) -> None:
        self.now = 1000.0

    def __call__(self) -> float:
        return self.now


def _cache(monkeypatch, **kwargs):
    clock = _Clock()
    monkeypatch.setattr(cache_module.time, "monotonic", clock)
    return TTLCache(ttl_seconds=60.0, **kwargs), clock


def test_expired_entries_are_purged_by_a_later_set(monkeypatch):
    cache, clock = _cache(monkeypatch)
    for n in range(500):
        cache.set(f"page-{n}", n)
    clock.now += 61
    cache.set("fresh", 1)
    assert list(cache._entries) == ["fresh"]
    assert cache.get("fresh") == 1


def test_a_live_entry_survives_the_purge(monkeypatch):
    cache, clock = _cache(monkeypatch)
    cache.set("old", 1)
    clock.now += 40
    cache.set("young", 2)
    clock.now += 30  # old is 70s, young 30s
    cache.set("trigger", 3)
    assert cache.get("old") is None
    assert cache.get("young") == 2
    assert cache.get("trigger") == 3


def test_the_purge_is_amortised_not_run_on_every_set(monkeypatch):
    cache, clock = _cache(monkeypatch)
    calls = []
    original = cache._entries.items

    class _Spy(dict):
        def items(self):
            calls.append(1)
            return original()

    cache._entries = _Spy()
    for n in range(100):
        cache.set(str(n), n)
    assert calls == []  # nothing has expired and no sweep is due
    clock.now += 61
    cache.set("a", 1)
    cache.set("b", 1)
    assert len(calls) == 1  # one sweep, not one per set


def test_max_entries_evicts_oldest_first(monkeypatch):
    cache, _ = _cache(monkeypatch, max_entries=3)
    for key in "abcd":
        cache.set(key, key)
    assert list(cache._entries) == ["b", "c", "d"]
    cache.set("b", "again")  # a rewrite is the newest write
    cache.set("e", "e")
    assert list(cache._entries) == ["d", "b", "e"]


def test_a_default_bound_holds_without_naming_one(monkeypatch):
    cache, _ = _cache(monkeypatch)
    for n in range(cache_module.DEFAULT_MAX_ENTRIES + 50):
        cache.set(str(n), n)
    assert len(cache._entries) == cache_module.DEFAULT_MAX_ENTRIES
    assert cache.get("0") is None
    assert cache.get(str(cache_module.DEFAULT_MAX_ENTRIES + 49)) is not None


def test_public_interface_is_unchanged(monkeypatch):
    cache, clock = _cache(monkeypatch)
    assert cache.get_or_set("k", lambda: 5) == 5
    assert cache.get_or_set("k", lambda: 6) == 5
    cache.pop("k")
    assert cache.get("k") is None
    cache.set("k", 1)
    clock.now += 61
    assert cache.get("k") is None
    cache.set("z", 1)
    cache.clear()
    assert cache.get("z") is None
