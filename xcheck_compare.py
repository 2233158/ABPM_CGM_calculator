#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Compare the R engine output (xcheck_r.json) against the independent Python
# reference (xcheck_py.json) field by field.
import json
import math
import os
import sys

BASE_DIR = os.path.abspath(os.path.dirname(os.path.abspath(__file__)))


def safe_open(name, mode):
    full = os.path.normpath(os.path.join(BASE_DIR, name))
    if not full.startswith(BASE_DIR + os.sep) and full != BASE_DIR:
        raise ValueError("path escapes the base directory: %r" % name)
    return open(full, mode, encoding="utf-8")


def norm(x):
    if isinstance(x, dict):
        return {k: norm(v) for k, v in x.items()}
    if isinstance(x, list):
        return [norm(v) for v in x]
    if x is None or (isinstance(x, float) and math.isnan(x)):
        return float("nan")
    return x


def close(a, b):
    fa = float("nan") if a is None else float(a)
    fb = float("nan") if b is None else float(b)
    if math.isnan(fa) and math.isnan(fb):
        return True
    if math.isnan(fa) or math.isnan(fb):
        return False
    return abs(fa - fb) <= 1e-6 + 1e-6 * max(abs(fa), abs(fb))


def main():
    with safe_open("xcheck_py.json", "r") as f:
        py = json.load(f)
    with safe_open("xcheck_r.json", "r") as f:
        r = json.load(f)
    keys_py = set(py.keys())
    keys_r = set(r.keys())
    missing_in_r = keys_py - keys_r
    missing_in_py = keys_r - keys_py
    if missing_in_r:
        print("MISSING in R:", sorted(missing_in_r))
    if missing_in_py:
        print("EXTRA in R:", sorted(missing_in_py))
    n_pass = n_fail = 0
    fails = []
    for key in sorted(keys_py & keys_r):
        for field in sorted(set(py[key]) & set(r[key])):
            if close(py[key][field], r[key][field]):
                n_pass += 1
            else:
                n_fail += 1
                fails.append((key, field, py[key][field], r[key][field]))
    print("fields compared: %d, pass: %d, fail: %d" % (n_pass + n_fail, n_pass, n_fail))
    for key, field, pv, rv in fails[:60]:
        print("  FAIL %-46s %-14s py=%s r=%s" % (key, field, pv, rv))
    # per-domain summary
    for dom in ("bp", "glu"):
        dpass = sum(1 for k, f, pv, rv in fails if k.startswith(dom))
        print("domain %s: failures=%d" % (dom, dpass))
    if n_fail == 0 and not missing_in_r and not missing_in_py:
        print("XCHECK RESULT: ALL FIELDS MATCH")
        return 0
    print("XCHECK RESULT: MISMATCHES FOUND")
    return 1


if __name__ == "__main__":
    sys.exit(main())
