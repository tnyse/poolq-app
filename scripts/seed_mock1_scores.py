#!/usr/bin/env python3
"""Seed MOCK1 simulated finals into Firestore game_results (+ optional local JSON finals).

Reads assets/data/mock_week_answer_key.json produced by rebuild_2026_schedule_from_espn.py.

Usage:
  python3 scripts/seed_mock1_scores.py
  python3 scripts/seed_mock1_scores.py --mark-local-final
"""

from __future__ import annotations

import argparse
import json
import subprocess
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PROJECT = "nflgamesapp"
WEEK = "MOCK1"
ROOT = Path(__file__).resolve().parents[1]
SCHEDULE = ROOT / "assets" / "data" / "nfl_schedule_2026.json"
ANSWER_KEY = ROOT / "assets" / "data" / "mock_week_answer_key.json"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"


def token() -> str:
    return subprocess.check_output(
        ["gcloud", "auth", "print-access-token"], text=True
    ).strip()


def auth_headers() -> dict:
    return {
        "Authorization": f"Bearer {token()}",
        "Content-Type": "application/json",
    }


def int_field(n: int) -> dict:
    return {"integerValue": str(int(n))}


def str_field(s: str) -> dict:
    return {"stringValue": s}


def ts_field(dt: datetime) -> dict:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return {
        "timestampValue": dt.astimezone(timezone.utc)
        .isoformat()
        .replace("+00:00", "Z")
    }


def put_doc(path: str, fields: dict) -> None:
    url = f"{BASE}/{path}"
    body = json.dumps({"fields": fields}).encode()
    req = urllib.request.Request(
        url, data=body, method="PATCH", headers=auth_headers()
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        resp.read()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mark-local-final",
        action="store_true",
        help="Also mark MOCK1 games final in local schedule JSON",
    )
    args = parser.parse_args()

    key = json.loads(ANSWER_KEY.read_text())
    games = key["games"]
    schedule = json.loads(SCHEDULE.read_text())
    local_by_id = {g["id"]: g for g in schedule["weeks"].get(WEEK, [])}

    print(f"Seeding {len(games)} MOCK1 game_results...")
    for g in games:
        local = local_by_id.get(g["id"], {})
        kickoff = local.get("date") or datetime.now(timezone.utc).isoformat()
        try:
            raw = kickoff.replace("Z", "+00:00")
            if raw.count(":") == 1:
                raw = raw.replace("+00:00", ":00+00:00")
            kick_dt = datetime.fromisoformat(raw)
        except Exception:
            kick_dt = datetime.now(timezone.utc)

        fields = {
            "weekName": str_field(WEEK),
            "homeTeam": str_field(local.get("homeTeam", {}).get("name", g["homeTeamAbbr"])),
            "awayTeam": str_field(local.get("awayTeam", {}).get("name", g["awayTeamAbbr"])),
            "homeTeamAbbr": str_field(g["homeTeamAbbr"]),
            "awayTeamAbbr": str_field(g["awayTeamAbbr"]),
            "homeScore": int_field(g["homeScore"]),
            "awayScore": int_field(g["awayScore"]),
            "winner": str_field(g["winner"]),
            "gameDate": ts_field(kick_dt),
            "status": str_field("final"),
            "source": str_field("mock_test"),
            "lastUpdated": ts_field(datetime.now(timezone.utc)),
            "espnId": str_field(g["id"]),
        }
        put_doc(f"game_results/{g['id']}", fields)
        print(
            f"  {g['awayTeamAbbr']:3s} {g['awayScore']:2d} @ "
            f"{g['homeTeamAbbr']:3s} {g['homeScore']:2d} → {g['winner']}"
        )

    if args.mark_local_final:
        for g in schedule["weeks"].get(WEEK, []):
            ans = next((a for a in games if a["id"] == g["id"]), None)
            if not ans:
                continue
            g["homeScore"] = ans["homeScore"]
            g["awayScore"] = ans["awayScore"]
            g["completed"] = True
            g["status"] = "STATUS_FINAL"
            g["statusDetail"] = "Final (mock)"
        schedule["lastUpdated"] = datetime.now(timezone.utc).isoformat()
        SCHEDULE.write_text(json.dumps(schedule, indent=2) + "\n")
        print("✅ Local MOCK1 marked final")

    print("✅ Done — admin can Declare Week Results for MOCK1 after users pick")


if __name__ == "__main__":
    main()
