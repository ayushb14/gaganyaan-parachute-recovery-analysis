%% Balloon stress-strain rough estimate for cylinder-to-balloon inflation
% Run after/alongside OpenFOAM case to connect pressure values with wall stress.
% SI units throughout.

clear; clc; close all;

ambientPressure_Pa = 101325;
balloonRadius_m = 0.15;
initialBalloonRadius_m = 0.05;
wallThickness_m = 0.00030;
tensileStrength_Pa = 20e6;

cylinderPressure_abs_bar = [1.2 1.5 2.0 3.0];
cylinderPressure_Pa = cylinderPressure_abs_bar * 1e5;
deltaPressure_Pa = cylinderPressure_Pa - ambientPressure_Pa;
deltaPressure_Pa(deltaPressure_Pa < 0) = 0;

membraneStress_Pa = deltaPressure_Pa .* balloonRadius_m ./ (2*wallThickness_m);
membraneStress_MPa = membraneStress_Pa / 1e6;
safetyFactor = tensileStrength_Pa ./ membraneStress_Pa;
strain = (balloonRadius_m - initialBalloonRadius_m)/initialBalloonRadius_m;
strain_percent = 100*strain*ones(size(cylinderPressure_abs_bar));

resultsTable = table(cylinderPressure_abs_bar(:), deltaPressure_Pa(:)/1e5, ...
    membraneStress_MPa(:), strain_percent(:), safetyFactor(:), ...
    'VariableNames', {'CylinderPressure_abs_bar','DeltaPressure_bar', ...
    'MembraneStress_MPa','EngineeringStrain_percent','SafetyFactor'});

disp(resultsTable);

figure('Color','w');
plot(cylinderPressure_abs_bar, membraneStress_MPa, 'o-', 'LineWidth', 2);
yline(tensileStrength_Pa/1e6, '--', 'Tensile strength estimate');
grid on; xlabel('Cylinder pressure (bar absolute)'); ylabel('Membrane stress (MPa)');
title('Balloon membrane stress vs cylinder pressure');
set(gca, 'FontSize', 12);

figure('Color','w');
plot(cylinderPressure_abs_bar, safetyFactor, 'o-', 'LineWidth', 2);
yline(1.0, '--', 'Failure limit');
grid on; xlabel('Cylinder pressure (bar absolute)'); ylabel('Safety factor');
title('Safety factor against tensile failure');
set(gca, 'FontSize', 12);

writetable(resultsTable, 'balloon_stress_strain_results.csv');
