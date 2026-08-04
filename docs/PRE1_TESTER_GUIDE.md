# PoolQ PRE1 Live Test — Tester Guide

**Season:** 2026 · **Active week:** PRE1 · **Entry:** Free (preseason auto-verified)  
**Status:** Ready for internal testers  
**Firebase:** `nflgamesapp`

---

## What to test

1. Register (invite code) or log in
2. Open Play for PRE1 — confirm free-entry banner
3. Make all game picks + tiebreaker → submit
4. Confirm entry appears on the leaderboard
5. (Optional) Admin path: verify Players list shows your entry

Out of scope for PRE: paid entry, Stripe, multipage picks UI, push notifications.

---

## How to get in

### Existing test accounts

| Role | Email | Password |
|------|-------|----------|
| Player | `demo@poolq.app` | `demo123456` |
| Player | `testuser@poolq.app` | `test123456` |
| Admin (Firebase user) | `admin@poolq.app` | `admin123456` |
| Admin UI (mock login) | username `admin` | `admin123` |

Mock admin is reached from the app drawer → Admin Login (not Firebase Auth).

### New testers

1. Open the app (Chrome / device build from the team)
2. Register with invitation code: **`fitz`** (reusable)
3. Complete profile if prompted
4. Submit PRE1 picks

---

## Admin check (owners)

1. Profile tab → **Admin Login** → `admin` / `admin123`
2. Dashboard → Players (people icon)
3. Week **PRE1** — entrants + payment status (`auto_verified` for PRE)
4. **Set Active** can switch weeks (leave on PRE1 for this test)

---

## How to report bugs

Include:

- Device / browser (e.g. Chrome macOS)
- Account email used
- Steps to reproduce
- Expected vs actual
- Screenshot if UI

Severity guide:

- **P0** — crash, can’t submit picks, data loss  
- **P1** — leaderboard wrong / missing entry  
- **P2** — copy/UI polish  

---

## Known notes

- PRE weeks are **free** (`preseasonFree=true`); no Venmo/PayPal/CashApp required to enter.
- REG payment handles are configured for later (`venmo.com/u/PoolQPayments`, `poolq.payments@gmail.com`, `$PoolQPayments`) — Venmo/CashApp profile pages currently 404 until those accounts are claimed; not a PRE blocker.
- Firestore composite indexes for leaderboard / game_results are deployed; allow a few minutes if a query warns about a building index.
- **Mock PRE1 scores (testing only):** run `python3 scripts/seed_mock_pre1_scores.py` to mark PRE1 finals in local schedule + Firestore `game_results` and recompute pickrecord scores. Not live NFL data — remove/replace when real PRE1 scores arrive.

---

## Invite message (copy/paste)

```
Subject: PoolQ PRE1 internal test — free entry

You're invited to smoke-test PoolQ for 2026 preseason (PRE1).

What: NFL pick'em — pick every game + tiebreaker. Preseason entry is FREE.
Invite code (new accounts): fitz

Or use a shared test login (ask us for the current password if you don't have it):
  demo@poolq.app

Please try:
1) Log in / register
2) Submit PRE1 picks
3) Confirm you show on the leaderboard
4) Reply with any bugs (steps + screenshot)

Out of scope: payments (PRE is free), push notifications, polish.

Thanks — reply in this thread with feedback.
```

---

## Go / No-Go checklist (owners)

- [x] Wave B committed; indexes deployed
- [x] Demo PRE1 entry `auto_verified` on leaderboard
- [x] Admin Set Active / verify-reject backend verified
- [ ] 5–10 invites sent
- [ ] ≥3 distinct testers submitted PRE1
- [ ] Zero P0 bugs open after first 48h
