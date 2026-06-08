# Step 3 — Monte Carlo Uncertainty Analysis

Run only `main_step3.m`.

Default uncertainty model:

- Cd for capsule/drogue/main: uniform ±10%
- Mass: 6500 ± 50 kg
- Drogue and main deployment altitude jitter: ±200 m
- Atmosphere density scale: ±3%
- Number of runs: 1000

Outputs are saved in `gaganyaan_step3_outputs`:

- `11_monte_carlo_velocity_altitude_95ci.png`
- `12_monte_carlo_time_history_95ci.png`
- `13_monte_carlo_output_histograms.png`
- `14_monte_carlo_deceleration_95ci.png`
- `step3_monte_carlo_samples.csv`
- `step3_monte_carlo_summary.csv`

For quick checking, open `main_step3.m` and change:

```matlab
monteCarloOptions.runCount = 100;
```

For final report plots, set it back to:

```matlab
monteCarloOptions.runCount = 1000;
```
