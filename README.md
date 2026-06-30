# Gry podrozne

Zestaw prostych gier na jeden telefon (hot-seat, 2 osoby), offline.

## Gry
- **Kolko i krzyzyk** — klasyka na 3 w rzedzie
- **Czworki** — ulóz 4 zetony w linii
- **Pojedynek refleksu** — kto szybciej dotknie, gdy ekran zmieni kolor
- **Bitwa klikania** — kto wiecej kliknie w 10 sekund

## Jak to dziala
Aplikacja Flutter budowana w chmurze przez GitHub Actions (bez lokalnego Fluttera).
Po wgraniu kodu do galezi `main` build startuje automatycznie; gotowy APK jest
w zakladce Actions → wybrany przebieg → Artifacts → `gry-apk`.

## Podpisywanie
APK podpisywany stalym kluczem z sekretow repozytorium:
`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`.
Dzieki temu aktualizacje nakladaja sie bez odinstalowywania.
