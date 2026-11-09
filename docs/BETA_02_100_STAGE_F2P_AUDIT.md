# MutantSurvivor — Beta 0.2 | audyt kampanii 1–100, F2P i blokad wydania

Data: 2026-11-09. Projekt: `gardeninhome24-svg/MUTANT`, `main`.

## Decyzja

**CONDITIONAL NO-GO** dopóki najnowszy `MutantSurvivor Android APK` nie przejdzie nowych testów Godot i nie zostanie sprawdzony na Androidzie. Ten audyt **nie** stanowi dowodu, że człowiek lub bot rozegrał 100 etapów. Zawiera:
1. Przegląd rzeczywistych JSON misji, kontraktów, bossów, ekwipunku i skryptów.
2. Arytmetyczny model 100 zwycięstw za pierwszą próbą, domyślna trudność `ocalaly`, bez doładowań.
3. Nowy test `qa/campaign_100_f2p.gd`, który symuluje 100 wyników `complete_stage_run` w odrębnym zapisie. Weryfikuje dostępność kolejnego etapu, nagrody, przedmioty, brak zakupów, zapis postępu; NIE symuluje fizyki ani prawdopodobieństwa wygranej.
4. Test `qa/gameplay_regression.gd`, uruchamiający sceny etapu 1 i 100, bossów, stany wygranej/przegranej oraz trwałość zapisu. **Wynik nowego przebiegu CI do sprawdzenia**.

## Fakty w danych i w kodzie

- 100 kolejnych misji w `mutant_v1/data/campaign_100_INTEGRATION.json`, każda z 10 falami.
- Tylko **10** misji (10, 20, ..., 100) ma przypisanego w V2 konkretnego bossa. **20** misji ma wskazaną elitę w piątej fali. Odrębna definicja `gamedesign/etapy_001_100.json` deklaruje bossów w 100 etapach, ale w czasie gry wartości V2 mają pierwszeństwo, co jest różnicą między obietnicą danych projektowych a działającym systemem.
- 100/100 misji w pliku integracyjnym ma status `DRAFT`; 100/100 definicji bazowych ma `DRAFT_PLAYTEST_REQUIRED`.
- 30/30 rekordów bossów i elit w `boss_and_elite_roster_v2.json` ma `MISSING_PRODUCTION_ASSET`; 30/30 szablonów przedmiotów w `equipment_catalog_v2.json` ma `MISSING_PRODUCTION_SPRITE`. Gra posiada alternatywne tekstury, ale wygląd finalny **nie jest potwierdzony**.
- Sklep SANDBOX dawał darmowe pakiety, kryształy i VIP bez systemu płatności. Zakupy testowe są obecnie zablokowane dla uczciwego testu F2P; darmowy pakiet dzienny i normalne kredyty zdobywane w grze pozostają.
- 5 prób kampanii, regeneracja pojedynczej próby co 30 minut; trening nie zużywa prób, ale nie zwiększa trwałego postępu.

## Model ekonomiczny bez top-upów

Założenia: `ocalaly` — mnożnik nagród ×1,25; każde 100 podejść kończy się zwycięstwem za pierwszym razem; nie używamy sklepu SANDBOX, refillów za kryształy, reklam ani bonusów z zadań dziennych. Nagrody misji z `campaign_100_INTEGRATION.json`.

| Do etapu | Kredyty zdobyte (zaokrąglenia jak w przybliżeniu) | XP konta | Złom z misji |
|---|---:|---:|---:|
| 1 | 116 | 44 | 1 |
| 10 | 2 357 | 720 | 10 |
| 20 | 9 101 | 2 065 | 28 |
| 30 | 22 983 | 4 035 | 53 |
| 50 | 83 159 | 9 850 | 125 |
| 75 | 247 512 | 20 634 | 260 |
| 90 | 410 161 | 28 980 | 363 |
| 100 | **551 005** | **35 325** | **443** |

Oznacza to dodatni strumień zasobów przy **założeniu wygranych**. Nikt nie wymaga zapłaty pieniędzmi za odblokowanie następnego etapu w kontrolowanym kodzie. Kryształy są dostępne także przez zadania dzienne.

### Ile trwa kampania?

10 fal × 65 s = **650 s = 10 min 50 s** nominalnie na etap.
- 100 zwycięstw, bez pauz, przedłużenia walki z bossem i porażek: **18 h 3 min** aktywnej rozgrywki.
- Uproszczony model odnowy 5 początkowych prób i +1 co 30 min przy ciągłych rozgrywkach po 650 s: **ok. 47 h 41 min czasu kalendarzowego** od rozpoczęcia do ukończenia (w tym ok. 29 h 38 min czekania). To *model matematyczny*, nie zegar zmierzony w APK. Nie obejmuje przerw, przyspieszania za kryształy, porażek i możliwości regeneracji podczas innej aktywności.

**Wniosek:** F2P nie jest zablokowane płatnością, ale limity prób są znacznym ograniczeniem tempa. To trzeba ocenić z dwoma testerami.

## Ryzyko balansu 50–100

Model skalowania z `StageDirector.get_enemy_scaled_stats` rośnie gwałtownie w późnych etapach, a liczba przeciwników może być adaptowana do FPS. Same dane dodatnich nagród nie dowodzą, że da się wygrać etap 50 lub 100 na przeciętnym telefonie i bez zakupów. Bez rzeczywistych walk nie zatwierdzać balansu ani czasu każdego etapu.

## Wprowadzone poprawki

- Odczyt `stages` z bazowego pliku JSON o strukturze obiektu (poprzednio ładowano tylko top-level Array).
- Mnożnik kredytów za powtórne ukończenie według wartości w V2.
- Złom pierwszego ukończenia według `rewards.materials.scrap`.
- Katalog ekwipunku nie losuje awaryjnie przedmiotów niedostępnych dla danego etapu.
- Zwrot kryształów przy pustym losowaniu skrzyni.
- Wybór etapu w menu kampanii ograniczony do odblokowanych poziomów.
- Kalendarz 7 dni wymaga prawidłowej kolejności i najwyżej jednego odbioru na dzień UTC.
- Sklep SANDBOX nie umożliwia darmowego doładowywania na potrzeby bety.
- Kopia zapasowa poprawnego zapisu JSON (`.bak`) i odczyt rezerwowy przy uszkodzeniu pliku głównego. To mechanizm odzysku, **nie test aktualizacji APK na Androidzie**.
- Testy CI dla 100 etapów, dropów, nagród, zapisu, statystyk przeciwników i ostatniego bossa.

## Warunki startu zamkniętej Bety 0.2 (P0)

- [ ] Sprawdzić najnowszy **zielony** workflow po wszystkich commitach, w tym krok `Full 100-stage F2P progression and rewards audit`.
- [ ] Potwierdzić, że `Gameplay regression`, `Pre-beta structural validation`, menu i scena walki są zielone, APK artefakt wygenerowany.
- [ ] Zainstalować debug APK na Androidzie i przejść etapy 1 i 10, sprawdzić mechanikę zadań, minimapę, XP, ekwipunek, walkę i bossów.
- [ ] Przy pomocy odblokowanego testowego zapisu przetestować przynajmniej etapy 50 i 100 na Androidzie (bez publicznego rozdawania zapisu/modowania postępu).
- [ ] Zweryfikować HUD, estetykę postaci/bossów/ikon, skalowanie elementów, ekran wygranej i porażki, multitouch.
- [ ] Testować aktualizację aplikacji bez utraty danych i odzyskiwanie uszkodzonego zapisu.
- [ ] Zmierzyć FPS / RAM / nagrzewanie podczas ciężkiej fali, w szczególności 9–10.
- [ ] Publiczne repozytorium, tajne tokeny, brak niezatwierdzonej publikacji: dopilnować ograniczonego dostępu do bety.
- [ ] Nie przedstawiać sandboxowego sklepu i brakujących assetów jako ostatecznych funkcji produkcyjnych.

### Rekomendacja

Po przejściu CI i krótkim testowaniu na urządzeniu można udostępnić grę **dwóm testerom jako zamkniętą betę z jawnymi ograniczeniami**. Publiczna premiera i deklaracja „100 poziomów ukończonych i zbalansowanych” wymagają dalszych playtestów i grafiki produkcyjnej.
