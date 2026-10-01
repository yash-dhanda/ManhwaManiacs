"""Letters: Recommend to / Pass it on, and the /home sections they feed (backend/09)."""

from __future__ import annotations

import pytest
from sqlalchemy import func, select, update

from database.models import CircleLetter, ReadingProfile
from tests.test_home_feed import SRC as HOME_SRC
from tests.test_home_feed import chapters, env, read  # noqa: F401  (env is autouse there)

SRC = "asurascans"
MATURE_SRC = "18porncomic"
X = "series-x"
SECRET = "SECRETMATURETITLE"


@pytest.fixture
def world(make_user, make_profile):
    u1, u2, u3 = make_user("acct1"), make_user("acct2"), make_user("acct3")
    return {
        "u1": u1.id, "u2": u2.id, "u3": u3.id,
        "a": make_profile(u1.id, "A", mature_content_enabled=True).id,
        "b": make_profile(u1.id, "B").id,
        "c": make_profile(u2.id, "C").id,
    }


@pytest.fixture
def H(as_user, world):
    def make(who: str) -> dict:
        u = {"a": "u1", "b": "u1", "c": "u2"}[who]
        return as_user(world[u], world[who])

    return make


def sharing(client, H, world, who, **body):
    r = client.patch(f"/profiles/{world[who]}/sharing", json={"activity": True, **body}, headers=H(who))
    assert r.status_code == 200, r.text


def send(client, H, world, who, to, series=X, src=SRC, note=None):
    body = {"to_profile_ids": [world.get(t, t) for t in to], "source_id": src, "series_key": series}
    if note is not None:
        body["note"] = note
    return client.post("/circle/letters", json=body, headers=H(who))


def inbox(client, H, who, **params):
    r = client.get("/circle/letters", params=params, headers=H(who))
    assert r.status_code == 200, r.text
    return r.json()


def test_send_inbox_and_sent_box(client, H, world):
    for who in ("a", "b", "c"):
        sharing(client, H, world, who)
    r = send(client, H, world, "a", ["b", "c"], note="  you'll love the tower arc.  ")
    assert r.status_code == 201
    sent = r.json()
    assert isinstance(sent["id"], str) and len(sent["id"]) == 32
    assert [t["state"] for t in sent["to"]] == ["new", "new"] and sent["note"] == "you'll love the tower arc."
    for who in ("b", "c"):
        (letter,) = inbox(client, H, who)
        assert isinstance(letter["id"], int) and letter["state"] == "new"
        assert letter["from"]["name"] == "A" and letter["title"] == X
        assert {"ambient", "palette", "content_kind", "cover_url"} <= set(letter)
    (row,) = inbox(client, H, "a", box="sent")
    assert row["id"] == sent["id"] and {t["profile_id"] for t in row["to"]} == {world["b"], world["c"]}
    assert client.get("/circle/letters", params={"box": "outbox"}, headers=H("a")).status_code == 422


def test_recipient_unavailable_writes_nothing(client, H, world, db_session):
    sharing(client, H, world, "a")
    sharing(client, H, world, "b", recommendations=False)
    # c does not share
    for to, bad in (
        (["b"], [world["b"]]), (["c"], [world["c"]]), (["a"], [world["a"]]), ([9999], [9999]),
    ):
        r = send(client, H, world, "a", to)
        assert r.status_code == 409 and r.json()["code"] == "recipient_unavailable"
        assert r.json()["details"] == {"profile_ids": bad}
    sharing(client, H, world, "c")
    r = send(client, H, world, "a", ["c", "b", 9999])
    assert r.status_code == 409 and sorted(r.json()["details"]["profile_ids"]) == sorted([world["b"], 9999])
    assert db_session.execute(select(func.count()).select_from(CircleLetter)).scalar_one() == 0
    assert inbox(client, H, "c") == [] and inbox(client, H, "a", box="sent") == []


def test_validation(client, H, world):
    sharing(client, H, world, "a")
    sharing(client, H, world, "c")
    assert send(client, H, world, "a", ["c"], note="x" * 141).status_code == 422
    assert send(client, H, world, "a", ["c"], note="x" * 140).status_code == 201
    # Emoji count as one each, as on the phone: 2-code-point flags and skin tones, a 7-code-point family.
    emoji = "\U0001F1EE\U0001F1F3" * 60 + "\U0001F44D\U0001F3FD" * 60 + "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466" * 20
    assert send(client, H, world, "a", ["c"], note=emoji).status_code == 201
    assert send(client, H, world, "a", ["c"], note=emoji + "x").status_code == 422
    assert send(client, H, world, "a", [], note="hi").status_code == 422
    assert send(client, H, world, "a", list(range(100, 111))).status_code == 422
    assert send(client, H, world, "a", ["c", "c"]).status_code == 422
    r = send(client, H, world, "a", ["c"], note="   ")
    assert r.status_code == 201 and r.json()["note"] is None


@pytest.fixture
def mature(client, as_user, make_user, make_profile, seed_follow, world):
    """A (open gate) plus R1 (gate closed), R2 (open, include off), R3 (open, include on)."""
    u = world["u2"]
    r1 = make_profile(u, "R1", mature_content_enabled=False)
    r2 = make_profile(u, "R2", mature_content_enabled=True)
    r3 = make_profile(u, "R3", mature_content_enabled=True)
    ids = {"r1": r1.id, "r2": r2.id, "r3": r3.id}
    hs = {k: as_user(u, v) for k, v in ids.items()}
    ha = as_user(world["u1"], world["a"])
    seed_follow(world["u1"], world["a"], source_id=MATURE_SRC, series_key="m", title=SECRET)
    client.patch(f"/profiles/{world['a']}/sharing", json={"activity": True}, headers=ha)
    for k in ids:
        client.patch(
            f"/profiles/{ids[k]}/sharing",
            json={"activity": True, "include_mature": k != "r2"}, headers=hs[k],
        )
    return ids, hs, ha


def test_mature_can_receive_matrix_and_no_reason(client, world, mature):
    ids, hs, ha = mature
    r = client.get(
        "/circle/members", params={"source_id": MATURE_SRC, "series_key": "m"}, headers=ha
    )
    cells = {m["name"]: m for m in r.json()}
    assert [cells[n]["can_receive"] for n in ("R1", "R2", "R3")] == [False, False, True]
    assert all(not ({"reason", "why"} & set(m)) for m in cells.values())
    plain = client.get("/circle/members", headers=ha).json()
    assert all("can_receive" not in m for m in plain)
    for params in ({"source_id": MATURE_SRC}, {"series_key": "m"}):
        assert client.get("/circle/members", params=params, headers=ha).status_code == 422
    for k, expect in (("r1", 409), ("r2", 409), ("r3", 201)):
        assert send(client, lambda _w: ha, world, "a", [ids[k]], series="m", src=MATURE_SRC).status_code == expect


def test_a_mature_title_never_reaches_a_gated_recipient(client, world, mature, db_session):
    ids, hs, ha = mature
    assert send(client, lambda _w: ha, world, "a", [ids["r3"]], series="m", src=MATURE_SRC, note="hi").status_code == 201
    home = lambda: client.get("/home", params={"content_kind": "manga", "tz_offset_minutes": 0}, headers=hs["r3"])  # noqa: E731
    (letter,) = inbox(client, lambda _w: hs["r3"], "r3")
    assert letter["title"] == SECRET
    assert [i["title"] for s in home().json()["sections"] if s["type"] == "sent_to_you" for i in s["items"]] == [SECRET]
    db_session.execute(update(ReadingProfile).where(ReadingProfile.id == ids["r3"]).values(mature_content_enabled=False))
    db_session.commit()
    assert inbox(client, lambda _w: hs["r3"], "r3") == []
    body = home()
    assert body.status_code == 200 and SECRET not in body.text
    assert [s for s in body.json()["sections"] if s["type"] == "sent_to_you"][0]["items"] == []
    assert all(i["kind"] != "letter" for i in body.json()["also"])
    for path in ("/circle/members", "/circle/feed", "/circle/letters"):
        assert SECRET not in client.get(path, headers=hs["r3"]).text
    r = client.patch(f"/circle/letters/{letter['id']}", json={"state": "read"}, headers=hs["r3"])
    assert r.status_code == 404
    # a gated sender cannot probe the rating through who may receive it
    db_session.execute(update(ReadingProfile).where(ReadingProfile.id == world["a"]).values(mature_content_enabled=False))
    db_session.commit()
    r = send(client, lambda _w: ha, world, "a", [ids["r2"]], series="m", src=MATURE_SRC)
    assert r.status_code == 404 and r.json()["code"] == "series_not_found"
    assert client.get("/circle/members", params={"source_id": MATURE_SRC, "series_key": "m"}, headers=ha).status_code == 404
    assert inbox(client, lambda _w: ha, "a", box="sent") == []


def test_patch_states(client, H, world):
    for who in ("a", "b", "c"):
        sharing(client, H, world, who)
    send(client, H, world, "a", ["b", "c"], note="n")
    lid = inbox(client, H, "c")[0]["id"]
    patch = lambda who, state, i=None: client.patch(  # noqa: E731
        f"/circle/letters/{i or lid}", json={"state": state}, headers=H(who)
    )
    assert patch("c", "new").status_code == 422 and patch("c", "bogus").status_code == 422
    assert patch("b", "read").status_code == 404 and patch("c", "read", 99999).status_code == 404
    assert patch("c", "read").json()["state"] == "read"
    assert patch("c", "kept").json()["state"] == "kept"
    (row,) = inbox(client, H, "a", box="sent")
    assert row["state"] == "new"  # B has not opened it
    assert {t["profile_id"]: t["state"] for t in row["to"]} == {world["b"]: "new", world["c"]: "read"}
    assert patch("c", "dismissed").json()["state"] == "dismissed"
    assert inbox(client, H, "c") == []
    (row,) = inbox(client, H, "a", box="sent")
    assert {t["state"] for t in row["to"]} == {"new", "read"}


def test_home_sent_to_you_and_also(client, as_user, make_user, make_profile, seed_follow, seed_progress, world):
    """Viewer R follows four series; S (another account) sends letters."""
    ru = make_user("reader")
    r = make_profile(ru.id, "R", mature_content_enabled=True)
    hr, hs = as_user(ru.id, r.id), as_user(world["u2"], world["c"])
    client.patch(f"/profiles/{world['c']}/sharing", json={"activity": True}, headers=hs)
    client.patch(f"/profiles/{r.id}/sharing", json={"activity": True}, headers=hr)
    acct = (ru.id, r.id)
    for key, title, n in (("a", "Alpha Tale", 6), ("b", "Bravo Tale", 6), ("c", "Charlie Tale", 4)):
        seed_follow(*acct, source_id=HOME_SRC, series_key=key, title=title, known_chapters=chapters(n))
    read(seed_progress, acct, "a", 2)  # cover story
    read(seed_progress, acct, "b", 4, ago_days=2)
    read(seed_progress, acct, "c", 3, ago_days=3)

    def home():
        return client.get("/home", params={"content_kind": "manga", "tz_offset_minutes": 0}, headers=hr).json()

    def letter(series, note=None, src=HOME_SRC):
        body = {"to_profile_ids": [r.id], "source_id": src, "series_key": series}
        if note:
            body["note"] = note
        assert client.post("/circle/letters", json=body, headers=hs).status_code == 201

    body = home()  # primes the composed cache
    assert body["cover"]["series_key"] == "a" and all(i["kind"] != "letter" for i in body["also"])
    letter("zeta", note="older note")
    letter("eta", note="newest note")
    body = home()  # computed per request, not from the cache
    (sec,) = [s for s in body["sections"] if s["type"] == "sent_to_you"]
    assert [i["series_key"] for i in sec["items"]] == ["eta", "zeta"]
    assert sec["note"] == "newest note" and sec["state"] == "ready" and sec["title"] == "Sent to you"
    kinds = [i["kind"] for i in body["also"]]
    assert kinds == ["new_chapters", "letter", "almost_there"]
    got = body["also"][1]
    assert got["headline"] == "C recommends eta" and got["deck"] == "newest note" and got["series_key"] == "eta"
    # the cover story's series is never repeated
    lid = client.get("/circle/letters", headers=hr).json()
    for row in lid:
        client.patch(f"/circle/letters/{row['id']}", json={"state": "dismissed"}, headers=hr)
    letter("a", note="same as the cover")
    assert all(i["kind"] != "letter" for i in home()["also"])
    order = [s["type"] for s in home()["sections"]]
    assert order.index("sent_to_you") < order.index("circle") if "circle" in order else True
    # kept stays in the section, read letters leave the also candidate
    letter("kappa", note="k")
    lid = [x for x in client.get("/circle/letters", headers=hr).json() if x["series_key"] == "kappa"][0]["id"]
    client.patch(f"/circle/letters/{lid}", json={"state": "kept"}, headers=hr)
    body = home()
    assert "kappa" in [i["series_key"] for s in body["sections"] if s["type"] == "sent_to_you" for i in s["items"]]
    assert all(i["kind"] != "letter" or i["series_key"] != "kappa" for i in body["also"])
