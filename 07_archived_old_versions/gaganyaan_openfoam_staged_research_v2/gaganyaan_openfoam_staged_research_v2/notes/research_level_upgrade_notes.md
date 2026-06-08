# Research-level upgrade notes

The previous v1 pack was a single fixed projected-canopy validation case. This v2 pack introduces a staged quasi-transient CFD sequence driven by the MATLAB descent model.

## Why quasi-steady snapshots?

A parachute inflation problem includes fabric motion, reefing-line cuts, porosity, canopy breathing, wake recontact, riser elasticity, and unsteady FSI. A true model requires dynamic mesh and structural coupling. This v2 workflow is the correct next step before FSI because it answers:

- how the wake changes from reefed to full-open geometry,
- how Cd differs between drogue and main stages,
- how dynamic pressure reduces as velocity falls,
- whether MATLAB Cd values are aerodynamically reasonable,
- where mesh/wake refinement is needed before snappyHexMesh and compressible simulations.

## Next v3 direction

- replace projected 2D canopy with curved STL inflated canopy,
- run snappyHexMesh,
- repeat coarse/medium/fine mesh independence,
- change solver from incompressibleFluid to compressible solver for Mach > 0.3 cases,
- add porous jump / Darcy-Forchheimer model for parachute cloth.
