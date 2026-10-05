import sys
from pathlib import Path

import pandas as pd

from db import get_engine

pd.set_option("display.width", 200)
pd.set_option("display.max_columns", None)


def main(path):
    sql = Path(path).read_text(encoding="utf-8")
    engine = get_engine()
    for stmt in filter(None, (s.strip() for s in sql.split(";"))):
        print(pd.read_sql(stmt, engine).to_string(index=False))
        print()


if __name__ == "__main__":
    main(sys.argv[1])