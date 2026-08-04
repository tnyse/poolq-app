#!/usr/bin/env python3
"""Rebuild nfl_schedule_2026.json from ESPN Core API + add MOCK1 test week.

Also:
  - blanks scores on all real weeks (scheduled, not final)
  - writes assets/data/mock_week_answer_key.json (simulated finals for MOCK1)
  - optionally wipes Firestore pickrecord/game_results and sets activeWeek=MOCK1

Usage:
  python3 scripts/rebuild_2026_schedule_from_espn.py
  python3 scripts/rebuild_2026_schedule_from_espn.py --wipe-firestore
"""

from __future__ import annotations

import argparse
import json
import subprocess
import time
import urllib.request
from datetime import datetime, timezone, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEDULE = ROOT / "assets" / "data" / "nfl_schedule_2026.json"
ANSWER_KEY = ROOT / "assets" / "data" / "mock_week_answer_key.json"
PROJECT = "nflgamesapp"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"

HEADERS = {
    "User-Agent": "Mozilla/5.0 PoolQScheduleBot/1.0",
    "Accept": "application/json",
    "Referer": "https://www.espn.com/",
}

# ESPN type=1 week N → our key (week 1 = HoF)
PRE_MAP = {
    1: ("PRE0", 0),
    2: ("PRE1", 1),
    3: ("PRE2", 2),
    4: ("PRE3", 3),
}

# Deterministic MOCK1 slate (away @ home) + simulated finals (home, away)
MOCK1_GAMES: list[tuple[str, str, tuple[int, int]]] = [
    ("DAL", "PHI", (27, 20)),  # PHI
    ("KC", "BUF", (21, 24)),   # KC
    ("SF", "SEA", (14, 17)),   # SF
    ("BAL", "CIN", (24, 28)),  # BAL
    ("DET", "GB", (28, 31)),   # DET
    ("MIA", "NYJ", (21, 14)),  # NYJ
    ("LAR", "CHI", (17, 24)),  # LAR
    ("DEN", "LAC", (23, 20)),  # DEN
]

TEAM_META = {
    "ARI": ("Arizona Cardinals", "22", "97233f"),
    "ATL": ("Atlanta Falcons", "1", "a71930"),
    "BAL": ("Baltimore Ravens", "33", "241773"),
    "BUF": ("Buffalo Bills", "2", "00338d"),
    "CAR": ("Carolina Panthers", "29", "0085ca"),
    "CHI": ("Chicago Bears", "3", "0b162a"),
    "CIN": ("Cincinnati Bengals", "4", "fb4f14"),
    "CLE": ("Cleveland Browns", "5", "311d00"),
    "DAL": ("Dallas Cowboys", "6", "002244"),
    "DEN": ("Denver Broncos", "7", "fb4f14"),
    "DET": ("Detroit Lions", "8", "0076b6"),
    "GB": ("Green Bay Packers", "9", "203731"),
    "HOU": ("Houston Texans", "34", "03202f"),
    "IND": ("Indianapolis Colts", "11", "002c5f"),
    "JAX": ("Jacksonville Jaguars", "30", "006778"),
    "KC": ("Kansas City Chiefs", "12", "e31837"),
    "LAC": ("Los Angeles Chargers", "24", "0080c6"),
    "LAR": ("Los Angeles Rams", "14", "003594"),
    "LV": ("Las Vegas Raiders", "13", "000000"),
    "MIA": ("Miami Dolphins", "15", "008e97"),
    "MIN": ("Minnesota Vikings", "16", "4f2683"),
    "NE": ("New England Patriots", "17", "002244"),
    "NO": ("New Orleans Saints", "18", "d3bc8d"),
    "NYG": ("New York Giants", "19", "0b2265"),
    "NYJ": ("New York Jets", "20", "125740"),
    "PHI": ("Philadelphia Eagles", "21", "004c54"),
    "PIT": ("Pittsburgh Steelers", "23", "ffb612"),
    "SEA": ("Seattle Seahawks", "26", "002244"),
    "SF": ("San Francisco 49ers", "25", "aa0000"),
    "TB": ("Tampa Bay Buccaneers", "27", "d50a0a"),
    "TEN": ("Tennessee Titans", "10", "0c2340"),
    "WSH": ("Washington Commanders", "28", "5a1414"),
    "WAS": ("Washington Commanders", "28", "5a1414"),
}


def http_get(url: str) -> dict:
    url = url.replace("http://", "https://")
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=45) as resp:
        return json.loads(resp.read().decode())


def team_obj(abbr: str) -> dict:
    key = "WSH" if abbr == "WAS" else abbr
    name, tid, color = TEAM_META.get(key, (abbr, "0", "063a73"))
    return {
        "id": tid,
        "name": name,
        "abbreviation": key,
        "logo": f"assets/images/teams/{key}.png",
        "color": color,
    }


def competitors_from_event(ed: dict) -> tuple[dict, dict]:
    """Return (home, away) team dicts. Prefer shortName; Core API teams are $refs."""
    sn = (ed.get("shortName") or "").upper().replace(" VS ", " @ ")
    parts = [p.strip() for p in sn.split("@") if p.strip()]
    if len(parts) != 2:
        raise ValueError(
            f"Cannot parse shortName for event {ed.get('id')}: {ed.get('shortName')}"
        )
    away = team_obj(parts[0])
    home = team_obj(parts[1])

    competitions = ed.get("competitions") or []
    comps = []
    if competitions and isinstance(competitions[0], dict):
        comps = competitions[0].get("competitors") or []
    for c in comps:
        if not isinstance(c, dict):
            continue
        tid = str(c.get("id") or "")
        if c.get("homeAway") == "home" and tid:
            home["id"] = tid
        elif c.get("homeAway") == "away" and tid:
            away["id"] = tid
    return home, away


def venue_from_event(ed: dict) -> str:
    competitions = ed.get("competitions") or []
    if competitions and isinstance(competitions[0], dict):
        venue = competitions[0].get("venue") or {}
        if isinstance(venue, dict):
            return venue.get("fullName") or ""
    return ""


def normalize_game(
    ed: dict,
    week: str,
    mode: str,
    week_number: int,
    year: int = 2026,
) -> dict:
    home, away = competitors_from_event(ed)
    return {
        "id": str(ed.get("id") or ""),
        "date": ed.get("date"),
        "name": ed.get("name") or f"{away['name']} at {home['name']}",
        "shortName": f"{away['abbreviation']} @ {home['abbreviation']}",
        "week": week,
        "mode": mode,
        "weekNumber": week_number,
        "year": year,
        "homeTeam": home,
        "awayTeam": away,
        "homeScore": None,
        "awayScore": None,
        "status": "STATUS_SCHEDULED",
        "statusDetail": "Scheduled",
        "completed": False,
        "venue": venue_from_event(ed),
        "broadcast": "",
    }


def fetch_week_games(seasontype: int, week_num: int) -> tuple[dict, list[dict]]:
    base = (
        "https://sports.core.api.espn.com/v2/sports/football/leagues/nfl"
        f"/seasons/2026/types/{seasontype}/weeks/{week_num}"
    )
    meta = http_get(base)
    ev_ref = meta["events"]["$ref"]
    sep = "&" if "?" in ev_ref else "?"
    evs = http_get(ev_ref.replace("http://", "https://") + f"{sep}limit=100")
    games = []
    for item in evs.get("items") or []:
        ed = http_get(item["$ref"])
        games.append(ed)
        time.sleep(0.04)
    return meta, games


def build_mock1(now: datetime) -> list[dict]:
    """8 pickable games starting ~2h from now, staggered."""
    games = []
    start = now + timedelta(hours=2)
    for i, (away, home, _scores) in enumerate(MOCK1_GAMES):
        kick = start + timedelta(hours=i * 3)
        away_t, home_t = team_obj(away), team_obj(home)
        games.append(
            {
                "id": f"mock1-{i+1:02d}",
                "date": kick.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "name": f"{away_t['name']} at {home_t['name']}",
                "shortName": f"{away_t['abbreviation']} @ {home_t['abbreviation']}",
                "week": "MOCK1",
                "mode": "MOCK",
                "weekNumber": 1,
                "year": 2026,
                "homeTeam": home_t,
                "awayTeam": away_t,
                "homeScore": None,
                "awayScore": None,
                "status": "STATUS_SCHEDULED",
                "statusDetail": "Mock test — scheduled",
                "completed": False,
                "venue": "Mock Stadium",
                "broadcast": "TEST",
            }
        )
    return games


def write_answer_key(mock_games: list[dict]) -> None:
    results = []
    for game, (_a, _h, (home_score, away_score)) in zip(mock_games, MOCK1_GAMES):
        home = game["homeTeam"]["abbreviation"]
        away = game["awayTeam"]["abbreviation"]
        winner = home if home_score > away_score else away
        results.append(
            {
                "id": game["id"],
                "shortName": game["shortName"],
                "homeTeamAbbr": home,
                "awayTeamAbbr": away,
                "homeScore": home_score,
                "awayScore": away_score,
                "winner": winner,
                "total": home_score + away_score,
            }
        )
    payload = {
        "week": "MOCK1",
        "note": "Simulated finals for admin declare / scoring tests. Not shown to players until seeded into game_results.",
        "games": results,
    }
    ANSWER_KEY.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"✅ Wrote answer key {ANSWER_KEY}")


def rebuild_schedule() -> dict:
    weeks: dict[str, list] = {}

    print("Fetching ESPN preseason (Core API)...")
    for espn_week, (our_key, week_number) in PRE_MAP.items():
        meta, raw_events = fetch_week_games(1, espn_week)
        print(f"  ESPN PRE week {espn_week} '{meta.get('text')}' → {our_key} ({len(raw_events)})")
        weeks[our_key] = [
            normalize_game(ed, our_key, "PRE", week_number) for ed in raw_events
        ]

    print("Fetching ESPN regular season weeks 1–3...")
    for wk in range(1, 4):
        meta, raw_events = fetch_week_games(2, wk)
        key = f"REG{wk}"
        print(f"  ESPN REG week {wk} '{meta.get('text')}' → {key} ({len(raw_events)})")
        weeks[key] = [normalize_game(ed, key, "REG", wk) for ed in raw_events]

    now = datetime.now(timezone.utc)
    weeks["MOCK1"] = build_mock1(now)
    write_answer_key(weeks["MOCK1"])
    print(f"  MOCK1 test week → {len(weeks['MOCK1'])} games")

    # Stable key order
    ordered = {}
    for k in ["MOCK1", "PRE0", "PRE1", "PRE2", "PRE3", "REG1", "REG2", "REG3"]:
        if k in weeks:
            ordered[k] = weeks[k]

    total = sum(len(v) for v in ordered.values())
    payload = {
        "season": 2026,
        "lastUpdated": now.isoformat().replace("+00:00", "Z"),
        "totalGames": total,
        "currentWeek": "MOCK1",
        "source": "espn-core-api + MOCK1",
        "weeks": ordered,
    }
    SCHEDULE.write_text(json.dumps(payload, indent=2) + "\n")
    print(f"✅ Wrote {SCHEDULE} ({total} games). currentWeek=MOCK1")
    return payload


def token() -> str:
    return subprocess.check_output(
        ["gcloud", "auth", "print-access-token"], text=True
    ).strip()


def auth_headers() -> dict:
    return {
        "Authorization": f"Bearer {token()}",
        "Content-Type": "application/json",
    }


def str_field(s: str) -> dict:
    return {"stringValue": s}


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


def delete_doc(name: str) -> None:
    # name is full projects/.../documents/collection/id
    url = f"https://firestore.googleapis.com/v1/{name}"
    req = urllib.request.Request(url, method="DELETE", headers=auth_headers())
    with urllib.request.urlopen(req, timeout=30) as resp:
        resp.read()


def wipe_firestore() -> None:
    print("Wiping pickrecord + game_results for test reset...")
    # Delete all pickrecord docs (page via runQuery without filter — use list)
    # Use list documents API with page tokens
    for collection in ("pickrecord", "game_results", "week_results"):
        page_token = None
        deleted = 0
        while True:
            url = f"{BASE}/{collection}?pageSize=100"
            if page_token:
                url += f"&pageToken={page_token}"
            req = urllib.request.Request(url, headers=auth_headers())
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.load(resp)
            for doc in data.get("documents") or []:
                delete_doc(doc["name"])
                deleted += 1
                time.sleep(0.02)
            page_token = data.get("nextPageToken")
            if not page_token:
                break
        print(f"  deleted {deleted} from {collection}")

    # Set active week to MOCK1
    url = f"{BASE}/config/appConfig?updateMask.fieldPaths=activeWeek"
    body = json.dumps(
        {"fields": {"activeWeek": str_field("MOCK1")}}
    ).encode()
    req = urllib.request.Request(
        url, data=body, method="PATCH", headers=auth_headers()
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        resp.read()
    print("✅ config/appConfig.activeWeek = MOCK1")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--wipe-firestore",
        action="store_true",
        help="Delete pickrecord/game_results/week_results and set activeWeek=MOCK1",
    )
    args = parser.parse_args()
    rebuild_schedule()
    if args.wipe_firestore:
        wipe_firestore()
    else:
        print("Skipped Firestore wipe (pass --wipe-firestore to clear picks + set MOCK1).")


if __name__ == "__main__":
    main()
