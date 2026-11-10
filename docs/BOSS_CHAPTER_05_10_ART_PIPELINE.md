# MUTANT: unikalna grafika bossów rozdziałów 5–10

Nowy pipeline obsługuje opcjonalny, przygotowany poza repozytorium pakiet `MUTANT_Boss_05_10_Godot_Assets.zip`. Każdy rozdział 5–10 ma osobny katalog `assets/bosses/boss_chNN/` z 11 plikami PNG:

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