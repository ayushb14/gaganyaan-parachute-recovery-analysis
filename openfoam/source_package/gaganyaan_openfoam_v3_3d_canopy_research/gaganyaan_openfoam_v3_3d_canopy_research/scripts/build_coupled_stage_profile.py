#!/usr/bin/env python3
"""Build a MATLAB/OpenFOAM coupled stage summary.
If CFD Cd is available, it uses it. Otherwise it uses MATLAB target Cd.
"""
import csv, os, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
conds=ROOT/'stage_conditions'/'stage_conditions.csv'
cdfile=ROOT/'postProcessing_summary'/'all_stage_cd_summary.csv'
outdir=ROOT/'coupled_outputs'; outdir.mkdir(exist_ok=True)
cd_by_case={}
if cdfile.exists():
    with open(cdfile) as f:
        for r in csv.DictReader(f):
            try: cd_by_case[r['case']]=float(r['Cd_CFD'])
            except: pass
rows=[]
with open(conds) as f:
    for r in csv.DictReader(f):
        cd=float(r['cd_target'])
        if r['case'] in cd_by_case and not math.isnan(cd_by_case[r['case']]): cd=cd_by_case[r['case']]
        q=float(r['q']); A=float(r['Aref']); qty=float(r['quantity'])
        total=cd*q*A*qty
        rows.append({**r, 'Cd_used':cd, 'total_drag_used_N':total, 'source':'CFD' if r['case'] in cd_by_case else 'MATLAB_target'})
with open(outdir/'matlab_openfoam_coupled_stage_profile.csv','w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print('Saved:', outdir/'matlab_openfoam_coupled_stage_profile.csv')
