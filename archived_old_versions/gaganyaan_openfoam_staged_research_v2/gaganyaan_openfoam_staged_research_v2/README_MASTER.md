# Gaganyaan OpenFOAM staged parachute CFD research pack v2

This pack upgrades the first single-Cd validation case into a staged, MATLAB-coupled OpenFOAM workflow.

## What this pack does

It runs multiple quasi-steady CFD snapshots representing the major parachute opening states:

1. Drogue reefed opening: 30% area, 190 m/s, 10 km
2. Drogue full open: 100% area, 120 m/s, 8 km
3. Main first reef: 20% area, 70 m/s, 2.5 km
4. Main second reef: 60% area, 40 m/s, 1.5 km
5. Main full open: 100% area, 20 m/s, 1.0 km

Each case changes effective diameter, reference area, air density, viscosity, velocity, Mach number, and force coefficient settings. This gives stage-wise airflow/wake/Cd behaviour instead of only one static parachute state.

## What this still is not

This is not full cloth FSI and not a certified parachute-inflation solver. It is a research-level staged RANS validation workflow. Full inflation would require dynamic mesh/FSI/porosity/fabric structural coupling.

## Run all cases

Copy/extract this folder into your OpenFOAM run folder, then:

```bash
cd $FOAM_RUN/gaganyaan_openfoam_staged_research_v2
chmod +x Allrun_all_stages
./Allrun_all_stages
```

## Run only one case

```bash
cd $FOAM_RUN/gaganyaan_openfoam_staged_research_v2/cases/01_drogue_reefed
chmod +x Allrun
./Allrun
paraFoam
```

## ParaView viewing

Open each case with `paraFoam`, press Apply, then use:

- `U` for velocity magnitude and wake visualization.
- `p` for pressure field.
- Slice filter to see internal 2D field.
- Stream Tracer for wake/recirculation.

## Output

Each case writes:

```text
postProcessing_stage/stage_cd_summary.csv
```

All cases combined are written to:

```text
postProcessing_summary/all_stage_cd_summary.csv
```

## Research interpretation

Use the CFD Cd outputs to compare against the MATLAB reduced-order Cd values. If Cd_CFD is within ±10–15% of the MATLAB Cd assumption, the reduced-order model is consistent for early design. If not, update MATLAB Cd and rerun descent/Monte Carlo.
