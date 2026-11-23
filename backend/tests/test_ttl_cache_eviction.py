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


class _HookedEntries(dict):
    """Entries dict that runs a hook while the sweep is part-way through it."""

    hook = None

    def items(self):
        for item in list(super().items()):
            yield item
            hook, self.hook = self.hook, None
            if hook is not None:
                hook()


def test_an_expiry_pop_during_the_sweep_neither_breaks_it_nor_is_lost(monkeypatch):
    import threading

    cache, clock = _cache(monkeypatch)
    cache._entries = _HookedEntries()
    for n in range(5):
        cache.set(f"page-{n}", n)
    clock.now += 61

    errors: list[BaseException] = []

    def reader() -> None:
        try:
            assert cache.get("page-4") is None
        except BaseException as exc:  # noqa: BLE001 - the test reports it
            errors.append(exc)

    def reader_mid_sweep() -> None:
        t = threading.Thread(target=reader)
        t.start()
        # With the lock held by the sweep the reader waits; without it the
        # reader's pop lands inside the sweep's iteration.
        t.join(0.2)
        threads.append(t)

    threads: list[threading.Thread] = []
    cache._entries.hook = reader_mid_sweep
    cache.set("fresh", 1)
    for t in threads:
        t.join(2)
    assert errors == []
    assert list(cache._entries) == ["fresh"]


def test_concurrent_readers_writers_and_sweeps_raise_nothing():
    import threading

    cache = TTLCache(ttl_seconds=0.002, max_entries=64)
    errors: list[BaseException] = []
    stop = threading.Event()

    def writer(seed: int) -> None:
        n = 0
        try:
            while not stop.is_set():
                cache.set(f"k{(n * 7 + seed) % 200}", n)
                n += 1
        except BaseException as exc:  # noqa: BLE001
            errors.append(exc)

    def reader(seed: int) -> None:
        n = 0
        try:
            while not stop.is_set():
                key = f"k{(n * 5 + seed) % 200}"
                cache.get(key)
                if n % 50 == 0:
                    cache.pop(key)
                if n % 997 == 0:
                    cache.clear()
                n += 1
        except BaseException as exc:  # noqa: BLE001
            errors.append(exc)

    threads = [threading.Thread(target=writer, args=(i,)) for i in range(4)]
    threads += [threading.Thread(target=reader, args=(i,)) for i in range(4)]
    for t in threads:
        t.start()
    stop.wait(1.0)
    stop.set()
    for t in threads:
        t.join(5)
    assert errors == []


def test_get_or_set_does_not_hold_the_lock_across_the_factory():
    cache: TTLCache[int] = TTLCache(ttl_seconds=60.0)

    def factory() -> int:
        # A factory that touches the cache (a nested fetch) must not deadlock.
        cache.set("inner", 1)
        return 2

    assert cache.get_or_set("outer", factory) == 2
    assert cache.get("inner") == 1
