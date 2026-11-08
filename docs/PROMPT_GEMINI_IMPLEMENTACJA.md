# GEMINI / ANTIGRAVITY — PEŁNY PLAN REALIZACJI BETA MUTANTSURVIVOR

Pracujesz w **istniejącym** projekcie `C:\Users\patry\Desktop\2026\MutantSurvivor`, Godot 4.7.2. **Nie zakładaj, że opis lub zdjęcia potwierdzają działanie w grze.** Raport ma zawierać rzeczywiste wyniki i załączniki.

## Reguły bezpieczeństwa

- Przed pracą backup projektu, user://mutant_campaign_save.json, kontrola Git diff, ostrożność z plikami asset_registry, player, main, stage_director i profil.
- NIE zastępuj najnowszego projektu starszym ZIP. NIE kasuj już działających systemów kampanii, RPG, ekonomii ani UI.
- Zachowaj zatwierdzony wygląd: ekran bazy z żołnierzem, płonącym miastem i złotym GRAJ; zbrojownia dla postaci i plecaka; magazyn zaopatrzenia dla sklepu; osobny układ 9:16 Android/iOS oraz 16:9 PC.
- Usuń debugowe przyciski / przerzucanie etapów bez blokady; zachowaj pełne walidacje etapu, bossów, wypłat, prób, treningu i revive.

## Priorytet P0: AUTOMATYCZNA WALKA I JEDEN JOYSTICK

1. Gracz steruje wyłącznie ruchem. Karabin wystrzeliwuje automatycznie; usuń przyciski FireBtn, DashBtn oraz trzy buttony `dash_skill_btn`, `grenade_skill_btn`, `vortex_skill_btn` z UI (najpierw odłącz wejścia, potem ukryj w scenach; bez ryzyka null reference).
2. Q/E/Spacja też nie aktywują już ukrytych umiejętności. Metody gracza zachowaj w kodzie jako zaplecze systemu automatycznego.
3. Na początku pierwszego etapu tylko broń podstawowa. Umiejętności klasowe pojawiają się stopniowo: przykładowo poziom klasy 5 oraz 30; wartości odczytaj z data/combat_config.json, dostosuj do rzeczywistej progresji.
4. Użyj `addons/ms_beta/auto_skill_controller.gd` jako opcjonalnego wzorca do podpięcia pod Player. Gdy skille są odblokowane, aktywuj je automatycznie, gdy wrogowie są blisko oraz cooldown wynosi zero. Nie aktywuj wszystkich mocy każdemu graczowi od razu.
5. Rozróżnij patterny broni: karabin nearest; strzelba wachlarz multi-hit; plazma pierce; dron wybór kilku celów; obszarowa najlepiej skupiona grupa. Nie powielaj istniejących obrażeń przez jednoczesne stare i nowe strzały. Przetestuj limit pocisków i FPS przy 100+ wrogach.
6. Perki podczas runu są wybierane w pauzie po zdobyciu XP, maksymalnie 3 karty, spójna polonizacja i ikony. Ich ataki/efekty uruchamiają się automatycznie.

## Priorytet P0: 4 KLASY / 100 ETAPÓW KAŻDA

- Każda klasa: własny XP, poziom (max 100), ukończenia etapów, talenty, wyposażone sloty. Ta sama kampania i cel misji.
- Pierwsze ukończenie etapu N daną klasą: postęp poziomu +1 do max 100 i odblokowanie następnego etapu dla tej klasy; mechanika początkowego Lv1 / etap1 wymaga jasnego mapowania indeksów. Ponowne ukończenie nie dodaje kolejnego poziomu „za first clear”.
- Magazyn, kredyty, złom, kryształy, skiny, VIP i Battle Pass wspólne. Wszystkie przedmioty pasują do każdej klasy; konfiguracje założonych slotów per klasa.
- Darmowa zmiana klasy TYLKO w Bazie. Nie pozwalaj przełączać postaci podczas rozpoczętego etapu.
- Zwykłe pierwsze nagrody per klasa, duże premium milestone tylko raz na konto. Praktyka/trening zero nagród.
- Migracja istniejących zapisów: snapshot starego save -> nowy format, zachowaj majątek i odblokowania, test idempotencji i cofnięcia zmian.

## Priorytet P0: STABILNOŚĆ I PEŁNY RUN

- Każdy etap 10 fal. Zwycięstwo dopiero po ukończeniu rzeczywistych celów i bossa. Rezygnacja z revive finalizuje porażkę. Brak zerowych sukcesów i podwójnych nagród.
- 5 prób kampanii, +1 co 30 min, retry kosztuje nową próbę, trening darmowy ale nie wypłaca walut. Dopilnuj resetów czasu offline i walidacji zakupów po reconnect.
- 45–60 dni aktywnego F2P przy 45–90 minutach dziennie to cel do symulacji, nie obietnica. Po etapie 30 wymagająca mechanika zamiast sztucznego hard paywall. 100 poziomów 5 biomów; po 100 tygodniowe wyzwania.
- Test prawdziwego finału 001, 030, 100 i 10–15 minut; wykres nagród i DPS/HP, unikanie nadmiernego ekwipunku P2W.

## Priorytet P1: PRAWDZIWE ANIMACJE I EFEKTY

- Wdrożyć osobne klatki idle/walk/shoot/hit/death dla Żołnierza, Inżyniera, Medyka, Zwiadowcy. Przełączanie zależnie od prędkości, celowania, trafienia i śmierci. Kierunkowość min. E/W i najlepiej 8 kierunków dla top-down; lustrzane odbicia tylko tam, gdzie broń/pancerz nie oszukują perspektywy.
- Przyśpieszenie/hamowanie kroków, stabilne stopy, brak przesuwania statycznej ilustracji udającego chodzenie. Co 0.1 s pokazuj rzeczywistą inną klatkę lub animację szkieletową z prawdziwą artykulacją nóg i ramion.
- Mutanty i bossowie: bieg, atak, obrażenia, śmierć. Bossowie wielofazowi: telegraph czytelny min. 0.8–1.2 s; kamera shake subtelny, hit flash i odrzut, bez zalewu cząstek na słabym telefonie.
- Użyj pomocniczych 24 klatek FX z `assets/vfx`; są proceduralne. Wyższej jakości obecne efekty HD mają pierwszeństwo. Wprowadź pooling pocisków/efektów i limit jednoczesnych particle nodes.
- Filmik 15–30 s prawdziwego chodu i walki 4 klas + zrzuty ruchu z Godot, nie sam plakat.

## Priorytet P1: NOWOCZESNY HUD I UI

- Jeden joystick na mobile w lewym dolnym rogu; brak aktywnych buttonów po prawej. PC WASD/strzałki; zero ręcznego celowania/strzelania.
- Zajętość HUD minimalna: HP, XP, fala, boss tylko w boss fight, zwijane cele misji i powiadomienia NPC auto-hide.
- Polskie fonty z kompletnymi znakami; PL/EN/DE lokalizacja, teksty nie wychodzą poza kartę; nie mieszaj angielskich nazw `SUPERCONDUCTORS`.
- Nawigacja nieucięta na 720x1280, 1080x1920, 1280x720, 1920x1080; safe area; porównaj screeny z zaakceptowanym menu. Korzystaj z PNG paneli i buttonów niniejszej paczki tylko jeśli lepsze od bieżących HD. Zero czarnych zasłaniających bloków.

## Priorytet P1: EKONOMIA I WARSZTAT

- Losowe dropy + materiały gwarantowanego postępu; duplikaty rozkład na złom LUB fuzja dowolnych 3 przedmiotów tej samej rzadkości -> losowy wyższej, z potwierdzeniem i transakcyjnym zapisem.
- Skrzynie darmowe oraz za kryształy, jawny drop i licznik gwarancji legendarnego maks. 50 otwarć; procenty NAJPIERW policz, nie wymyślaj finalnego %. Upgrade 100% sukcesu.
- VIP 9.99 EUR/30 dni, Battle Pass 9.99 EUR/30 dni, wspólne na konto; drobne bonusy oraz codzienne kryształy. Ads wyłącznie opt-in i wyłączalne konfiguracją. Wszystko sandbox do prawdziwych zakupów i weryfikacji rachunków.

## Priorytet P2: GLOBALNE RANKINGI I ONLINE

- Jeden globalny ranking wszystkich platform: poziom, sezon (30 dni), przetrwanie (7 dni). Serwer autorytatywnie weryfikuje wynik, ignoruje lokalne JSON jako dowód. Offline kampania możliwa, rankingi online.
- 14-dniowe wydarzenia co miesiąc, nagrody kosmetyczne; 25 zweryfikowanych, różnych graczy po finale 100 -> odblokowanie wdrożenia gotowej aktualizacji 101–200 i Sala Legend. Nie aktualizuj gry samym przekroczeniem licznika, gdy content nie gotowy.

## Dowody zakończenia

1. Raport `PASS/FAIL` dla `qa/ACCEPTANCE_MATRIX.csv`, z logami i dokładną wersją silnika.
2. Screenshot menu, postać, ekwipunek, kampania, sklep, daily, HUD, karty ulepszeń, victory/defeat 9:16 i układy PC 16:9.
3. Wideo chodu + walki (nie screenshot).
4. Pełne sesje etapów 1, 30, 100 bez debug skrótów i oszustw w zapisie.
5. Profilowanie FPS, RAM, startup i dotyk na realnym Androidzie.
6. Lista braków, zwłaszcza pełnych sprite'ów animacji; stan kont/backendu/rankingów, billing/ads testowych.
7. Finalny ZIP nowej wersji projektu z zachowaniem backupu; nie ogłaszaj gotowości do zamkniętej bety, jeśli testy P0 nie są PASS.
