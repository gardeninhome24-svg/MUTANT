# REALISTYCZNA ANIMACJA BOHATERÓW — KONTRAKT ART + IMPLEMENTACJA

## Problem w poprzedniej wersji

Z wcześniejszego kodu dostępnego w archiwum `MutantSurvivor_Aktualny_Projekt(1).zip` wynika, że Player rusza statycznym Sprite2D przez bob/tilt/scale. Żołnierz ma częściowe 5-klatkowe sekwencje walk i shoot, ale nie potwierdzono kompletnych cykli 4 klas. Sama skala/obrót nie daje realistycznego chodu.

## Wymagania dla KAŻDEJ z 4 klas

- Idle: min. 4–6 unikalnych klatek lub prawdziwa animacja szkieletowa, ruch tułowia, oddech.
- Walk/run: min. 8–12 czytelnych klatek na kierunek/cykl (kontakt lewej stopy, przeniesienie ciężaru, wybicie, kontakt prawej), 8–12 FPS. E/W osobne lub ostrożne flip, lepiej pełne N/NE/E/SE/S/SW/W/NW.
- Shoot: min. 4–6 klatek, lufa/gun recoil, odchył ramion, górna połowa animowana niezależnie od nóg (blend tree / bones).
- Hit: 2–4 klatki, flinch i krótkie flash, bez zmiany hitboxu.
- Death: 6–10 klatek, jedna pozycja końcowa, brak zapętlenia.
- Render: przezroczyste RGBA, stały punkt odniesienia stóp, spójny rozmiar i punkt obrotu, brak tła i podpisów; pivot w dolnej środkowej części.
- Kontrola: kontakt stóp z podłożem, brak sliding, uzbrojenie bez zmiany stron niezgodnie z perspektywą, różna dynamika klas.

## Godot

1. Jeśli już istnieje AnimatedSprite2D/AnimationTree, użyj go. Jeśli jest Sprite2D z prawdziwymi osobnymi klatkami, można użyć `addons/ms_beta/animation_bridge.gd` jako przejściowego kontrolera.
2. **NIE podpinaj dwóch systemów animacji równocześnie** — wyłącz kod modyfikujący Sprite2D texture/scale w `_physics_process` starego Player, jeśli dodajesz nową animację.
3. Prowadź kierunek celowania górnej części postaci niezależnie od kierunku biegu. Najpierw poprawna artykulacja, dopiero później efekty idle bob/tilt.
4. Czas reakcji na ogień ≤100ms; animacja shooting nie może blokować sterowania.
5. Dodaj warstwy efektów: muzzle flash 60–120ms, impact 100–200ms, pierce trail, acid pool 0.4–1.2s. Godot pooling i minimalizacja overdraw.
6. Boss: atak poprzedzony telegraph, shockwave i hitstop 40–70ms, ograniczyć camera shake, nie symulować krwawej przemocy.

## Kontrola jakości na filmie z gry

- 15s: chód lewo/prawo/po skosie, bieganie i oddzielnie automatyczny strzał; pokazuj stopklatki 25%, 50%, 75% cyklu, aby sprawdzić kroki.
- 15s: kolizje z przeszkodami, unik bez przycisku (sam ruch), zdarzenia hit/damage/death.
- Sprawdź animacje wszystkich klas, a nie wyłącznie Soldier.

## Braki

W tej paczce **NIE ma ukończonych ręcznie malowanych animacji postaci**. Do pozyskania: prawdziwe frame sets z produkcji artystycznej, rig 2D dla istniejących ilustracji lub profesjonalny frame-by-frame. Nie wolno nazywać infografiki `reference/` pełnym sprite sheetem.
