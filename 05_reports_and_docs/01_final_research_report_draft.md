# Numerical Simulation and Uncertainty Analysis of a Multi-Stage Parachute Recovery System for a Gaganyaan-Type Crew Module

## Abstract

This project develops a MATLAB-based reduced-order simulation framework for a Gaganyaan-type crew module parachute recovery system. The model simulates staged descent from high-altitude parachute initiation to sea-level touchdown using an ISA atmosphere model, altitude-varying gravity, capsule drag, drogue parachute deceleration, main parachute reefing, Monte Carlo uncertainty analysis, and simplified 3D wind-drift dynamics. The final simulation includes nominal three-main parachute operation, two-main redundancy, one-main failure, asymmetric disreefing, pendulum oscillation, lateral drift, riser tension estimation, and 3D animation.

## 1. Background

The Gaganyaan crew module recovery sequence uses a multi-parachute architecture with apex cover separation parachutes, drogue parachutes, pilot parachutes, and main parachutes. Public ISRO releases describe a 10-parachute sequence with two apex cover separation parachutes, two drogues, three pilots, and three main parachutes. The main parachutes are deployed in a reefed inflation process to control opening shock and reduce the crew module speed to a safe touchdown range. Public sources also describe redundancy, where two of the three main parachutes are sufficient for safe landing.

## 2. Objective

The objective of this project is to create a research-level engineering simulation that can:

1. Reconstruct the parachute descent sequence using public and assumed parameters.
2. Estimate descent time, velocity history, dynamic pressure, drag loads, and g-loads.
3. Study sensitivity to mass, Cd, atmospheric density, and deployment altitude uncertainty.
4. Compare nominal and failure-mode recovery cases.
5. Prepare a foundation for OpenFOAM CFD analysis of inflated parachute drag and wake structure.

## 3. Model Assumptions

The simulation uses SI units throughout. The crew module/payload mass is assumed as 6500 kg for the full-mission research case. The capsule drag coefficient is assumed as 0.70. Drogue parachutes are modeled using two 5.8 m chutes with a nominal Cd of 0.55. Main parachutes are modeled using three 25 m parachutes with a nominal Cd of 0.87. Cd uncertainty is modeled as ±10%.

The simulation starts at 15.3 km altitude with an initial downward velocity of 276 m/s. Drogue deployment is triggered near 10 km altitude, and main deployment near 2.5 km altitude. The parachute inflation model uses reefed area growth rather than instantaneous full opening to avoid unrealistically high impulse loads.

## 4. Governing Equations

The vertical descent equation is:

```text
m * dv/dt = m * g(h) - D_total
```

where downward velocity is positive, and total drag is:

```text
D_total = 0.5 * rho(h) * v^2 * sum(Cd_i * A_i)
```

The dynamic pressure is:

```text
q = 0.5 * rho(h) * v^2
```

Altitude-varying gravity is:

```text
g(h) = g0 * (R_earth / (R_earth + h))^2
```

The reefing model uses a time-dependent effective area:

```text
A_effective(t) = A_reefed + (A_full - A_reefed) * (1 - exp(-t/tau_fill))
```

## 5. MATLAB Simulation Architecture

The MATLAB code is modular and contains the following major components:

- `ISA_atmosphere.m`: atmosphere properties, density, temperature, pressure, speed of sound, viscosity, and gravity.
- `drag_model.m`: capsule, drogue, and main parachute drag calculation.
- `descent_2D.m`: staged vertical descent using event-based deployment logic.
- `monte_carlo.m`: uncertainty propagation for Cd, mass, deployment altitude, and atmospheric density.
- `descent_3D.m`: 3D wind drift, pendulum oscillation, and failure-mode analysis.
- `plot_results_2D.m`, `plot_monte_carlo_results.m`, `plot_results_3D.m`: publication-style result figures.
- `animate_3D_descent.m`: simplified 3D animation of capsule-parachute descent.

## 6. Results

### Nominal 3-main configuration

- Touchdown velocity: 8.99 m/s
- Total descent time: 362.66 s
- Peak drogue deceleration: 3.19 g
- Peak main deceleration: 2.70 g
- Maximum dynamic pressure: 11.75 kPa
- Drogue deployment time: 20.02 s
- Main deployment time: 111.79 s

### Monte Carlo uncertainty result

A 1000-run Monte Carlo analysis was performed using ±10% Cd variation, ±50 kg mass variation, ±200 m deployment-altitude jitter, and ±3% density perturbation.

- Touchdown velocity mean: 9.01 m/s
- Touchdown velocity 95% CI: 8.56 to 9.50 m/s
- Total descent time mean: 362.32 s
- Total descent time 95% CI: 339.49 to 387.18 s
- Peak deceleration mean: 3.20 g
- Peak deceleration 95% CI: 2.91 to 3.55 g

### 3D wind drift and failure modes

Using a 5 m/s crosswind profile and simplified pendulum dynamics:

- Nominal lateral drift: 785.12 m
- Nominal maximum pendulum angle: 5.00 deg
- Asymmetric 0.5 s main delay maximum tilt proxy: 9.71 deg
- Two-main touchdown velocity: 11.00 m/s
- One-main touchdown velocity: 15.50 m/s

## 7. Discussion

The nominal three-main parachute case produces a touchdown velocity of approximately 9 m/s, which is consistent with the intended low-speed water landing regime. The two-main case increases touchdown speed to approximately 11 m/s, showing the expected performance degradation under redundancy operation. The one-main case produces approximately 15.5 m/s and excessive swing/tilt proxy, indicating that it should be treated as a severe failure mode.

The Monte Carlo envelope shows that the descent remains controlled under realistic parametric uncertainty. The 95% touchdown velocity confidence interval remains within a narrow band, indicating that Cd and atmosphere variations affect descent time more strongly than final landing speed when all three main parachutes function.

The 3D wind drift model shows that lateral drift can be significant even for modest crosswind. This supports the need for recovery-zone planning and wind-profile measurement during actual drop tests.

## 8. Limitations

This is a reduced-order simulation. The following effects are simplified:

- Full canopy fluid-structure interaction.
- Fabric porosity and transient canopy breathing.
- Wake recontact and capsule-parachute aerodynamic interference.
- Actual riser/line elasticity.
- Real sea-state touchdown and flotation dynamics.
- Certified mission-specific ADRDE/ISRO parameters that are not public.

## 9. OpenFOAM Transition

The next step is CFD validation of parachute drag coefficients. The first OpenFOAM case should model the drogue parachute at approximately 190 m/s using a simplified inflated canopy geometry. A steady-state incompressible/transonic-approximate case may be used for first drag extraction, but a compressible solver is better if Mach number approaches transonic values. The main objective is to extract Cd and compare it against the reduced-order MATLAB model.

## 10. Conclusion

The MATLAB simulation successfully models the multi-stage parachute recovery sequence of a Gaganyaan-type crew module. It includes staged deployment, reefing, uncertainty propagation, redundancy analysis, asymmetric disreefing, wind drift, pendulum response, and 3D visualization. The nominal case achieves a touchdown velocity of approximately 9 m/s with peak deceleration near 3.2 g, while the Monte Carlo results show robust performance under reasonable uncertainty. The model is now ready to be extended toward OpenFOAM-based CFD validation.

## References

1. T. W. Knacke, Parachute Recovery Systems Design Manual, NWC TP 6575, 1991.
2. USAF, Parachute Design Manual, AFFDL-TR-78-151, 1978.
3. ISRO public releases on Gaganyaan parachute system, IADT, IMAT, and TV-D1.
4. DRDO public releases and newsletters on Gaganyaan drogue parachute testing at RTRS/TBRL.
