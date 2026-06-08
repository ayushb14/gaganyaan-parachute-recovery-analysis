# Gaganyaan OpenFOAM V3 — 3D Canopy CFD Research Pack

This pack is the next step after the MATLAB descent simulation. It converts the MATLAB stage conditions into fixed-shape 3D OpenFOAM RANS snapshots for parachute drag/wake validation.

## Why V3 exists

The earlier 2D/projected test case ran successfully but produced a low drag coefficient for the reefed drogue (`Cd_CFD ≈ 0.214` versus target `Cd = 0.55`). That is useful as a proof-of-workflow, but it is not a final parachute CFD model. V3 replaces that with parametric 3D bluff/domed canopy geometry and snappyHexMesh-based cases.

## Stage cases

| Case | Stage | U (m/s) | Altitude (m) | Effective D (m) | Cd target | Qty |
|---|---|---:|---:|---:|---:|---:|
| `01_drogue_reefed_3D` | Drogue reefed opening | 190.0 | 10000 | 3.177 | 0.55 | 2 |
| `02_drogue_full_3D` | Drogue full open | 120.0 | 8000 | 5.800 | 0.55 | 2 |
| `03_main_reef1_3D` | Main reef stage 1 | 70.0 | 2500 | 11.180 | 0.87 | 3 |
| `04_main_reef2_3D` | Main reef stage 2 | 40.0 | 1500 | 19.365 | 0.87 | 3 |
| `05_main_full_3D` | Main full open | 20.0 | 1000 | 25.000 | 0.87 | 3 |


## Run one case first

```bash
cd $FOAM_RUN
rm -rf gaganyaan_openfoam_v3_3d_canopy_research
cp -r /mnt/d/Downloads/gaganyaan_openfoam_v3_3d_canopy_research .
cd gaganyaan_openfoam_v3_3d_canopy_research/cases/01_drogue_reefed_3D
chmod +x Allrun
./Allrun
paraFoam
```

In ParaView: Apply → Time = final → Color by `U` or `p` → use Slice/Stream Tracer.

## Run all stages

```bash
cd $FOAM_RUN/gaganyaan_openfoam_v3_3d_canopy_research
chmod +x Allrun_all_cases
./Allrun_all_cases
cat postProcessing_summary/all_stage_cd_summary.csv
```

## Outputs

- Each case: `postProcessing/forceCoeffs_canopy/.../forceCoeffs.dat`
- Summary: `postProcessing_summary/all_stage_cd_summary.csv`
- Coupled MATLAB/OpenFOAM profile: `coupled_outputs/matlab_openfoam_coupled_stage_profile.csv`

## Research interpretation

This is still fixed-geometry CFD, not full FSI. It is appropriate for:

1. Stage-wise airflow/wake visualization.
2. CFD extraction of Cd for reefed/full canopy states.
3. Comparison with MATLAB Cd targets.
4. Generating correction factors for the reduced-order descent model.

Next research upgrades:

1. Mesh independence study.
2. Compressible solver at the 190 m/s drogue condition.
3. Porosity / pressure-jump baffle modelling for ribbon/fabric behavior.
4. Transient dynamic mesh / FSI canopy inflation.
