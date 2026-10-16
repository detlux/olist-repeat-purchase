import numpy as np
import pandas as pd
import plotly.express as px

from db import get_engine

P0 = 0.0176
DISCOUNT = 0.10
AUDIENCE = 21279
MARGINS = [0.15, 0.20, 0.30, 0.40]
LIFTS = [0.003, 0.005, 0.0075, 0.01, 0.0125]
SCENARIOS = {"pessimistic": 0.003, "base": 0.0075, "optimistic": 0.011}

q = """
SELECT o.revenue
FROM v_orders o
JOIN (
    SELECT customer_unique_id, MIN(purchased_at) AS first_at
    FROM v_orders
    GROUP BY 1
) f ON f.customer_unique_id = o.customer_unique_id
WHERE o.purchased_at > f.first_at
"""
R = float(pd.read_sql(q, get_engine())["revenue"].astype(float).mean())


def profit_delta(lift, m, d=DISCOUNT):
    return (P0 + lift) * R * (m - d) - P0 * R * m


def coupon_cost(lift, d=DISCOUNT):
    return (P0 + lift) * R * d


def breakeven_lift(m, d=DISCOUNT):
    return np.inf if m <= d else P0 * d / (m - d)


print(f"mean repeat order = {R:.2f}, baseline = {P0:.4f}, discount = {DISCOUNT:.0%}\n")

be = pd.DataFrame({"margin": MARGINS, "breakeven_lift": [breakeven_lift(m) for m in MARGINS]})
print(be.round(4).to_string(index=False))
print()

rows = []
for name, lift in SCENARIOS.items():
    for m in MARGINS:
        delta = profit_delta(lift, m) * AUDIENCE
        cost = coupon_cost(lift) * AUDIENCE
        rows.append(
            {
                "scenario": name,
                "lift": lift,
                "margin": m,
                "incremental_profit": round(delta),
                "coupon_cost": round(cost),
                "roi": round(delta / cost, 2),
            }
        )
print(pd.DataFrame(rows).to_string(index=False))

grid = pd.DataFrame(
    [[profit_delta(l, m) * AUDIENCE for l in LIFTS] for m in MARGINS],
    index=[f"{m:.0%}" for m in MARGINS],
    columns=[f"+{l * 100:.2f} п.п." for l in LIFTS],
)
fig = px.imshow(
    grid,
    text_auto=".0f",
    aspect="auto",
    color_continuous_scale="RdYlGn",
    color_continuous_midpoint=0,
    labels=dict(x="Uplift конверсии", y="Маржа", color="Δ прибыль, R$"),
    title="Прирост прибыли от купона 10% на аудиторию 21 279 клиентов",
)
fig.write_html("reports/figures/coupon_sensitivity.html")
fig.show()