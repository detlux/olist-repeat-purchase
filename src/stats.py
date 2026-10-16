import numpy as np
from scipy.stats import norm
from statsmodels.stats.power import NormalIndPower
from statsmodels.stats.proportion import proportion_confint, proportions_ztest, proportion_effectsize


def sample_size_per_group(p0, mde_abs, alpha=0.05, power=0.8):
    es = proportion_effectsize(p0 + mde_abs, p0)
    return int(np.ceil(NormalIndPower().solve_power(es, alpha=alpha, power=power, ratio=1.0)))


def mde_for_n(p0, n_per_group, alpha=0.05, power=0.8):
    es = NormalIndPower().solve_power(nobs1=n_per_group, alpha=alpha, power=power, ratio=1.0)
    lo, hi = 0.0, 1.0 - p0
    for _ in range(60):
        mid = (lo + hi) / 2
        if proportion_effectsize(p0 + mid, p0) < es:
            lo = mid
        else:
            hi = mid
    return hi


def ztest_two_props(x_a, n_a, x_b, n_b):
    stat, p = proportions_ztest([x_b, x_a], [n_b, n_a], alternative="two-sided")
    p_a, p_b = x_a / n_a, x_b / n_b
    se = np.sqrt(p_a * (1 - p_a) / n_a + p_b * (1 - p_b) / n_b)
    z = norm.ppf(0.975)
    diff = p_b - p_a
    return {"p_a": p_a, "p_b": p_b, "diff": diff, "ci_low": diff - z * se, "ci_high": diff + z * se, "z": stat, "p_value": p}


def bootstrap_diff(a, b, n_boot=5000, seed=42):
    rng = np.random.default_rng(seed)
    a, b = np.asarray(a), np.asarray(b)
    diffs = [
        rng.choice(b, len(b)).mean() - rng.choice(a, len(a)).mean()
        for _ in range(n_boot)
    ]
    return np.percentile(diffs, [2.5, 97.5])