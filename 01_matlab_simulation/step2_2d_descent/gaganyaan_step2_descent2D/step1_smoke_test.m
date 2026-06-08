% STEP 1 SMOKE TEST FOR GAGANYAAN MATLAB FUNCTIONS
% Put this file in the same folder as ISA_atmosphere.m and drag_model.m, then run.

clear; clc;

altitudes_m = [0, 2500, 10000, 15300, 16700];
atmosphere = ISA_atmosphere(altitudes_m);

fprintf('\nISA atmosphere check:\n');
fprintf('Altitude (m) | rho (kg/m^3) | T (K) | a (m/s)\n');
for i = 1:numel(altitudes_m)
    fprintf('%10.0f | %12.4f | %6.2f | %7.2f\n', ...
        altitudes_m(i), atmosphere.density_kg_m3(i), ...
        atmosphere.temperature_K(i), atmosphere.speedOfSound_mps(i));
end

% Drogue case: 10 km, 190 m/s, two drogues active, 1.0 s after deployment.
stageState = struct();
stageState.drogueActive = true;
stageState.timeSinceDrogueDeployment_s = 1.0;

dragAtDrogue = drag_model(0.0, 10000.0, 190.0, [], stageState);

fprintf('\nDrogue drag-model check at 10 km and 190 m/s:\n');
fprintf('Dynamic pressure: %.3f kPa\n', dragAtDrogue.dynamicPressure_Pa/1000);
fprintf('Mach number:       %.3f\n', dragAtDrogue.machNumber);
fprintf('Total CdA:         %.3f m^2\n', dragAtDrogue.totalCdA_m2);
fprintf('Total drag:        %.3f kN\n', dragAtDrogue.totalDrag_N/1000);
fprintf('Net accel:         %.3f g, down-positive\n', dragAtDrogue.netAccelerationDown_mps2/9.80665);

% Main case: 2.5 km, 70 m/s, three mains active, 8.0 s after deployment.
stageState = struct();
stageState.mainActive = true;
stageState.timeSinceMainDeployment_s = 8.0;
stageState.mainQuantityActive = 3;

dragAtMain = drag_model(0.0, 2500.0, 70.0, [], stageState);

fprintf('\nMain drag-model check at 2.5 km and 70 m/s:\n');
fprintf('Dynamic pressure: %.3f kPa\n', dragAtMain.dynamicPressure_Pa/1000);
fprintf('Mach number:       %.3f\n', dragAtMain.machNumber);
fprintf('Total CdA:         %.3f m^2\n', dragAtMain.totalCdA_m2);
fprintf('Total drag:        %.3f kN\n', dragAtMain.totalDrag_N/1000);
fprintf('Net accel:         %.3f g, down-positive\n', dragAtMain.netAccelerationDown_mps2/9.80665);

fprintf('\nStep 1 smoke test completed.\n');
