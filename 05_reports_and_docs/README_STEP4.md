# Gaganyaan Step 4 — MATLAB 3D Descent Extension

Run:

```matlab
cd("D:\Downloads\gaganyaan_step4_3D")
main_step4
```

This step adds:
- 3D wind-drift trajectory
- parachute-capsule pendulum oscillation
- asymmetric main disreefing: one main delayed by 0.5 s
- riser tension comparison for 3 mains
- failure cases: 3 mains, 2 of 3 mains, 1 of 3 mains
- simplified canopy snapshot visualization

Output folder:

```text
gaganyaan_step4_outputs
```

Important modelling note: this is an engineering trajectory model, not full FSI.
Vertical motion is taken from the validated Step 2/3 1-DOF solver. Lateral drift
is modelled as wind-following dynamics, and tilt is a pendulum proxy driven by
riser tension imbalance. Replace assumptions with ADRDE/ISRO-provided values
when available.
