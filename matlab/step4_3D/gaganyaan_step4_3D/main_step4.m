% MAIN_STEP4  3D descent, wind drift, pendulum, asymmetric disreefing, failures.
%
% Run this after Step 3 is working:
%   cd("D:\Downloads\gaganyaan_step4_3D")
%   main_step4

clear; clc; close all;

missionParameters = mission_parameters('PUBLIC_6500_RESEARCH');
missionParameters.outputFolder = fullfile(pwd, 'gaganyaan_step4_outputs');
if ~exist(missionParameters.outputFolder, 'dir')
    mkdir(missionParameters.outputFolder);
end

%% Nominal 3-main 3D trajectory
nominal3DOptions = struct();
nominal3DOptions.crosswindReferenceSpeed_mps = 5.0;
nominal3DOptions.crosswindReferenceAltitude_m = 5000.0;
nominal3DOptions.windDirection_deg = 90.0;
nominal3DOptions.mainQuantityActive = 3;
nominal3DOptions.mainCanopyDeploymentDelays_s = [0, 0, 0];
nominal3DOptions.mainCanopyFailed = [false, false, false];
nominal3DOptions.initialPendulumAngle_deg = 5.0;
nominal3D = descent_3D(missionParameters, nominal3DOptions);

%% Asymmetric disreefing: one main chute delayed by 0.5 s
asymmetricOptions = nominal3DOptions;
asymmetricOptions.mainCanopyDeploymentDelays_s = [0.0, 0.5, 0.0];
asymmetricOptions.initialPendulumAngle_deg = 5.0;
asymmetric3D = descent_3D(missionParameters, asymmetricOptions);

%% Failure-mode 3D/vertical comparison
all3Options = nominal3DOptions;
all3Options.mainQuantityActive = 3;
all3Options.mainCanopyFailed = [false, false, false];
failureCases.all3 = descent_3D(missionParameters, all3Options);

twoOf3Options = nominal3DOptions;
twoOf3Options.mainQuantityActive = 2;
twoOf3Options.mainCanopyFailed = [false, false, true];
failureCases.twoOf3 = descent_3D(missionParameters, twoOf3Options);

oneOf3Options = nominal3DOptions;
oneOf3Options.mainQuantityActive = 1;
oneOf3Options.mainCanopyFailed = [false, true, true];
failureCases.oneOf3 = descent_3D(missionParameters, oneOf3Options);

%% Plot and export
plot_results_3D(nominal3D, asymmetric3D, failureCases, missionParameters.outputFolder);

%% Export CSV tables
nominal3DTable = table(nominal3D.time_s, nominal3D.x_m, nominal3D.y_m, nominal3D.altitude_m, ...
    nominal3D.vx_mps, nominal3D.vy_mps, nominal3D.velocityDown_mps, nominal3D.stageId, ...
    nominal3D.windX_mps, nominal3D.windY_mps, nominal3D.theta_deg, nominal3D.horizontalDrift_m, ...
    'VariableNames', {'time_s','x_m','y_m','altitude_m','vx_mps','vy_mps','velocityDown_mps', ...
    'stageId','windX_mps','windY_mps','theta_deg','horizontalDrift_m'});
writetable(nominal3DTable, fullfile(missionParameters.outputFolder, 'step4_nominal_3d_trajectory.csv'));

summaryTable = table( ...
    ["3 mains nominal"; "asymmetric 0.5s main delay"; "2 of 3 mains"; "1 of 3 mains"], ...
    [nominal3D.summary.touchdownVelocity_mps; asymmetric3D.summary.touchdownVelocity_mps; ...
     failureCases.twoOf3.summary.touchdownVelocity_mps; failureCases.oneOf3.summary.touchdownVelocity_mps], ...
    [nominal3D.summary.lateralDrift_m; asymmetric3D.summary.lateralDrift_m; ...
     failureCases.twoOf3.summary.lateralDrift_m; failureCases.oneOf3.summary.lateralDrift_m], ...
    [nominal3D.summary.maximumSwingAngle_deg; asymmetric3D.summary.maximumSwingAngle_deg; ...
     failureCases.twoOf3.summary.maximumSwingAngle_deg; failureCases.oneOf3.summary.maximumSwingAngle_deg], ...
    'VariableNames', {'caseName','touchdownVelocity_mps','lateralDrift_m','maximumSwingAngle_deg'});
writetable(summaryTable, fullfile(missionParameters.outputFolder, 'step4_3d_summary.csv'));

disp(summaryTable);

fprintf('\n============================================\n');
fprintf(' GAGANYAAN STEP 4 3D DESCENT SUMMARY\n');
fprintf('============================================\n');
fprintf(' Nominal touchdown velocity:   %.2f m/s\n', nominal3D.summary.touchdownVelocity_mps);
fprintf(' Nominal lateral drift:        %.2f m\n', nominal3D.summary.lateralDrift_m);
fprintf(' Max pendulum angle nominal:   %.2f deg\n', nominal3D.summary.maximumSwingAngle_deg);
fprintf(' Asym max swing / tilt proxy:  %.2f deg\n', asymmetric3D.summary.maximumSwingAngle_deg);
fprintf(' 2-of-3 touchdown velocity:    %.2f m/s\n', failureCases.twoOf3.summary.touchdownVelocity_mps);
fprintf(' 1-of-3 touchdown velocity:    %.2f m/s\n', failureCases.oneOf3.summary.touchdownVelocity_mps);
fprintf(' Output folder:                %s\n', missionParameters.outputFolder);
fprintf('============================================\n');

fprintf('\nStep 4 complete. Check gaganyaan_step4_outputs for PNG plots and CSV data.\n');
