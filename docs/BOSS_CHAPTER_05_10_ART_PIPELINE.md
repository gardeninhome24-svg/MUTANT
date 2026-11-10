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
