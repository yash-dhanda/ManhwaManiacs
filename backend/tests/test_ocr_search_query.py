"""The FTS5 MATCH expression ``GET /ocr/search`` builds (spec §4.4).

Each whitespace-separated term is wrapped in double quotes so that punctuation
a reader types (``!``, ``-``, ``*``, ``:``) is matched literally instead of
being parsed as FTS5 query syntax. Wrapping alone is not enough: a term
carrying its OWN double quote closes the string early. ``he"llo`` became
``"he"llo"`` — an unterminated FTS5 string — and SQLite answered the whole
request with ``OperationalError: unterminated string``, i.e. a 500 on exactly
the query someone searching for a remembered line of manga dialogue types.

``match_expr`` is pure, so the quoting rule is pinned here directly; the
end-to-end test underneath proves the route no longer 500s on it.
"""

from __future__ import annotations

import json

import pytest
from sqlalchemy import delete, update

from database.models import ChapterOcr, FollowedSeries
from services.ocr_search import box_fractions, locate, match_expr, terms_of

SRC = "mangadex"
SERIES = "the-quoted-series"


# --- the pure rule --------------------------------------------------------


def test_plain_terms_are_quoted_one_by_one():
    assert match_expr("hello world") == '"hello" "world"'


def test_an_embedded_quote_is_doubled_not_left_to_terminate_the_string():
    """The regression. Doubling is how SQL string literals escape a quote, and
    FTS5 strings follow the same rule."""
    assert match_expr('he"llo') == '"he""llo"'


def test_a_bare_quote_is_a_term_of_its_own():
    assert match_expr('"') == '""""'


def test_punctuation_a_reader_types_stays_literal():
    assert match_expr("wait-what?! *sigh*") == '"wait-what?!" "*sigh*"'


def test_terms_and_expression_never_disagree_about_what_was_searched():
    """``terms_of`` also drives snippet highlighting, so a divergence would
    mark the wrong words in results that did match."""
    raw = '  the "crimson"   knight '
    assert terms_of(raw) == ["the", '"crimson"', "knight"]
    assert match_expr(raw) == '"the" """crimson""" "knight"'


# --- the same expression, through real SQLite FTS5 ------------------------


def test_a_nul_byte_separates_terms_instead_of_ending_the_query():
    """FTS5 treats NUL as the end of the query string, so a quoted term with
    one inside never closes: ``unterminated string``, and a 500."""
    assert terms_of("hey\x00you") == ["hey", "you"]
    assert match_expr("hey\x00you") == '"hey" "you"'
    assert terms_of("\x00\x01") == []


@pytest.mark.parametrize(
    "query", ['he"llo', '"', 'a "b" c', 'say "hi"', "hey\x00you", "x\x00"]
)
def test_the_expression_is_accepted_by_sqlite(db_session, query):
    """Straight at the engine: an unescaped quote raises OperationalError here,
    which is what surfaced as the route's 500."""
    from sqlalchemy import text

    db_session.execute(
        text("SELECT rowid FROM chapter_ocr_fts WHERE chapter_ocr_fts MATCH :q"),
        {"q": match_expr(query)},
    ).all()


# --- snippet highlighting --------------------------------------------------


def _snippet(text_value, raw_query):
    from services.ocr_search import OcrSearchService

    return OcrSearchService._snippet(
        text_value, [t.lower() for t in terms_of(raw_query)]
    )


def test_a_short_term_never_splits_the_marks_a_longer_one_added():
    """The regression. One ``re.sub`` per term ran over the output of the one
    before, so "a" matched inside the ``<mark>`` tags already added and the
    clients printed ``<m<mark>a</mark>rk>`` as literal text."""
    assert _snippet("I am a hunter, and that is all.", "i am a hunter") == (
        "<mark>I</mark> <mark>am</mark> <mark>a</mark> <mark>hunter</mark>, "
        "<mark>a</mark>nd th<mark>a</mark>t <mark>i</mark>s <mark>a</mark>ll."
    )


@pytest.mark.parametrize("query", ["hunter mark", "hunter /", "hunter k", "hunter <"])
def test_terms_found_in_the_tag_text_leave_the_tags_whole(query):
    got = _snippet("the hunter left", query)
    assert "<mark>hunter</mark>" in got
    stripped = got.replace("<mark>", "").replace("</mark>", "")
    assert stripped == "the hunter left"


def test_the_longest_term_still_wins_at_a_position():
    assert _snippet("the hunter", "hunt hunter") == "the <mark>hunter</mark>"


# --- end to end -----------------------------------------------------------


@pytest.fixture
def acct(make_user, make_profile):
    user = make_user("ocr-quote")
    profile = make_profile(user.id, "Main")
    return user.id, profile.id


@pytest.fixture
def h(as_user, acct):
    uid, pid = acct
    return as_user(uid, pid)


@pytest.fixture
def seeded(client, h, acct, seed_follow):
    uid, pid = acct
    seed_follow(
        uid, pid, source_id=SRC, series_key=SERIES,
        known_chapters='[{"key": "c1"}]',
    )
    up = client.post(
        "/ocr/chapter",
        json={
            "source_id": SRC,
            "series_key": SERIES,
            "chapter_key": "c1",
            "engine": "mlkit",
            "pages": [{"page": 1, "text": 'he said "hello" and left'}],
        },
        headers=h,
    )
    assert up.status_code == 200, up.text


@pytest.mark.parametrize("query", ['he"llo', '"', 'said "hello"'])
def test_a_query_with_a_quote_does_not_500(client, h, seeded, query):
    got = client.get("/ocr/search", params={"q": query}, headers=h)
    assert got.status_code == 200, got.text


@pytest.mark.parametrize("query", ["he\x00llo", "\x00", "said\x00hello"])
def test_a_query_with_a_nul_byte_does_not_500(client, h, seeded, query):
    got = client.get("/ocr/search", params={"q": query}, headers=h)
    assert got.status_code == 200, got.text


def test_a_nul_byte_between_words_still_finds_the_line(client, h, seeded):
    got = client.get("/ocr/search", params={"q": "said\x00left"}, headers=h)
    assert got.status_code == 200, got.text
    assert [hit["chapter_key"] for hit in got.json()["items"]] == ["c1"]


def test_a_quoted_phrase_still_finds_the_line(client, h, seeded):
    got = client.get("/ocr/search", params={"q": 'said "hello"'}, headers=h)
    assert got.status_code == 200, got.text
    assert [hit["chapter_key"] for hit in got.json()["items"]] == ["c1"]


# --- page and box (backend/02 F) -------------------------------------------


def _pages(*pages):
    return json.dumps(list(pages))


def test_locate_first_matching_page_and_box():
    raw = _pages(
        {"page": 3, "text": "the hunter again", "boxes": [
            {"text": "the hunter again", "x": 0.5, "y": 0.5, "width": 0.1, "height": 0.1}]},
        {"page": 1, "text": "nothing here", "boxes": []},
        {"page": 2, "text": "a line. I am a hunter", "boxes": [
            {"text": "a line.", "x": 0.1, "y": 0.1, "width": 0.2, "height": 0.05},
            {"text": "I am a HUNTER", "x": 0.123456, "y": 0.4, "width": 0.3, "height": 0.08},
            {"text": "hunter too", "x": 0.9, "y": 0.9, "width": 0.05, "height": 0.05},
        ]},
    )
    assert locate(raw, ["hunter"]) == (2, {"x": 0.1235, "y": 0.4, "w": 0.3, "h": 0.08})


def test_left_top_right_bottom_geometry_converts():
    box = {"left": 0.1, "top": 0.2, "right": 0.45, "bottom": 0.3}
    assert box_fractions(box) == {"x": 0.1, "y": 0.2, "w": 0.35, "h": 0.1}


@pytest.mark.parametrize("box", [
    {"x": 120, "y": 40, "width": 300, "height": 80},
    {"left": 10, "top": 20, "right": 300, "bottom": 90},
    {"x": 0.1, "y": 0.2, "width": 0.3},
    {"x": 0.1, "y": 0.2, "width": "0.3", "height": 0.1},
    {"x": 0.9, "y": -0.1, "width": 0.3, "height": 0.1},
    {"left": 0.5, "top": 0.2, "right": 0.4, "bottom": 0.3},
    {"text": "only text"},
])
def test_pixel_or_partial_geometry_gives_no_box(box):
    assert box_fractions(box) is None
    raw = _pages({"page": 4, "text": "hunter", "boxes": [{"text": "hunter", **box}]})
    assert locate(raw, ["hunter"]) == (4, None)


def test_page_text_match_without_a_matching_box_keeps_the_page():
    raw = _pages({"page": 1, "text": "the hunter", "boxes": None})
    assert locate(raw, ["hunter"]) == (1, None)


@pytest.mark.parametrize("raw", [None, "", "not json", "{}", _pages({"page": 1, "text": "x"})])
def test_no_page_texts_or_no_substring_match_gives_nulls(raw):
    assert locate(raw, ["hunter"]) == (None, None)


@pytest.fixture
def boxed(client, h, acct, seed_follow):
    uid, pid = acct
    seed_follow(uid, pid, source_id=SRC, series_key="boxed",
                known_chapters='[{"key": "b1"}, {"key": "b2"}]')
    for key, pages in (
        ("b1", [
            {"page": 1, "text": "opening narration"},
            {"page": 2, "text": "I will find the crimson knight", "boxes": [
                {"text": "I will find", "x": 0.1, "y": 0.1, "width": 0.2, "height": 0.1},
                {"text": "the crimson knight", "x": 0.25, "y": 0.5, "width": 0.4,
                 "height": 0.12}]},
        ]),
        ("b2", [{"page": 1, "text": "crimson skies over the city", "boxes": [
            {"text": "crimson skies", "x": 40, "y": 60, "width": 200, "height": 90}]}]),
    ):
        up = client.post("/ocr/chapter", json={
            "source_id": SRC, "series_key": "boxed", "chapter_key": key,
            "engine": "vision", "pages": pages}, headers=h)
        assert up.status_code == 200, up.text


def test_search_items_carry_page_and_box(client, h, boxed):
    got = client.get("/ocr/search", params={"q": "crimson"}, headers=h)
    assert got.status_code == 200, got.text
    by_key = {i["chapter_key"]: i for i in got.json()["items"]}
    assert by_key["b1"]["page"] == 2
    assert by_key["b1"]["box"] == {"x": 0.25, "y": 0.5, "w": 0.4, "h": 0.12}
    assert by_key["b2"]["page"] == 1 and by_key["b2"]["box"] is None


def test_a_row_without_page_texts_gives_nulls(client, h, boxed, db_session):
    db_session.execute(update(ChapterOcr).where(ChapterOcr.chapter_key == "b1")
                       .values(page_texts=None))
    db_session.commit()
    items = client.get("/ocr/search", params={"q": "knight"}, headers=h).json()["items"]
    assert [(i["chapter_key"], i["page"], i["box"]) for i in items] == [("b1", None, None)]


def test_unfollowed_and_gated_series_stay_absent(client, h, boxed, db_session):
    db_session.execute(update(FollowedSeries).where(FollowedSeries.series_key == "boxed")
                       .values(mature_override=True))
    db_session.commit()
    assert client.get("/ocr/search", params={"q": "crimson"}, headers=h).json()["items"] == []
    db_session.execute(update(FollowedSeries).where(FollowedSeries.series_key == "boxed")
                       .values(mature_override=None))
    db_session.commit()
    assert len(client.get("/ocr/search", params={"q": "crimson"}, headers=h).json()["items"]) == 2
    db_session.execute(delete(FollowedSeries).where(FollowedSeries.series_key == "boxed"))
    db_session.commit()
    assert client.get("/ocr/search", params={"q": "crimson"}, headers=h).json()["items"] == []
