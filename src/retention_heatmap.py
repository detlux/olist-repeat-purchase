import pandas as pd
import plotly.express as px

from db import get_engine

q = open("sql/05_cohorts.sql", encoding="utf-8").read().split(";")[0]
df = pd.read_sql(q, get_engine())
pivot = df[df.month_n.between(1, 6)].pivot(index="cohort", columns="month_n", values="retention_pct")
fig = px.imshow(
    pivot,
    text_auto=".2f",
    aspect="auto",
    color_continuous_scale="Blues",
    labels=dict(x="Месяц после первой покупки", y="Когорта", color="Retention, %"),
    title="Когортный retention (месяцы 1-6)",
)
fig.write_html("reports/figures/retention_heatmap.html")
fig.show()