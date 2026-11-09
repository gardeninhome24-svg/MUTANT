# MutantSurvivor — rzeczywisty audyt wizualny, 9.11.2026

## Dowody
Oceniono 10 autentycznych PNG Godota przesłanych w rozmowie:
01 menu, 02 postać, 03 ekwipunek, 04 kampania, 05 sklep,
06 nagrody, 07 walka (720×1280), 08 walka, 09 sklep,
10 ekwipunek (420×933). To zrzuty CI / Xvfb, NIE ekran
rzeczywistego telefonu i NIE test wydajności ani dotyku.

## Ocena PRZED poprawkami (skala 1–10, ocena redakcyjna)
- Jakość dostarczonego środowiska/scenerii walki: **7/10** — spójne
  sci-fi industrialne tilesety, dobry kontrast beczek i toksycznych pól;
  nadal wymagane animacje i czytelność przy hordzie.
- Menu główne: **5/10** — mocna główna ilustracja, lecz dużo pustego
  miejsca i relatywnie słaba hierarchia postępu kampanii.
- Postać/ekwipunek: **5/10** — spójny mroczny styl, lecz gęste mikroteksty,
  dużo pustej dolnej przestrzeni, niewystarczająca czytelność ikon.
- Sklep/nagrody: **5/10** — działający podział i ceny, lecz nadal wygląd
  produkcyjnego prototypu, mała ilość informacji o wyglądzie skórek.
- HUD 720×1280: **6/10** — funkcjonalny, lecz radio, radar i cele często
  konkurują o uwagę, małe cyfry i etykiety.
- HUD 420×933: **3/10** — twardy błąd wizualny: pasek walut, statystyki
  i przyciski nachodzą na siebie; menu ma ucięty przycisk ustawień.
- Całościowa prezentacja: **5/10; NIE GOTOWE DO PREMIERY**.

## Naprawy zapisane po obejrzeniu obrazów
- 420px górny pasek menu: mniejsze kontrolki portfela, ikony,
  nawigacja i odstępy; zachowana dostępność ustawień.
- 420px walka: waluty przeniesione pod cele i radar, licznik fali
  przesunięty niżej, radio poniżej licznika; bez kolizji top-row.
- Workflow screenshots: dodanie brakującego `python3` usuwające
  potwierdzony błąd exit 127; rzeczywiste wymiary PNG i kontrole
  ucięcia settings + nakładania HUD.
- Test regresji geometrii: odrębny pas walut i licznika fali.

**Ocena poprawek po renderingu:** NIEPOTWIERDZONA — nowy workflow
musi zakończyć się sukcesem i dostarczyć obrazy. Nie podnosić oceny
na podstawie samego commita.

## Kryteria akceptacji (bramki przed publiczną premierą)
- [ ] Nowe rzeczywiste PNG potwierdzają 420px bez ucięć i kolizji.
- [ ] Sklep, nagrody, ekwipunek i kampania czytelne przy fizycznym
      ekranie telefonu; docelowe minimum targetów 44–48 dp.
- [ ] Przedmioty, bossowie i elity mają finalne spójne sprite'y/animacje.
- [ ] Wszystkie 100 etapów faktycznie przechodzi playtest balansowy.
- [ ] FPS, RAM, nagrzewanie oraz multitouch na min. 2 telefonach.
- [ ] Ponowna instalacja/aktualizacja zachowuje postęp bez strat.
- [ ] Płatności real-money bez sandboxu: oficjalny IAP, weryfikacja
      serwerowa, osobna ewidencja testowych 10 000 kryształów.
- [ ] Brak krytycznych błędów i poprawna polityka prywatności/sklepu.

## Decyzja
Nowe poprawki UI są krokiem w stronę produktu, ale projekt nadal
nie spełnia warunku 'gotowej, dopracowanej gry graficznej'. Nie
publikować publicznie i nie twierdzić, że render lub test Androida
przeszedł, jeśli nie ma potwierdzonego zielonego workflow.
