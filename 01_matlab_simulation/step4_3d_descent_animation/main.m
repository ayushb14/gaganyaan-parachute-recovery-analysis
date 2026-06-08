% MAIN  Step 2 runner for Gaganyaan-type 2D parachute descent simulation.
%
% Put all files in one folder and run this file only.
% Do not directly run function files such as drag_model.m or descent_2D.m.

clear; clc; close all;

missionParameters = mission_parameters('PUBLIC_6500_RESEARCH');

% Nominal 3-main case.
simulationOptions = struct();
simulationOptions.mainQuantityActive = 3;
simulationOptions.densityScaleFactor = 1.0;
simulationOptions.massScaleFactor = 1.0;

nominalResult = descent_2D(missionParameters, simulationOptions);

if ~exist(missionParameters.outputFolder, 'dir')
    mkdir(missionParameters.outputFolder);
end

plot_results_2D(nominalResult, missionParameters.outputFolder);
comparisonResult = compare_main_chute_cases(missionParameters, missionParameters.outputFolder); %#ok<NASGU>

% Save key data for report use.
summaryTable = table(nominalResult.time_s, nominalResult.altitude_m, nominalResult.velocityDown_mps, ...
    nominalResult.dynamicPressure_Pa/1000, nominalResult.machNumber, ...
    nominalResult.decelerationUp_g, nominalResult.totalDrag_N/1000, nominalResult.stageId, ...
    'VariableNames', {'time_s','altitude_m','velocityDown_mps','dynamicPressure_kPa','Mach','deceleration_g','totalDrag_kN','stageId'});

writetable(summaryTable, fullfile(missionParameters.outputFolder, 'step2_nominal_time_history.csv'));

fprintf('\n============================================\n');
fprintf(' GAGANYAAN PARACHUTE DESCENT SUMMARY\n');
fprintf('============================================\n');
fprintf(' Scenario:                   %s\n', missionParameters.scenarioName);
fprintf(' Total descent time:         %.2f s\n', nominalResult.summary.totalDescentTime_s);
fprintf(' Touchdown velocity:         %.2f m/s\n', nominalResult.summary.touchdownVelocity_mps);
fprintf(' Peak deceleration drogue:   %.2f g\n', nominalResult.summary.peakDrogueDeceleration_g);
fprintf(' Peak deceleration main:     %.2f g\n', nominalResult.summary.peakMainDeceleration_g);
fprintf(' Max dynamic pressure:       %.2f kPa\n', nominalResult.summary.maxDynamicPressure_kPa);
fprintf(' Drogue deployment time:     %.2f s\n', nominalResult.events.drogueTime_s);
fprintf(' Main deployment time:       %.2f s\n', nominalResult.events.mainTime_s);
fprintf(' Output folder:              %s\n', missionParameters.outputFolder);
fprintf('============================================\n');

fprintf('\nStep 2 complete. Check the output folder for PNG plots and CSV data.\n');
