#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Independent reference implementation of the ABPM/CGM metric pipeline.
# Pure numpy re-derivation of the documented formulas (raw statistics +
# trapezoid areas with threshold crossings + day/night window pattern), used
# to cross-validate the R engine on multi-day data with many day/night
# alternations (14-day CGM sample and a synthetic 12-day 5-metric BP set).
#
# All file access goes through safe_open(): every name is joined onto a fixed
# base directory, normalized, and verified to stay inside that directory.
import json
import math
import os
import re
import subprocess
import sys

import numpy as np

BASE_DIR = os.path.abspath(os.path.dirname(os.path.abspath(__file__)))


def safe_open(name, mode, encoding="utf-8"):
    full = os.path.normpath(os.path.join(BASE_DIR, name))
    if not full.startswith(BASE_DIR + os.sep) and full != BASE_DIR:
        raise ValueError("path escapes the base directory: %r" % name)
    return open(full, mode, encoding=encoding)


DAY = 1440
D1S, N1S, D2C, N2C = 7 * 60, 22 * 60, 7 * 60, 22 * 60  # 07:00 / 22:00 both days


def parse_time(tstr):
    m = re.match(r"(\d{2})(\d{2})\+(\d+)D", tstr.strip())
    if not m:
        raise ValueError("bad time: %r" % tstr)
    return int(m.group(3)) * DAY + int(m.group(1)) * 60 + int(m.group(2))


def minute_to_time(t):
    d, c = divmod(int(t), DAY)
    return "%02d%02d+%dD" % (c // 60, c % 60, d)


def classify(t):
    k, c = divmod(int(t), DAY)
    ds = D1S if k == 0 else D2C
    ns = N1S if k == 0 else N2C
    return "day" if ds <= c < ns else "night"


def boundary_clocks(ws, we):
    pts = set()
    for k in range(int(ws) // DAY - 1, int(we) // DAY + 2):
        base = k * DAY
        ds = D1S if k == 0 else D2C
        ns = N1S if k == 0 else N2C
        for p in (base + ds, base + ns):
            if ws <= p <= we:
                pts.add(p)
    return pts


def raw_stats(values, upper):
    v = [float(x) for x in values if math.isfinite(x)]
    n = len(v)
    out = dict(max=math.nan, min=math.nan, delta=math.nan, mean=math.nan,
               sd=math.nan, cv=math.nan, arv=math.nan, load=math.nan,
               n_over=0, n_total=n)
    if n == 0:
        if upper is not None and math.isfinite(upper):
            out["load"] = math.nan  # 0/0 -> NaN in R
        return out
    mx, mn = max(v), min(v)
    mean = sum(v) / n
    sd = math.sqrt(sum((x - mean) ** 2 for x in v) / (n - 1)) if n > 1 else 0.0
    cv = sd / abs(mean) * 100 if abs(mean) > 1e-9 else math.nan
    arv = sum(abs(v[i + 1] - v[i]) for i in range(n - 1)) / (n - 1) if n > 1 else math.nan
    out.update(max=mx, min=mn, delta=mx - mn, mean=mean, sd=sd, cv=cv, arv=arv)
    if upper is not None and math.isfinite(upper):
        n_over = sum(1 for x in v if x > upper)
        out["load"] = n_over / n * 100
        out["n_over"] = n_over
    return out


def seg_contrib(t1, y1, t2, y2, upper, lower):
    dx = t2 - t1
    out = dict(Sd=0.0, Sa=0.0, Sc=0.0, Ts1=0.0, Ts2=0.0, Ts3=0.0)
    if dx <= 1e-9:
        return out
    out["Sd"] = 0.5 * (y1 + y2) * dx
    has_u = upper is not None and math.isfinite(upper)
    has_l = lower is not None and math.isfinite(lower)

    def region(y):
        if has_u and y > upper:
            return "above"
        if has_l and y < lower:
            return "below"
        return "between"

    r1, r2 = region(y1), region(y2)
    if r1 == r2:
        if r1 == "above" and has_u:
            out["Sa"] += 0.5 * ((y1 - upper) + (y2 - upper)) * dx
            out["Ts1"] += dx
        elif r1 == "below" and has_l:
            out["Sc"] += 0.5 * ((lower - y1) + (lower - y2)) * dx
            out["Ts3"] += dx
        else:
            out["Ts2"] += dx
        return out
    pts = [(t1, y1)]
    crosses = []
    denom = y2 - y1
    if has_u and abs(denom) > 1e-10 and (y1 - upper) * (y2 - upper) < 0:
        crosses.append((t1 + dx * (upper - y1) / denom, upper))
    if has_l and abs(denom) > 1e-10 and (y1 - lower) * (y2 - lower) < 0:
        crosses.append((t1 + dx * (lower - y1) / denom, lower))
    for tc, yc in sorted(crosses):
        if t1 <= tc <= t2:
            pts.append((tc, yc))
    pts.append((t2, y2))
    pts = sorted(pts, key=lambda p: p[0])
    seen = set()
    dedup = []
    for p in pts:
        key = round(p[0], 6)
        if key not in seen:
            seen.add(key)
            dedup.append(p)
    for j in range(len(dedup) - 1):
        p1, p2 = dedup[j], dedup[j + 1]
        sdt = p2[0] - p1[0]
        if sdt <= 1e-9:
            continue
        mid = (p1[1] + p2[1]) / 2
        sr = region(mid)
        if sr == "above" and has_u:
            out["Sa"] += 0.5 * ((p1[1] - upper) + (p2[1] - upper)) * sdt
            out["Ts1"] += sdt
        elif sr == "below" and has_l:
            out["Sc"] += 0.5 * ((lower - p1[1]) + (lower - p2[1])) * sdt
            out["Ts3"] += sdt
        else:
            out["Ts2"] += sdt
    return out


def interp_value(x, xs, ys, rule):
    if len(xs) == 1:
        return ys[0] if x == xs[0] else (ys[0] if rule == 2 else math.nan)
    if x < xs[0]:
        return ys[0] if rule == 2 else math.nan
    if x > xs[-1]:
        return ys[-1] if rule == 2 else math.nan
    if x in xs:
        return ys[xs.index(x)]
    i = np.searchsorted(xs, x)
    x0, x1 = xs[i - 1], xs[i]
    y0, y1 = ys[i - 1], ys[i]
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0)


def edge_fill(t, xs, ys, rule="linear"):
    if t in xs:
        return ys[xs.index(t)]
    if rule == "none":
        return math.nan
    below = [xs[i] for i in range(len(xs)) if xs[i] <= t]
    above = [xs[i] for i in range(len(xs)) if xs[i] >= t]
    if not below and not above:
        return math.nan
    if not below:
        return ys[xs.index(above[0])]
    if not above:
        return ys[xs.index(below[-1])]
    b, a = below[-1], above[0]
    if rule == "nearest":
        return ys[xs.index(b)] if (t - b) <= (a - t) else ys[xs.index(a)]
    yb, ya = ys[xs.index(b)], ys[xs.index(a)]
    return yb + (ya - yb) * (t - b) / (a - b)


def build_axis(full_t, full_v, win_obs, ws, we, interp, calendar, edge="linear"):
    # Axis POINTS are window-restricted (endpoints + in-window observations +
    # in-window day/night boundaries); VALUES are linearly interpolated over
    # the FULL observation set (R's approx uses the whole source as x), and
    # endpoint fills for user-specified windows also use the full set.
    pts = sorted(set([ws, we]) | set(win_obs) | boundary_clocks(ws, we))
    rule = 2 if interp == "full" else 1
    vals = [interp_value(p, full_t, full_v, rule) for p in pts]
    if not calendar and interp == "valid":
        for pos in (0, len(pts) - 1):
            vals[pos] = edge_fill(pts[pos], full_t, full_v, edge)
    t = [pts[i] for i in range(len(pts)) if math.isfinite(vals[i])]
    v = [vals[i] for i in range(len(pts)) if math.isfinite(vals[i])]
    return t, v


def period_area(axis_t, axis_v, period, upper, lower):
    has_u = upper is not None and math.isfinite(upper)
    has_l = lower is not None and math.isfinite(lower)
    if period == "all":  # the 24h period spans the whole window
        idx = list(range(len(axis_t)))
    else:
        idx = [i for i, t in enumerate(axis_t) if classify(t) == period]
    empty = dict(Sa=(0.0 if has_u else math.nan), Sc=(0.0 if has_l else math.nan),
                 Sd=0.0, AUC=0.0, Ts1=0.0, Ts2=0.0, Ts3=0.0)
    if not idx:
        return empty
    acc = dict(Sa=0.0, Sc=0.0, Sd=0.0, Ts1=0.0, Ts2=0.0, Ts3=0.0)
    runs = []
    start = idx[0]
    for a, b in zip(idx[:-1], idx[1:]):
        if b - a > 1:
            runs.append((start, a))
            start = b
    runs.append((start, idx[-1]))
    for s, e in runs:
        pos = list(range(s, e + 1))
        nxt = pos[-1] + 1
        if nxt < len(axis_t):
            pos.append(nxt)
        for a, b in zip(pos[:-1], pos[1:]):
            c = seg_contrib(axis_t[a], axis_v[a], axis_t[b], axis_v[b], upper, lower)
            for k in acc:
                acc[k] += c[k]
    if not has_u:
        acc["Sa"] = math.nan
    if not has_l:
        acc["Sc"] = math.nan
    acc["AUC"] = acc["Sd"]
    return acc


def ratios(area, upper, lower):
    sd, ts1, ts2, ts3 = area["Sd"], area["Ts1"], area["Ts2"], area["Ts3"]
    nan = math.nan
    out = dict(Se=nan, Sf=nan, hyper=nan, hypo=nan, cum=nan, TTR=nan, TOTR=nan, TUTR=nan)
    has_u = upper is not None and math.isfinite(upper)
    has_l = lower is not None and math.isfinite(lower)
    if not all(math.isfinite(x) for x in (sd, ts1, ts2, ts3)):
        return out
    out["Se"] = ts1 * upper if has_u else nan
    out["Sf"] = ts3 * lower if has_l else nan
    total = ts1 + ts2 + ts3
    if total > 1e-9:
        out["TTR"] = ts2 / total * 100
        out["TOTR"] = ts1 / total * 100
        out["TUTR"] = ts3 / total * 100
    else:
        out["TTR"] = out["TOTR"] = out["TUTR"] = 0.0
    if has_u and math.isfinite(area["Sa"]) and math.isfinite(out["Se"]) and math.isfinite(ts1):
        denom = area["Sa"] + out["Se"]
        if total > 1e-9 and abs(denom) > 1e-9:
            out["hyper"] = (area["Sa"] / denom) * (ts1 / total) * 100
        elif total > 1e-9 and abs(denom) <= 1e-9 and abs(area["Sa"]) < 1e-9:
            out["hyper"] = 0.0
        elif total <= 1e-9:
            out["hyper"] = 0.0
    if has_l and math.isfinite(area["Sc"]) and math.isfinite(out["Sf"]) and math.isfinite(ts3):
        if total > 1e-9 and abs(out["Sf"]) > 1e-9:
            out["hypo"] = (area["Sc"] / out["Sf"]) * (ts3 / total) * 100
        elif total > 1e-9 and abs(out["Sf"]) <= 1e-9 and abs(area["Sc"]) < 1e-9:
            out["hypo"] = 0.0
        elif total <= 1e-9:
            out["hypo"] = 0.0
    if math.isfinite(area["Sa"]) and math.isfinite(sd):
        if abs(sd) > 1e-9:
            out["cum"] = area["Sa"] / sd * 100
        elif abs(area["Sa"]) < 1e-9:
            out["cum"] = 0.0
    return out


def vim_fixed(mean, sd, ref=100.0):
    if math.isfinite(mean) and mean > 0 and math.isfinite(sd) and sd > 0:
        return sd / (mean ** 1) * ref
    return math.nan


def run_case(data_key, times, values, metric, ws, we, interp, calendar,
             day_lim, night_lim, h24_lim, edge="linear"):
    """Reference results for one (data, mode, interp, metric) case."""
    results = {}
    obs_t_all = sorted(set(times))
    obs_v_all = [float(np.mean([v for t0, v in zip(times, values) if t0 == x]))
                 for x in obs_t_all]
    in_win = [(t, v) for t, v in zip(obs_t_all, obs_v_all) if ws <= t <= we]
    obs_t = [t for t, v in in_win]
    raw_in = sorted(((t, v) for t, v in zip(times, values) if ws <= t <= we),
                    key=lambda p: p[0])
    if not raw_in:
        return results
    axis_t, axis_v = build_axis(obs_t_all, obs_v_all, obs_t, ws, we, interp,
                                calendar, edge)
    for period, lim in (("day", day_lim), ("night", night_lim), ("24h", h24_lim)):
        if period == "24h":
            area = period_area(axis_t, axis_v, "all", lim[1], lim[0])
            r = raw_stats([v for t, v in raw_in], lim[1])
        else:
            area = period_area(axis_t, axis_v, period, lim[1], lim[0])
            r = raw_stats([v for t, v in raw_in if classify(t) == period], lim[1])
        out = dict(max_value=r["max"], min_value=r["min"], Delta=r["delta"],
                   mean=r["mean"], SD=r["sd"], CV=r["cv"], ARV=r["arv"],
                   VIM=vim_fixed(r["mean"], r["sd"]),
                   Sa=area["Sa"], Sc=area["Sc"], AUC=area["AUC"],
                   Ts1_total=area["Ts1"], Ts2_total=area["Ts2"], Ts3_total=area["Ts3"],
                   Load=r["load"])
        if lim[0] is None and lim[1] is None:
            # without-limits path (PP/MAP): threshold fields stay NA
            for k in ("Ts1_total", "Ts2_total", "Ts3_total", "Load",
                      "TTR", "TOTR", "TUTR", "hyper_Burden", "hypo_Burden",
                      "cumulative_Load", "Se", "Sf", "Sa", "Sc"):
                out[k] = math.nan
        else:
            rat = ratios(area, lim[1], lim[0])
            out.update(TTR=rat["TTR"], TOTR=rat["TOTR"], TUTR=rat["TUTR"],
                       hyper_Burden=rat["hyper"], hypo_Burden=rat["hypo"],
                       cumulative_Load=rat["cum"], Se=rat["Se"], Sf=rat["Sf"])
        results[(data_key, metric, period)] = out
    # segmented: day areas with day limits + night areas with night limits
    seg = {k: math.nan for k in (
        "max_value", "min_value", "Delta", "mean", "SD", "CV", "ARV", "VIM",
        "Sa", "Sc", "AUC", "Ts1_total", "Ts2_total", "Ts3_total", "Load",
        "cumulative_Load", "TTR", "TOTR", "TUTR", "hyper_Burden", "hypo_Burden",
        "Se", "Sf")}
    if day_lim[0] is None or night_lim[0] is None:
        # PP/MAP -> without-limits 24h
        r24 = raw_stats([v for t, v in raw_in], None)
        seg.update(max_value=r24["max"], min_value=r24["min"], Delta=r24["delta"],
                   mean=r24["mean"], SD=r24["sd"], CV=r24["cv"], ARV=r24["arv"],
                   VIM=vim_fixed(r24["mean"], r24["sd"]))
        seg["AUC"] = period_area(axis_t, axis_v, "all", None, None)["AUC"]
    else:
        da = period_area(axis_t, axis_v, "day", day_lim[1], day_lim[0])
        na = period_area(axis_t, axis_v, "night", night_lim[1], night_lim[0])
        r_day = raw_stats([v for t, v in raw_in if classify(t) == "day"], day_lim[1])
        r_night = raw_stats([v for t, v in raw_in if classify(t) == "night"], night_lim[1])
        r_full = raw_stats([v for t, v in raw_in], None)

        def s_aware(a, b):
            return a + b if (math.isfinite(a) and math.isfinite(b)) else math.nan

        def s_zero(a, b):
            return (a if math.isfinite(a) else 0.0) + (b if math.isfinite(b) else 0.0)

        Sa = s_aware(da["Sa"], na["Sa"])
        Sc = s_aware(da["Sc"], na["Sc"])
        Sd = s_zero(da["Sd"], na["Sd"])
        Ts1 = s_zero(da["Ts1"], na["Ts1"])
        Ts2 = s_zero(da["Ts2"], na["Ts2"])
        Ts3 = s_zero(da["Ts3"], na["Ts3"])
        total = Ts1 + Ts2 + Ts3
        Se = s_aware(da["Ts1"] * day_lim[1], na["Ts1"] * night_lim[1])
        Sf = s_aware(da["Ts3"] * day_lim[0], na["Ts3"] * night_lim[0])
        ttr = Ts2 / total * 100 if total > 1e-9 else 0.0
        totr = Ts1 / total * 100 if total > 1e-9 else 0.0
        tutr = Ts3 / total * 100 if total > 1e-9 else 0.0
        hyper = math.nan
        if math.isfinite(Sa) and math.isfinite(Se):
            denom = Sa + Se
            if total <= 1e-9:
                hyper = 0.0
            elif abs(denom) > 1e-9:
                hyper = (Sa / denom) * (Ts1 / total) * 100
            else:
                hyper = 0.0
        hypo = math.nan
        if math.isfinite(Sc) and math.isfinite(Sf):
            if total <= 1e-9:
                hypo = 0.0
            elif abs(Sf) > 1e-9:
                hypo = (Sc / Sf) * (Ts3 / total) * 100
            else:
                hypo = 0.0
        cum = math.nan
        if math.isfinite(Sa) and math.isfinite(Sd):
            if abs(Sd) > 1e-9:
                cum = Sa / Sd * 100
            elif abs(Sa) < 1e-9:
                cum = 0.0
        n_over = s_zero(r_day["n_over"], r_night["n_over"])
        n_total = s_zero(r_day["n_total"], r_night["n_total"])
        raw_load = n_over / n_total * 100 if n_total > 0 else math.nan
        seg.update(max_value=r_full["max"], min_value=r_full["min"],
                   Delta=r_full["delta"], mean=r_full["mean"], SD=r_full["sd"],
                   CV=r_full["cv"], ARV=r_full["arv"],
                   VIM=vim_fixed(r_full["mean"], r_full["sd"]),
                   Sa=Sa, Sc=Sc, AUC=Sd, Ts1_total=Ts1, Ts2_total=Ts2, Ts3_total=Ts3,
                   Load=raw_load, cumulative_Load=cum, TTR=ttr, TOTR=totr,
                   TUTR=tutr, hyper_Burden=hyper, hypo_Burden=hypo, Se=Se, Sf=Sf)
    results[(data_key, metric, "segmented")] = seg
    return results


def gen_bp_synthetic():
    rng = np.random.default_rng(42)
    t = np.arange(540, 12 * DAY + 540, 15)  # 12 days, 09:00 start
    is_day = np.array([classify(x) == "day" for x in t], dtype=float)
    shift = np.where(is_day == 1, 4.0, -4.0)
    phase = 2 * np.pi * t / DAY
    sbp = 122 + 9 * np.sin(phase + 1.0) + shift + rng.normal(0, 3, len(t))
    dbp = 74 + 6 * np.sin(phase + 2.0) + shift * 0.5 + rng.normal(0, 2.5, len(t))
    hr = 85 + 13 * np.sin(phase + 0.5) + shift + rng.normal(0, 3, len(t))
    pp = sbp - dbp + rng.normal(0, 1.5, len(t))
    mp = dbp + pp / 3 + rng.normal(0, 1.5, len(t))
    rows = []
    for i, ti in enumerate(t):
        rows.append(("M1", minute_to_time(ti), round(sbp[i], 1), round(dbp[i], 1),
                     round(hr[i], 1), round(pp[i], 1), round(mp[i], 1)))
    for i in (17, 500, 777):  # duplicate timestamps (source averaging path)
        rows.append(rows[i])
    with safe_open("xcheck_bp_synth.csv", "w") as f:
        f.write("MASKID,Time,SBP,DBP,HR,PP,MAP\n")
        for r in rows:
            f.write(",".join(str(x) for x in r) + "\n")
    return rows


def load_csv(name):
    rows = []
    with safe_open(name, "r") as f:
        header = f.readline().strip().split(",")
        for line in f:
            p = line.rstrip("\n").split(",")
            rows.append((p[0], parse_time(p[1]), [float(x) for x in p[2:]]))
    return header, rows


def main():
    bp_rows = gen_bp_synthetic()
    times = [parse_time(r[1]) for r in bp_rows]  # integer minutes
    vals = {m: [r[2 + i] for r in bp_rows]
            for i, m in enumerate(["SBP", "DBP", "HR", "PP", "MAP"])}

    with safe_open("ABPM_calculator_integrated.R", "r") as f:
        src = f.read()
    m = re.search(r'GLUCOSE_SAMPLE_CSV <- "(.*?)"', src, re.S)
    glu_body = m.group(1).replace('\\"', '"').split("\n")
    glu_rows = []
    for line in glu_body[1:]:
        p = line.split(",")
        glu_rows.append((p[0], parse_time(p[1]), [float(p[2])]))
    g_times = [r[1] for r in glu_rows]
    g_vals = {"GLU": [r[2][0] for r in glu_rows]}

    bp_limits = {
        "SBP": dict(day=(90.0, 120.0), night=(90.0, 110.0), h24=(90.0, 115.0)),
        "DBP": dict(day=(55.0, 70.0), night=(55.0, 60.0), h24=(55.0, 65.0)),
        "HR": dict(day=(60.0, 100.0), night=(50.0, 90.0), h24=(55.0, 95.0)),
        "PP": dict(day=(None, None), night=(None, None), h24=(None, None)),
        "MAP": dict(day=(None, None), night=(None, None), h24=(None, None)),
    }
    glu_limits = {"GLU": dict(day=(3.9, 10.0), night=(3.9, 10.0), h24=(3.9, 10.0))}

    ref = {}
    dmin = min(times)
    dmax = max(times)

    def add(data_key, metric, ws, we, interp, calendar, lims, key_mode, edge="linear"):
        for (_, mk, period), out in run_case(
                data_key, times if data_key == "bp" else g_times,
                vals[metric] if data_key == "bp" else g_vals[metric],
                metric, ws, we, interp, calendar,
                lims["day"], lims["night"], lims["h24"], edge).items():
            key = "%s|%s|%s|%s" % (data_key, mk, period, key_mode)
            ref[key] = out

    for metric, lims in bp_limits.items():
        add("bp", metric, 0, 3 * DAY, "valid", True, lims, "cal_valid")
        add("bp", metric, 0, 3 * DAY, "full", True, lims, "cal_full")
        # mode 2: from_first + 48h
        add("bp", metric, dmin, min(dmin + 48 * 60, dmax), "valid", False, lims, "win_valid")
        # mode 4: custom start+end (mid-day window on days 3-4)
        add("bp", metric, 3 * DAY + 540, 4 * DAY + 540, "valid", False, lims, "win2_valid")
        # mode 3: from_start 1300+2D + 24h
        add("bp", metric, 2 * DAY + 780, min(2 * DAY + 780 + 1440, dmax),
            "valid", False, lims, "win3_valid")
        # custom full cycle starting at night (2200+4D .. 2200+5D)
        add("bp", metric, 4 * DAY + 1320, 5 * DAY + 1320, "valid", False, lims, "win4_valid")
        # mode 2: from_first + 24h
        add("bp", metric, dmin, dmin + 1440, "valid", False, lims, "win5_valid")
        # endpoint interpolation: window endpoints have no exact reading
        add("bp", metric, 2 * DAY + 100, 2 * DAY + 100 + 1440, "valid", False,
            lims, "win6_valid", edge="nearest")
        add("bp", metric, 2 * DAY + 100, 2 * DAY + 100 + 1440, "valid", False,
            lims, "win7_valid", edge="none")
    gdmin = min(g_times)
    gdmax = max(g_times)
    for metric, lims in glu_limits.items():
        add("glu", metric, 0, 16 * DAY, "valid", True, lims, "cal_valid")
        add("glu", metric, 0, 16 * DAY, "full", True, lims, "cal_full")
        add("glu", metric, gdmin, min(gdmin + 72 * 60, gdmax), "valid", False, lims, "win_valid")
        add("glu", metric, 4 * DAY + 22 * 60, 6 * DAY + 22 * 60, "valid", False, lims, "win2_valid")

    with safe_open("xcheck_py.json", "w") as f:
        json.dump(ref, f, allow_nan=True)
    print("reference cases:", len(ref))
    return 0


if __name__ == "__main__":
    sys.exit(main())
