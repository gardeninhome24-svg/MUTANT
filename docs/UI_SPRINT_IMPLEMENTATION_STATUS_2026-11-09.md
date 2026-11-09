# MutantSurvivor — wdrożenie oprawy UI i graficzne QA (9 listopada 2026)

## Zakres wykonany na gałęzi main

Ten raport dotyczy faktycznie zapisanych zmian w Godot 4.7.2.
Makiety graficzne zatwierdzone przez użytkownika **nie są interaktywnymi assetami** i nie zostały bezpośrednio wklejone jako gotowe ekrany.

### Sprint 1 — współdzielony system wizualny: implementacja podstaw
- `scripts/ui/survivor_visual_system.gd` — wspólne kolory, StyleBoxFlat z ramkami i cieniami, stany normal/hover/pressed/disabled, typografia i rzadkości przedmiotów.
- Wdrożono w bazie/menu, postaci, ekwipunku, sklepie, kampanii i przyciskach umiejętności podczas walki.
- Testy instancjonowanych kontrolek pilnują minimalnego obszaru przycisku (44px) oraz stanów.

### Sprint 2 — Baza / Postać / Ekwipunek: wdrożona pierwsza warstwa graficzna
- Baza: karta etapu i postępu + trzy aktywne skróty do kampanii, nagród i ekwipunku; moc operatora pochodzi z rzeczywistych statystyk konta.
- Usunięto niezgodną z ekonomią ikonę kryształu z nagród za etap, wstawiając kredyty.
- Postać: ilustracja hangaru za prawdziwą sylwetką operatora, sloty dopasowane do szerokości 420px.
- Ekwipunek: większe ikony/karty z obramowaniem rzeczywistej rzadkości oraz zaznaczenia; logika zakładania/ulepszania pozostała aktywna.
- **Nadal nieukończone:** indywidualne produkcyjne ikony każdego przedmiotu, wielowarstwowe skórki, dopracowanie wszystkich podstron do jakości referencji.

### Sprint 3 — Kampania / Sklep / Nagrody: częściowe wdrożenie
- Kampania: wizualna mapa 10 rozdziałów, z blokadami postępu, obramowane przyciski i większa grafika bossa; istniejąca nawigacja konkretnych etapów zachowana.
- Sklep: ilustracja składu zaopatrzenia, czytelniejsze karty, działające przyciski zaopatrzenia, transakcje i potwierdzenia, zgodne z polityką beta 10 000 testowych kryształów.
- Nagrody: stosowany wspólny styl paneli; mechanika 7 dni i zadań bez zmian.
- **Nadal nieukończone:** ostateczne graficzne karty talentów, kalendarza i wszystkich rozdziałów.

### Sprint 4 — Walka / Biomy / VFX: częściowe wdrożenie
- HUD: wspólne metalowe ramki, większy tekst HP i celów, czytelne przyciski umiejętności, krótsze radio bez duplikacji NPC.
- Biomy: osobne palety ruin miejskich i reaktora, różne kolory animowanego światła w 5 biomach; zaledwie cztery lekkie tweens lamp, bez kosztownego postprocessingu.
- **Nadal nieukończone:** produkcyjne wieloklatkowe animacje czterech klas, mutantów i bossów; VFX dla całego arsenału, optymalizacja hord na realnym telefonie. Nie deklarować produkcyjnej gotowości tych assetów.

### Sprint 5 — QA i wydanie: w trakcie
- `qa/mobile_ui_regression.gd`: wspólne komponenty, bloki UI, nagrody, sklep, zakupione skórki, 420px, mapa rozdziałów i sloty postaci.
- `qa/production_art_audit.gd`: brakuje danego pliku PNG? build przerywany. Raportuje także statyczne referencje wymagające pełnej animacji.
- `qa/capture_phone_layout.gd`: 12 prawdziwych kadrów Godota w 720x1280 i 420x933, menu/postać/plecak/kampania/sklep/nagrody/walka.
- `.github/workflows/phone-screenshots.yml`: weryfikacja liczby, rozdzielczości, minimalnych rozmiarów i unikalności PNG; osobny `index.html` z galerią wizualną.
- `.github/workflows/android-apk.yml` oraz workflow signed: bramki funkcjonalne, F2P i art asset.
- **Nadal nieukończone:** wizualna ocena każdego nowego kadru względem zatwierdzonych obrazów, zrzuty z prawdziwego urządzenia, dotyk/multitouch, stabilność FPS i pamięci, aktualizacja APK z zachowaniem zapisów, podpisane wydanie i serwerowo weryfikowane real-money IAP.

## Uczciwa ocena obecnego stanu
- Stan sprzed obecnego pakietu: **5/10 wizualnie** według audytu zatwierdzonego w rozmowie.
- Ocena wizualna po nowych zmianach: **NIEPOTWIERDZONA** bez osobistego obejrzenia nowych kadrów.
- Nie twierdzić, że 8.5/10 zostało osiągnięte dzięki zielonym workflowom.
- Beta może być instalowana, gdy Android APK workflow jest zielony, ale gotowość do publicznej premiery pozostaje NIEZATWIERDZONA.
- Skróty, ekwipunek, klasa, sklep i progresja muszą nadal opierać się na prawdziwych danych gracza.
- Nie publikować automatycznie na itch.io; wymaga to świadomej decyzji właściciela.

## Odbiór
1. Sprawdzić dwa zielone workflowy na **najnowszym commicie**.
2. Pobrać z Artifact `MutantSurvivor-Phone-Two-Resolutions-Screenshots`, otworzyć `index.html`, porównać każdy obraz z referencją.
3. Powtórzyć poprawki, aż gra faktycznie osiągnie akceptowany wygląd. Widoczny GIF/PNG z generatora nie jest sam w sobie wdrożeniem do Godota.
4. Zainstalować APK debug na telefonie, zmierzyć FPS, dotyk, wczytanie zapisów, walutę testową i reakcję sklepu.
5. Przed publikacją przeprowadzić osobny audyt płatności, praw, assetów oraz aktualizacji aplikacji.
