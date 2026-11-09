# MutantSurvivor — oferta sklepu i nagrody dla graczy

Stan projektu na 9 listopada 2026. Ten dokument opisuje mechanikę zapisaną w kodzie i warunki premiery. Nie jest potwierdzeniem działających płatności za prawdziwe pieniądze.

## Zasady

1. **Kampania 1–100 pozostaje grywalna bez zakupów.** Nagrody podstawowe: kredyty, złom, XP i wyposażenie za ukończenie operacji. Brak przedmiotów wymaganych do progresji wyłącznie z płatnego sklepu.
2. **Kryształy Ciemnej Materii to waluta premium** — docelowo kupowana, a nie automatycznie przyznawana za darmowe misje i logowanie. Testowa beta przyznaje jednorazowo 10 000 kryształów, osobno oznaczonych w zapisie. To nie jest promocja na premierę.
3. **Nie ma udawanych transakcji**: pakiet kryształów za prawdziwe pieniądze jest niedostępny do czasu wdrożenia zweryfikowanych płatności. Skórki można w becie kupować za testowe kryształy z salda.
4. **Unikamy skrzyń premium typu pay-to-win**. Sprzedaż bezpośrednia przedmiotów o lepszych parametrach i płatne losowania sprzętu nie są częścią aktualnego aktywnego sklepu. Ekwipunek zdobywa się w misjach i za kredyty.
5. Zakup skórki i przywrócenie prób ma potwierdzenie, sprawdzenie salda, zabezpieczenie przed duplikatem i zapis po transakcji.

## Działające oferty w becie (kryształy, nie PLN/EUR)

| Produkt | Cena | Zasady |
|---|---:|---|
| Cyber Ronin X-9 | 120 kryształów | Trwała skórka, bez premii bojowych |
| Szturmowiec Bio-Hazmat | 120 kryształów | Trwała skórka, bez premii bojowych |
| Karmazynowy Medyk | 120 kryształów | Trwała skórka, bez premii bojowych |
| Snajper Otchłani | 150 kryształów | Trwała skórka, bez premii bojowych |
| Odnowienie prób do 5/5 | 60 kryształów | Przywraca próby tylko, gdy nie są pełne |
| Pakiet 500 kryształów | Nieustalona cena pieniężna | Wyłączony do czasu prawdziwego IAP |

Pozostałe niegotowe oferty (VIP, battle pass, płatne skrzynie, starter-packi) nie są prezentowane jako gotowe produkty. Ewentualne kolejne kosmetyki i przepustka powinny być zaprojektowane i wydane dopiero z pełnymi nagrodami, estetyką i własnym systemem płatności.

## Nagrody niepłatne

### Start konta poza betą

- 350 kredytów, 12 złomu, podstawowy ekwipunek czterech slotów, 5/5 prób.
- 0 przyznanych kryształów premium; brak darmowej rzadkiej broni deweloperskiej.
- W becie **dodatkowe 10 000 kryształów tylko raz na zapis**.
- Konto z wcześniejszego testu zachowuje poprzednie zdobyte saldo do przeprowadzenia migracji; nie resetujemy bez ostrzeżenia.

### Operacje 1–100

- Pierwsze ukończenie: kredyty i XP z `mutant_v1/data/campaign_100_INTEGRATION.json`, złom z `rewards.materials.scrap`, gwarantowany przedmiot dopasowany do etapu.
- Powtórki: standardowo 35% kredytów/XP pierwszego przejścia (jeśli definicja misji nie mówi inaczej), 1 złom, szansa na drop sprzętu.
- Porażka: proporcjonalna, niska wypłata za rzeczywiście ukończone fale; zero fal = brak nagrody.
- Trening: nie kosztuje prób, ale nie daje trwałych nagród.
- Niewymagane zakupy: postęp do 100 etapu jest sprawdzany automatycznie z **zerowym saldem kryształów**.

### Codzienne zaopatrzenie

- Raz na dzień UTC: **150 kredytów + 5 złomu**, bez kryształów.
- Trzy proste misje: zabij 30 mutantów (+150 Kr, +5 złomu), ukończ operację (+220 Kr, +8 złomu), ulepsz przedmiot (+180 Kr, +6 złomu).
- Misje są odnawiane zgodnie z dotychczasowym UTC resetem; zapisane stare misje nie mogą wypłacać kryształów z poprzednich definicji.

### Jednorazowy kalendarz 7 dni

| Dzień | Kredyty | Złom | Dodatkowo |
|---|---:|---:|---|
| 1 | 120 | 4 | — |
| 2 | 160 | 5 | — |
| 3 | 220 | 6 | — |
| 4 | 180 | 8 | — |
| 5 | 250 | 10 | Przedmiot dopasowany do etapu |
| 6 | 320 | 14 | — |
| 7 | 500 | 24 | Przedmiot dopasowany do etapu |
| **Łącznie** | **1 750** | **71** | **2 przedmioty** |

Kolejność odbioru jest wymagana, najwyżej jedna nagroda dziennie. Po siódmym dniu nie powtarza się automatycznie kalendarz powitalny; codzienne zadania i zaopatrzenie trwają dalej.

## Warunki przejścia z bety do premiery

- Ustawić `StageDirector.BETA_TEST_GEMS_ENABLED = false` przed przygotowaniem publicznego APK; przy migracji istniejącego zapisu system odbiera **niewydaną** część bonusu beta i skórki opłacone w całości testową walutą.
- Bonus testowy jest zapisywany przez `beta_test_gems_granted`, `beta_test_gems_remaining`, `beta_test_skins_purchased`. Pozostałe korzyści z testów (np. odnowione próby albo rozwój przyspieszony bonusowym saldem) wymagają planu migracji lub oddzielnych kont testowych.
- **Płatności nie są gotowe.** Real-money IAP wymaga oficjalnych narzędzi platform, weryfikacji serwerowej odbioru zakupów, niezależnego rejestru sald i audytu zwrotów. Zapisy `user://` pozostają edytowalne przez użytkownika i nie mogą autoryzować wartości pieniężnej na premierze.
- Zatwierdzić ceny pakietów w EUR i PLN dopiero po sprawdzeniu regulaminów sklepu, podatków, walut regionalnych i rzeczywistych kosztów.
- Wykonać test na prawdziwym Androidzie, porównać zrzuty 720×1280 i 420×933, zbadać wydajność, zapisy, sprzedaż w sklepie i blokady duplikatów.

## Automatyzacja

`qa/premium_shop_regression.gd` testuje jednorazowy bonus bety, zakup i podwójne kliknięcie skórki, odmowę przy braku środków, odnowienie prób, zapis/odczyt, odbiór bezpłatnych nagród bez kryształów i usunięcie korzyści testowych. `qa/campaign_100_f2p.gd` wykonuje syntetyczną progresję bez jakichkolwiek kryształów. Wszystkie te testy **nie zastępują** pełnej rozgrywki ani integracji realnych IAP.

## Porównanie z innymi grami

Gry survivor mogą stosować różne strategie: `Survivor.io` udostępnia także darmowe kryształy przez misje i wydarzenia, natomiast `Vampire Survivors` koncentruje się na pełnej grywalności podstawowej wersji i dobrowolnych zakupach dodatków. Wybrany tutaj model premium-only kryształów jest decyzją projektową dla MutantSurvivor — wymaga obserwacji retencji i reakcji graczy w becie, aby nie stać się zbyt restrykcyjny.
