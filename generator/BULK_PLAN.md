# 10.000 Fragen ohne Kosten — Plan & Anleitung

Dieses Dokument beschreibt den Plan, ~10.000 Quiz-Fragen für Poker Guessr zu
generieren, ohne dass bei Google Gemini Kosten anfallen. Das Skript dazu ist
[`bulk_orchestrator.py`](bulk_orchestrator.py).

## TL;DR

```bash
export GEMINI_API_KEY='dein-key'
cd generator/

# Plan anzeigen, ohne API zu rufen
python bulk_orchestrator.py --target 10000 --plan-only

# Tag 1: bis das Tageslimit hart anschlägt
python bulk_orchestrator.py --target 10000

# Nächster Tag (oder nach Abbruch): einfach wieder starten
python bulk_orchestrator.py --resume
```

Erwartung: **3 Tage**, je **~60 Minuten Aktivzeit**, **0 € Kosten**.

## Free-Tier-Annahmen (Stand 2026)

| Modell                        | RPM  | RPD   | Pro 5er-Batch / Tag |
|-------------------------------|-----:|------:|--------------------:|
| **gemini-2.5-flash-lite** ⭐  |   15 |  1000 |        ~4750 Fragen |
| gemini-2.5-flash              |   10 |   250 |        ~1187 Fragen |
| gemini-2.5-pro                |    5 |   100 |         ~475 Fragen |

⭐ Default des Orchestrators. Die Quotas können sich ändern — vor einem
großen Lauf gegen die offizielle Doku gegenchecken und ggf. `--rpm`/`--rpd`
überschreiben.

Sicherheitspuffer: das Skript stoppt bei **95 % des RPD-Limits**, damit
spontane Service-Tier-Änderungen nicht in eine kostenpflichtige Anfrage
münden.

## Was das Skript macht (und was nicht)

✅ **Macht es:**
- Persistenter Fortschritt in `progress.json` — Abbruch jederzeit OK.
- Tages-Counter pro `YYYY-MM-DD` (UTC) gegen RPD-Limit.
- Sleeps zwischen Requests gemäß RPM (z. B. 4 s bei 15 RPM).
- Round-Robin durch alle 11 Kategorien × 3 Schwierigkeiten — keine Slice
  bleibt liegen.
- Failure-Log `failures.jsonl` mit Timestamp + Trace pro fehlgeschlagenem Batch.
- Ruft den existierenden `generate_batch()` + `process_questions()` auf —
  also identische Validierung, Dedup und Firestore-Schicht wie beim
  Einzel-Lauf.

❌ **Macht es nicht:**
- Kein Bezahl-Tier-Switch. Bleibt strikt im Free-Tier.
- Keine Auto-Retry-Logik über Tage hinweg — du startest täglich neu mit
  `--resume`.
- Kein Caching von Prompts. (Optional Post-Launch — würde Tokens sparen,
  aber für 10 k unnötig.)

## Datei-Übersicht

| Datei                  | Inhalt                                       | git? |
|------------------------|----------------------------------------------|:----:|
| `bulk_orchestrator.py` | Das Skript                                   |  ✅  |
| `progress.json`        | Aktueller Stand (Cursor, Counts, RPD)        |  ❌  |
| `failures.jsonl`       | Eine Zeile JSON pro fehlgeschlagenem Batch   |  ❌  |
| `serviceAccountKey.json` | Firebase-Admin-Key (Secret)                |  ❌  |

`progress.json` und `failures.jsonl` sind in `.gitignore`.

## Realistischer Ablauf (10k @ 5er-Batch)

| Tag | Cumulative Fragen | Cumulative Requests | Bemerkung                       |
|----:|------------------:|--------------------:|---------------------------------|
|  1  | ~4 500            | ~950                | RPD-Cap, Skript stoppt selbst.  |
|  2  | ~9 000            | ~1 900              | `--resume`, weiter.             |
|  3  | 10 000            | ~2 000              | Ziel erreicht — Skript exit 0.  |

Streuung: durch Validation-Fails / Duplikat-Filter rechnen wir mit ~5 %
Verlust pro Batch. Die Tabelle berücksichtigt das nicht — der reale Lauf
braucht ggf. einen halben Tag mehr.

## Resume nach Abbruch

`progress.json` wird **nach jedem Batch** geschrieben. Wenn du `Ctrl-C`
drückst oder dein Mac in den Standby geht: einfach wieder

```bash
python bulk_orchestrator.py --resume
```

Der Cursor steht beim nächsten Kategorie/Schwierigkeit-Paar weiter, der
Tages-Counter in `daily_requests` kennt heute schon und respektiert das
verbliebene Tageslimit.

## Kategorien anpassen

```bash
python bulk_orchestrator.py --target 2000 \
    --categories Sport Geografie \
    --difficulties easy medium
```

## Weniger / mehr pro Batch

Defaults sind 5 Fragen/Request — guter Kompromiss zwischen Quality und
Token-Kosten. Bei 10 stiegen die Validation-Fails messbar; bei 3 wurden
Fragen redundanter. 5 hat sich im Probelauf bewährt.

## Failures inspizieren

```bash
jq -r '"\(.ts) [\(.category)/\(.difficulty)] \(.error)"' generator/failures.jsonl
```

Eine fehlgeschlagene Generierung bedeutet meistens: 5xx von Gemini oder
schema-Validierungsfehler — beide werden vom nächsten Round-Robin-Sweep
automatisch nachgeholt.

## Wenn doch ein höherer Tier vorhanden ist

```bash
python bulk_orchestrator.py --target 10000 --rpm 60 --rpd 5000
```

Damit läuft der ganze Lauf in ~30 Minuten durch. Verwende dies nur, wenn
dein API-Key wirklich auf Paid Tier liegt — sonst wirft Gemini ab Limit
einfach 429 und das Skript schreibt jeden Versuch ins Failure-Log.
