#!/usr/bin/env python3
import os, glob, csv
root = os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
rows=[]
for file in sorted(glob.glob(os.path.join(root,'cases','*','postProcessing_stage','stage_cd_summary.csv'))):
    with open(file,newline='') as f:
        rows.extend(list(csv.DictReader(f)))
outdir=os.path.join(root,'postProcessing_summary')
os.makedirs(outdir,exist_ok=True)
out=os.path.join(outdir,'all_stage_cd_summary.csv')
if rows:
    with open(out,'w',newline='') as f:
        w=csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print('Collected',len(rows),'stage results')
print('Saved:',out)
