# balloonFillSteady_v2 — cylinder to balloon fixed-geometry OpenFOAM case

This is Level 1/2 starter model for: compressed cylinder/neck -> balloon chamber.

## Run

From Ubuntu/WSL:

```bash
cd $FOAM_RUN
cp -r /mnt/d/Downloads/balloonFillSteady_v2 .
cd balloonFillSteady_v2
blockMesh
checkMesh
foamRun -solver incompressibleFluid | tee log.foamRun
python3 post_process_balloon_stress.py
paraFoam
```

Or simply:

```bash
./run_balloon_v2.sh
```

## Post-processing

The Python script reads the latest OpenFOAM time folder and estimates:

- max velocity
- kinematic pressure range
- physical pressure range using rho = 1.225 kg/m3
- membrane stress using sigma = DeltaP*r/(2t)
- strain using epsilon = (r-r0)/r0
- safety factor using tensile strength = 20 MPa

Output CSV:

```text
postProcessing_balloon/balloon_stress_summary.csv
```

## Important note

In OpenFOAM incompressible solvers, `p` is kinematic pressure [m2/s2], not directly Pa. The script converts it using physical pressure = rho * p.
