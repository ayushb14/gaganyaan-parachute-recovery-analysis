#!/usr/bin/env python3
import os, csv, glob, math
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
CONDS = ROOT/'stage_conditions'/'stage_conditions.csv'
OUTDIR = ROOT/'postProcessing_summary'
OUTDIR.mkdir(exist_ok=True)

def parse_force_file(case_dir):
    files = sorted(glob.glob(str(case_dir/'postProcessing'/'forceCoeffs_canopy'/'*'/'forceCoeffs.dat')) +
                   glob.glob(str(case_dir/'postProcessing'/'forceCoeffs_canopy'/'*'/'coefficient.dat')))
    if not files:
        return None, None
    # Choose the force file containing the most numeric rows
    best=None; best_count=-1; best_header=None; best_last=None
    for fp in files:
        header=None; last=None; count=0
        with open(fp) as f:
            for line in f:
                s=line.strip()
                if not s: continue
                if s.startswith('#'):
                    if 'Time' in s:
                        header=s.replace('#','').split()
                    continue
                parts=s.split()
                try:
                    vals=[float(x) for x in parts]
                    count += 1
                    last=vals
                except Exception:
                    pass
        if count > best_count and last is not None:
            best=fp; best_count=count; best_header=header; best_last=last
    if best_last is None:
        return files[-1], None
    if best_header and 'Cd' in best_header:
        cd_idx=best_header.index('Cd')
    else:
        # OpenFOAM forceCoeffs common: Time Cm Cd Cl Cl(f) Cl(r)
        cd_idx=2
    if cd_idx >= len(best_last):
        cd_idx=2
    return best, best_last[cd_idx]

rows=[]
with open(CONDS) as f:
    for row in csv.DictReader(f):
        case_dir = ROOT/'cases'/row['case']
        fp, cd = parse_force_file(case_dir)
        U=float(row['U']); rho=float(row['rho']); Aref=float(row['Aref']); q=float(row['q'])
        qty=float(row['quantity']); cd_target=float(row['cd_target'])
        if cd is None or math.isnan(cd):
            drag_per=float('nan'); total=float('nan'); err=float('nan'); corr=float('nan')
        else:
            drag_per=cd*q*Aref
            total=drag_per*qty
            err=(cd-cd_target)/cd_target*100.0
            corr=cd_target/cd if abs(cd)>1e-12 else float('nan')
        target_total=cd_target*q*Aref*qty
        rows.append({
            'case':row['case'], 'stage':row['stage'], 'velocity_mps':U, 'altitude_m':float(row['altitude']),
            'rho_kg_m3':rho, 'q_Pa':q, 'D_eff_m':float(row['D_eff']), 'Aref_m2':Aref, 'quantity':qty,
            'Cd_CFD':cd, 'Cd_target_MATLAB':cd_target, 'Cd_error_percent':err, 'Cd_correction_factor_target_over_CFD':corr,
            'drag_per_chute_CFD_N':drag_per, 'total_drag_CFD_N':total, 'total_drag_target_N':target_total,
            'force_file': fp or ''
        })

out = OUTDIR/'all_stage_cd_summary.csv'
with open(out,'w',newline='') as f:
    fieldnames=list(rows[0].keys()) if rows else []
    w=csv.DictWriter(f,fieldnames=fieldnames); w.writeheader(); w.writerows(rows)
print('\n================ OPENFOAM V3 CD SUMMARY ================')
for r in rows:
    print(f"{r['case']}: Cd_CFD={r['Cd_CFD']} target={r['Cd_target_MATLAB']} error%={r['Cd_error_percent']}")
print('Saved:', out)
