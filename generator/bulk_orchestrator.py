#!/usr/bin/env python3
"""
Poker Guessr — Bulk Question Orchestrator

Generates many quiz questions in a controlled, resumable way that respects
the Gemini Free-Tier rate limits. Wraps the existing generator without
modifying it.

Key features:
  - Persistent progress (progress.json) — safe to interrupt and resume.
  - Daily RPD tracking — hard-stops when the configured daily quota is hit.
  - RPM throttling — sleeps between requests to stay under per-minute limits.
  - Failure log — every failed batch is appended to failures.jsonl with the
    exception, so a re-run can investigate or retry.
  - Even distribution across categories × difficulties so no slice is starved.
  - Defaults targeting `gemini-2.5-flash-lite` with 1000 RPD / 15 RPM.

Usage:
    export GEMINI_API_KEY='...'

    # 10k Fragen, 5 pro Request, deutsch, Free-Tier-sicher.
    python bulk_orchestrator.py --target 10000 --batch-size 5 --lang de

    # Plan anzeigen ohne API-Aufruf:
    python bulk_orchestrator.py --target 10000 --plan-only

    # Nach Abbruch fortsetzen (liest progress.json):
    python bulk_orchestrator.py --resume

Free-Tier-Annahmen (Stand 2026; vor Lauf prüfen):
    gemini-2.5-flash-lite : 15 RPM, 1000 RPD
    gemini-2.5-flash      : 10 RPM, 250 RPD
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import traceback
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path

# Reuse the existing generator without modification.
from generator import generate_batch, process_questions
from prompts import VALID_CATEGORIES, VALID_DIFFICULTIES


SCRIPT_DIR = Path(__file__).resolve().parent
PROGRESS_PATH = SCRIPT_DIR / "progress.json"
FAILURES_PATH = SCRIPT_DIR / "failures.jsonl"

# Gemini Free-Tier defaults — change with --rpd/--rpm flags if Google updates them.
FREE_TIER_DEFAULTS = {
    "gemini-2.5-flash-lite": {"rpm": 15, "rpd": 1000},
    "gemini-2.5-flash":      {"rpm": 10, "rpd": 250},
    "gemini-2.5-pro":        {"rpm": 5,  "rpd": 100},
}

# Safety buffer: stay under the published limit by this fraction.
QUOTA_SAFETY = 0.95


@dataclass
class Progress:
    target: int = 0
    pushed_total: int = 0
    skipped_validation: int = 0
    skipped_duplicate: int = 0
    requests_total: int = 0
    daily_requests: dict[str, int] = field(default_factory=dict)
    last_run_at: str = ""
    plan_cursor: int = 0  # index into the (category × difficulty) work list

    @classmethod
    def load(cls) -> "Progress":
        if PROGRESS_PATH.exists():
            data = json.loads(PROGRESS_PATH.read_text(encoding="utf-8"))
            return cls(**data)
        return cls()

    def save(self) -> None:
        self.last_run_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
        PROGRESS_PATH.write_text(
            json.dumps(asdict(self), indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    def today_key(self) -> str:
        return datetime.now(timezone.utc).strftime("%Y-%m-%d")

    def requests_today(self) -> int:
        return self.daily_requests.get(self.today_key(), 0)

    def record_request(self) -> None:
        key = self.today_key()
        self.daily_requests[key] = self.daily_requests.get(key, 0) + 1
        self.requests_total += 1


def log_failure(category: str, difficulty: str, exc: BaseException) -> None:
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "category": category,
        "difficulty": difficulty,
        "error": str(exc),
        "trace": traceback.format_exception_only(type(exc), exc)[-1].strip(),
    }
    with FAILURES_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def build_work_list(
    categories: list[str],
    difficulties: list[str],
) -> list[tuple[str, str]]:
    """Even distribution: round-robin difficulty within each category sweep."""
    plan: list[tuple[str, str]] = []
    for difficulty in difficulties:
        for category in categories:
            plan.append((category, difficulty))
    return plan


def expected_run_summary(
    target: int,
    batch_size: int,
    rpm: int,
    rpd: int,
) -> str:
    requests_needed = (target + batch_size - 1) // batch_size
    daily_cap = int(rpd * QUOTA_SAFETY)
    days = (requests_needed + daily_cap - 1) // daily_cap
    seconds_per_request = max(60.0 / rpm, 4.0)
    runtime_per_day_min = (daily_cap * seconds_per_request) / 60
    return (
        f"  Ziel: {target} Fragen ({batch_size}/Request → {requests_needed} Requests)\n"
        f"  Free-Tier: {rpm} RPM / {rpd} RPD (Sicherheits-Cap {daily_cap}/Tag bei {QUOTA_SAFETY*100:.0f}%)\n"
        f"  Mindestens {days} Tag(e), ~{runtime_per_day_min:.0f} Min Aktivzeit pro Tag.\n"
        f"  Sleep zwischen Requests: {seconds_per_request:.1f}s"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Bulk-Generator für viele Fragen mit Free-Tier-Schutz",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--target", type=int, default=10_000,
                        help="Gesamtzahl Fragen, die am Ende vorhanden sein sollen (default: 10000)")
    parser.add_argument("--batch-size", type=int, default=5,
                        help="Fragen pro Gemini-Request (default: 5)")
    parser.add_argument("--lang", choices=["de", "en"], default="de")
    parser.add_argument("--model", default="gemini-2.5-flash-lite",
                        help="Gemini-Modell (default: gemini-2.5-flash-lite — höchster Free-Tier-RPD)")
    parser.add_argument("--rpm", type=int, default=None,
                        help="Override: Requests-per-Minute Limit für gewähltes Modell")
    parser.add_argument("--rpd", type=int, default=None,
                        help="Override: Requests-per-Day Limit für gewähltes Modell")
    parser.add_argument("--categories", nargs="+", default=VALID_CATEGORIES,
                        help="Eingeschränkte Kategorien-Liste")
    parser.add_argument("--difficulties", nargs="+", default=VALID_DIFFICULTIES,
                        choices=VALID_DIFFICULTIES)
    parser.add_argument("--resume", action="store_true",
                        help="Setze nach Abbruch fort (liest progress.json)")
    parser.add_argument("--plan-only", action="store_true",
                        help="Zeige nur den Plan, mache keine API-Aufrufe")
    parser.add_argument("--reset", action="store_true",
                        help="Setze progress.json zurück (vorher gepushte Fragen bleiben in Firestore)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Generiere, aber pushe NICHT in Firestore")
    args = parser.parse_args()

    # Resolve quotas
    defaults = FREE_TIER_DEFAULTS.get(args.model, {"rpm": 10, "rpd": 250})
    rpm = args.rpm or defaults["rpm"]
    rpd = args.rpd or defaults["rpd"]
    daily_cap = int(rpd * QUOTA_SAFETY)
    sleep_between = max(60.0 / rpm, 4.0)

    print("\n══════════════════════════════════════════════════════════")
    print("  Poker Guessr — Bulk Orchestrator")
    print("══════════════════════════════════════════════════════════")
    print(expected_run_summary(args.target, args.batch_size, rpm, rpd))
    print("══════════════════════════════════════════════════════════\n")

    if args.plan_only:
        return 0

    # API key check
    if not (os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")):
        print("❌ GEMINI_API_KEY oder GOOGLE_API_KEY ist nicht gesetzt.", file=sys.stderr)
        return 1

    # Progress state
    if args.reset and PROGRESS_PATH.exists():
        PROGRESS_PATH.unlink()
        print("🧹 progress.json gelöscht.\n")

    progress = Progress.load() if (args.resume or PROGRESS_PATH.exists()) else Progress()
    if progress.target == 0:
        progress.target = args.target

    # Load existing questions for dedup
    if not args.dry_run:
        print("📚 Lade bestehende Fragen aus Firestore (für Dedup) …")
        from firestore_client import load_existing_questions
        existing_questions = load_existing_questions()
        print(f"   {len(existing_questions)} Fragen geladen.\n")
    else:
        existing_questions = []
        print("🏃 DRY-RUN — kein Firestore-Zugriff.\n")

    # Build / restore work plan
    work_list = build_work_list(args.categories, args.difficulties)
    if progress.plan_cursor >= len(work_list):
        progress.plan_cursor = 0  # wrap around for next sweep

    while progress.pushed_total < progress.target:

        # Daily quota check
        if progress.requests_today() >= daily_cap:
            print(f"🛑 Tageslimit erreicht ({progress.requests_today()}/{daily_cap}).")
            print("   Komm morgen wieder oder erhöhe --rpd, falls dein Tier höher ist.")
            break

        category, difficulty = work_list[progress.plan_cursor]
        remaining = progress.target - progress.pushed_total
        count = min(args.batch_size, remaining)

        print(f"▶︎  [{progress.pushed_total}/{progress.target}] "
              f"{category} / {difficulty} → {count} Fragen "
              f"(Req heute: {progress.requests_today()}/{daily_cap})")

        try:
            generated = generate_batch(
                category=category,
                difficulty=difficulty,
                count=count,
                language=args.lang,
                existing_questions=existing_questions,
                model=args.model,
            )
        except Exception as exc:  # noqa: BLE001 — broad on purpose, batches must not crash the run
            log_failure(category, difficulty, exc)
            progress.record_request()  # API call was attempted, count it
            progress.save()
            print(f"   ⚠️  Fehler — geloggt in failures.jsonl: {exc}")
            print(f"   Sleep {sleep_between:.0f}s …\n")
            time.sleep(sleep_between)
            progress.plan_cursor = (progress.plan_cursor + 1) % len(work_list)
            continue

        progress.record_request()

        if generated is None:
            generated = []

        pushed, skipped_val, skipped_dup = process_questions(
            generated=generated,
            category=category,
            difficulty=difficulty,
            language=args.lang,
            existing_questions=existing_questions,
            dry_run=args.dry_run,
        )

        progress.pushed_total += pushed
        progress.skipped_validation += skipped_val
        progress.skipped_duplicate += skipped_dup
        progress.plan_cursor = (progress.plan_cursor + 1) % len(work_list)
        progress.save()

        print(f"   ✅ +{pushed} gepusht | ⚠️ {skipped_dup} dup | ❌ {skipped_val} invalid\n")

        if progress.pushed_total >= progress.target:
            break

        time.sleep(sleep_between)

    # Final summary
    print("══════════════════════════════════════════════════════════")
    print("  Zusammenfassung")
    print("══════════════════════════════════════════════════════════")
    print(f"  Gepusht insgesamt    : {progress.pushed_total}/{progress.target}")
    print(f"  Validation skipped   : {progress.skipped_validation}")
    print(f"  Duplicates skipped   : {progress.skipped_duplicate}")
    print(f"  Requests insgesamt   : {progress.requests_total}")
    print(f"  Requests heute       : {progress.requests_today()}/{daily_cap}")
    print(f"  Progress gespeichert : {PROGRESS_PATH}")
    if FAILURES_PATH.exists():
        print(f"  Failures-Log         : {FAILURES_PATH}")
    print()
    return 0 if progress.pushed_total >= progress.target else 2


if __name__ == "__main__":
    raise SystemExit(main())
