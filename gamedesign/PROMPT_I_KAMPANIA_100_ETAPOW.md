# MUTANTSURVIVOR — MASTER PROMPT DLA ANTIGRAVITY

**Wersja:** v1.0 projekt wykonawczy • **cel:** naprawa obecnego prototypu + pełna struktura kampanii 100 etapów.  
**Status:** Specyfikacja projektowa. Liczby są propozycją do walidacji w Godot, nie odczytem aktualnego kodu. Nie oznaczaj funkcji jako wykonanych bez testu.

## 0. PRZECZYTAJ TO NAJPIERW — ZADANIE DLA AGENTA

Pracujesz na **ISTNIEJĄCYM projekcie MutantSurvivor** użytkownika; NIE twórz nowej gry, NIE zamieniaj działających skryptów na makietę i NIE usuwaj mechanik bez udokumentowanej przyczyny. Odszukaj `project.godot` w aktualnym katalogu roboczym, ustal działającą scenę startową, mapę, kamerę, postać, wrogów, system broni, licznik fal, GUI i ekwipunek. Przed zmianami wykonaj kopię bezpieczeństwa lub commit, jeśli repozytorium na to pozwala. Najpierw podaj audyt, co naprawdę działa i które elementy wymagają poprawy. 

**WAŻNY SCREEN UŻYTKOWNIKA:** Okno ma szarą pustą przestrzeń pod mapą oraz z prawej strony, zaś joystick, pociski i część wrogów pojawiają się na szarej przestrzeni. Właściwa grafika mapy obejmuje tylko prostokąt w górnej części. To jest niedopuszczalne. **Priorytet P0: naprawić pełnoekranowe pokrycie świata, kamerę, widoczne granice i kotwiczenie HUD, zanim zaczniesz projektować 100 etapów.** Zrzut z poprzedniego projektu referencyjnego nie jest pełną gotową teksturą planszy; NIE wklejaj zrzutu z HUD-em jako powtarzającego się tła, NIE rozciągaj całego obrazka jako substytutu mapy.

## 1. WYMAGANIA WIZUALNE (BEZ WPROWADZANIA NOWEGO STYLU)

- Utrzymaj mroczne, szczegółowo ilustrowane 2D / 2.5D top-down dark sci-fi: grafitowe ruiny, toksyczna zieleń, cyjan energii, pomarańczowe pociski i fioletowe kryształy.
- Separuj świat od interfejsu: **World/TileMapLayer/CharacterBody2D/Camera2D** i **CanvasLayer/Control** dla HUD. Faktyczne typy dopasuj po audycie wersji Godot i obecnych scen.
- Kamera zawsze kadruje poprawnie **cały grywalny viewport** (PC 1280×720, 1600×900, 1920×1080; mobile pion/poziom jeśli dostępny), a nie nieruchomą bitmapę w rogu. Zastosuj stabilne skalowanie, obszar dopełnienia i odpowiednie kotwice UI. Poza krawędzią mapy nie może ujawniać się szare tło; użyj rozbudowanej, grywalnej mapy kafelkowej lub prawidłowo ogranicz kamerę i dopełnij teren. Kamera nie może pokazywać pozaświatowej szarości po przesunięciu postaci do dowolnej krawędzi.
- Mapy buduj warstwowo: tło podłogi (tiling / kilkadziesiąt logicznych kafli lub obszarów), dekoracje, obiekty kolizyjne, światła/fog, elementy interaktywne; **nie** nakładaj wyłącznie ilustracji na sterowany sprite. Nieruchome wraki, lampy, mury i kraty powinny mieć sensowne kolizje.
- Przeciwnicy i gracz nigdy nie mogą pojawiać się poza grywalną mapą; spawn z dala od kamerowego kadru, ale w obrębie nawigowalnego świata i poza ścianami. Użyj kontrolowanej puli spawnów, nie losowego `randf()` bez kontroli świata.
- UI: na PC kompaktowy HP/XP/fale u góry po lewej, waluta i minimapa u góry po prawej, nie zasłaniają środka walki; na telefonie joystick i przyciski w bezpiecznych obszarach. **Nie pokazuj wielkiego joysticka na PC, jeśli gracz steruje klawiaturą/myszą.** Zastosuj marginesy i responsywne Control anchors.
- W poziomach bez wsparcia mikropłatności przyciski „Premium Vault”, waluty premium i energia nie powinny zaciemniać rozgrywki. Nie usuwaj jednak ekonomii istniejącego projektu bez audytu i zgody; oddziel skórkę UI od rozgrywki. Nie wprowadzaj blokady prób przez energię jako rozwiązania balansu.
- Czytelność walki ma priorytet nad efektownością: zachowaj kontrast sylwetek, widoczne telegraphy ataków, wyraźne zdrowie elit, czytelny kolor XP/pickupów, zminimalizuj oślepiające błyski.
- Kontrola obrazowa: dla każdej mapy i rozdzielczości zrób zrzuty gry faktycznie uruchomionej, NIE render statycznej planszy. Wyświetl screenshoty obok wyniku testów i popraw błędy przed kontynuacją.

## 2. MODEL GRY — ROZRÓŻNIJ 3 RZECZY

1. **ETAP / STAGE 1–100:** kolejne misje kampanii, zapis postępu, 10 rozdziałów × 10 etapów. W GUI pokazuj `ETAP 01/100 — nazwa`, a nie dwuznaczne `LEVEL 1/100`.
2. **POZIOM POSTACI 1–100:** trwały poziom profilu, zdobywany za rozgrywkę, maks. 100. To NIE to samo co etap. Zwiększa dostęp do ekwipunku / drzewka talentów, lecz nie powinien wymuszać jednego builda.
3. **POZIOM ROZGRYWKI (RUN LEVEL):** tymczasowe ulepszenia podczas 10–12 minut etapu, zwykle 12–20 awansów, reset po misji. Nie przenoś za darmo potężnych bonusów z rundy na rundę.

Każdy etap ma 10 fal. Podstawowa fala trwa 50–65 s w zależności od etapu; fale 5 i 10 mogą obejmować minibossa/bossa i czas na odbiór nagrody. Docelowy czas gry jednego etapu ~10–12 min. Jeśli istnieje już stabilny system 10 fal, **zachowaj go** i dostosuj duration do scenariusza. Etap kończy się dopiero po ukończeniu wszystkich wymaganych zadań i pokonaniu bossa. Nie zmuszaj gracza do czekania przy pustym ekranie.

## 3. MODELE TRUDNOŚCI — DANE, NIE LOSOWE STAŁE

**Zasada:** przeciwnicy skalują się według czasu, etapu, archetypu i wybranej trudności, nie według aktualnego poziomu w rozgrywce; zdobycie ulepszenia naprawdę daje przewagę. Formuły są bazą do playtestów, nie absolutnym „poprawnym balansem”.

- Minuta etapu `t` ∈ [0,12]; `stage` ∈ [1,100].
- Mnożnik zdrowia w czasie: `T_HP(t) = 1 + 0.08*t + 0.004*t*t`.
- Mnożnik obrażeń w czasie: `T_DMG(t) = 1 + 0.045*t`.
- Mnożnik HP etapu: `S_HP(stage) = 1 + 0.035*(stage-1) + 0.00018*(stage-1)^2` (rośnie wolniej niż moc uzbrojenia, weryfikuj z metaprogresem).
- Mnożnik DMG etapu: `S_DMG(stage) = 1 + 0.016*(stage-1)`.
- HP przeciwnika: `round(base_hp[archetype] * T_HP(t) * S_HP(stage) * difficulty.hp)`.
- Obrażenia: `round(base_damage[archetype] * T_DMG(t) * S_DMG(stage) * difficulty.damage)`.
- Częstotliwość tworzenia wrogów: `min(spawn_cap, (3 + 0.7*t + 0.08*t*t) * difficulty.spawn * stage_spawn_factor(stage))`, z `stage_spawn_factor = min(1.5, 1+0.005*(stage-1))`. Utrzymuj limity aktywnych jednostek oraz adaptację do platformy, ale nie zmieniaj pod spodem mnożników w sposób psujący uczciwość; redukuj VFX i nadmiar prostych mobów, nie bossów.
- Elita: bazowe HP zwykłego archetypu × 4–7; boss etapu: HP z oczekiwanego efektywnego DPS docelowego gracza × 35–75 s, z korektą faz i czasu nietykalności. Nie wyliczaj boss HP od aktualnego DPS konkretnego gracza w trakcie pojedynku (by uniknąć rubber-banding).
- Przykładowi przeciwnicy na poziomie bazowym 1: Zdziczały HP30/DMG8, Biegacz HP22/DMG6, Żrący Pełzacz HP45/DMG10, Tarczownik HP100/DMG12, Miotacz HP50/DMG9, Kolos HP180/DMG18. Nowe archetypy parametryzuj w katalogu.
- Spawn na początku 3–5/s, w środkowej części 8–14/s, końcówka 18–23/s dla standardowego etapu w bazowej trudności, tylko gdy limity i mobilna wydajność to dopuszczają. Dynamicznie ograniczaj liczbę aktywnych mobów: początek ~35, środek ~80–110, koniec ~140–160 dla PC; na mobile dobierz na podstawie profilowania. Zapobiegaj nierozwiązywalnemu korkowi spawnów.

| Tryb | HP × | DMG × | Spawn × | Nagrody × | Cel odsetka zwycięstw w kwalifikowanej grupie |
|---|---:|---:|---:|---:|---:|
| Rekrut | 0.75 | 0.70 | 0.80 | 1.00 | 80–95% |
| Ocalały | 1.00 | 1.00 | 1.00 | 1.25 | 55–75% |
| Weteran | 1.25 | 1.20 | 1.25 | 1.60 | 35–55% |
| Koszmar | 1.60 | 1.40 | 1.45 | 2.10 | 15–35% |
| Apokalipsa | 2.00 | 1.65 | 1.70 | 2.80 | 5–20% |

Nagrody trudności zwiększają **tylko walutę zdobywaną w grze / zasoby ulepszeń**, nie kupowaną walutę premium. Podstawowe ukończenie kampanii dostępne w Rekrucie. Poziomy wyższej trudności odblokowują się opcjonalnie po zaliczeniu odpowiedniego etapu na łatwiejszym trybie. Nie wymagaj wielogodzinnego grindu dla normalnej historii.

## 4. SZABLON 10 FAL — DLA KAŻDEGO ETAPU

| Fala | Czas docelowy | Zagrożenie / reguła | Działanie gracza |
|---|---|---|---|
| 1 | 0:00–1:00 | Zdziczałe i łatwi przeciwnicy | Zbieraj XP, poznaj teren |
| 2 | 1:00–2:00 | Dodaj szybkie mutanty | Opanuj ruch i strzelanie |
| 3 | 2:00–3:00 | Zwiększona liczba; pierwsze przeszkody taktyczne | Zdobądź ulepszenie |
| 4 | 3:00–4:00 | Wróg dystansowy/obszarowy | Naucz się uniku ostrzeżeń |
| 5 | 4:00–5:10 | Miniboss lub elita | Odbierz nagrodę po walce |
| 6 | 5:10–6:10 | Nowy miks dwóch archetypów | Dokonaj wyboru builda |
| 7 | 6:10–7:10 | Obszarowa presja lokalnej mechaniki mapy | Zrealizuj cel fabularny |
| 8 | 7:10–8:10 | Gęsta horda z bezpiecznymi lukami | Kontroluj przestrzeń |
| 9 | 8:10–9:10 | Przedbossowa elita, sygnalizowane zagrożenia | Uzupełnij zasoby i przygotuj walkę |
| 10 | 9:10–10:50 | Boss etapu lub silniejszy boss rozdziału | Pokonaj bossa, zakończ misję |

Warianty celów pobocznych **nie mogą zmuszać do stania w jednym miejscu w nieskończoność**. Średnio 1–2 cele eksploracyjne na etap, a w co piątym ważny test umiejętności. Pomiędzy falami mikroprzerwy max 4–7 sekund na czytelny wybór ulepszenia (pauza symulacji, jeśli ekran wyboru nie jest bezpieczny). Wszystkie specjalne ataki mają telegraph i kontrę.

## 5. BROŃ I PROGRESJA

Start: karabin impulsowy z obrażeniami 12 na pocisk, 3 pociski/s, efektywny DPS przy 70% trafień około 25.2. Target time-to-kill zwykły mutant 0.5–1.5 s na początku, 0.8–2 s w środku, 1–2.5 s pod koniec po zdobyciu ulepszeń; elita 5–12 s, boss 35–75 s. Nie obliczaj TTK tylko na papierze: testuj celność, ilość równoległych celów, przerwy strzałów, przeładowanie i ruch. 

Przykładowe awanse w runie: +15% dmg, +12% szybkostrzelność, +1 penetracja, +10% prędkość, +1 pocisk boczny, +20% zasięg pickupów, podpalenie, spowolnienie, dodatkowa tarcza. Każdy upgrade ma maksymalną liczbę poziomów i wzajemne wykluczenia tam, gdzie sensowne. Szansa zdobycia rzadkiej zdolności nie może opierać progresji wyłącznie na RNG. Zamiast samych procentów: każda nowa broń zmienia sposób walki, a nie tylko numer DPS.

Tymczasowe XP: próg następnego awansu `20 + 8*L + 2*L^2`, gdzie `L` to aktualny poziom w runie. EXP za mutanta wyliczaj z docelowego poziomu awansu i przewidywanych zabójstw na minutę, nie stałą 1 XP od początku do końca. Zdobywany XP nie przemieszcza się poza mapę. Poziom trwały `character_level` oddzielny, cel 100 jako długoterminowa progresja; dokładną liczbę godzin do 100 dopasuj z telemetrii, nie podbijaj sztucznie wymaganych zabójstw.

## 6. NAGRODY I RETENCJA (BEZ PŁATNYCH BLOKAD)

- Każde ukończenie etapu: kredyty na ulepszenia (nie waluta premium), XP postaci, szansa na kosmetykę; co piąty: schemat/moduł; co dziesiąty: nowa broń + rozdział + wpis fabularny.
- Nagrody bazowe do walidacji: `credits = round((80 + 18*stage) * difficulty.reward)`; `character_xp = round((60 + 16*stage) * difficulty.reward)`; pierwsze ukończenie +30% kredytów; w razie porażki 30% uzbieranych kredytów, z limitem przeciw AFK farmieniu; nagroda przyznana na serwerze / trwałym zapisie dokładnie raz na zdarzenie rozliczenia.
- Wybór jednego z trzech ulepszeń co awans; 1 darmowe przetasowanie co 3 awanse. Brak losowych nagród obowiązkowych dla fabuły.
- Po porażce: pokaż jasny powód przegranej, zachowaj uzasadnioną część zdobytych kredytów i zaproponuj zmianę builda. Nie karz energią, nie wymuszaj reklam do kontynuacji.
- Etapy mają krótkie cele fabularne, odkrywane archiwa i narastającą tajemnicę, ale nie zasypuj gracza niepomijalnymi dialogami. Tutorial diegetyczny do 2 min.

## 7. ARCHE TYPY WROGÓW I SYSTEM PREDYKCJI ZAGROŻEŃ

- Zwykły: idzie do gracza; Biegacz: szybka słaba jednostka; Tarczownik: broni przodu, słaby z boku; Miotacz: chmura skażenia, widoczny obszar ostrzegawczy; Skoczek: najpierw oznacza strefę lądowania; Kolos: wolny, silny, atak z zamachem; Dron: utrzymuje odległość; Faza: co jakiś czas znika, ale sygnalizuje powrót; Regenerator: widoczna animacja leczenia, możliwa przerwa przez obrażenia; Syrena: wzmacnia pobliskie hordy, wyraźny dźwięk i wskaźnik.
- Lokalny mutator każdej mapy nie może być przypadkowo śmiertelny. Podłoga z ostrzeżeniem: 0.7–1.2 s przed zadaniem obrażeń. Bossowie 2–3 fazy i co najmniej jedna kontrakcja dająca graczowi sprawczość.
- W każdym etapie maksymalnie 3 główne typy wrogów + 1 elita + boss; w etapach 90–100 maks. 4 bez chaosu wizualnego.

## 8. IMPLEMENTACJA W GODOT — STANDARD

**DANE:** `data/campaign/stages_001_100.json` (lub zasób Godot) dla etapów, `data/combat/enemy_archetypes.json`, `data/combat/difficulty_profiles.json`, `data/combat/weapons.json`, `data/campaign/story_logs.json`. Zaimplementuj jeden StageDirector ładowany z danych, nie 100 kopiowanych scen z innymi liczbami. Rozdziel StageDirector, SpawnDirector, EnemyDirector, UpgradeDirector, CampaignSave i HUD. Nadpisz istniejące skrypty tylko tam, gdzie wynika to z audytu, unikaj dublowania logiki.

**BEZPIECZEŃSTWO I ZAPIS:** przechowuj current_stage, stars/clear_by_difficulty, unlocked_weapons, character_level, unlocked_chapters; migracja istniejących zapisów przez wersję schematu. Nagrody tylko raz za ukończenie (nie za każde kliknięcie). Przegrana nie cofa wcześniejszych etapów. Możliwość ponownego grania odblokowanych etapów.

**OPTYMALIZACJA:** pooling mutantów, pocisków i pickupów; ograniczenie kosztu AI dalekich przeciwników, separacja logiki fizyki od renderingu; zróżnicowanie liczby obiektów PC/mobile. Profilowanie FPS, liczby draw calls, fizyki, pamięci; nie obiecuj stałych 60 FPS bez pomiaru.

**TESTY P0:** (1) brak szarego tła przy ruchu do każdej krawędzi; (2) kamera poprawna 1280×720, 1600×900, 1920×1080 oraz mobile, jeśli wspierany; (3) wszystkie UI trzymają pozycje i nie zakrywają ważnej walki; (4) enemy spawn wewnątrz świata i poza ścianami; (5) kolizje; (6) 10 fal kończy się dokładnie raz; (7) licznik etapów 1/100 i poziom postaci niezależny; (8) boss nie respawnuje po śmierci; (9) save/load po wygranej/przegranej; (10) brak podwójnych nagród; (11) zmiana trudności zmienia tylko właściwe mnożniki; (12) profil FPS po 10 minutach; (13) ponowne uruchomienie nie zrywa postępu; (14) rzeczywiste zrzuty ekranów i raport błędów.

**KOLEJNOŚĆ WYKONANIA:**
A. AUDYT: pliki, sceny, rozdzielczości, stan działających systemów; raport PASS/FAIL. 
B. NAPRAWA P0: pełna mapa, kamera, HUD, kolizje, spawn. Dokumentuj screenshoty z gry.
C. VERTICAL SLICE: gotowy ETAP 001, 10 fal, 3 mutanty, miniboss, boss, ulepszenia, zapis, sterowanie PC i mobile, testy.
D. STAGE DATA: warianty etapów 002–010, test czasu, fal i odblokowań; pierwszy rozdział. 
E. ROLLOUT: pełne dziesięć rozdziałów i 100 etapów z tabeli niżej, ale nie deklaruj wszystkich ukończonych, dopóki nie zostały rozegrane i zweryfikowane. 
F. BALANS: symulacje/telemetria; test F2P, utrzymanie czytelności, wydajność na niższym sprzęcie.

**RAPORTUJ PO KAŻDYM ETAPIE PRACY:** faktyczne zmienione pliki, zaimplementowane mechaniki, komenda testu, PASSED/FAILED, screenshot z uruchomionej gry, lista braków. Nie generuj sztucznych logów ani nie twierdź, że obrazek referencyjny jest funkcjonalną grą.

---

# KAMPANIA FABULARNA — 100 ETAPÓW

**Główny wątek:** Po awarii eksperymentalnego rdzenia grawitacyjnego w dolinie badawczej powstają anomalie, mutanci i anomalne kryształy. Bohater odbiera sygnał ocalałych, odkrywa powiązanie eksperymentów z mutacjami i zdobywa 10 kluczy technicznych potrzebnych, by wyłączyć „Rdzeń Zero”. Każdy rozdział rozwija tajemnicę i uczy nowej mechaniki, a finał nie wymaga płatności ani sztucznej energii.

## A. DZIESIĘĆ ROZDZIAŁÓW I NAGRODY

| Zakres | Rozdział | Nowa broń po finale | Boss finałowy | Mechanika |
|---|---|---|---|---|
| 001–010 | Przedmieścia Pustkowia | Karabin impulsowy | Matka Roju | niska presja, bezpieczne miejsca między przeszkodami |
| 011–020 | Martwa Strefa Przemysłowa | Strzelba rozpryskowa | Żelazny Nadzorca | wąskie korytarze i strefy pary |
| 021–030 | Zalane Kanały | Granat EMP | Lewiatan Kanałów | zmieniające się ścieżki i okresowe wycieki |
| 031–040 | Miasto Ciszy | Wieżyczka automatyczna | Król Ulic | zasadzki i przeciwnicy z dystansu |
| 041–050 | Ogród Biologiczny | Miotacz ognia | Kwiat Zagłady | czasowe chmury zarodników i osłony roślinne |
| 051–060 | Kompleks Antygrawitacyjny | Działo grawitacyjne | Strażnik Grawitacji | strefy przyciągania/odpychania z telegraphami |
| 061–070 | Mroźny Reaktor | Karabin termiczny | Serce Reaktora | śliskie odcinki i narastająca ekspozycja na chłód |
| 071–080 | Czarna Cytadela | Laser przebijający | Komendant Alfa | reflektory przywołujące posiłki i niszczalne osłony |
| 081–090 | Otchłań Mutacji | Wyrzutnia plazmy | Pierwotna Bestia | mutacje wrogów i zmiana geometrii tras |
| 091–100 | Rdzeń Zero | Moduł końcowy: Przeciążenie | Architekt Zero | łączenie znanych mechanik z jasnym ostrzeganiem |

## B. LISTA 100 ETAPÓW — DO ZASILENIA STAGEDIRECTOR

Każdy etap realizuje opis celu, ma 10 fal zgodnie ze wzorem; etap 5 w każdym rozdziale kładzie nacisk na minibossa, etap 10 — na finałowego bossa rozdziału. Dla pozostałych etapów fala 10 zawiera bossa lokalnego (wariant elity, z osobną fazą i czytelnym ostrzeżeniem), a w etapie 10 bossa unikatowego. Nagroda za pierwszy clear: kredyty+XP postaci wg formuły, co 5 etapów schemat, co 10 unikatowa broń.

### ROZDZIAŁ 1: Przedmieścia Pustkowia — ETAPY 001–010

**Mapa:** spękany asfalt, wraki, zarośnięte barierki. **Wrogowie lokalni:** Biegacz, Żrący Pełzacz, Zdziczały. **Historia:** Nawiąż kontakt z ocalałymi; odnajdź sygnał ewakuacyjny. **Nowy element walki:** niska presja, bezpieczne miejsca między przeszkodami.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **001** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Znaleziony dziennik patrolu | wpis w archiwum + kredyty/XP |
| **002** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Pierwszy ślad zielonych kryształów | kredyty + XP postaci |
| **003** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Magazyn kryje ocalały nadajnik | kredyty + XP postaci |
| **004** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Ktoś zagłusza sygnał ratunkowy | wpis w archiwum + kredyty/XP |
| **005** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Bestie bronią starego punktu kontrolnego | schemat modułu z tej strefy |
| **006** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Sygnał prowadzi przez blokadę | kredyty + XP postaci |
| **007** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Konwój zaginął przed ewakuacją | kredyty + XP postaci |
| **008** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Odkrycie kodu fabrycznej bramy | wpis w archiwum + kredyty/XP |
| **009** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Ostatnia wiadomość dowódcy | kredyty + XP postaci |
| **010** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Matka Roju | Odsłonięcie drogi do fabryki | odblokowanie Karabin impulsowy; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 2: Martwa Strefa Przemysłowa — ETAPY 011–020

**Mapa:** zardzewiałe hale, taśmociągi, zawory pary. **Wrogowie lokalni:** Spawacz, Toksyczny Miotacz, Tarczownik. **Historia:** Zasil fabryczną stację przekaźnikową. **Nowy element walki:** wąskie korytarze i strefy pary.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **011** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Ślady transportu nieznanego serum | wpis w archiwum + kredyty/XP |
| **012** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Roboty strażnicze nadal działają | kredyty + XP postaci |
| **013** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | W cysternach są ślady skażenia | kredyty + XP postaci |
| **014** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Dziennik technika wskazuje kanały | wpis w archiwum + kredyty/XP |
| **015** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Nadzorca nadzoruje mutację | schemat modułu z tej strefy |
| **016** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Uszkodzona linia produkcyjna | kredyty + XP postaci |
| **017** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Konwój został przekierowany | kredyty + XP postaci |
| **018** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Alarm otwiera sekcję badawczą | wpis w archiwum + kredyty/XP |
| **019** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Nagranie mówi o projekcie Zero | kredyty + XP postaci |
| **020** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Żelazny Nadzorca | Droga przez odpływy | odblokowanie Strzelba rozpryskowa; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 3: Zalane Kanały — ETAPY 021–030

**Mapa:** mokre tunele, mostki, wycieki zielonej wody. **Wrogowie lokalni:** Skoczek, Pijawka, Wodny Łowca. **Historia:** Odnajdź źródło skażenia w rurociągach. **Nowy element walki:** zmieniające się ścieżki i okresowe wycieki.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **021** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Odnaleziono przeprawę pod miastem | wpis w archiwum + kredyty/XP |
| **022** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Ślady eksperymentów na wodzie | kredyty + XP postaci |
| **023** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Bezpieczny schowek ekipy śledczej | kredyty + XP postaci |
| **024** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Kanały są kontrolowane z góry | wpis w archiwum + kredyty/XP |
| **025** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Pierwsze spotkanie z Lewiatanem | schemat modułu z tej strefy |
| **026** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Zalana blokada elektrozaworów | kredyty + XP postaci |
| **027** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Stary sonar zdradza korytarz | kredyty + XP postaci |
| **028** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | W próbkach jest biologiczny klucz | wpis w archiwum + kredyty/XP |
| **029** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Koordynaty miejskiej anteny | kredyty + XP postaci |
| **030** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Lewiatan Kanałów | Otwiera się śluza do miasta | odblokowanie Granat EMP; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 4: Miasto Ciszy — ETAPY 031–040

**Mapa:** zrujnowane ulice, autobusy, apartamenty. **Wrogowie lokalni:** Szarżownik, Łowca Dachów, Syrena. **Historia:** Uratuj nadajnik archiwalny i ustal kierunek sygnału. **Nowy element walki:** zasadzki i przeciwnicy z dystansu.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **031** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Miasto opustoszało po alarmie | wpis w archiwum + kredyty/XP |
| **032** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Dron zwiadowczy znajduje ślady życia | kredyty + XP postaci |
| **033** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Punkt pomocy jest pusty | kredyty + XP postaci |
| **034** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Antena nadaje wciąż na żywo | wpis w archiwum + kredyty/XP |
| **035** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Król Ulic strzeże centrum | schemat modułu z tej strefy |
| **036** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Sygnał prowadzi na dachy | kredyty + XP postaci |
| **037** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Ostatnia próba ratunku cywilów | kredyty + XP postaci |
| **038** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Archiwum ujawnia ogród badawczy | wpis w archiwum + kredyty/XP |
| **039** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Rozmowa głosowa z nieznanym naukowcem | kredyty + XP postaci |
| **040** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Król Ulic | Udostępnienie mapy ogrodu | odblokowanie Wieżyczka automatyczna; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 5: Ogród Biologiczny — ETAPY 041–050

**Mapa:** przerośnięte korzenie, szklarnie, zarodniki. **Wrogowie lokalni:** Zarodnik, Kolczasty, Zbieracz. **Historia:** Zbierz próbki antidotum bez niszczenia próbek. **Nowy element walki:** czasowe chmury zarodników i osłony roślinne.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **041** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Rośliny pochłonęły placówkę | wpis w archiwum + kredyty/XP |
| **042** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Pierwsza próbka antytoksyny | kredyty + XP postaci |
| **043** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Szklarnia zawiera uśpione zarodniki | kredyty + XP postaci |
| **044** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Profesor zostawił szyfr | wpis w archiwum + kredyty/XP |
| **045** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Kwiat Zagłady pokazuje swą siłę | schemat modułu z tej strefy |
| **046** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Korytarz korzeni zmienia trasę | kredyty + XP postaci |
| **047** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Ratowanie banku nasion | kredyty + XP postaci |
| **048** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Odkrycie stabilizatora grawitacji | wpis w archiwum + kredyty/XP |
| **049** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Serum jest tylko częścią rozwiązania | kredyty + XP postaci |
| **050** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Kwiat Zagłady | Wejście do kompleksu antygrawitacji | odblokowanie Miotacz ognia; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 6: Kompleks Antygrawitacyjny — ETAPY 051–060

**Mapa:** metalowe platformy, unoszące się skały, cyjanowe pole. **Wrogowie lokalni:** Dron, Faza, Magnetyczny Tytan. **Historia:** Wyłącz trzy stabilizatory rdzenia. **Nowy element walki:** strefy przyciągania/odpychania z telegraphami.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **051** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Przedmioty lewitują bez zasilania | wpis w archiwum + kredyty/XP |
| **052** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Drony strzegą paneli | kredyty + XP postaci |
| **053** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Naukowcy ukryli schemat rdzenia | kredyty + XP postaci |
| **054** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Pierwszy stabilizator traci moc | wpis w archiwum + kredyty/XP |
| **055** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Strażnik Grawitacji aktywuje pułapki | schemat modułu z tej strefy |
| **056** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Niestabilny tunel transportowy | kredyty + XP postaci |
| **057** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Drugi stabilizator zostaje odcięty | kredyty + XP postaci |
| **058** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Trzeci stabilizator otwiera reaktor | wpis w archiwum + kredyty/XP |
| **059** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Ktoś uruchamia procedurę awaryjną | kredyty + XP postaci |
| **060** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Strażnik Grawitacji | Pole grawitacyjne osłabione | odblokowanie Działo grawitacyjne; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 7: Mroźny Reaktor — ETAPY 061–070

**Mapa:** zlodowaciałe rury, chłodziwo, mroźna para. **Wrogowie lokalni:** Mroźnik, Kolos Lodu, Rój Dronów. **Historia:** Odtwórz procedurę schładzania i wyłącz awaryjny obieg. **Nowy element walki:** śliskie odcinki i narastająca ekspozycja na chłód.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **061** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Reaktor jest nadal aktywny | wpis w archiwum + kredyty/XP |
| **062** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Zagrożenie chłodziwem | kredyty + XP postaci |
| **063** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Znaleziona instrukcja wyłączenia | kredyty + XP postaci |
| **064** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Część instalacji zamarzła | wpis w archiwum + kredyty/XP |
| **065** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Pierwsze pęknięcie rdzenia | schemat modułu z tej strefy |
| **066** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Awaryjna przeprawa | kredyty + XP postaci |
| **067** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Przywracanie przepływu chłodziwa | kredyty + XP postaci |
| **068** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Zabezpieczenie laboratorium | wpis w archiwum + kredyty/XP |
| **069** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Dane o dowództwie Cytadeli | kredyty + XP postaci |
| **070** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Serce Reaktora | Przejście w stronę Cytadeli | odblokowanie Karabin termiczny; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 8: Czarna Cytadela — ETAPY 071–080

**Mapa:** fortyfikacje, reflektory, bunkry, wieże alarmowe. **Wrogowie lokalni:** Łowca Alfa, Minotaur, Saper. **Historia:** Przejmij nadajnik i poznaj twórców mutantów. **Nowy element walki:** reflektory przywołujące posiłki i niszczalne osłony.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **071** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Warownia śledzi każdą transmisję | wpis w archiwum + kredyty/XP |
| **072** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Ukryte zasilanie reflektorów | kredyty + XP postaci |
| **073** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Dziennik więźniów | kredyty + XP postaci |
| **074** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Wyłączenie wieży alarmowej | wpis w archiwum + kredyty/XP |
| **075** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Elita Alfa broni dziedzińca | schemat modułu z tej strefy |
| **076** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Otwarcie bocznej bramy | kredyty + XP postaci |
| **077** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Ocalono zakodowaną wiadomość | kredyty + XP postaci |
| **078** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Pochodzenie protokołu mutacji | wpis w archiwum + kredyty/XP |
| **079** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Ślad Architekta Zero | kredyty + XP postaci |
| **080** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Komendant Alfa | Dostęp do podziemnej otchłani | odblokowanie Laser przebijający; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 9: Otchłań Mutacji — ETAPY 081–090

**Mapa:** ciemne jaskinie, organiczne korytarze, pulsujące błony. **Wrogowie lokalni:** Widmo, Rozszczepiciel, Regenerator. **Historia:** Zniszcz żywe inkubatory i pozyskaj kod dostępu do źródła. **Nowy element walki:** mutacje wrogów i zmiana geometrii tras.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **081** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Ściany reagują na ruch | wpis w archiwum + kredyty/XP |
| **082** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Pierwszy regenerujący mutant | kredyty + XP postaci |
| **083** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Znaleziono biologiczny nadajnik | kredyty + XP postaci |
| **084** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Światło ujawnia żywe drzwi | wpis w archiwum + kredyty/XP |
| **085** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Pierwotna Bestia budzi się | schemat modułu z tej strefy |
| **086** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Inkubatory zamykają przejście | kredyty + XP postaci |
| **087** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Próbki tłumaczą szybkość mutacji | kredyty + XP postaci |
| **088** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Drzwi wymagają sekwencji kodów | wpis w archiwum + kredyty/XP |
| **089** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Prawdziwa lokalizacja rdzenia | kredyty + XP postaci |
| **090** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Pierwotna Bestia | Wejście do Rdzenia Zero | odblokowanie Wyrzutnia plazmy; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

### ROZDZIAŁ 10: Rdzeń Zero — ETAPY 091–100

**Mapa:** laboratorium dowodzenia, kryształy, portale i rdzeń. **Wrogowie lokalni:** Elita Alfa, Hybryda, Anomalia. **Historia:** Zatrzymaj powielanie mutantów i zdecyduj o losie rdzenia. **Nowy element walki:** łączenie znanych mechanik z jasnym ostrzeganiem.

| Etap | Nazwa | Cel gry | Zmiana w falach | Zdarzenie fabularne | Nagroda specjalna |
|---|---|---|---|---|---|
| **091** — Pierwszy trop | Dotrzyj do punktu sygnału | Zwykłe fale; poznanie zagrożeń | Rdzeń symuluje poprzednie strefy | wpis w archiwum + kredyty/XP |
| **092** — Rozpoznanie terenu | Pokonaj elitarnego zwiadowcę | Szybkie cele od drugiej połowy | Przejście przez pułapki pola | kredyty + XP postaci |
| **093** — Zasoby ocalałych | Utrzymaj obszar przy skrzyni zaopatrzenia | Wrogowie nadchodzą z dwóch kierunków | Zabezpieczenie trzech archiwów | kredyty + XP postaci |
| **094** — Zaginiona transmisja | Aktywuj dwa terminale w czasie walki | Pojedyncze odwracające uwagę ataki dystansowe | Spotkanie z pierwszą hybrydą | wpis w archiwum + kredyty/XP |
| **095** — Mocne uderzenie | Przetrwaj minibossa w fali 5 i końcowego mutanta | Pierwszy wariant elity danego rejonu | Obrońca rdzenia odcina odwrót | schemat modułu z tej strefy |
| **096** — Zepsuty szlak | Przejdź do punktu ewakuacji po fali 10 | Zmiana użytecznych przejść; brak pułapek bez ostrzeżenia | Zmieniające się zasady grawitacji | kredyty + XP postaci |
| **097** — Ostatni konwój | Ocal urządzenie konwoju przed falami | Silniejsza presja na punkt obrony | Znaleziono przełącznik awaryjny | kredyty + XP postaci |
| **098** — Próba przeciążeniowa | Wyłącz trzy źródła zagrożenia w kolejnych falach | Kontrolowana presja obszarowa | Dane dowodzą manipulacji Architekta | wpis w archiwum + kredyty/XP |
| **099** — Przed burzą | Pokonaj dwie różne elity, potem bossa | Dwie odmienne taktyki przeciwników | Dostęp do komory centralnej | kredyty + XP postaci |
| **100** — Serce sektora | Pokonaj bossa rozdziału i uruchom przekaźnik | Wielofazowa walka, bez nieczytelnego chaosu; boss finału: Architekt Zero | Finał: wyłącz rdzeń i zakończ kampanię | odblokowanie Moduł końcowy: Przeciążenie; klucz sektora |

**Warunek rozdziału:** odblokowanie etapu następnego wymaga ukończenia bieżącego na dowolnej trudności; boss finałowy ma minimum dwie fazy i specjalny sygnalizowany atak obszarowy. Po ukończeniu finału odtwórz 10–25 sekundowy nieobowiązkowy dialog radiowy i odblokuj rozdział następny.

## C. RÓŻNICOWANIE ETAPÓW — NIE KOPIUJ 100 RAZY TEGO SAMEGO

Cel każdego etapu i rytm fal wynikają z tabeli, ale poziomy muszą mieć również rzeczywiste **warianty geometrii i zawartości**: co najmniej 3 grywalne układy mapy w każdym rozdziale (30 wariantów łącznie); co najmniej 1 nowy typ przeszkody/interakcji na rozdział; osobne palety oświetlenia i efekty środowiskowe; 1 charakterystyczny boss rozdziału; 2–3 mutacje lokalnych wrogów. Dla realizmu produkcji we wczesnej fazie można najpierw stworzyć po 1 mapie na rozdział, potem rozszerzyć do trzech wariantów — to nie jest powód do udawania, że 100 unikatowych scen już istnieje.

NARRACJA: etap 1 ujawnia problem, 2–4 zarysowują zagrożenie, 5 — punkt zwrotny, 6–8 — kontrdziałanie, 9 — stawka finału, 10 — finał i nagroda. **Etapy 50, 60, 70, 80, 90, 100** mają wyraźnie odmiennych bossów niż we wcześniejszych rozdziałach; etap 100: 3 fazy Architekta Zero (ochrona kryształów → przywoływanie hybryd → wyłączenie rdzenia w bezpiecznym oknie). Zakończenie kampanii odblokowuje tryb dodatkowych wyzwań, NIE nowe obowiązkowe 100 etapów.

## D. KRYTERIA ODBIORU CAŁEGO PROJEKTU

1. Brak szarych obszarów przy żadnym punkcie mapy, rozdzielczości i typie kamery.
2. Autentyczna mapa grywalna z kolizjami; nigdy zdjęcie mockupu pod spodem.
3. Wszystkie etapy 001–100 mają własny identyfikator, rozdział, nazwę, cel, konfigurowalne fale, typy mobów, boss ID, nagrody i warunki odblokowania.
4. Ukończenie 100. etapu uruchamia finał i zapisuje clear; ponowne przejście nie duplikuje nagród pierwszego clear.
5. 5 profili trudności i brak paywalli; nagrody nie udają prawdziwych walut premium.
6. Główny bohater jest czytelny, wrogowie nadchodzą wyłącznie z grywalnych stref, ostrzeżenia ataków są widoczne.
7. Ulepszenia nie psują gry przez zbyt gwałtowny power creep, bossowie mogą być pokonani na bazowym poziomie trudności bez nadmiernego grindu.
8. Dokumentacja wdrożenia i testów wiernie odzwierciedla stan gry; bez fałszywych deklaracji „100 poziomów gotowe”, jeśli ukończono tylko dane.

## E. ZALECANA PIERWSZA KOMENDA DLA ANTIGRAVITY

> Otwórz istniejący projekt MutantSurvivor w aktualnym katalogu roboczym. Zacznij WYŁĄCZNIE od audytu i naprawy błędu widocznego na screenie: świat zajmuje tylko górny lewy prostokąt, pozostały obszar okna jest szary, przeciwnicy i joystick wychodzą poza mapę. Napraw viewport / Camera2D / TileMapLayer / CanvasLayer i spawny bez niszczenia stylu graficznego. Uruchom projekt w 1280×720 i 1920×1080, udokumentuj screenshotami i testami. Następnie przygotuj pierwszy w pełni grywalny etap (001) z 10 falami, minibossem, bossem i osobnym poziomem postaci. Dalej idź według tego dokumentu: NIE implementuj 100 etapów na ślepo przed potwierdzeniem pionowego wycinka.
