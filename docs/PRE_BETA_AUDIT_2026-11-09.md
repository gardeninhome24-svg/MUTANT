# MutantSurvivor — raport gotowości do zamkniętej bety Android
Data audytu: 2026-11-09
Repozytorium: `gardeninhome24-svg/MUTANT` (`main`)
Plan wydania: zamknięta beta na itch.io dla dwóch niezależnych testerów, nie multiplayer

## Status: CONDITIONAL / NO-GO do publikacji do czasu weryfikacji APK i testów urządzeń

**Nie wykonano pełnego end-to-end testu całej gry na telefonie.** Audyt objął
odczyt kodu i konfiguracji w GitHub, strukturalną walidację 100 definicji
kampanii oraz przygotowanie zautomatyzowanych testów Godot. Brak dostępu do
działającego emulatora Androida i potwierdzonych logów najnowszej kompilacji
oznacza, że działanie gry **nie jest jeszcze potwierdzone**. Nie interpretować
commitów, kontroli kodu ani statusu workflow jako udanego playtestu.

## Zweryfikowane na podstawie repozytorium

- Projekt ma scenę menu, scenę walki, kontroler gracza i wirtualny joystick.
- Android debug export i ręczny signed-release workflow są skonfigurowane.
  Podpisany release wymaga tajnych danych klucza i nie jest automatycznie
  wysyłany na itch.io.
- Dwie kompilacje są oddzielone; publikacja itch.io w zwykłym workflow jest
  opcjonalna i tylko na ręczne uruchomienie.
- Plik `gamedesign/etapy_001_100.json` zawiera 100 etapów o numerach 1–100,
  bez duplikatów; każdy ma 10 fal, minibossa w fali 5, bossa w fali 10 i
  niepuste `boss_id`. To test struktury danych, nie balansu.
- Wszystkie 100 etapów mają znacznik `DRAFT_PLAYTEST_REQUIRED`; ich
  balans i przechodzalność pozostają niezweryfikowane.
- Save system `StageDirector` zapisuje progresję, waluty, wyposażenie,
  ustawienia i nagrody w JSON. Nie wykonano testu odporności na korupcję zapisu.

## Poprawki przygotowane w tym pakiecie

1. **Reset dziennych misji i darmowego pakietu** według UTC, z ochroną
   istniejących zapisów przed powtórną wypłatą w dniu migracji.
2. **Naliczanie zabitych mutantów** do dziennej misji `kill_mutants`.
3. **Zablokowanie nagród z reklam bez integracji SDK i potwierdzenia**
   obejmujące wskrzeszenie i przyznawanie kredytów. Reklamowe wskrzeszenie
   nie jest dostępne w tej becie; wskrzeszenie za walutę pozostaje.
4. **Zatrzymanie joysticka po porażce**, aby dotyk nie pozostawał aktywny
   pod oknem modalnym.
5. **Nowy skrypt `qa/prebeta_validation.gd`** sprawdzający JSON kampanii
   i ładowanie trzech głównych scen; podpięty do debug i release workflow.
6. Zachowano wcześniejsze poprawki HUD, mobilnego ekwipunku, prawdziwego
   XP w menu i oddzielnego ręcznego podpisywania wydania.

## Nowa regresja integracyjna (przed APK)
W ramach kolejnego pakietu dodano `qa/gameplay_regression.gd`, wykonywany przez
workflow debug i ręczny workflow release **przed** eksportem APK. Ten test
uruchamia scenę walki w Godot headless i w izolowanym pliku `user://` sprawdza:
- broń i hełm, założenie/zdejmowanie, ulepszenie i pobranie zasobów;
- zapis/odczyt ekwipunku, poziomu ulepszenia i kredytów;
- jednorazowy pakiet dzienny, blokadę drugiego odbioru, reset UTC i zapis;
- brak nagród w trybie treningowym i po przegranej z zerową liczbą fal;
- nagrodę pierwszego ukończenia, odblokowanie tylko następnego etapu i powtórkę;
- pojawienie się mutanta i dokładnie jeden zaliczony kill;
- minibossa fali 5, bossa fali 10 i blokadę zwycięstwa przed zabiciem bossa;
- ekran zwycięstwa i ekran porażki.

**Poprawiony błąd:** `MutantEnemy.die()` już naliczał zabitego mutanta
do misji dziennej, a dopisane naliczenie w `main.gd` dublowało wynik.
Pozostawiono pojedyncze naliczenie przy rzeczywistej śmierci przeciwnika.

Nie oznaczać regresji jako zaliczonej, dopóki **najnowszy** workflow nie
pokaże zielonego wyniku. Test Godot headless nie mierzy FPS Androida,
multitouch na urządzeniu ani wyglądu grafiki.

## Co musi przejść przed zaproszeniem testerów (P0)

- [ ] GitHub Actions na najnowszym commicie: import, `qa/prebeta_validation.gd`,
      test startowy menu, test startowy sceny walki, Android debug export.
- [ ] Zweryfikować najnowszy APK: instalacja na Androidzie, uruchomienie,
      uruchomienie etapu, 10 fal, miniboss, boss, wygrana, nagrody, kolejny etap.
- [ ] Porażka: nie nalicza nagród wielokrotnie; powrót do menu, retry oraz
      płatne walutą wskrzeszenie zachowują stan.
- [ ] Sterowanie: multitouch, odrywanie palca, obrót ekranu, wyjście i powrót
      do aplikacji, otwieranie panelu RPG podczas walki.
- [ ] Zapisy: pierwsze uruchomienie, ponowne otwarcie, nowe wydanie APK,
      zachowanie ekwipunku i walut; backup zapisu przed zmianą debug->release.
- [ ] Test dwóch urządzeń: przynajmniej pełen etap na obu; nie zakładać
      identycznego wyglądu ani wydajności.
- [ ] Rozstrzygnąć, czy debug APK służy tylko do wewnętrznej bety; dla
      przyszłych aktualizacji release potrzebny stały bezpieczny certyfikat.
- [ ] Zweryfikować zgodność pakietu i podpisu; ustalić numer wersji i
      zapewnić wyższy `versionCode` przy kolejnych aktualizacjach.
- [ ] Przed publikacją: ograniczyć dostęp do strony itch.io i sprawdzić,
      czy klucz API itch.io został wymieniony, jeśli był ujawniony.

## Do poprawy przed publicznym wydaniem (P1)

- [ ] Dokładna wizualna kontrola HUD, menu, ekranów RPG, plecaka, dialogów
      i ekranów win/death na telefonach 9:16 i innych proporcjach.
- [ ] Balans kampanii 1–100 (100/100 etapów wciąż oznaczonych jako draft),
      trudność bossów i ekonomia nagród, czas pojedynczego etapu.
- [ ] Większe testy automatyczne: zapisy i migracje, ekwipunek, podnoszenie XP,
      zakończenie etapu, reset dzienny, obsługa błędów.
- [ ] Poprawna integracja reklam nagradzanych: grant wyłącznie po
      zweryfikowanym callbacku; testowe grante wyłączone.
- [ ] Rozliczanie rzeczywistych zakupów (sklep jest obecnie SANDBOX TEST),
      prawne i platformowe wymogi płatności, prywatności i ochrony konsumenta.
- [ ] Audyt praw do zasobów graficznych/audio, paczki finalnej i materiałów sklepu.
- [ ] Kontrola wydajności na słabszym telefonie: FPS, RAM, temperatury, bateria.

## Bezpieczeństwo i dystrybucja

Repozytorium było **publiczne** podczas audytu. Jeśli kod i grafiki nie mają
być publiczne, zmienić widoczność przed wydaniem. Plików keystore oraz tokenów
nie dodawać do repo ani czatu. Debug APK nie powinien być uznany za finalny
release; przed aktualizacją na certyfikat wydaniowy chronić zapisy testerów.

## Jak odczytywać testy

`qa/prebeta_validation.gd` zwraca kod wyjścia 1 w przypadku błędu struktury
kampanii lub niezaładowania sceny. Kompilacja GitHub Actions ma wykrywać błędy
na starcie menu/sceny walki, ale **nie** potrafi sprawdzić wyglądu Androida,
gestów, balansu, wszystkich 100 rozgrywek ani podpisania aktualizacji na
prawdziwym urządzeniu.

## Decyzja o becie

**NO-GO do natychmiastowej publikacji bez potwierdzonego udanego builda i
playtestu na telefonie.** Po przejściu P0 można uruchomić ograniczoną
zamkniętą betę dla dwóch testerów, nadal z jawnie komunikowanymi błędami
i ograniczeniami oraz bez pozorowania gotowych reklam/płatności.
