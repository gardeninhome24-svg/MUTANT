# MutantSurvivor — audyt przed premierą na Google Play
**Stan repozytorium: 10 listopada 2026.** Zakres: kod gry, ekwipunek, `export_presets.cfg`, `.github/workflows/android-apk.yml`, `.github/workflows/android-release-signed.yml`, dotychczasowe testy oraz oficjalne zasady Google Play. Nie obejmuje zweryfikowanych testów fizycznych urządzeń ani danych Play Console.

## Decyzja: NO-GO dla publicznej premiery — prywatna beta nadal możliwa

**Aktualizacja workflow:** prywatny debug APK uruchamia raport `tools/google_play_preflight.py --report-only` po instalacji Pythona w obrazie CI. Raport nie blokuje testowania APK, ale wyraźnie zachowuje status `NO-GO` dla wydania. Manualny workflow AAB instaluje wymagane narzędzia, testuje strukturę ZIP i wymaga rygorystycznej walidacji podpisu `jarsigner -verify -strict`. Nie oznacza to, że podpisany AAB został zbudowany ani zaakceptowany przez Play Console.
Udana kompilacja debug APK i headless QA nie dowodzi zgodności z Google Play. Trzeba zamknąć wszystkie P0 poniżej przed przekazaniem do Production.

## Ekwipunek Metin-style — wdrożony zakres
- Sześć klikalnych slotów paperdoll: broń, pancerz, buty, hełm, rękawice, amulet.
- Grafiki założonych przedmiotów odczytywane z `StageDirector.equipped_items`, a nie z szablonu.
- Siatka plecaka 30 widocznych pól: 5 kolumn na 720px, 4 na 420px, wypełniana pustymi slotami (przy większej liczbie przedmiotów gra ich nie obcina).
- Wybrany przedmiot, informacje o statystykach, szybkie ZAŁÓŻ/ZDEJMIJ na ekranie ekwipunku i trwały zapis w `user://`.
- Ochrona zaznaczenia przed nieaktualnym ID po zmianie filtra, test w `qa/mobile_ui_regression.gd`.
- **Nieukończone**: przeciąganie między slotami (na telefonie wymagane testy multitouch) oraz test zapisu/odczytu po aktualizacji aplikacji na prawdziwym Androidzie. **Paginacja dużego plecaka jest wdrożona** i objęta zrzutami dwóch stron w Visual QA.

## P0 — wymagania Google Play

| Obszar | Stan projektu | Wymaganie / następny krok |
|---|---|---|
| AAB | **CZĘŚCIOWO NAPRAWIONE**: dodano izolowany preset `Android Google Play AAB` (Gradle, AAB, target 36). Nadal nie ma sprawdzonego, podpisanego pliku AAB; bazowy workflow do bety pozostaje APK. | Uruchomić **odrębny manualny** `.github/workflows/google-play-aab.yml` po wyłączeniu waluty beta i dodaniu podpisu, sprawdzić release-signed AAB w Play Console. Debug APK pozostaje niezależny. |
| API Android | **CZĘŚCIOWO NAPRAWIONE**: nowy preset Play ma jawny `gradle_build/target_sdk="36"`, manualny pipeline instaluje Android SDK 36; nie sprawdzono wartości w faktycznie zbudowanym AAB. | Zweryfikować faktyczny target SDK w wygenerowanym AAB. Od 31 sierpnia 2026 nowe aplikacje wymagają API 36. |
| Signing | Manualny release APK wymaga secrets, co jest dobrym rozwiązaniem. Dostępny manualny pipeline AAB z secrets; brak potwierdzenia udanego podpisanego eksportu i trwałego klucza upload. | Zweryfikować klucz, Play App Signing, numer wersji i instalację aktualizacji bez utraty zapisu. Nie publikować klucza w repo. |
| Testowe kryształy | **Poprawione w kodzie**: `StageDirector.BETA_TEST_GEMS_ENABLED = false`; migracja wcześniejszych zapisów beta nadal wymaga testu na rzeczywistym urządzeniu. | Potwierdzić, że po aktualizacji i odtworzeniu starego zapisu nie pozostają nieuprawnione waluty ani przedmioty beta. |
| Płatności cyfrowe | Pakiet 500 kryształów za realne pieniądze niedostępny; zakupy skórek używają lokalnego salda, nie Play Billing. | Google Play Billing oraz bezpieczna weryfikacja transakcji i zwrotów lub jawne wyłączenie płatnej oferty w publicznej wersji. Nie sprzedawać wartości przechowywanej tylko w lokalnym pliku. |
| Polityka prywatności | W źródłach brak dowodu na publiczną stronę polityki prywatności, poprawne wypełnienie Data safety i link w grze. | Publiczny HTTPS URL, prawdziwy opis danych/SDK/reklam i widoczny link w grze; deklaracje w Play Console. Jeśli aplikacja oferuje zakładanie kont, także kanał ich usunięcia w aplikacji i przez stronę WWW. |
| Treści / wiek | Zombie, walka, krew/efekty — brak zatwierdzonej klasyfikacji IARC w Play Console. | Wypełnić rzetelnie kwestionariusz wieku, przemocy i reklam; dopasować kampanię reklam do kategorii wiekowej. |
| Testowanie konta | Brak potwierdzenia typu i daty utworzenia konta wydawcy. | Dla nowych osobistych kont od 13.11.2023 zwykle wymagane 12 testerów opt-in bez przerwy przez 14 dni przed wnioskiem o Production. |
| Native ABI / 16 KB | arm64-v8a w presetach włączone, ale brak weryfikacji bibliotek `.so` i 16 KB page size docelowego AAB. | Sprawdzić bibliotekę Godot i ewentualne SDK w finalnym AAB oraz instalację na urządzeniu z 16 KB page size. |
| Materiały sklepu / prawa | Brak potwierdzenia pełnej listy licencji grafik, muzyki, fontów i nazwy gry. | Zinwentaryzować prawa i przygotować ikony, feature graphic, screenshoty zgodne z faktyczną wersją oraz opis produktu. |
| Ikona aplikacji | **W kodzie poprawiono**: `project.godot` wskazuje osobny kwadratowy SVG `assets/ui/target_theme/icon_mutant_survivor.svg`, wywodzący się z istniejącego logo. CI sprawdza ścieżkę, import i geometrię. **Niezweryfikowane**: wygląd rzeczywistej ikony launchera i wariantów adaptacyjnych na Androidzie. | Sprawdzić wygląd ikony na urządzeniu, przygotować/włączyć monochromatyczny i adaptacyjny wariant Androida oraz zatwierdzić branding w Play Console. |

## P0 — stabilność samej gry
- Test na fizycznych urządzeniach: 420×933, 720×1280, 20:9; Android 13–16, gesty systemowe, notch, joystick multitouch, rotacja.
- Pełna rozgrywka min. jednego etapu na słabszym telefonie, fala 10 i boss, porażka/wygrana, nagrody, zapis po zabiciu procesu, upgrade APK ze starym zapisem.
- FPS, temperatury, RAM, ANR, crash logs i Play pre-launch report.
- Brak regresji sklep/bonusy/saldu oraz klikania zakrytych przycisków; sprawdzić gameplay bez połączenia.
- Spójne, faktycznie obejrzane screeny wszystkich ekranów. Deklarowany przez właściciela próg **97% podobieństwa do zaakceptowanych referencji** nie został obiektywnie zmierzony ani potwierdzony.

## Priorytet wdrożenia
1. Utrwalić i przetestować ekwipunek na telefonie; porównać rzeczywiste screenshoty.
2. Zbudować osobny preset AAB z API 36 (nie naruszać debug APK); sprawdzić 16 KB i release signing.
3. Ustalić model monetyzacji na publiczną premierę, wyłączyć betę i zapewnić zgodność Billing/Data safety.
4. Przejść fizyczne QA, IARC, metadane i test zamknięty Play Console.
5. Dopiero wtedy rozważyć status GO.

## Oficjalne źródła — aktualne na dzień audytu
- Google Play target API: https://support.google.com/googleplay/android-developer/answer/11926878
- Google Play Billing policy: https://support.google.com/googleplay/android-developer/answer/9858738
- Google Play privacy policy / data safety: https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play testowanie nowych kont: https://support.google.com/googleplay/android-developer/answer/14151465
- Google Play content ratings: https://support.google.com/googleplay/android-developer/answer/9898843
- Google Play AAB publication: https://developer.android.com/studio/publish
- Godot 4.7 Android export: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html
- Godot 4.7 Gradle build: https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html

## Wdrożenia repozytoryjne podczas audytu (10.11.2026)
- Poprawiono wybór pustego slotu, synchronizację zaznaczenia plecaka i zabezpieczenie szybkich akcji przy zmianie filtra.
- Dodano test regresji filtra bez pasujących przedmiotów do `qa/mobile_ui_regression.gd`.
- Dodano `tools/google_play_preflight.py`: statyczny test typu NO-GO, który zatrzymuje release przy włączonych kryształach beta lub niegotowym AAB.
- Dodano osobny preset `Android Google Play AAB` oraz manualny workflow `.github/workflows/google-play-aab.yml` — **nie zostały jeszcze zweryfikowane przez udany podpisany build AAB**.
- Zwykły debug APK pozostaje na dotychczasowym presie i jest testowany osobno. Release do Play nie jest publikowany automatycznie.


## Blokada końcowego AAB — brak finalnych grafik bossów 5–10

Ścisły `tools/google_play_preflight.py` weryfikuje teraz, czy wszystkie **66 plików PNG** sześciu bossów znajdują się w repozytorium używanym do budowania wydania. Wersja prywatna APK pokazuje informację o braku, lecz nie jest blokowana przez tę kontrolę. Podpisane AAB nie powinno przejść, dopóki komplet grafik nie trafi do źródeł. Ten test sprawdza obecność i niepustość plików, **nie zatwierdza jakości 97%** ani licencji; odbiór wizualny nadal jest obowiązkowy.
