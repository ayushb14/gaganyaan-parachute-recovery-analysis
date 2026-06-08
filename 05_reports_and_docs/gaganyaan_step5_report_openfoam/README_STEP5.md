# Step 5 — Final Validation, Report Assembly, and OpenFOAM Transition

This package is the bridge between the MATLAB simulation phase and the OpenFOAM CFD phase.

## Current MATLAB status

- Step 1: ISA atmosphere and aerodynamic drag model completed.
- Step 2: 2D parachute descent with staged deployment completed.
- Step 3: 1000-run Monte Carlo uncertainty analysis completed.
- Step 4: 3D trajectory, wind drift, pendulum response, asymmetric disreefing, and main-chute failure cases completed.

## What to do now

1. Run `collect_step_outputs.m` from MATLAB after editing the paths at the top of the file.
2. Use `01_final_research_report_draft.md` as the written report draft.
3. Use `02_validation_matrix.csv` to explain which outputs validate which model assumptions.
4. Use `03_openfoam_phase2_plan.md` before starting CFD.
5. Use `openfoam_drogue_case_skeleton/` as a starting structure for the first CFD case.

## Important note

The MATLAB model is a reduced-order engineering simulation. It is suitable for trajectory, loads, uncertainty, and early design studies. It does not replace certified mission software, wind tunnel testing, hardware drop tests, or fluid-structure-interaction parachute qualification.
