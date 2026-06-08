# V3 Research Workflow

## Step 1: MATLAB stage extraction

The MATLAB model already provides stage velocities, parachute states, drag targets, dynamic pressure, and failure modes. V3 uses this as the coupling table.

## Step 2: CFD stage snapshots

OpenFOAM runs five fixed-shape 3D canopy cases:

1. Drogue reefed.
2. Drogue full.
3. Main reef stage 1.
4. Main reef stage 2.
5. Main full.

Each snapshot is a quasi-steady RANS solution at the velocity/density of that stage.

## Step 3: Cd extraction

For each stage:

Cd_CFD = Drag_CFD / (0.5*rho*U^2*Aref)

The extracted Cd is compared against the MATLAB Cd target. The output correction factor is:

Cd_correction = Cd_target / Cd_CFD

## Step 4: Model update

The correction factor can be used to rerun the MATLAB descent with CFD-informed Cd values.

## Step 5: Higher fidelity

After the V3 fixed-canopy workflow works:

- replace the solid canopy with porous/ribbon canopy,
- repeat with compressible solver at high Mach,
- add dynamic mesh for opening,
- later attempt FSI.
