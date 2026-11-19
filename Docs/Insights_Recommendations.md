# Insights & Recommendations

Scope: 96,203 delivered orders from 93,096 customers, Jan 2017 – Aug 2018. All figures come from `Python/olist_analysis.ipynb` and are reproduced by `SQL/03_analysis.sql`.

---

## 1. Late delivery is the strongest driver of bad reviews

**Finding**
- Late orders average **2.27★**, compared with **4.29★** for orders delivered on time.
- **62%** of late orders receive a 1–2★ review, against **9%** of on-time orders.
- The drop starts at the first day late: 1–3 days late averages 3.29★, and 8+ days late averages below 1.7★.
- Late orders are only **6.8%** of orders but **33%** of all 1–2★ reviews.
- A Mann-Whitney U test confirms late orders score lower (p < 0.001).

**What it's worth (illustrative):** if late orders had been reviewed like on-time orders, there would have been about 3,400 fewer 1–2★ reviews (**−28%**). The average score would have risen from 4.16 to about 4.29.

**Recommendation:** make the on-time rate the primary satisfaction KPI for operations, sellers and carriers. Set SLAs and alerts on it, not just on average delivery days.

---

## 2. Lateness spikes when volume spikes

**Finding**
- In normal months the late rate runs at about 3–7%.
- It jumped to **12.4% in Nov 2017** (Black Friday, the largest month for revenue).
- It reached **14–19% in Feb–Mar 2018**, then fell back to 1–7% from April 2018.

**Recommendation:** plan logistics capacity ahead of known peaks such as Black Friday and post-holiday periods. For high-volume weeks, consider temporarily widening delivery estimates or limiting sellers with poor late records.

---

## 3. Large regional gap in delivery speed

**Finding**
- **São Paulo** (42% of orders) averages **8.7 days**.
- The **North** averages **22.6 days**, and the **Northeast** averages 20.0 days with a **12.8% late rate**.
- States such as AL (21.5% late) and MA (17.5% late) also have the lowest review scores.
- Across states, slower delivery correlates with lower satisfaction (r = −0.46).

**Recommendation:** prioritise better carrier contracts or regional fulfilment for the Northeast. It has 9,000+ orders and the worst combination of slow and late deliveries.

---

## 4. Delivery estimates are heavily padded

**Finding:** **92%** of orders arrive before the promised date, typically about **12 days early**. The late rate looks good partly because the promise is so conservative.

**Recommendation:** A/B test tighter, more accurate estimates at checkout. A shorter promise may lift conversion, but monitor the late rate, because being late is far more costly than being early.

---

## 5. Almost no customers return

**Finding**
- Only **3.0%** of customers placed a second order.
- **827 of those 2,789** second orders were placed on the **same day** as the first. That's a split basket, not a return visit, so the **true return rate is 2.1%**.
- Month-1 cohort retention averages under **0.5%**.
- Repeat customers generate only **5.6%** of revenue.

**Recommendation:** growth is driven almost entirely by acquisition, so a small gain in retention is high-leverage. Build a second-purchase program, such as a post-delivery email with a time-limited offer, and send it only after an on-time delivery.

---

## 6. Two segments hold over half of revenue

| Segment | % customers | % revenue | Action |
|---|---:|---:|---|
| New high-value (recent, top-40% spend) | 15.4% | 28.3% | Nurture toward a 2nd order |
| At-risk high-value (old, top-40% spend) | 14.7% | 27.5% | Win-back campaign; check if their order was late first |
| Cooling | 19.4% | 17.8% | Light reminders |
| Hibernating / New low-value | 47.5% | 20.9% | Low-cost channels only |
| Loyal + Lapsed repeat | 3.0% | 5.6% | Loyalty perks |

**Recommendation:** focus CRM budget on the two high-value one-time segments (30% of customers, 56% of revenue).

---

## 7. Instalments go with bigger baskets

**Finding:** orders paid in full average **R$120**. Orders split into 7–10 instalments average **R$333** (2.8x). Credit cards cover 75.5% of orders, and boleto (bank slip) 19.9%.

**Recommendation:** promote interest-free instalments on high-ticket categories and validate the effect with an A/B test. Today's data only shows correlation: people buying expensive items choose instalments.

---

## Limitations

- The data is observational, so it shows association, not causation. Lateness may also stand in for other problems, such as a weak seller or a remote region.
- Only delivered orders are analysed. Cancelled or unavailable orders (about 1.2%) are excluded from satisfaction metrics.
- 643 delivered orders have no review.
- Olist's data is anonymised, so customer-level history outside this window is unknown.
