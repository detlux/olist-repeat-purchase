import numpy as np
import pandas as pd

from db import get_engine
from stats import bootstrap_diff, ztest_two_props

SEED = 42
DISCOUNT = 0.10
LIFTS = [0.0, 0.005, 0.0075, 0.01]
engine = get_engine()
rng = np.random.default_rng(SEED)

baseline_q = """
WITH t AS (
    SELECT PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY revenue) AS thr FROM v_orders
),
first_order AS (
    SELECT DISTINCT ON (customer_unique_id) customer_unique_id, purchased_at, revenue
    FROM v_orders
    ORDER BY customer_unique_id, purchased_at
),
f AS (
    SELECT fo.customer_unique_id, fo.purchased_at
    FROM first_order fo, t
    WHERE fo.revenue >= t.thr
      AND fo.purchased_at <= TIMESTAMP '2018-09-01' - INTERVAL '90 days'
)
SELECT COUNT(*) AS n, COUNT(x.customer_unique_id) AS converted
FROM f
LEFT JOIN (
    SELECT DISTINCT f2.customer_unique_id
    FROM f f2
    JOIN v_orders o ON o.customer_unique_id = f2.customer_unique_id
    WHERE o.purchased_at > f2.purchased_at
      AND o.purchased_at <= f2.purchased_at + INTERVAL '90 days'
) x ON x.customer_unique_id = f.customer_unique_id
"""

repeat_q = """
SELECT o.revenue
FROM v_orders o
JOIN (
    SELECT customer_unique_id, MIN(purchased_at) AS first_at
    FROM v_orders
    GROUP BY 1
) f ON f.customer_unique_id = o.customer_unique_id
WHERE o.purchased_at > f.first_at
"""

audience_q = """
SELECT customer_unique_id, segment
FROM rfm
WHERE segment IN ('Promising high value', 'At risk high value')
"""

b = pd.read_sql(baseline_q, engine).iloc[0]
p0 = b["converted"] / b["n"]
repeat_rev = pd.read_sql(repeat_q, engine)["revenue"].astype(float).to_numpy()
df = pd.read_sql(audience_q, engine)

n = len(df)
df["group"] = rng.permutation(np.where(np.arange(n) < n // 2, "A", "B"))
mask_a = (df["group"] == "A").to_numpy()
mask_b = ~mask_a
n_a, n_b = mask_a.sum(), mask_b.sum()

print(f"baseline={p0:.4f} (n={int(b['n'])}), audience={n}, A={n_a}, B={n_b}")
print(f"median repeat order={np.median(repeat_rev):.2f}, discount={DISCOUNT:.0%}\n")


def simulate(lift):
    p = np.where(mask_b, p0 + lift, p0)
    conv = rng.random(n) < p
    rev = np.where(conv, rng.choice(repeat_rev, n), 0.0)
    rev = np.where(conv & mask_b, rev * (1 - DISCOUNT), rev)
    return conv, rev


def power(lift, n_sims=1000):
    xa = rng.binomial(n_a, p0, n_sims)
    xb = rng.binomial(n_b, p0 + lift, n_sims)
    pv = np.array([ztest_two_props(a, n_a, c, n_b)["p_value"] for a, c in zip(xa, xb)])
    return float(np.mean(pv < 0.05))


rows = []
for lift in LIFTS:
    conv, rev = simulate(lift)
    r = ztest_two_props(conv[mask_a].sum(), n_a, conv[mask_b].sum(), n_b)
    lo, hi = bootstrap_diff(conv[mask_a], conv[mask_b])
    rows.append(
        {
            "true_lift": lift,
            "conv_A": round(r["p_a"], 4),
            "conv_B": round(r["p_b"], 4),
            "diff": round(r["diff"], 4),
            "ci_z": f"[{r['ci_low']:.4f}, {r['ci_high']:.4f}]",
            "ci_boot": f"[{lo:.4f}, {hi:.4f}]",
            "p_value": round(r["p_value"], 4),
            "aov_A": round(rev[mask_a & conv].mean(), 2),
            "aov_B": round(rev[mask_b & conv].mean(), 2),
            "rev_per_cust_A": round(rev[mask_a].mean(), 3),
            "rev_per_cust_B": round(rev[mask_b].mean(), 3),
            "power": power(lift),
        }
    )

pd.set_option("display.width", 250)
pd.set_option("display.max_columns", None)
print(pd.DataFrame(rows).to_string(index=False))

df.to_csv("data/processed/ab_assignment.csv", index=False)