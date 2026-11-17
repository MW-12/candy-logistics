# Karta Projektu – Marża po dostawie i koszty logistyczne (US Candy Distributor)

Aktualizacja: 2026-11-17 · English version: [project_charter.md](project_charter.md)

## Cel biznesowy

Celem projektu jest sprawdzenie, gdzie US Candy Distributor traci marżę na dostawie paczek i jakie dźwignie mogą ją poprawić: przypisanie zamówień i produktów do fabryk, polityka opłat za dostawę, konsolidacja wysyłek.

Hipoteza: obecny model, w którym każdy produkt ma jedną stałą fabrykę, wysyła towar przez cały kraj i obniża marżę po dostawie. Przy stałej opłacie za dostawę klienci blisko fabryk dopłacają do klientów dalekich.

Podejście holistyczne: przez cały projekt prowadzimy rejestr problemów (problem → dowód w danych → propozycja rozwiązania → wpływ). Na końcu staje się on podstawą rekomendacji.

## Pytania biznesowe

1. Jaka jest marża po dostawie w obecnym modelu i gdzie firma dokłada do paczek (wielkość zamówienia, odległość, produkt, fabryka)?
2. Które trasy fabryka → klient są najbardziej efektywne, a które najmniej?
3. Które linie produktowe mają najlepszą marżę, przed dostawą i po niej?
4. Które linie produktowe warto przenieść do innej fabryki, żeby skrócić trasy, i ile to daje?
5. O ile wzrośnie marża po dostawie, jeśli zamówienia będą realizowane z bliższej fabryki?
6. Które dźwignie najmocniej poprawiają marżę: przypisanie do fabryk, polityka opłat za dostawę (minimalna wartość zamówienia, próg darmowej dostawy), konsolidacja wysyłek, huby przy wzroście skali?

## Źródła danych

Podstawą jest zbiór US Candy Distributor z [Maven Analytics Data Playground](https://mavenanalytics.io/data-playground): sprzedaż, produkty, fabryki, cele sprzedażowe i kody pocztowe USA, lata 2021–2024.

Zbiór nie zawiera kosztu transportu, dlatego uzupełnimy go danymi zewnętrznymi: rzeczywistymi dystansami drogowymi (OpenRouteService, profil ciężarówki driving-hgv) i publicznymi cennikami przewoźników paczkowych (USPS, UPS). Kolumna kosztu w danych to wyłącznie koszt produkcji.

## Model kosztów transportu

Każdą paczkę wyceniamy wzorem dopasowanym do cennika przewoźnika: cena = a + b·waga + c·mile + e·waga·mile.

- **Dystans:** drogowy z OpenRouteService (driving-hgv) dla 5 fabryk × 631 kodów pocztowych; decyduje o wyborze najbliższej fabryki. Cenę wyznacza odległość w linii prostej, bo strefy przewoźników są promieniowe.
- **Paczka:** zamówienie × fabryka (produkty z jednej fabryki w jednym zamówieniu jadą razem). Waga: 2 oz na sztukę + 0,5 lb opakowania, zaokrąglona w górę do pełnego funta.
- **Cenniki:** bazowy USPS Ground Advantage commercial i wyższy UPS Ground (stawki dzienne).
- **Opłata za dostawę:** klient płaci stałą kwotę równą średniemu kosztowi wysyłki w obecnym modelu, osobno dla każdego cennika. Opłata jest taka sama we wszystkich scenariuszach, więc kwoty oszczędności od niej nie zależą.
- **Główna miara:** marża po dostawie = zysk brutto + opłata klienta − koszt przewoźnika, w procentach przychodu (sprzedaż + opłata); pomocniczo w procentach samej sprzedaży.
- **Scenariusze:** obecny; realistyczny (najbliższa fabryka tej samej dywizji); optymalny (najbliższa z 5 fabryk); przeniesienie całej linii produktowej do innej fabryki.

Kwoty w USD są poglądowe; wiarygodne są proporcje i mile. Wynikiem będzie marża po dostawie dla obu cenników oraz test wrażliwości na poziom opłaty (niższa opłata, darmowa dostawa od progu).

## Zakres projektu

Analiza jest wstępem do dalszych badań: ma wykazać potencjał poprawy marży po dostawie i wskazać dźwignie warte dalszych badań, a nie przesądzić o zmianie modelu.

**W zakresie:** zamówienia z USA z lat 2021–2024, koszt wysyłki i marża po dostawie w modelu obecnym i alternatywnych, rejestr problemów z propozycjami rozwiązań, analiza geograficzna (skupiska klientów, huby przy wzroście skali).

**Poza zakresem (temat na osobną analizę):** koszt przejścia na nowy model, ryzyka i zagrożenia z nim związane (np. analiza SWOT), rzeczywiste koszty wysyłki firmy i moce produkcyjne fabryk. Te kwestie wykraczają poza możliwości, jakie daje baza danych.

## Założenia i ograniczenia

Scenariusze alternatywne służą do zobrazowania skali możliwych oszczędności na transporcie. Ograniczenia i trudności związane z przejściem na ten model są materiałem na kolejne badania.

- Scenariusz realistyczny wymaga, by obie fabryki czekolady produkowały wszystkie batony; najpierw trzeba zweryfikować ich moce produkcyjne.
- Baza nie zawiera danych o mocach produkcyjnych fabryk ani o rzeczywistych kosztach transportu; koszty są szacunkiem opartym na modelu kosztów.
- Opłata klienta za dostawę to założenie: dane nie mówią, kto płaci za wysyłkę.
- Cenniki zawierają stawki bazowe, bez dopłat (paliwo, adres prywatny) i bez wyceny ekspresu (Same Day).
- Waga sztuki (2 oz) jest jednakowa dla wszystkich produktów; jej wpływ sprawdzamy testem wrażliwości.
- Dane są syntetyczne: każdy klient złożył jedno zamówienie, a dywizja Sugar ma tylko 40 pozycji.
- Ograniczenia zostaną opisane w rekomendacjach jako punkt wyjścia do dalszych analiz.

## Narzędzia i środowisko

| Narzędzie | Rola |
| --- | --- |
| Python | Czyszczenie danych, dystanse z API, model kosztów, analiza statystyczna i mapy |
| PostgreSQL (lokalnie) | Baza danych na własnym komputerze: model danych i analiza w SQL |
| Power BI | Model danych i dashboard |
| GitHub | Kod, zapytania SQL, opis projektu |

## Produkty końcowe

- Dashboard Power BI: marża po dostawie w scenariuszach, przełącznik cennika, mapa paczek i strat.
- Raport z wnioskami i rekomendacjami.
- Rejestr problemów z propozycjami rozwiązań.
- Repozytorium GitHub z kodem i README.
- Karta Projektu w wersji polskiej i angielskiej.

## Etapy projektu

1. Karta Projektu.
2. Przygotowanie środowiska: lokalna baza PostgreSQL.
3. Przegląd i czyszczenie danych.
4. Pobranie dystansów drogowych i model kosztów wysyłki.
5. Model danych i załadowanie tabel do bazy.
6. Przegląd projektu i rejestr problemów; wdrożenie nowego modelu (paczka = zamówienie × fabryka, opłata klienta, marża po dostawie).
7. Analiza w Pythonie: rentowność dostaw i marże linii produktowych, efektywność tras, przeniesienie produktów między fabrykami, analiza geograficzna.
8. Analiza w SQL: odpowiedzi na pytania biznesowe.
9. Porównanie dźwigni i rekomendacje.
10. Dashboard w Power BI.
11. Wnioski, README (PL/EN) i publikacja.

## Ryzyka

| Ryzyko | Sposób ograniczenia |
| --- | --- |
| Brak rzeczywistych stawek frachtu | Dwa cenniki (USPS commercial, UPS Ground); wynik wyrażony także w milach i proporcjach |
| Limity darmowych API do wyznaczania tras | Liczenie dystansów dla unikalnych par lokalizacji, nie dla każdego zamówienia |
| Problemy z jakością danych | Weryfikacja na etapie czyszczenia i opis przyjętych decyzji |
| Błędne założenie modelu (np. definicja paczki) | Sanity check każdego wniosku i rejestr problemów |

## Kryteria sukcesu

- Odpowiedź z liczbami na każde pytanie biznesowe.
- Marża po dostawie i potencjał jej poprawy pokazane dla dwóch cenników i w teście wrażliwości na poziom opłaty.
- Każdy problem w rejestrze ma dowód w danych i propozycję rozwiązania.
- Rekomendacje, które jasno uwzględniają ograniczenia analizy.
- Działający dashboard i opublikowane repozytorium.
