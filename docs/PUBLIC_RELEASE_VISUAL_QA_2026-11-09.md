# MutantSurvivor — audyt wizualny i warunki publicznej premiery
Data: 2026-11-09. Źródło: repozytorium `gardeninhome24-svg/MUTANT`, Godot 4.7.2, Android 9:16.

## Metoda i ograniczenia
Przejrzano `scripts/main.gd`, `scripts/main_menu.gd`, `scripts/user_profile_panel.gd`,
`scripts/asset_registry.gd`, sceny `scenes/main/main.tscn` i
`scenes/ui/main_menu.tscn`, `project.godot` oraz rejestry zasobów.
Nie wykonano renderingu scen ani nagrania w emulatorze/telefonie. Nie oceniamy
faktycznie wyświetlonych kolorów/ostrości/animacji na podstawie samego kodu.
Zielony GitHub Actions #56 oznacza wykonany pipeline, a nie certyfikację UI.

## Priorytet P0 — przed publiczną premierą
1. **Przegląd rzeczywistego renderingu na Androidzie**: menu, HUD przy normalnej
   walce i dużej hordzie, okno awansu, porażka, zwycięstwo, ekwipunek, profil,
   mapa kampanii, sklep i nagrody; dla co najmniej dwóch proporcji i rozmiarów
   ekranu. Zrzuty oraz pomiar prostokątów interaktywnych.
2. **Główne menu — sztywne rozmiary** w `main_menu.gd`: karta etapu
   `Vector2(500, 220)`, przycisk gry `Vector2(420, 88)`,
   obszar bohatera `275` jednostek wysokości. Przy małych ekranach lub
   większych ustawieniach tekstu mogą wypychać elementy. Główny przycisk
   ma `text = ""` i opiera się wyłącznie na teksturze `btn_play_gold_clean.png`;
   potrzebne awaryjne oznaczenie i QA dostępności.
3. **HUD — pozycjonowanie sztywne** w `main.gd`: stats 10..205,
   currency prawa -302..-10, wave center ±145; joystick 132×132,
   fire 126×126, broń/powers w dwóch blokach na dole. Układ dla bazowego
   720×1280 ma logiczny podział, ale brak testu rzeczywistych safe areas
   i porównania 19.5:9 / 20:9 / landscape.
4. **Kampania/panel RPG — bardzo szeroki wiersz nawigacji** w
   `user_profile_panel.gd` zawiera -10, -1, skoki 1/10/30/50/100, +1, +10
   w pojedynczym `HBoxContainer`. Jest potencjalnym źródłem przycięcia i
   zbyt małych targetów dotykowych w pionie. Zastąpić zawijaniem,
   przewijaniem poziomym lub selektorem etapu przed publicznym wydaniem.
5. **Braki assetów produkcyjnych**: w
   `mutant_v1/data/boss_and_elite_roster_v2.json` wszystkie 30 rekordów
   oznaczono `MISSING_PRODUCTION_ASSET`, a w
   `equipment_catalog_v2.json` wszystkie 30 przedmiotów
   `MISSING_PRODUCTION_SPRITE`. Te metadane nie dowodzą braku obrazów
   podczas gry — `AssetRegistry` ma fallbacki — ale trzeba ocenić wygląd
   i spójność na faktycznym renderze.
6. **Animacje**: `AssetRegistry.CHARACTER_ASSETS` zawiera pięć wpisów
   statycznych `fps: 0`, `hframes=1`; gameplay może polegać na innych
   animacjach/efektach, ale kompletności animacji bohaterów nie zatwierdzono.
7. **Sklep i monetyzacja**: zakupowe opcje SANDBOX zostały wyłączone na czas
   bety. Publiczna oferta płatności wymaga gotowego i prawnie dopuszczonego
   mechanizmu zakupowego, a nie bezpłatnego przyznawania towarów.
8. **Android release**: podpisany i wersjonowany release, aktualizacja bez
   utraty danych, przetestowane FPS, dotyk, RAM i crash log na urządzeniach;
   klucze i tajne tokeny poza publicznym repo.

## Priorytet P1 — przed zatwierdzeniem grafiki
- Ujednolicić paletę kolorów, wielkości typografii i grubość obramowań
  między sceną HUD i menu z `StyleBoxFlat` oraz `StyleBoxTexture`.
- Ekwipunek: siatka filtrów 4 kolumny, sloty 4 kolumny, sklep 2 kolumny,
  nagrody 4 kolumny w pionie; sprawdzić długie nazwy i języki PL/EN/DE.
- Przejrzeć HUD przy długim tytule misji, bossie, dialogu NPC oraz
  otwartym oknie modalnym w czasie walki.
- Sprawdzić poprawne interakcje przycisków na wszystkich ekranach:
  kliknięcie, disabled, aktywność w czasie pauzy, zachowanie klawisza Wstecz.
- Potwierdzić czytelność ikon i wierność sprite'ów gracza oraz przeciwników
  w rzeczywistej skali urządzenia.

## Akceptacja UI (wymagane dowody)
- [ ] Screenshot menu, walki fala 1 i 10, awansu, porażki, wygranej,
      ekwipunku, kampanii, sklepu na docelowym telefonie.
- [ ] Zmiana proporcji 9:16 -> 20:9 nie ucina nawigacji, tekstów i CTA.
- [ ] Każdy przycisk daje czytelną informację: normal, pressed, disabled.
- [ ] Joystick/dash/bronie/power buttons nie nachodzą na siebie ani na gesty systemu.
- [ ] Boss i pociski są wizualnie czytelne przy dużej liczbie wrogów.
- [ ] FPS/RAM/temperatura zmierzone w rozgrywce przez co najmniej jeden pełny etap.
- [ ] Test aktualizacji APK z zachowaniem postępu i poprawnym podpisem.
- [ ] Przejście etapu 1, 10, 50, 100 na urządzeniu; przebieg 1–100
      automatycznie dotąd testuje logikę i dane, nie wygrywanie walk.

## Decyzja
- **Zamknięta Beta 0.2**: dopuszczalna dla 2 testerów po sprawdzeniu
  instalacji i minimum jednego pełnego etapu na Androidzie.
- **Publiczna premiera**: NO-GO bez wizualnego QA, kompletności assets,
  testów urządzeń, stabilnego release Android, legalnej monetyzacji oraz
  wyeliminowania błędów krytycznych.


## Aktualizacja audytu — automatyczne testy wizualne (9.11.2026)

Dodano `qa/visual_release_gate.gd` i włączono do workflow debug oraz
release. Po przygotowaniu nowego przebiegu CI sprawdza on:
- wymagane pliki tekstur menu, joysticka, ognia, uniku i podstawowej postaci,
  wraz z niezerowymi wymiarami obrazów;
- faktycznie utworzoną scenę walki i jej kontrolki na domyślnym
  pionowym rozmiarze 720×1280;
- brak geometrycznego nakładania: statystyk i walut, statystyk i licznika
  fal, celów i minimapy, celów i licznika fal, paska broni i umiejętności,
  joysticka i paska broni, joysticka i uniku/strzału, uniku i strzału;
- niezerowy rozmiar podstawowych elementów dotykowych.

**Wynik nowego workflow należy jeszcze odczytać.** Nie ma tu screenshotów
ani prawdziwego pomiaru na Androidzie. Nie uznawać za zaliczone
przed zielonym wykonaniem `Portrait HUD overlap and required art resource gate`.

### Pozostałe braki przed publicznym wydaniem
- [ ] Wizualny rendering i zrzuty rzeczywistych scen 9:16, 20:9, 16:9
      (Godot headless nie ocenia czytelności tekstur ani harmonii kolorów).
- [ ] Faktyczne animacje 4 klas bohaterów, bossów i elit, uzupełnienie
      metadanych brakujących assetów produkcyjnych.
- [ ] Test sceny awansu i modalnych okien w trakcie walki — nie tylko start.
- [ ] Pomiary 10 fali na Androidzie: FPS, pamięć, nagrzewanie i bateria.
- [ ] Test aktualizacji wydaniowego APK z zachowaniem zapisu i certyfikatu.
- [ ] Komplet licencji zasobów, sklep/płatności (jeśli mają być dostępne),
      polityka prywatności i zasady dystrybucji.
