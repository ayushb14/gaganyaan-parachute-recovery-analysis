function missionParameters = mission_parameters(scenarioName)
%MISSION_PARAMETERS  Public/assumed parameter set for Gaganyaan-style descent simulation.
%
%   missionParameters = mission_parameters()
%   missionParameters = mission_parameters('PUBLIC_6500_RESEARCH')
%
% This file keeps every assumption in one editable place. Values are SI units.
% Use this as an open-source/public-data simulation baseline only. Replace
% assumptions with ADRDE/ISRO-provided internal values only if your supervisor
% is allowed to share them.

    if nargin < 1 || isempty(scenarioName)
        scenarioName = 'PUBLIC_6500_RESEARCH';
    end

    missionParameters.scenarioName = scenarioName;

    %% Capsule / payload
    missionParameters.mass_kg = 6500.0;
    missionParameters.capsule.diameter_m = 3.5;
    missionParameters.capsule.height_m = 3.58;
    missionParameters.capsule.Cd = 0.70;

    %% Parachute system architecture
    missionParameters.acs.quantity = 2;
    missionParameters.acs.diameter_m = 2.5;
    missionParameters.acs.Cd = 0.60;
    missionParameters.acs.reefingTimes_s = 0.0;
    missionParameters.acs.reefingRatios = 1.0;
    missionParameters.acs.fillTimeConstant_s = 0.25;
    missionParameters.acs.openingShockFactor = 1.5;
    missionParameters.acs.includeDragOnCrewModule = false;

    missionParameters.drogue.quantity = 2;
    missionParameters.drogue.diameter_m = 5.8;
    missionParameters.drogue.Cd = 0.55;
    missionParameters.drogue.reefingTimes_s = [0.0, 2.0];
    missionParameters.drogue.reefingRatios = [0.30, 1.00];
    missionParameters.drogue.fillTimeConstant_s = 0.40;
    missionParameters.drogue.openingShockFactor = 2.0;

    missionParameters.pilot.quantity = 3;
    missionParameters.pilot.diameter_m = 3.4;
    missionParameters.pilot.Cd = 0.60;

    missionParameters.main.quantity = 3;
    missionParameters.main.diameter_m = 25.0;
    missionParameters.main.Cd = 0.87;
    missionParameters.main.reefingTimes_s = [0.0, 3.0, 7.0];
    missionParameters.main.reefingRatios = [0.20, 0.60, 1.00];
    missionParameters.main.fillTimeConstant_s = 0.50;
    missionParameters.main.openingShockFactor = 1.8;

    %% Event altitudes and initial condition
    missionParameters.events.acsAltitude_m = 15300.0;
    missionParameters.events.drogueDeployAltitude_m = 10000.0;
    missionParameters.events.drogueReleaseAltitude_m = 2500.0;
    missionParameters.events.mainDeployAltitude_m = 2500.0;
    missionParameters.events.touchdownAltitude_m = 0.0;

    missionParameters.initial.altitude_m = 15300.0;
    missionParameters.initial.velocityDown_mps = 276.0;

    %% Aerodynamic modelling options
    missionParameters.aero.enableTransonicCdCorrection = true;

    % Keep false for stable trajectory integration. Opening-shock multipliers
    % are still calculated in drag_model and can be used for peak load plots.
    % Set true only after validating fill-time/reefing data.
    missionParameters.aero.useOpeningShockInEom = false;

    %% Solver and plotting
    missionParameters.solver.relativeTolerance = 1e-7;
    missionParameters.solver.absoluteTolerance = 1e-9;
    missionParameters.solver.maximumStageTime_s = 2500.0;
    missionParameters.outputFolder = fullfile(pwd, 'gaganyaan_step2_outputs');

    %% Scenario shortcuts
    switch upper(string(scenarioName))
        case "PUBLIC_6500_RESEARCH"
            % Baseline already set.

        case "PROJECT_NOTE_10KM"
            missionParameters.initial.altitude_m = 10000.0;
            missionParameters.initial.velocityDown_mps = 190.0;
            missionParameters.events.drogueDeployAltitude_m = 10000.0;

        case "TV_D1_PUBLIC_SCALE_CHECK"
            % Useful public-scale check, not the 6500 kg final mission case.
            missionParameters.mass_kg = 4520.0;
            missionParameters.capsule.diameter_m = 3.1;
            missionParameters.capsule.height_m = 2.97;
            missionParameters.initial.altitude_m = 16700.0;
            missionParameters.initial.velocityDown_mps = 140.0;
            missionParameters.events.drogueDeployAltitude_m = 16700.0;

        otherwise
            warning('Unknown scenarioName. Using PUBLIC_6500_RESEARCH defaults.');
    end
end
