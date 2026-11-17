# Project Charter – Delivery Margin and Logistics Costs (US Candy Distributor)

Last updated: 2026-11-17 · Polish version: [karta_projektu.md](karta_projektu.md)

## Business objective

The objective is to find where US Candy Distributor loses margin on parcel delivery and which levers can improve it: assigning orders and products to factories, delivery fee policy, shipment consolidation.

Hypothesis: the current model, in which each product has one fixed factory, ships goods across the whole country and lowers the margin after delivery. With a flat delivery fee, customers near the factories subsidize distant customers.

Holistic approach: throughout the project we keep a problem register (problem → evidence in the data → proposed solution → impact). At the end it becomes the basis for the recommendations.

## Business questions

1. What is the margin after delivery in the current model, and where does the company lose money on parcels (order size, distance, product, factory)?
2. Which factory → customer routes are the most efficient, and which are the least efficient?
3. Which product lines have the best margin, before and after delivery?
4. Which product lines should be moved to a different factory to shorten routes, and what would it bring?
5. How much would the margin after delivery grow if orders were fulfilled from a closer factory?
6. Which levers improve the margin most: factory assignment, delivery fee policy (minimum order value, free-shipping threshold), shipment consolidation, hubs as the business scales?

## Data sources

The base is the US Candy Distributor dataset from [Maven Analytics Data Playground](https://mavenanalytics.io/data-playground): sales, products, factories, sales targets and US ZIP codes, 2021–2024.

The dataset contains no transportation cost, so we add external data: actual road distances (OpenRouteService, driving-hgv truck profile) and published parcel carrier rate tables (USPS, UPS). The cost column in the data is manufacturing cost only.

## Shipping cost model

Each parcel is priced with a formula fitted to the carrier's rate table: price = a + b·weight + c·miles + e·weight·miles.

- **Distance:** road distance from OpenRouteService (driving-hgv) for 5 factories × 631 ZIP codes; it determines the nearest factory. Price is based on straight-line distance, because carrier zones are radius-based.
- **Parcel:** order × factory (products from one factory in the same order ship together). Weight: 2 oz per unit + 0.5 lb packaging, rounded up to the next full pound.
- **Rate tables:** base USPS Ground Advantage commercial and higher UPS Ground (daily rates).
- **Delivery fee:** the customer pays a flat fee equal to the average shipping cost in the current model, separately for each rate table. The fee is the same in all scenarios, so savings in dollars do not depend on it.
- **Main metric:** margin after delivery = gross profit + customer fee − carrier cost, as a percentage of revenue (sales + fee); secondary as a percentage of sales only.
- **Scenarios:** current; realistic (nearest factory of the same division); optimum (nearest of all 5 factories); moving a whole product line to a different factory.

Dollar amounts are illustrative; proportions and miles are reliable. The result will be the margin after delivery for both rate tables plus a sensitivity test on the fee level (lower fee, free shipping above a threshold).

## Project scope

The analysis is a starting point for further research: it aims to show the potential to improve the margin after delivery and to point to levers worth further study, not to decide on changing the model.

**In scope:** US orders from 2021–2024, shipping cost and margin after delivery under the current and alternative models, a problem register with proposed solutions, geographic analysis (customer clusters, hubs as the business scales).

**Out of scope (separate analysis):** the cost of transitioning to the new model, its risks and threats (e.g. a SWOT analysis), the company's actual shipping costs and factory production capacity. These go beyond what the dataset allows.

## Assumptions and limitations

The alternative scenarios serve to illustrate the scale of possible savings. The limitations and difficulties of switching to them are material for further research.

- The realistic scenario requires both chocolate factories to make all chocolate bars; their production capacity must be verified first.
- The dataset contains no data on factory production capacity or actual transportation costs; costs are an estimate based on the cost model.
- The customer delivery fee is an assumption: the data does not say who pays for shipping.
- Rate tables include base rates only, without surcharges (fuel, residential) and without express pricing (Same Day).
- Unit weight (2 oz) is the same for all products; its impact is checked with a sensitivity test.
- The data is synthetic: each customer placed one order, and the Sugar division has only 40 order lines.
- The limitations will be described in the recommendations as a starting point for further analysis.

## Tools and environment

| Tool | Role |
| --- | --- |
| Python | Data cleaning, distances from an API, cost model, statistical analysis and maps |
| PostgreSQL (local) | Database on own computer: data model and SQL analysis |
| Power BI | Data model and dashboard |
| GitHub | Code, SQL queries, project description |

## Deliverables

- Power BI dashboard: margin after delivery by scenario, rate table switch, map of parcels and losses.
- Report with findings and recommendations.
- Problem register with proposed solutions.
- GitHub repository with code and README.
- Project Charter in Polish and English.

## Project phases

1. Project Charter.
2. Environment setup: local PostgreSQL database.
3. Data review and cleaning.
4. Retrieving road distances and building the shipping cost model.
5. Data model and loading tables into the database.
6. Project review and problem register; new model implemented (parcel = order × factory, customer fee, margin after delivery).
7. Python analysis: delivery profitability and product line margins, route efficiency, moving products between factories, geographic analysis.
8. SQL analysis: answering the business questions.
9. Lever comparison and recommendations.
10. Power BI dashboard.
11. Findings, README (PL/EN) and publication.

## Risks

| Risk | Mitigation |
| --- | --- |
| No actual freight rates | Two rate tables (USPS commercial, UPS Ground); result also expressed in miles and proportions |
| Free routing API limits | Calculate distances for unique location pairs, not for every order |
| Data quality issues | Verification during cleaning and documentation of decisions taken |
| Wrong model assumption (e.g. parcel definition) | Sanity check of every conclusion and a problem register |

## Success criteria

- A quantified answer to each business question.
- Margin after delivery and its improvement potential shown for both rate tables and in a sensitivity test on the fee level.
- Every problem in the register has evidence in the data and a proposed solution.
- Recommendations that clearly account for the limitations of the analysis.
- A working dashboard and a published repository.
