#!/usr/bin/env python3
"""
Poker Guessr — Quiz Question Generator

Generates high-quality quiz questions using Google Gemini and pushes them to Firebase Firestore.

Usage:
    python generator.py --category "Geografie" --difficulty medium --count 10 --lang de
    python generator.py --all --count 5 --lang en
    python generator.py --category "Sport" --difficulty hard --count 3 --dry-run
"""

import argparse
import json
import os
import sys
import time
from typing import Literal

from google import genai
from pydantic import BaseModel, Field

from prompts import VALID_CATEGORIES, VALID_DIFFICULTIES, build_system_prompt, build_user_prompt
from validator import validate_question, is_duplicate, is_value_duplicate


# ──────────────────────────────────────────────
# Pydantic schema for Gemini structured output
# ──────────────────────────────────────────────

class GeneratedQuestion(BaseModel):
    question: str = Field(description="Fragetext, OHNE Einheit. Zeitabhängige Fakten mit (Stand: YYYY) taggen")
    answerBaseValue: float = Field(description="Numerischer Wert in der Basiseinheit der dimension")
    dimension: Literal["weight", "length", "time", "volume", "count", "currency", "none"]
    defaultUnitText: str = Field(description="Kürzel der Basiseinheit, z.B. 'm', 'kg', 'L', '€', ''")
    category: str = Field(description="Kategorie aus der erlaubten Liste")
    tip1: str = Field(description="Indirekter Vergleich — kreativ, erfordert eigenes Schätzen")
    tip2: str = Field(description="Direkte Eingrenzung — Ober-/Untergrenzen mit bekannten Vergleichen")
    tip3: str = Field(description="Starke Annäherung — mathematisch/deduktiv, ±20% des Werts")


class QuestionBatch(BaseModel):
    questions: list[GeneratedQuestion]


# ──────────────────────────────
# Core generation logic
# ──────────────────────────────

MAX_RETRIES = 3
BASE_RETRY_DELAY = 15  # seconds


def generate_batch(
    category: str,
    difficulty: str,
    count: int,
    language: str,
    existing_questions: list[dict],
    model: str = "gemini-2.5-flash",
) -> list[GeneratedQuestion]:
    """Generate a batch of questions via Gemini API with structured output and automatic retry."""

    # Build prompts
    existing_texts = [q.get("question", "") for q in existing_questions]
    system_prompt = build_system_prompt(language, difficulty, existing_texts)
    user_prompt = build_user_prompt(category, count)

    # Initialize Gemini client (uses GEMINI_API_KEY or GOOGLE_API_KEY env var)
    client = genai.Client()

    print(f"  🤖 Gemini-Anfrage: {count} Fragen für '{category}' ({difficulty}, {language})...")

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.models.generate_content(
                model=model,
                contents=user_prompt,
                config={
                    "response_mime_type": "application/json",
                    "response_schema": QuestionBatch,
                    "system_instruction": system_prompt,
                },
            )
            batch = QuestionBatch.model_validate_json(response.text)
            return batch.questions

        except Exception as e:
            error_str = str(e)
            is_rate_limit = "429" in error_str or "RESOURCE_EXHAUSTED" in error_str
            is_unavailable = "503" in error_str or "UNAVAILABLE" in error_str

            if (is_rate_limit or is_unavailable) and attempt < MAX_RETRIES:
                # Try to parse retry delay from error message
                import re
                delay_match = re.search(r"retry in (\d+(?:\.\d+)?)s", error_str, re.IGNORECASE)
                if delay_match:
                    wait_time = int(float(delay_match.group(1))) + 2  # Add buffer
                else:
                    wait_time = BASE_RETRY_DELAY * attempt  # Exponential backoff

                status = "Rate-Limit" if is_rate_limit else "Server überlastet"
                print(f"  ⏳ {status} (Versuch {attempt}/{MAX_RETRIES}) — warte {wait_time}s...")
                time.sleep(wait_time)
            else:
                raise  # Re-raise on last attempt or non-retryable error


def process_questions(
    generated: list[GeneratedQuestion],
    category: str,
    difficulty: str,
    language: str,
    existing_questions: list[dict],
    dry_run: bool = False,
) -> tuple[int, int, int]:
    """
    Validate, deduplicate, and optionally push generated questions to Firestore.
    Returns (pushed, skipped_validation, skipped_duplicate).
    """
    # Import firestore only when needed (not during dry-run without credentials)
    if not dry_run:
        from firestore_client import push_question

    existing_texts = [q.get("question", "") for q in existing_questions]
    pushed = 0
    skipped_validation = 0
    skipped_duplicate = 0

    for i, q in enumerate(generated, 1):
        q_dict = q.model_dump()
        prefix = f"  [{i}/{len(generated)}]"

        # Validate
        errors = validate_question(q_dict, category, difficulty)
        if errors:
            print(f"{prefix} ❌ Validierungsfehler:")
            for err in errors:
                print(f"       ↳ {err}")
            skipped_validation += 1
            continue

        # Duplicate check
        if is_duplicate(q.question, existing_texts):
            print(f"{prefix} ⚠️  Duplikat (ähnliche Frage existiert): {q.question[:60]}...")
            skipped_duplicate += 1
            continue

        if is_value_duplicate(q.answerBaseValue, q.dimension, category, existing_questions):
            print(f"{prefix} ⚠️  Duplikat (gleicher Wert in Kategorie+Dimension): {q.answerBaseValue}")
            skipped_duplicate += 1
            continue

        # Build Firestore document
        doc = {
            "question": q.question,
            "answerBaseValue": q.answerBaseValue,
            "dimension": q.dimension,
            "defaultUnitText": q.defaultUnitText,
            "category": category,
            "difficulty": difficulty,
            "language": language,
            "tips": [q.tip1, q.tip2, q.tip3],
        }

        if dry_run:
            print(f"{prefix} ✅ [DRY-RUN] Würde pushen:")
            print(f"       Frage: {q.question}")
            print(f"       Antwort: {q.answerBaseValue} ({q.dimension}, {q.defaultUnitText})")
            print(f"       Tipp 1: {q.tip1[:80]}...")
            print(f"       Tipp 2: {q.tip2[:80]}...")
            print(f"       Tipp 3: {q.tip3[:80]}...")
            print()
        else:
            doc_id = push_question(doc)
            print(f"{prefix} ✅ Gepusht: {q.question[:60]}... → ID: {doc_id}")

        # Add to existing for subsequent duplicate checks within this batch
        existing_texts.append(q.question)
        existing_questions.append(doc)
        pushed += 1

    return pushed, skipped_validation, skipped_duplicate


# ──────────────────────────────
# CLI
# ──────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="🃏 Poker Guessr — Quiz-Fragen-Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Beispiele:
  python generator.py --category "Geografie" --difficulty medium --count 10 --lang de
  python generator.py --all --count 5 --lang en
  python generator.py --category "Sport" --count 3 --dry-run
        """,
    )
    parser.add_argument(
        "--category", "-c",
        type=str,
        choices=VALID_CATEGORIES,
        help="Kategorie der Fragen",
    )
    parser.add_argument(
        "--difficulty", "-d",
        type=str,
        choices=VALID_DIFFICULTIES,
        default="medium",
        help="Schwierigkeitsgrad (default: medium)",
    )
    parser.add_argument(
        "--count", "-n",
        type=int,
        default=10,
        help="Anzahl Fragen pro Batch (default: 10)",
    )
    parser.add_argument(
        "--lang", "-l",
        type=str,
        choices=["de", "en"],
        default="de",
        help="Sprache der Fragen (default: de)",
    )
    parser.add_argument(
        "--all", "-a",
        action="store_true",
        help="Generiere Fragen für ALLE Kategorien",
    )
    parser.add_argument(
        "--all-difficulties",
        action="store_true",
        help="Generiere Fragen für ALLE Schwierigkeitsgrade",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Fragen nur anzeigen, NICHT in Firestore pushen",
    )
    parser.add_argument(
        "--model", "-m",
        type=str,
        default="gemini-2.5-flash",
        help="Gemini-Modell (default: gemini-2.5-flash)",
    )

    args = parser.parse_args()

    # Validate arguments
    if not args.all and not args.category:
        parser.error("Entweder --category oder --all muss angegeben werden.")

    # Check API key
    api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("❌ Fehler: Kein API-Key gefunden!")
        print("   Setze die Umgebungsvariable GEMINI_API_KEY oder GOOGLE_API_KEY:")
        print("   export GEMINI_API_KEY='dein-api-key-hier'")
        sys.exit(1)

    # Determine categories and difficulties to process
    categories = VALID_CATEGORIES if args.all else [args.category]
    difficulties = VALID_DIFFICULTIES if args.all_difficulties else [args.difficulty]

    # Load existing questions (skip for dry-run without Firebase credentials)
    existing_questions = []
    if not args.dry_run:
        print("📚 Lade bestehende Fragen aus Firestore...")
        from firestore_client import load_existing_questions
        existing_questions = load_existing_questions()
        print(f"   {len(existing_questions)} bestehende Fragen geladen.\n")
    else:
        print("🏃 DRY-RUN Modus — kein Firestore-Zugriff\n")

    # Stats
    total_pushed = 0
    total_skipped_val = 0
    total_skipped_dup = 0
    total_errors = 0

    # Generate for each category × difficulty
    for category in categories:
        for difficulty in difficulties:
            header = f"📝 {category} / {difficulty} / {args.lang}"
            print(f"\n{'═' * 60}")
            print(f"  {header}")
            print(f"{'═' * 60}")

            try:
                generated = generate_batch(
                    category=category,
                    difficulty=difficulty,
                    count=args.count,
                    language=args.lang,
                    existing_questions=existing_questions,
                    model=args.model,
                )
                print(f"  📦 {len(generated)} Fragen von Gemini erhalten.\n")

                pushed, skipped_val, skipped_dup = process_questions(
                    generated=generated,
                    category=category,
                    difficulty=difficulty,
                    language=args.lang,
                    existing_questions=existing_questions,
                    dry_run=args.dry_run,
                )

                total_pushed += pushed
                total_skipped_val += skipped_val
                total_skipped_dup += skipped_dup

            except Exception as e:
                print(f"  ❌ Fehler bei {category}/{difficulty}: {e}")
                total_errors += 1

            # Pause between API calls to respect free tier rate limits
            # Free tier: ~15 RPM for Flash models
            if len(categories) > 1 or len(difficulties) > 1:
                print("  ⏸️  Warte 5s (Rate-Limit-Schutz)...")
                time.sleep(5)

    # Summary
    print(f"\n{'═' * 60}")
    print(f"  📊 ZUSAMMENFASSUNG")
    print(f"{'═' * 60}")
    print(f"  ✅ Erfolgreich{'  [DRY-RUN]' if args.dry_run else ' gepusht'}: {total_pushed}")
    print(f"  ❌ Validierungsfehler: {total_skipped_val}")
    print(f"  ⚠️  Duplikate: {total_skipped_dup}")
    if total_errors:
        print(f"  💥 API-Fehler: {total_errors}")
    print()


if __name__ == "__main__":
    main()
