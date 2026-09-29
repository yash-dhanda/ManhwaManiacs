"""Headline, deck and number rules of the home cover story (cinematic §9.1.2).

Pure functions: no database, no HTTP.
"""

from __future__ import annotations

import pytest

from services.home_service import (
    first_sentence,
    graphemes,
    spell,
    time_word,
    write_cover,
)

STREAK = {"at_risk": False, "current_days": 0}


def _cover(reason, hour=21, **kw):
    return write_cover(reason, hour=hour, **kw)


@pytest.mark.parametrize(
    "hour,word",
    [
        (4, "Tonight"), (5, "This morning"), (11, "This morning"),
        (12, "This afternoon"), (17, "This afternoon"), (18, "Tonight"),
    ],
)
def test_time_words_at_the_boundaries(hour, word):
    assert time_word(hour) == word


def test_spell_table():
    assert [spell(n, capital=True) for n in (0, 1, 12, 20, 31, 77, 100)] == [
        "Zero", "One", "Twelve", "Twenty", "Thirty-one", "Seventy-seven", "One hundred",
    ]
    assert spell(101, capital=True) == "101"
    assert [spell(n, capital=False) for n in (0, 3, 9, 10, 101)] == [
        "zero", "three", "nine", "10", "101",
    ]
    assert spell(21, capital=True) == "Twenty-one"


def test_new_chapters_headline_and_overflow():
    c = _cover("new_chapters", title="Omniscient Reader", chapter_number=143)
    assert c["headline"] == "Tonight: chapter 143 of Omniscient Reader."
    assert c["kicker_title"] is None
    long_title = "A" * 70
    c = _cover("new_chapters", title=long_title, chapter_number=143.5)
    assert c["headline"] == "Tonight: chapter 143.5."
    assert c["kicker_title"] == long_title
    assert _cover("new_chapters", title="X", chapter_number=None)["headline"] == (
        "Tonight: a new chapter of X."
    )
    assert _cover("new_chapters", title="A" * 70)["headline"] == "Tonight: a new chapter."
    assert _cover("new_chapters", hour=8, title="X", chapter_number=1)["headline"].startswith(
        "This morning:"
    )
    assert _cover("new_chapters", title="T", chapter_number=2, synopsis="Syn.")["deck"] == "Syn."
    assert _cover(
        "new_chapters", title="T", chapter_number=2, synopsis="Syn.", editorial_deck="Ed."
    )["deck"] == "Ed."


def test_in_progress_manga_and_novel():
    c = _cover("in_progress", chapter_number=12, last_page=4, page_count=10, ago_days=0)
    assert c["headline"] == "Tonight: finish chapter 12. Six pages left."
    assert c["deck"] == "You were on page 4 of 10 today."
    c = _cover("in_progress", chapter_number=12, last_page=9, page_count=10, ago_days=1)
    assert c["headline"] == "Tonight: finish chapter 12. One page left."
    assert c["deck"].endswith("yesterday.")
    c = _cover("in_progress", chapter_number=12, last_page=1, page_count=30, ago_days=3)
    assert "Twenty-nine pages left." in c["headline"]
    assert c["deck"] == "You were on page 1 of 30 three days ago."
    c = _cover("in_progress", chapter_number=5, last_page=31, page_count=50,
               ago_days=12, content_kind="novel")
    assert c["headline"] == "Tonight: finish chapter 5."
    assert c["deck"] == "You were 62 % through it 12 days ago."


def test_paused_and_overflow():
    c = _cover("paused", title="Tower of God", chapter_number=88, paused_days=12)
    assert c["headline"] == "Tonight: back to Tower of God."
    assert c["deck"] == "You paused 12 days ago at chapter 88. Previously on is ready."
    assert _cover("paused", title="T", chapter_number=1, paused_days=8)["deck"].startswith(
        "You paused eight days ago"
    )
    c = _cover("paused", title="B" * 80, chapter_number=1, paused_days=9)
    assert (c["headline"], c["kicker_title"]) == ("Tonight: back to it.", "B" * 80)


def test_ai_pick_first_pick_caught_up_popular():
    c = _cover("ai_pick", title="Solo", why="Because.", synopsis="Other.")
    assert c["headline"] == "Tonight: start Solo." and c["deck"] == "Because."
    assert _cover("ai_pick", title="Solo", synopsis="Other.")["deck"] == "Other."
    assert _cover("ai_pick", title="Solo")["deck"] is None
    c = _cover("ai_pick", title="C" * 90)
    assert (c["headline"], c["kicker_title"]) == ("Tonight: start something new.", "C" * 90)
    c = _cover("first_pick", title="Solo")
    assert c["deck"] == "Chapter 1 is waiting. The rest of your picks are below."
    c = _cover("caught_up")
    assert c["headline"] == "Tonight: you're caught up."
    assert c["deck"] == "Nothing new on your shelf. Here's something else."
    for reason in ("popular", None):
        c = _cover(reason)
        assert c["headline"] == "Your first issue starts here."
        assert c["deck"] == "Follow three series and this page fills itself in."


@pytest.mark.parametrize(
    "days,head",
    [
        (2, "Two days and counting. One chapter keeps it alive."),
        (12, "Twelve days and counting. One chapter keeps it alive."),
        (31, "Thirty-one days and counting. One chapter keeps it alive."),
        (77, "Seventy-seven days and counting. One chapter keeps it alive."),
        (100, "One hundred days and counting. One chapter keeps it alive."),
        (101, "Your 101-day streak ends at midnight."),
        (123, "Your 123-day streak ends at midnight."),
    ],
)
def test_at_risk_override(days, head):
    streak = {"at_risk": True, "current_days": days}
    c = _cover("new_chapters", title="T", chapter_number=3, streak=streak)
    assert c["headline"] == head
    assert c["deck"] == "Open any chapter before midnight to keep your streak."
    assert c["kicker_title"] is None


def test_every_spelled_at_risk_headline_fits_60_graphemes():
    for n in range(2, 101):
        head = _cover("in_progress", chapter_number=1, last_page=1, page_count=3,
                      streak={"at_risk": True, "current_days": n})["headline"]
        assert graphemes(head) <= 60, (n, head)
    assert graphemes(
        "Seventy-seven days and counting. One chapter keeps it alive."
    ) == 60


def test_at_risk_never_overrides_caught_up_or_popular_and_needs_two_days():
    on = {"at_risk": True, "current_days": 5}
    assert _cover("caught_up", streak=on)["headline"] == "Tonight: you're caught up."
    assert _cover("popular", streak=on)["headline"] == "Your first issue starts here."
    one = {"at_risk": True, "current_days": 1}
    c = _cover("new_chapters", title="T", chapter_number=9, streak=one)
    assert c["headline"] == "Tonight: chapter 9 of T."


def test_grapheme_count_ignores_combining_marks():
    assert graphemes("é") == 1
    assert graphemes("abc") == 3


def test_synopsis_first_sentence_cutter():
    assert first_sentence(None) is None and first_sentence("  ") is None
    text = "A boy wakes up in a strange world.  He must survive. Then more."
    assert first_sentence(text) == "A boy wakes up in a strange world."
    assert first_sentence("Short. But this second sentence is the long one!") == (
        "Short. But this second sentence is the long one!"
    )
    long = "word " * 60
    cut = first_sentence(long)
    assert cut.endswith("…") and len(cut) <= 160
    assert first_sentence("No terminator here at all really") == "No terminator here at all really"
