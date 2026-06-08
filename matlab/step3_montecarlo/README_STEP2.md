# Gaganyaan Step 2: MATLAB 2D Descent Simulation

## How to run

1. Extract this folder anywhere, for example:
   `D:\Downloads\gaganyaan_step2_descent2D`

2. In MATLAB Command Window:

```matlab
cd("D:\Downloads\gaganyaan_step2_descent2D")
main
```

3. Do not directly run function files like `ISA_atmosphere.m`, `drag_model.m`, or `descent_2D.m`.

## Main files

- `main.m` — run this only.
- `mission_parameters.m` — all assumed/public baseline values.
- `descent_2D.m` — ode45 vertical descent with altitude event switching.
- `plot_results_2D.m` — creates and saves the 9 Step 2 plots.
- `compare_main_chute_cases.m` — compares 3-main, 2-main, and 1-main cases.
- `ISA_atmosphere.m` — Step 1 atmosphere model.
- `drag_model.m` — Step 1 drag and reefing model.

## Output folder

After running, MATLAB creates:

`gaganyaan_step2_outputs`

It contains PNG figures and `step2_nominal_time_history.csv`.

## Notes

This is a public-data/assumed engineering baseline. Replace assumptions with supervisor-approved ADRDE/ISRO values only if they are permitted to share them.
