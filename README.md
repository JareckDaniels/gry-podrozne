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

## Wersja 1.12.0 — odświeżenie wszystkich gier

### Wygląd
- Wspólna ciemna paleta, pastelowe akcenty, gradientowe tło aplikacji,
  karty statusu, czytelniejsze przyciski i odświeżone menu.
- Kółko i krzyżyk: animacja pojawiania się znaku i podświetlania wygranej.
- Czwórki: opadanie krążka z odbiciem i blokada kolejnego ruchu do lądowania.
- Simon: symbole oprócz kolorów, nowe pola i anulowanie starych błysków po restarcie.
- Szybkie klikanie: oznaczenie aktywnych i zaliczonych pól, blokada dotyku między poziomami.
- Pojedynek refleksu i Bitwa klikania: odświeżone strefy graczy i reakcja na dotknięcie.
- Zgadywanka: przewijany ekran, zawijanie długich słów i poprawiona obsługa fokusu.
- Wąż: nowy panel wyniku, zachowany klasyczny ekran LCD i ruch po siatce.
- Arkanoid: nowe cieniowanie planszy i klocków, lepiej widoczne piłki.

### Balon
- Nowy krajobraz, chmury, cieniowana czasza i czytelne bariery.
- Wygładzony ruch do pozycji palca, bez teleportowania przez przeszkody.
- Fale z gwarantowanym przejściem; ograniczenie przeskoku szczeliny między falami.
- Dokładniejsze kolizje czaszy i kosza oraz koliste zbieranie kółek.
- Ograniczona maksymalna prędkość, stabilna symulacja 120 kroków na sekundę.

### Biegacz
- Przewijane warstwy krajobrazu, animowana postać, cień i nowe przeszkody.
- Krótkie dotknięcie daje niższy skok, przytrzymanie wyższy.
- Bufor 120 ms przy lądowaniu; bez dodatkowego skoku w powietrzu.
- Grawitacja niezależna od liczby klatek, limit prędkości i odstępy pozwalające wylądować.
- Kolizje dopasowane do przeszkód; pod latającą przeszkodą można przebiec.

### Pauza i poprawki
- Balon i Biegacz zatrzymują się przy obrocie, otwarciu rekordów i wyjściu do tła.
  Wznowienie jest ręczne. Obie gry nadal działają w pionie i poziomie.
- Simon, PopIt, Refleks i Bitwa mają pauzę zatrzymującą zegar i opóźnione akcje.
- Liczniki mierzą rzeczywisty czas aktywnej gry, zamiast sumować wywołania timera.
- Simon i PopIt zgłaszają liczbę ukończonych poziomów, bez doliczania przegranego.
- Zgadywanka nie pozwala wielokrotnie zaliczyć tego samego słowa.
- Zachowano klucze rekordów, ustawienia HIGH-SCORE i odblokowane poziomy Arkanoida.

### Sprawdzenie
Lokalnie przeszły testy silników Balonu, Biegacza, Arkanoida i Węża oraz test
pauzowanego zegara. Analiza nowych silników i zegara nie zgłosiła problemów.
Testy widoków wszystkich gier dodano do GitHub Actions; nie zostały uruchomione
lokalnie. Paczka zawiera źródła, bez skompilowanego APK.

## Wersja 1.12.1 — panele planszówek na małym ekranie

- Kółko i krzyżyk i Czwórki: panel tury i zwycięstwa może zawijać tekst
  oraz przenosić symbol gracza do następnego wiersza. Usunięto sztywny
  układ, który przekraczał szerokość przy czcionce testowej Fluttera.
- Zachowano wcześniejsze testy. Dodano szerokości 280/320 px, tekst
  w skali 1/1.5 oraz zwycięstwo i restart w Czwórkach.
- Testów Fluttera nie uruchomiono lokalnie; są wykonywane w GitHub Actions.

## Wersja 1.12.2 — wymagający Balon i shuriken w Biegaczu

- Balon: kolejne szczeliny wymagają zmiany toru; generator nie powtarza
  przejść przy krawędzi. Szczeliny stopniowo zwężają się, a tempo rośnie.
- Odstępy między przeszkodami pozwalają ominąć belkę całym balonem
  i wykonać następny manewr. Zachowano płynne sterowanie palcem.
- Biegacz: latającą przeszkodą jest obracający się metaliczny shuriken
  z kolistą strefą kolizji. Nadal można bezpiecznie przebiec pod nim.
- Test balansu: 216 prób bez ruchu kończy się przegraną; 72 aktywne
  symulacje po 150 sekund przechodzą trasę w różnych rozmiarach ekranu.
  Test dodano także do CI. Testów widoków Fluttera nie uruchomiono lokalnie.

## Wersja 1.12.3 — rzadsze bonusy Arkanoida

- Szansa bonusu spada z 22% do 6% na zniszczony klocek, z przerwą
  co najmniej 12 sekund aktywnej gry i limitem 3 bonusów na poziom.
- Serce wypada najwyżej raz na całą rozgrywkę, również po zmianie poziomu.
- Bonusy +1 i +2 dodają dokładnie jedną lub dwie piłki, zamiast mnożyć
  wszystkie obecne piłki. Życie oznaczone samym sercem.
- Testy silnika obejmują nowe bonusy, limity i ich reset przy nowej grze.
