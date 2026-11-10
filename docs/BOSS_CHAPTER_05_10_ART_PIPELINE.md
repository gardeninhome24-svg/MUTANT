# MUTANT: unikalna grafika bossów rozdziałów 5–10

Nowy pipeline obsługuje opcjonalny, przygotowany poza repozytorium pakiet `MUTANT_Boss_05_10_Godot_Assets_v2.zip`. Każdy rozdział 5–10 ma osobny katalog `assets/bosses/boss_chNN/` z 11 plikami PNG:

- `boss_portrait.png` (portret)
- `phase1_anim_1.png` do `phase1_anim_4.png` (ruch)
- `phase2_attack_1.png` do `phase2_attack_4.png` (atak)
- `death_1.png` i `death_2.png` (śmierć)

**Instalacja:** rozpakuj zawartość ZIP do katalogu głównego projektu, tak aby otrzymać np. `assets/bosses/boss_ch05/phase1_anim_1.png`. Otwórz projekt w Godot 4.7.2 i poczekaj na import. Nie nadpisuj wcześniejszych folderów `boss_matka_roju`, `boss_goliat` i `boss_lewiatan`.

`AssetRegistry.has_complete_chapter_boss_art()` aktywuje nowy zestaw dopiero po sprawdzeniu wszystkich 11 tekstur. Jeśli brakuje choć jednej, gra korzysta ze sprawdzonych animacji bazowych. Podgląd w kampanii przełącza się na nowy portret tylko razem z pełnym zestawem animacji.

**Status jakości:** arkusze zostały wygenerowane i automatycznie pocięte z sześciu odrębnych koncepcji. Są **kandydatami**, nie zasobami o potwierdzonej zgodności 97%. Wymagają wyrównania klatek, weryfikacji transparentności, porównania renderów na 420×933 / 720×1280 i testu na Androidzie. Kod z fallbackiem jest w repozytorium, ale same PNG są dostarczone w ZIP, nie w commicie. CI bez ZIP sprawdza wersję awaryjną.

Po skopiowaniu zasobów sprawdź Godot:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://qa/gameplay_regression.gd
godot --headless --path . --script res://qa/production_art_audit.gd
```

Ostatni warunek premiery: **nie traktować obecnych plików kandydackich jako zatwierdzonych grafik bossów** bez ręcznego i wizualnego QA.

## Kontrolowany import — nowy instalator

Pobierz ZIP z rozmowy, zapisz go obok katalogu projektu, następnie uruchom:

```powershell
cd "C:\\Users\\patry\\Desktop\\2026\\MUTANT"
py -3 tools/boss_art_pack.py --zip "..\\MUTANT_Boss_05_10_Godot_Assets_v2.zip"
py -3 tools/boss_art_pack.py --zip "..\\MUTANT_Boss_05_10_Godot_Assets_v2.zip" --install
```

Zmień ścieżkę projektu, jeśli lokalna kopia znajduje się w innym folderze. Instalator wymaga `project.godot`, sprawdza **66 plików, 6 katalogów, 8-bit RGBA PNG, rozdzielczości klatek i unikalność obrazów** oraz odrzuca niekompletny pakiet. Nie rozpakowuje dowolnych ścieżek z ZIP. Jeśli klatki były wcześniej zainstalowane, użyj `--replace` po wykonaniu kopii zapasowej katalogu zasobów.

Uwaga: wersja **v2 normalizuje położenie stóp i wielkość większości klatek**, ale generator grafik nie zapewnia w pełni jednolitej geometrii każdego bossa. Szczególnej ręcznej kontroli wymaga rozdział 8. Samo przejście instalatora **nie dowodzi 97% zgodności wizualnej**.

## Wersja v3 — kontrola geometrii i rozmiaru postaci

Pakiet `MUTANT_Boss_05_10_Godot_Assets_v3.zip` poprawia rozdział 8: w poprzednich klatkach ataku brakowało fragmentów postaci. Klatki v3 opierają się na kompletnej sylwetce tej samej postaci i delikatnych efektach broni, z zachowaniem poziomu stóp. **To etap przejściowy, a nie docelowa ręczna animacja.**

Instalator sprawdza teraz nie tylko format i liczbę plików, lecz również przezroczyste obszary, proporcje sylwetki pomiędzy klatkami, wysokość ataku względem ruchu i wyrównanie stóp. Plik kontrolny `tools/boss_art_geometry.py` potrafi wykonać osobny audyt:

```powershell
py -3 tools/boss_art_geometry.py --zip ".\\MUTANT_Boss_05_10_Godot_Assets_v3.zip" --report boss_geometry_report.json
py -3 tools/boss_art_pack.py --zip ".\\MUTANT_Boss_05_10_Godot_Assets_v3.zip" --install
```

Nie używaj już starszego ZIP v2 do instalacji, ponieważ zawiera niezgodne rozmiary postaci w rozdziale 8. Zielony wynik CI bez nowych PNG oznacza, że działa kod oraz test awaryjnych grafik, a nie że wszystkie nowe klatki występują już w APK. Zgodność 97% nadal wymaga niezależnego porównania artystycznego i prawdziwych screenów.


## Godot: prawdziwy podgląd klatek i informacja o fallbacku

Workflow `MutantSurvivor Phone Resolution Screenshots` renderuje dodatkowo dwa zrzuty (17 i 18) na podstawie faktycznie zaimportowanych tekstur:
- `17_bosses_05_07_720x1280.png`
- `18_bosses_08_10_720x1280.png`

Każdy boss pokazuje cztery stany: pierwszą i ostatnią klatkę ruchu, trzecią klatkę ataku i końcową klatkę śmierci. Obok jest status `NOWE PNG (kandydat)` albo `FALLBACK / stare PNG`. Plik `boss_art_status.txt` informuje, ile z sześciu nowych zestawów rzeczywiście załadował Godot.

**Ważne:** ten test nie mierzy 97% zgodności wizualnej. Jest testem obrazu i integracji. Dopóki PNG nie zostaną dodane do repozytorium lub podane do środowiska testowego, zrzuty pokazują fallback i raport wskazuje `NEW_BOSS_PACKS_ACTIVE=0/6`.


Podgląd bossów zawiera też **portret źródłowy obok klatek animacji**, aby wykryć sytuacje, gdy animacje są błędnie wycięte z atlasu, a portret jest poprawny. Zielony import pliku nie oznacza, że klatka zawiera pojedynczą postać.


## Audyt źródeł po rzeczywistym renderze Godota

Wyrenderowane screenshoty i wyeksportowane z Godota oryginalne pliki pokazały, że stare `phase1_anim_*.png` i `phase2_attack_*.png` zawierają **ucięte fragmenty**, nie kompletne postacie. Do czasu przygotowania prawidłowych klatek, fallback wyświetla pełny `boss_portrait.png` jako statyczną postać, z zachowaniem mechaniki walki i efektów. Rejestr oznacza to jako `BOSS_STATIC_SAFE`, a nie jako pełną animację. Statyczne portrety są skalowane do maksymalnego rozmiaru 155 pikseli w świecie gry. Rozdziały 5–10 przełączą się na pełne klatki wyłącznie przy kompletnym zestawie PNG. **Nadal trzeba przetestować wygląd na urządzeniu**, a zgodność 97% pozostaje niepotwierdzona.
