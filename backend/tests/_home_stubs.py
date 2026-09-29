"""Stub sources for the home tests: descriptors only, no network."""

from __future__ import annotations

import connectors.registry as registry
from core.config import get_settings


def _stub(source_id: str, name: str, *, mature=False, kind="manga"):
    return type(
        f"Stub_{source_id}",
        (),
        {
            "SOURCE_TYPE": source_id,
            "DISPLAY_NAME": name,
            "DESCRIPTION": "",
            "BROWSABLE": True,
            "SUPPORTS_IMPORT": False,
            "MATURE": mature,
            "CONTENT_KIND": kind,
            "LANGUAGE": "en" if kind == "novel" else None,
        },
    )


STUBS = {
    "hm_manga": _stub("hm_manga", "Alpha Scans"),
    "hm_manga2": _stub("hm_manga2", "Beta Scans"),
    "hm_manga3": _stub("hm_manga3", "Gamma Scans"),
    "hm_manga4": _stub("hm_manga4", "Delta Scans"),
    "hm_mature": _stub("hm_mature", "Adult Scans", mature=True),
    "hm_novel": _stub("hm_novel", "Novel Hall", kind="novel"),
}


def install(monkeypatch) -> None:
    monkeypatch.setenv("MM_NOVELS_ENABLED", "true")
    get_settings.cache_clear()
    for source_id, cls in STUBS.items():
        monkeypatch.setitem(registry._REGISTRY, source_id, cls)
