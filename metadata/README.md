# App Store Metadata — Poker Guessr

Dieser Ordner enthält die kanonischen App-Store-Texte und URLs. Format ist
kompatibel zu fastlane `deliver` / `asc metadata sync` (locale-Ordner mit Plain-Text-Dateien).

## Struktur

```
metadata/
├── de-DE/                  # Deutsche Locale (primär)
│   ├── name.txt            # App Name (≤ 30 Zeichen)
│   ├── subtitle.txt        # Untertitel (≤ 30 Zeichen)
│   ├── promotional_text.txt # Promo-Text (≤ 170 Zeichen, ohne Review änderbar)
│   ├── keywords.txt        # Komma-getrennt (≤ 100 Zeichen)
│   ├── description.txt     # Beschreibung (≤ 4000 Zeichen)
│   └── release_notes.txt   # "Was ist neu" für aktuelle Version
├── privacy_url.txt
├── support_url.txt
├── marketing_url.txt
├── copyright.txt
├── primary_category.txt    # App-Store-Kategorie (Konstante)
├── subcategories.txt       # Sub-Kategorien
└── age_rating.txt          # Altersfreigabe
```

## Zeichen-Limits (App Store Connect)

| Feld              | Limit |
|-------------------|------:|
| name              |    30 |
| subtitle          |    30 |
| promotional_text  |   170 |
| keywords          |   100 |
| description       |  4000 |
| release_notes     |  4000 |

## Workflow

**Manuell (heute):**
Texte aus den Files in App Store Connect kopieren.

**Mit asc CLI (später):**
```bash
asc metadata sync ./metadata --app-id <APP-ID>
```

## Locales

Aktuell nur `de-DE`. Englisch (`en-US`) ist Post-Launch-Task.
Beim Hinzufügen einer neuen Locale: ganzen `de-DE/`-Ordner kopieren und alle Texte übersetzen.

## Hinweise

- **Keywords** dürfen Wörter aus Title/Subtitle NICHT enthalten (App Store indexiert die ohnehin).
- **Promotional Text** lässt sich ohne neuen App-Review aktualisieren — gut für Saison-Promos.
- **Release Notes** werden mit jedem Build aktualisiert; halte sie kurz und nutzerorientiert.
- Alle URLs müssen vor Submission live + erreichbar sein, sonst rejected Apple.
