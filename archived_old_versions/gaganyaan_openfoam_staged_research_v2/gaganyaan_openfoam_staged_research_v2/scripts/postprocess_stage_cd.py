#!/usr/bin/env python3
import os, sys, csv, glob, math
case_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
meta = {}
with open(os.path.join(case_dir,'case_metadata.csv'), newline='') as f:
    for row in csv.DictReader(f):
        meta[row['parameter']] = row['value']
# find coefficient.dat
files = glob.glob(os.path.join(case_dir,'postProcessing','forceCoeffs_canopy','*','coefficient.dat'))
cd_last = float('nan')
cl_last = float('nan')
if files:
    latest = sorted(files, key=lambda p: float(os.path.basename(os.path.dirname(p))) if os.path.basename(os.path.dirname(p)).replace('.','',1).isdigit() else -1)[-1]
    last = None
    with open(latest) as f:
        for line in f:
            if line.strip() and not line.lstrip().startswith('#'):
                parts = line.split()
                last = parts
    if last and len(last) >= 3:
        # OpenFOAM forceCoeffs columns vary; usually Time Cd Cs Cl CmRoll CmPitch CmYaw Cd(f) Cd(r) Cs(f) Cs(r) Cl(f) Cl(r)
        cd_last = float(last[1])
        if len(last) > 3:
            cl_last = float(last[3])
# compute target drag
rho = float(meta.get('rhoInf', 'nan'))
U = float(meta.get('inlet_velocity', 'nan'))
A = float(meta.get('Aref_effective', 'nan'))
qty = float(meta.get('quantity', '1'))
cd_target = float(meta.get('Cd_MATLAB_target','nan'))
q = 0.5*rho*U*U
drag_per_chute_target = cd_target*q*A
drag_total_target = qty*drag_per_chute_target
if math.isnan(cd_last):
    drag_per_chute_cfd = float('nan')
    drag_total_cfd = float('nan')
    err = float('nan')
else:
    drag_per_chute_cfd = cd_last*q*A
    drag_total_cfd = qty*drag_per_chute_cfd
    err = 100*(cd_last-cd_target)/cd_target
out_dir = os.path.join(case_dir,'postProcessing_stage')
os.makedirs(out_dir, exist_ok=True)
out = os.path.join(out_dir,'stage_cd_summary.csv')
fields = ['case','stage_name','altitude_m','velocity_mps','mach','rho_kg_m3','quantity','effective_diameter_m','effective_area_m2','dynamic_pressure_Pa','Cd_CFD','Cd_MATLAB_target','Cd_error_percent','drag_per_chute_CFD_N','total_drag_CFD_N','total_drag_MATLAB_target_N']
with open(out,'w',newline='') as f:
    w=csv.DictWriter(f, fieldnames=fields); w.writeheader()
    w.writerow({
        'case': os.path.basename(case_dir),
        'stage_name': meta.get('stage_name',''),
        'altitude_m': meta.get('altitude',''),
        'velocity_mps': U,
        'mach': meta.get('mach',''),
        'rho_kg_m3': rho,
        'quantity': qty,
        'effective_diameter_m': meta.get('effective_diameter',''),
        'effective_area_m2': A,
        'dynamic_pressure_Pa': q,
        'Cd_CFD': cd_last,
        'Cd_MATLAB_target': cd_target,
        'Cd_error_percent': err,
        'drag_per_chute_CFD_N': drag_per_chute_cfd,
        'total_drag_CFD_N': drag_total_cfd,
        'total_drag_MATLAB_target_N': drag_total_target,
    })
print('=== Stage Cd post-process ===')
print('Case:', os.path.basename(case_dir))
print('Stage:', meta.get('stage_name',''))
print('Cd_CFD last:', cd_last)
print('Cd_MATLAB target:', cd_target)
print('Cd error %:', err)
print('Total drag CFD N:', drag_total_cfd)
print('Total drag MATLAB target N:', drag_total_target)
print('Saved:', out)
