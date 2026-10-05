import sys
from pathlib import Path

import pandas as pd
from sqlalchemy import text

from db import get_engine

pd.set_option("display.width", 200)
pd.set_option("display.max_columns", None)


def main(path):
    sql = Path(path).read_text(encoding="utf-8")
    with get_engine().begin() as conn:
        for stmt in filter(None, (s.strip() for s in sql.split(";"))):
            res = conn.execute(text(stmt))
            if res.returns_rows:
                print(pd.DataFrame(res.fetchall(), columns=res.keys()).to_string(index=False))
                print()


if __name__ == "__main__":
    main(sys.argv[1])