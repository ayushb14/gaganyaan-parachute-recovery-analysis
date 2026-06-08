# Phase 2 — OpenFOAM CFD Plan for Parachute Drag Validation

## Goal

Use OpenFOAM to estimate the drag coefficient of simplified inflated drogue and main parachute canopies, then compare CFD Cd against the MATLAB reduced-order model.

## First CFD case: drogue parachute

Recommended first case:

- Geometry: simplified axisymmetric inflated drogue canopy.
- Diameter: 5.8 m.
- Inlet velocity: 190 m/s.
- Altitude condition: around 10 km atmosphere.
- Flow regime: high-subsonic, Mach around 0.6 depending on local speed of sound.
- Primary output: drag force and Cd.

## Solver choice

For first learning case:

- `simpleFoam` if treating flow as incompressible and using low-risk setup.
- `rhoSimpleFoam` or compressible steady solver if Mach effects are considered important.

Because 190 m/s at about 10 km gives Mach around 0.6, compressibility may not be negligible. Start with `simpleFoam` for workflow learning, then repeat with a compressible solver.

## Turbulence model

Recommended:

- Start: k-omega SST for separated wake around bluff canopy.
- Alternative: realizable k-epsilon for robust initial convergence.

## Domain sizing

For drogue diameter D = 5.8 m:

- Upstream length: 8D to 10D.
- Downstream length: 20D to 30D.
- Radial/far-field clearance: 10D.

## Boundary conditions

For simplified steady case:

- Inlet: fixed velocity, turbulence quantities specified.
- Outlet: fixed pressure / zero-gradient velocity.
- Far field: slip or freestream.
- Canopy wall: no-slip wall for solid ideal canopy.

## Mesh strategy

1. Start with a basic blockMesh background domain.
2. Import canopy STL into `constant/triSurface/`.
3. Use snappyHexMesh for surface refinement.
4. Add wake refinement downstream of canopy.
5. Use boundary layers only after the first stable solution.

## Cd extraction

OpenFOAM drag coefficient relation:

```text
Cd = Drag / (0.5 * rho * U^2 * A_ref)
```

where:

```text
A_ref = pi * D^2 / 4
```

For drogue D = 5.8 m:

```text
A_ref = 26.42 m^2
```

Compare CFD Cd against MATLAB Cd = 0.55 ± 10%.

## Validation workflow

1. Run coarse mesh and confirm stable residuals.
2. Extract drag force and Cd.
3. Refine mesh and repeat.
4. Plot Cd versus cell count for mesh independence.
5. Compare final Cd with the MATLAB assumed Cd.
6. Repeat for main parachute D = 25 m after the drogue case works.

## What not to do initially

- Do not start with full flexible FSI.
- Do not start with porous fabric model.
- Do not model all 10 parachutes at once.
- Do not try full re-entry-to-landing CFD.

Start with one fixed inflated canopy and validate Cd.
