# Business Understanding

## Company context

Olist is a Brazilian e-commerce marketplace integrator. Small and medium sellers list products through Olist, which publishes them on large online marketplaces and handles the sales channel. Orders are shipped by the sellers through logistics partners. After delivery, the customer receives a satisfaction survey with a 1–5 star score.

Olist's revenue grows with order volume. That makes two things critical:

- **Customer satisfaction:** review scores affect marketplace rankings, seller reputation, and whether customers trust the channel again.
- **Retention:** acquiring customers is expensive, so repeat purchases are the cheapest source of growth.

## Business problem

Leadership wants to know:

1. **Does delivery performance drive customer satisfaction?** If so, by how much, and where and when do delivery failures happen?
2. **Do customers come back?** If not, which customers should retention efforts focus on?

## Key questions

| # | Question | Analysis |
|---|---|---|
| 1 | How large is the business and how has it grown? | Revenue, orders, AOV by month; top categories |
| 2 | How fast and how reliable is delivery? | Delivery days, accuracy of the estimate, late rate by month and state |
| 3 | How much does a late delivery hurt the review score? | Review score by days early or late; statistical test |
| 4 | What share of customers buy again, and how quickly? | Repeat rate, time to second order, monthly cohort retention |
| 5 | Which customers are most valuable, and what should we do with each group? | RFM segmentation |
| 6 | Do payment options relate to basket size? | AOV by instalments and payment method |

## Success metrics (KPIs)

| KPI | Definition |
|---|---|
| Revenue | Sum of item price + freight for delivered orders |
| Average order value (AOV) | Revenue ÷ delivered orders |
| Late delivery rate | % of orders delivered after the estimated delivery date |
| Average delivery time | Days from purchase to delivery to the customer |
| Average review score | Mean 1–5 score (latest review per order) |
| Repeat rate | % of customers (`customer_unique_id`) with 2+ orders |
| True return rate | % of customers whose 2nd order came on a later day than the 1st |
| Cohort retention (month N) | % of a first-purchase cohort ordering again N months later |

## Stakeholders

- **Operations / logistics:** delivery speed, carrier performance, regional gaps
- **Marketing / CRM:** retention, segments, win-back campaigns
- **Seller success:** sellers with high late rates
- **Leadership:** overall growth and satisfaction trends

## Scope

**In scope:** delivered orders purchased between January 2017 and August 2018. This covers SQL analysis, Python EDA and statistics, customer segmentation, an interactive dashboard, and recommendations.

**Out of scope:** forecasting or machine-learning models, text analysis of review comments, the geolocation table (state is used instead), and marketing-funnel data.
