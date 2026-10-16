import pandas as pd

from db import get_engine
from stats import mde_for_n, sample_size_per_group

BASELINE = 0.0201

q = """
SELECT segment, COUNT(*) AS customers
FROM rfm
GROUP BY segment
"""
sizes = pd.read_sql(q, get_engine()).set_index("segment")["customers"]

targets = {
    "Promising high value": sizes["Promising high value"],
    "Promising + At risk high value": sizes["Promising high value"] + sizes["At risk high value"],
}
for name, n in targets.items():
    per_group = n // 2
    print(f"{name}: n={n}, per_group={per_group}, MDE={mde_for_n(BASELINE, per_group):.4f}")

print()
for mde in (0.005, 0.0075, 0.01, 0.015, 0.02):
    print(f"MDE +{mde:.4f}: n per group = {sample_size_per_group(BASELINE, mde)}")
