# MATLAB–OpenFOAM Validation Notes

This project couples MATLAB reduced-order descent simulation with OpenFOAM CFD stage-wise canopy drag estimation.

## Validation approach

1. MATLAB provides altitude, velocity, parachute state and target Cd values.
2. OpenFOAM generates 3D canopy flow-field solutions for each staged condition.
3. forceCoeffs is used to extract stage-wise drag coefficient.
4. CFD Cd is compared with MATLAB target Cd.
5. The coupled profile is used to evaluate stage-wise agreement and discrepancy.

## Key result

Main parachute stages showed closer agreement with MATLAB targets than drogue stages. Drogue deviations are attributed to simplified solid-canopy geometry and missing porosity/ribbon modelling.
