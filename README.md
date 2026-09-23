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

## Wersja 1.10.0

- Nowa gra Wąż (Snake): zielona plansza 20 × 24, pikselowe jedzenie,
  wzrost po zjedzeniu i przegrana po uderzeniu w ścianę lub własne ciało.
- Skręcanie gestami w czterech kierunkach, blokada zawracania,
  stopniowe przyspieszanie co 5 punktów.
- Pauza i ręczne wznowienie, także po powrocie z tła lub tabeli rekordów.
- HIGH-SCORE z możliwością wyłączenia w ustawieniach.
- Testy logiki: `dart test/snake_engine_test.dart` (także podczas budowania APK).

## Wersja 1.11.0 — Arkanoid

- 30 różnych plansz; mur, piramida, diament, szachownica, brama, fala,
  skrzydła, twierdza, tunele i mozaika w trzech wariantach.
- Platforma sterowana palcem na planszy lub pasku pod nią. Kąt odbicia
  zależy od miejsca trafienia. Dotknięcie planszy wypuszcza piłkę.
- 3 życia na start; życie traci się dopiero po utracie wszystkich piłek.
- Bonusy do złapania: ×2 i ×3 piłki (limit 24), ×2 szerokość platformy
  na 20 sekund, dodatkowe życie.
- Mocniejsze klocki, rosnąca prędkość, pauza i automatyczna pauza w tle.
- Trwały zapis odblokowanych poziomów, wybór poziomu z menu gry.
  Ponowienie lub wybranie poziomu zaczyna nową grę z 3 życiami i 0 punktów.
  Stan trwającej rozgrywki nie jest zapisywany po zamknięciu aplikacji.
- HIGH-SCORE zgodny z ustawieniami; zgłoszenie po utracie żyć lub ukończeniu
  30. poziomu.
- Testy: `dart test/arkanoid_engine_test.dart` oraz
  `flutter test test/arkanoid_widget_test.dart`. Oba kroki uruchamia GitHub Actions.
