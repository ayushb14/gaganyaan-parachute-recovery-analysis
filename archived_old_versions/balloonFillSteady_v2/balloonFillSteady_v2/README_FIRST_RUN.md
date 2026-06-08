# balloonFillSteady_v1 — OpenFOAM starter case

## Purpose
This is the first simplified OpenFOAM case for the scientist's task:

**Air flow from a pressurised cylinder through a narrow neck into a balloon-like chamber.**

This first version is a fixed-geometry, steady, incompressible flow validation case. It is not yet a real flexible balloon inflation FSI case. The goal is to confirm OpenFOAM workflow, mesh, velocity field, and pressure drop through the neck. After this works, it can be upgraded to transient compressible filling and moving-wall balloon deformation.

## Geometry used
- 2D case with one-cell thickness in z-direction.
- Left plenum represents cylinder/reservoir side.
- Middle constriction represents narrow pipe/nozzle/balloon neck.
- Right large chamber represents balloon volume.

Approximate dimensions:
- Left plenum length: 50 mm
- Neck length: 50 mm
- Neck height: 5 mm in this 2D planar case
- Balloon chamber length: 300 mm
- Balloon chamber height: 300 mm
- z-thickness: 5 mm

## Rough physical values
- Air kinematic viscosity: 1.5e-5 m2/s
- Inlet velocity for first CFD validation: 20 m/s
- Later pressure-driven case target: 1.5 bar absolute cylinder pressure
- Ambient pressure: 101325 Pa
- Balloon radius for stress estimate: 0.15 m
- Balloon wall thickness: 0.30 mm
- Rough tensile strength: 20 MPa

## How to run in Ubuntu / WSL
Copy the zip into your OpenFOAM run folder, then run:

```bash
cd $FOAM_RUN
unzip balloonFillSteady_v1.zip
cd balloonFillSteady_v1
blockMesh
checkMesh
foamRun -solver incompressibleFluid | tee log.foamRun
paraFoam
```

In ParaView:
1. Click Apply.
2. Change coloring to U or p.
3. Use Filters -> Glyph for velocity arrows, or Filters -> Stream Tracer for streamlines.
4. View the neck region for acceleration and pressure drop.

## If `foamRun -solver incompressibleFluid` does not work
Try:

```bash
foamRun -solver incompressibleFluid -case . | tee log.foamRun
```

If the solver complains about dictionaries, send the terminal screenshot.

## What to show to scientist initially
- Mesh of cylinder-neck-balloon chamber.
- Velocity contours through neck.
- Pressure field in chamber.
- Statement: fixed-geometry flow model completed; next step is transient compressible filling with pressure decay and balloon stress-strain coupling.

## MATLAB post-processing
A small stress/strain estimate is included in:

```text
matlab_post/balloon_stress_strain_estimate.m
```

It computes approximate balloon membrane stress using:

sigma = DeltaP * r / (2*t)

and strain using:

strain = (r - r0)/r0
```
