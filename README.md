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


## Wersja 1.9.0 — ustawienia HIGH-SCORE

Koło zębate w menu otwiera ustawienia rekordów. Można włączyć lub wyłączyć
wszystkie siedem obsługiwanych gier, albo każdą osobno. Ustawienia są zapisywane
na telefonie. Wyłączenie ukrywa rekordy i zatrzymuje zapisywanie nowych wyników
oraz pytania o imię. Istniejące rekordy pozostają zachowane. Domyślnie wszystko
jest włączone, również po aktualizacji starszej wersji.

Kontrola na urządzeniu: wyłącz rekordy w jednej grze, zakończ rozgrywkę i sprawdź
brak pytania o imię oraz przycisku pucharu. Inne gry powinny nadal obsługiwać
rekordy. Uruchom ponownie aplikację i sprawdź zapamiętanie wyboru. Sprawdź też
przyciski Włącz wszystkie / Wyłącz wszystkie oraz powrót dotychczasowych
rekordów po ponownym włączeniu.
