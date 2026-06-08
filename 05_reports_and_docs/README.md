# Coupled MATLAB–OpenFOAM Simulation of Staged Parachute Deployment for a Gaganyaan-Type Crew Module Descent

This repository contains a coupled MATLAB and OpenFOAM workflow for staged parachute descent analysis. The work includes MATLAB-based descent modelling, Monte Carlo uncertainty analysis, 3D trajectory/visualization outputs, OpenFOAM CFD cases, stage-wise drag coefficient extraction, and MATLAB–OpenFOAM validation outputs.

## Repository structure

- `matlab/` — MATLAB simulation stages and Monte Carlo analysis
- `openfoam/` — OpenFOAM cases, scripts, post-processing and coupled outputs
- `results/` — CSV outputs, figures, validation plots, and report tables
- `docs/` — final report and methodology notes
- `validation/` — validation notes and comparison discussion
- `archived_old_versions/` — older/practice versions retained for reference

## Key outputs

- Stage-wise drag coefficient comparison
- MATLAB–OpenFOAM coupled stage profile
- Monte Carlo uncertainty plots
- OpenFOAM pressure, velocity, streamline, and canopy geometry figures
