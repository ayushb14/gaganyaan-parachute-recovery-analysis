#!/usr/bin/env python3
"""
Post-process OpenFOAM fixed-geometry balloon filling case.
Reads latest OpenFOAM time folder, extracts p and U, and estimates:
- physical pressure variation from incompressible kinematic pressure p
- balloon membrane stress sigma = DeltaP*r/(2*t)
- strain estimate epsilon = (r-r0)/r0
- safety factor against tensile strength

Run from inside the OpenFOAM case folder after foamRun completes:
    python3 post_process_balloon_stress.py
"""
from __future__ import annotations
import os
import re
import csv
import math
from pathlib import Path

# ---------------- user-editable rough values ----------------
rho_air = 1.225                 # kg/m^3, used to convert kinematic p to physical Pa
balloon_radius_m = 0.15         # m, assumed inflated balloon radius
initial_radius_m = 0.05         # m, assumed uninflated/reference radius
wall_thickness_m = 0.0003       # m, 0.30 mm
latex_tensile_strength_Pa = 20e6 # Pa, rough allowable tensile strength
ambient_pressure_Pa = 101325.0  # Pa
# ------------------------------------------------------------

number_re = re.compile(r"[-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][-+]?\d+)?")

def numeric_time_dirs(case_dir: Path):
    dirs = []
    for item in case_dir.iterdir():
        if item.is_dir():
            try:
                value = float(item.name)
                dirs.append((value, item))
            except ValueError:
                pass
    return [p for _, p in sorted(dirs, key=lambda x: x[0])]

def strip_boundary_field(text: str) -> str:
    idx = text.find("boundaryField")
    return text[:idx] if idx >= 0 else text

def parse_scalar_field(path: Path):
    text = strip_boundary_field(path.read_text(errors="ignore"))
    # Uniform field case
    m = re.search(r"internalField\s+uniform\s+([-+]?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][-+]?\d+)?)\s*;", text)
    if m:
        return [float(m.group(1))]
    # Nonuniform case: values are usually in parentheses after internalField
    if "internalField" in text:
        text = text[text.find("internalField"):]
    nums = [float(x) for x in number_re.findall(text)]
    # Remove dimensions/header accidental numbers by keeping list after first '(' if possible
    paren = text.find("(")
    if paren >= 0:
        nums = [float(x) for x in number_re.findall(text[paren:])]
    return nums

def parse_vector_field_magnitudes(path: Path):
    text = strip_boundary_field(path.read_text(errors="ignore"))
    m = re.search(r"internalField\s+uniform\s*\(([^)]*)\)\s*;", text)
    if m:
        comps = [float(x) for x in number_re.findall(m.group(1))[:3]]
        return [math.sqrt(sum(c*c for c in comps))]
    if "internalField" in text:
        text = text[text.find("internalField"):]
    # Extract vector triples like (Ux Uy Uz)
    triples = re.findall(r"\(([-+0-9eE\.]+)\s+([-+0-9eE\.]+)\s+([-+0-9eE\.]+)\)", text)
    mags = []
    for tri in triples:
        try:
            comps = [float(x) for x in tri]
            mags.append(math.sqrt(sum(c*c for c in comps)))
        except ValueError:
            pass
    return mags

def percentile(data, pct):
    values = sorted(data)
    if not values:
        return float('nan')
    if len(values) == 1:
        return values[0]
    pos = (pct/100.0)*(len(values)-1)
    lo = math.floor(pos)
    hi = math.ceil(pos)
    if lo == hi:
        return values[int(pos)]
    w = pos - lo
    return values[lo]*(1-w) + values[hi]*w

def main():
    case_dir = Path.cwd()
    times = numeric_time_dirs(case_dir)
    if not times:
        raise SystemExit("No numeric OpenFOAM time folders found. Run blockMesh and foamRun first.")
    latest = times[-1]
    p_path = latest / "p"
    u_path = latest / "U"
    if not p_path.exists():
        raise SystemExit(f"Could not find p field in latest time folder: {latest}")
    p_kin = parse_scalar_field(p_path)
    p_kin = [x for x in p_kin if math.isfinite(x)]
    if not p_kin:
        raise SystemExit("Could not parse pressure field values.")
    p_min = min(p_kin)
    p_max = max(p_kin)
    p_mean = sum(p_kin)/len(p_kin)
    p05 = percentile(p_kin, 5)
    p95 = percentile(p_kin, 95)

    # In incompressible solvers, p is kinematic pressure [m2/s2]. Physical pressure = rho*p.
    deltaP_max_Pa = rho_air * max(abs(p_max-p_min), abs(p95-p05))
    deltaP_robust_Pa = rho_air * abs(p95-p05)
    p_mean_gauge_Pa = rho_air * p_mean

    sigma_max_Pa = deltaP_max_Pa * balloon_radius_m / (2.0*wall_thickness_m)
    sigma_robust_Pa = deltaP_robust_Pa * balloon_radius_m / (2.0*wall_thickness_m)
    safety_factor_max = latex_tensile_strength_Pa / sigma_max_Pa if sigma_max_Pa > 0 else float('inf')
    safety_factor_robust = latex_tensile_strength_Pa / sigma_robust_Pa if sigma_robust_Pa > 0 else float('inf')
    strain = (balloon_radius_m - initial_radius_m)/initial_radius_m

    u_max = float('nan')
    u_mean = float('nan')
    if u_path.exists():
        mags = parse_vector_field_magnitudes(u_path)
        mags = [x for x in mags if math.isfinite(x)]
        if mags:
            u_max = max(mags)
            u_mean = sum(mags)/len(mags)

    out_dir = case_dir / "postProcessing_balloon"
    out_dir.mkdir(exist_ok=True)
    csv_path = out_dir / "balloon_stress_summary.csv"
    rows = [
        ["latest_time", latest.name, "s"],
        ["p_kinematic_min", p_min, "m2/s2"],
        ["p_kinematic_mean", p_mean, "m2/s2"],
        ["p_kinematic_max", p_max, "m2/s2"],
        ["p_kinematic_p05", p05, "m2/s2"],
        ["p_kinematic_p95", p95, "m2/s2"],
        ["mean_gauge_pressure_estimate", p_mean_gauge_Pa, "Pa"],
        ["deltaP_robust_p95_minus_p05", deltaP_robust_Pa, "Pa"],
        ["deltaP_max_range", deltaP_max_Pa, "Pa"],
        ["max_velocity", u_max, "m/s"],
        ["mean_velocity", u_mean, "m/s"],
        ["balloon_radius", balloon_radius_m, "m"],
        ["initial_radius", initial_radius_m, "m"],
        ["wall_thickness", wall_thickness_m, "m"],
        ["strain", strain, "-"],
        ["strain_percent", 100*strain, "%"],
        ["sigma_robust", sigma_robust_Pa, "Pa"],
        ["sigma_robust", sigma_robust_Pa/1e6, "MPa"],
        ["sigma_max", sigma_max_Pa, "Pa"],
        ["sigma_max", sigma_max_Pa/1e6, "MPa"],
        ["tensile_strength_assumed", latex_tensile_strength_Pa/1e6, "MPa"],
        ["safety_factor_robust", safety_factor_robust, "-"],
        ["safety_factor_max", safety_factor_max, "-"],
    ]
    with csv_path.open("w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["quantity", "value", "unit"])
        writer.writerows(rows)

    print("\n============================================")
    print(" BALLOON FILLING POST-PROCESS SUMMARY")
    print("============================================")
    print(f"Latest OpenFOAM time folder:      {latest.name}")
    print(f"Max velocity magnitude:           {u_max: .3f} m/s")
    print(f"Mean kinematic pressure p:        {p_mean: .3f} m2/s2")
    print(f"Pressure range estimate:          {deltaP_max_Pa/1000: .3f} kPa")
    print(f"Robust pressure range p95-p05:    {deltaP_robust_Pa/1000: .3f} kPa")
    print(f"Balloon radius assumed:           {balloon_radius_m: .3f} m")
    print(f"Wall thickness assumed:           {wall_thickness_m*1000: .3f} mm")
    print(f"Strain estimate:                  {100*strain: .1f} %")
    print(f"Membrane stress robust:           {sigma_robust_Pa/1e6: .3f} MPa")
    print(f"Membrane stress max-range:        {sigma_max_Pa/1e6: .3f} MPa")
    print(f"Assumed tensile strength:         {latex_tensile_strength_Pa/1e6: .1f} MPa")
    print(f"Safety factor robust:             {safety_factor_robust: .2f}")
    print(f"Safety factor max-range:          {safety_factor_max: .2f}")
    print(f"CSV saved to:                     {csv_path}")
    print("============================================\n")

if __name__ == "__main__":
    main()
