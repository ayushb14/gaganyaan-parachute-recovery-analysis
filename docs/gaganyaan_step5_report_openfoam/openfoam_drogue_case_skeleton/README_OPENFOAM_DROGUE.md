# OpenFOAM Drogue Parachute Case Skeleton

This is not a fully runnable OpenFOAM case yet because the canopy STL geometry is still missing. Use this structure as the first CFD case template.

## Required next action

1. Create or obtain a simplified inflated drogue canopy STL.
2. Save it here:

```text
constant/triSurface/drogue_canopy.stl
```

3. Then prepare:

```text
blockMeshDict
snappyHexMeshDict
controlDict
fvSchemes
fvSolution
forceCoeffs configuration
```

## Target condition

- Drogue diameter: 5.8 m
- Inlet velocity: 190 m/s
- Reference area: 26.42 m^2
- Expected Cd: around 0.55 ± 10% for the reduced-order MATLAB baseline
