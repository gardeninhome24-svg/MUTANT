# Krótko: co wpiąć w najnowszy projekt

1. Rozpakuj ten ZIP OBOK projektu Godot, nie na wierzch. Zweryfikuj backup.
2. Skopiuj `addons/ms_beta/` -> `res://addons/ms_beta/`, a `assets/` -> `res://assets/ms_beta_kit/` (zachowując podfoldery).
3. Nie nadpisuj istniejących HD postaci, animacji, bossów i efektów. Nowe PNG mogą być użyte jako panel background/TextureRect/StyleBoxTexture; zachowaj border margins 16–24 px (9-slice).
4. W `main.gd`: `fire_btn` i `dash_btn` w `_set_touch_controls_visible` mają pozostać niewidoczne, niezależnie od layoutu. Usuń UI trzech aktywnych skilli i jego update. Usuń ręczne Q/E/Spacja jeśli design wymaga pełnego auto. Nie usuwaj metod postaci, bo zostaną wywoływane automatycznie po odblokowaniu.
5. W Player (albo w Main): `var auto_controller = preload("res://addons/ms_beta/auto_skill_controller.gd").new(); player.add_child(auto_controller); auto_controller.bind_to_player(player); auto_controller.set_unlocks(can_grenade, can_vortex)`; `can_*` oblicz z aktualnego levelu klasy, nie poziomu runu. Powyższe jest **przykładowym snippetem do adaptacji**, nie gotową łatką do wszystkich wersji `player.gd`.
6. Dotychczasowy Player już auto strzela przy timerze, więc **nie dodawaj drugiej pętli auto-shoot**. Patterny shotgun/plasma/drone implementuj jako nowe logiczne warianty pocisków, bez podwójnego DPS.
7. `animation_bridge.gd` uruchamiaj tylko przy zweryfikowanym komplecie realnych klatek. W przeciwnym razie pozostaw bieżące animacje i zgłoś brak.
8. Migruj save per-class, konto wspólne. Wszystkie kosmetyczne i premium zakupy na konto. Zweryfikuj każdy scenariusz w CSV.
