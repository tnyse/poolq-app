#!/usr/bin/env python3
"""Seed mock PRE1 2026 final scores for testing (local JSON + Firestore).

Usage:
  python3 scripts/seed_mock_pre1_scores.py

Idempotent: game_results docs keyed by ESPN game id.
Also scores verified/auto_verified pickrecord docs for PRE1.
"""

from __future__ import annotations

import json
import subprocess
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PROJECT = "nflgamesapp"
WEEK = "PRE1"
ROOT = Path(__file__).resolve().parents[1]
SCHEDULE = ROOT / "assets" / "data" / "nfl_schedule_2026.json"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"

# Deterministic mock finals (home, away) — one per PRE1 game in schedule order.
# Varied winners so leaderboard differentiation is meaningful.
MOCK_SCORES: list[tuple[int, int]] = [
    (24, 17),  # DET @ CIN → CIN
    (14, 27),  # GB @ PIT → GB
    (20, 23),  # IND @ NE → IND
    (31, 28),  # ARI @ LV → ARI
    (17, 21),  # LAC @ HOU → LAC
    (13, 24),  # TEN @ SF → TEN
    (27, 20),  # DEN @ ATL → DEN? wait home ATL 27 away DEN 20 → ATL
    (16, 19),  # TB @ NYJ → TB
    (22, 25),  # MIA @ WAS → MIA
    (10, 28),  # CAR @ BUF → CAR? home BUF 28 away CAR 10 → BUF
    (21, 17),  # CLE @ CHI → CLE
    (24, 21),  # MIN @ NYG → MIN
    (14, 31),  # LAR @ KC → LAR? home KC 31 away LAR 14 → KC
    (27, 24),  # JAX @ NO → JAX
    (20, 17),  # PHI @ BAL → PHI
    (23, 26),  # DAL @ SEA → DAL? home SEA 26 away DAL 23 → SEA
]


def token() -> str:
    return subprocess.check_output(
        ["gcloud", "auth", "print-access-token"], text=True
    ).strip()


def auth_headers() -> dict:
    return {
        "Authorization": f"Bearer {token()}",
        "Content-Type": "application/json",
    }


def parse_iso(s: str) -> datetime:
    raw = s.replace("Z", "+00:00")
    # Handle missing seconds: 2026-08-13T23:00+00:00
    if "T" in raw and raw.count(":") == 1:
        raw = raw.replace("+", ":00+").replace("-", ":00-", 2) if False else raw
    try:
        return datetime.fromisoformat(raw)
    except ValueError:
        # 2026-08-13T23:00Z → add seconds
        if "T" in s and s.endswith("Z") and s.count(":") == 1:
            return datetime.fromisoformat(s[:-1] + ":00+00:00")
        raise


def sval(f):
    if not f:
        return None
    if "stringValue" in f:
        return f["stringValue"]
    if "integerValue" in f:
        return int(f["integerValue"])
    if "doubleValue" in f:
        return f["doubleValue"]
    if "booleanValue" in f:
        return f["booleanValue"]
    if "arrayValue" in f:
        return [sval(v) for v in f["arrayValue"].get("values", [])]
    if "timestampValue" in f:
        return f["timestampValue"]
    return str(f)


def patch_doc(path: str, fields: dict, masks: list[str] | None = None) -> dict:
    if masks is None:
        masks = list(fields.keys())
    q = "&".join(f"updateMask.fieldPaths={m}" for m in masks)
    url = f"{BASE}/{path}?{q}"
    body = json.dumps({"fields": fields}).encode()
    req = urllib.request.Request(url, data=body, method="PATCH", headers=auth_headers())
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def put_doc(path: str, fields: dict) -> dict:
    url = f"{BASE}/{path}"
    body = json.dumps({"fields": fields}).encode()
    req = urllib.request.Request(url, data=body, method="PATCH", headers=auth_headers())
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def run_query(structured: dict) -> list:
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents:runQuery"
    req = urllib.request.Request(
        url,
        data=json.dumps({"structuredQuery": structured}).encode(),
        method="POST",
        headers=auth_headers(),
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def int_field(n: int) -> dict:
    return {"integerValue": str(int(n))}


def str_field(s: str) -> dict:
    return {"stringValue": s}


def bool_field(b: bool) -> dict:
    return {"booleanValue": bool(b)}


def ts_field(dt: datetime) -> dict:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return {"timestampValue": dt.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")}


def update_local_schedule(games: list, scores: list[tuple[int, int]]) -> None:
    data = json.loads(SCHEDULE.read_text())
    week = data["weeks"][WEEK]
    assert len(week) == len(scores), f"score count {len(scores)} != games {len(week)}"
    for game, (home, away) in zip(week, scores):
        game["homeScore"] = home
        game["awayScore"] = away
        game["completed"] = True
        game["status"] = "STATUS_FINAL"
        game["statusDetail"] = "Final"
    data["lastUpdated"] = datetime.now(timezone.utc).isoformat()
    SCHEDULE.write_text(json.dumps(data, indent=2) + "\n")
    print(f"✅ Updated local schedule {SCHEDULE.name} — {WEEK} marked final")


def seed_firestore_results(games: list, scores: list[tuple[int, int]]) -> list[dict]:
    results = []
    for game, (home, away) in zip(games, scores):
        gid = str(game["id"])
        home_abbr = game["homeTeam"]["abbreviation"]
        away_abbr = game["awayTeam"]["abbreviation"]
        winner = home_abbr if home > away else away_abbr
        kickoff = parse_iso(game["date"])
        fields = {
            "weekName": str_field(WEEK),
            "homeTeam": str_field(game["homeTeam"]["name"]),
            "awayTeam": str_field(game["awayTeam"]["name"]),
            "homeTeamAbbr": str_field(home_abbr),
            "awayTeamAbbr": str_field(away_abbr),
            "homeScore": int_field(home),
            "awayScore": int_field(away),
            "winner": str_field(winner),
            "gameDate": ts_field(kickoff),
            "status": str_field("final"),
            "source": str_field("mock_test"),
            "lastUpdated": ts_field(datetime.now(timezone.utc)),
            "espnId": str_field(gid),
        }
        put_doc(f"game_results/{gid}", fields)
        results.append(
            {
                "id": gid,
                "home": home_abbr,
                "away": away_abbr,
                "homeScore": home,
                "awayScore": away,
                "winner": winner,
                "total": home + away,
            }
        )
        print(f"  {away_abbr:3s} {away:2d} @ {home_abbr:3s} {home:2d} → {winner}")
    print(f"✅ Seeded {len(results)} game_results for {WEEK}")
    return results


def score_pickrecords(results: list[dict]) -> None:
    winners = [r["winner"] for r in results]
    tb_total = results[-1]["total"]  # last game total (tiebreaker)

    # Firestore whereIn with two statuses — run two queries and merge
    docs = {}
    for status in ("verified", "auto_verified"):
        rows = run_query(
            {
                "from": [{"collectionId": "pickrecord"}],
                "where": {
                    "compositeFilter": {
                        "op": "AND",
                        "filters": [
                            {
                                "fieldFilter": {
                                    "field": {"fieldPath": "week"},
                                    "op": "EQUAL",
                                    "value": str_field(WEEK),
                                }
                            },
                            {
                                "fieldFilter": {
                                    "field": {"fieldPath": "paymentStatus"},
                                    "op": "EQUAL",
                                    "value": str_field(status),
                                }
                            },
                        ],
                    }
                },
            }
        )
        for row in rows:
            doc = row.get("document")
            if not doc:
                continue
            docs[doc["name"]] = doc

    if not docs:
        print("⚠️  No verified/auto_verified PRE1 pickrecords to score")
        return

    scored = []
    for name, doc in docs.items():
        fields = doc.get("fields", {})
        picks = sval(fields.get("picks")) or []
        tb = sval(fields.get("tiebreaker")) or 0
        correct = 0
        for i, pick in enumerate(picks):
            if i < len(winners) and pick == winners[i]:
                correct += 1
        diff = abs(int(tb) - tb_total)
        scored.append(
            {
                "path": "/".join(name.split("/")[-2:]),  # pickrecord/ID
                "id": name.split("/")[-1],
                "name": sval(fields.get("displayName")),
                "score": correct,
                "tiebreakerDiff": diff,
            }
        )

    scored.sort(key=lambda x: (-x["score"], x["tiebreakerDiff"]))
    for rank, entry in enumerate(scored, start=1):
        patch_doc(
            f"pickrecord/{entry['id']}",
            {
                "score": int_field(entry["score"]),
                "rank": int_field(rank),
                "tiebreakerDiff": int_field(entry["tiebreakerDiff"]),
            },
            ["score", "rank", "tiebreakerDiff"],
        )
        print(
            f"  #{rank} {entry['name']}: {entry['score']}/{len(winners)} "
            f"(TB diff {entry['tiebreakerDiff']})"
        )
    print(f"✅ Scored {len(scored)} pickrecord(s); TB actual total={tb_total}")


def main() -> None:
    data = json.loads(SCHEDULE.read_text())
    games = data["weeks"][WEEK]
    if len(MOCK_SCORES) != len(games):
        raise SystemExit(
            f"MOCK_SCORES has {len(MOCK_SCORES)} entries but {WEEK} has {len(games)} games"
        )

    print(f"Seeding mock finals for {WEEK} ({len(games)} games)…")
    update_local_schedule(games, MOCK_SCORES)
    # re-read after write
    games = json.loads(SCHEDULE.read_text())["weeks"][WEEK]
    results = seed_firestore_results(games, MOCK_SCORES)
    score_pickrecords(results)
    print("\nDone. Hot-restart the app to see schedule/leaderboard updates.")


if __name__ == "__main__":
    main()
