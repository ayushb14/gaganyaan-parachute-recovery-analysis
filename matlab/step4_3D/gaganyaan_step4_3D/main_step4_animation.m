% MAIN_STEP4_ANIMATION  Real animated 3D visualization for Step 4.
%
% Put this file and animate_3D_descent.m in the same folder as Step 4 files,
% then run:
%   cd("D:\Downloads\gaganyaan_step4_3D\gaganyaan_step4_3D")
%   main_step4_animation

clear; clc; close all;

missionParameters = mission_parameters('PUBLIC_6500_RESEARCH');
missionParameters.outputFolder = fullfile(pwd, 'gaganyaan_step4_outputs');
if ~exist(missionParameters.outputFolder, 'dir')
    mkdir(missionParameters.outputFolder);
end

nominal3DOptions = struct();
nominal3DOptions.crosswindReferenceSpeed_mps = 5.0;
nominal3DOptions.crosswindReferenceAltitude_m = 5000.0;
nominal3DOptions.windDirection_deg = 90.0;
nominal3DOptions.mainQuantityActive = 3;
nominal3DOptions.mainCanopyDeploymentDelays_s = [0, 0, 0];
nominal3DOptions.mainCanopyFailed = [false, false, false];
nominal3DOptions.initialPendulumAngle_deg = 5.0;

fprintf('\nRunning nominal 3D trajectory for animation...\n');
nominal3D = descent_3D(missionParameters, nominal3DOptions);

animationOptions = struct();
animationOptions.frameCount = 260;
animationOptions.saveGif = true;
animationOptions.saveAvi = true;
animationOptions.playInFigure = true;
animationOptions.visualCanopyScale = 8.0;
animationOptions.frameDelay_s = 0.04;

fprintf('Creating GIF/AVI animation. This may take 1-3 minutes...\n');
animationFiles = animate_3D_descent(nominal3D, missionParameters.outputFolder, animationOptions);

fprintf('\n============================================\n');
fprintf(' STEP 4 REAL 3D ANIMATION COMPLETE\n');
fprintf('============================================\n');
fprintf(' GIF saved at: %s\n', animationFiles.gifPath);
fprintf(' AVI saved at: %s\n', animationFiles.aviPath);
fprintf(' Touchdown velocity: %.2f m/s\n', nominal3D.summary.touchdownVelocity_mps);
fprintf(' Lateral drift:      %.2f m\n', nominal3D.summary.lateralDrift_m);
fprintf('============================================\n');
