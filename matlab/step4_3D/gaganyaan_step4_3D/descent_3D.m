function trajectory3D = descent_3D(missionParameters, simulationOptions3D)
%DESCENT_3D  Research-grade engineering 3D descent extension.
%
% This module uses the validated 1-DOF vertical descent model as the
% backbone, then integrates lateral wind drift and parachute pendulum motion.
% It is an engineering-level pre-CFD/pre-FSI model, intended for trajectory
% visualization, wind drift estimates, and asymmetric-disreefing studies.
%
% Required local files:
%   mission_parameters.m, descent_2D.m, ISA_atmosphere.m, drag_model.m
%
% State integrated here:
%   x, y       horizontal position [m]
%   vx, vy     horizontal velocity [m/s]
%   theta      pendulum swing angle [rad]
%   thetaDot   pendulum angular rate [rad/s]
%
% Vertical altitude and vertical speed are taken from descent_2D and
% interpolated. This keeps Step 4 stable while still giving a useful 3D path.

    if nargin < 1 || isempty(missionParameters)
        missionParameters = mission_parameters('PUBLIC_6500_RESEARCH');
    end
    if nargin < 2 || isempty(simulationOptions3D)
        simulationOptions3D = struct();
    end
    simulationOptions3D = fillDefault3DOptions(simulationOptions3D);

    % Run vertical baseline or use externally provided result.
    if isfield(simulationOptions3D, 'verticalResult') && ~isempty(simulationOptions3D.verticalResult)
        verticalResult = simulationOptions3D.verticalResult;
    else
        twoDOptions = struct();
        twoDOptions.mainQuantityActive = simulationOptions3D.mainQuantityActive;
        twoDOptions.mainCanopyDeploymentDelays_s = simulationOptions3D.mainCanopyDeploymentDelays_s;
        twoDOptions.mainCanopyFailed = simulationOptions3D.mainCanopyFailed;
        twoDOptions.densityScaleFactor = 1.0;
        twoDOptions.massScaleFactor = 1.0;
        twoDOptions.drogueDeployAltitudeOffset_m = 0.0;
        twoDOptions.mainDeployAltitudeOffset_m = 0.0;
        verticalResult = descent_2D(missionParameters, twoDOptions);
    end

    timeSpan_s = [verticalResult.time_s(1), verticalResult.time_s(end)];

    % Initial lateral state: zero position, small initial AoA/swing disturbance.
    initialTheta_rad = deg2rad(simulationOptions3D.initialPendulumAngle_deg);
    initialState = [0; 0; 0; 0; initialTheta_rad; 0];

    odeOptions = odeset('RelTol', 1e-6, 'AbsTol', 1e-8);
    [time3D_s, state3D] = ode45(@(time_s, stateVector) eom3D(time_s, stateVector, ...
        verticalResult, missionParameters, simulationOptions3D), timeSpan_s, initialState, odeOptions);

    altitude_m = interp1(verticalResult.time_s, verticalResult.altitude_m, time3D_s, 'linear', 'extrap');
    velocityDown_mps = interp1(verticalResult.time_s, verticalResult.velocityDown_mps, time3D_s, 'linear', 'extrap');
    stageId = interp1(verticalResult.time_s, verticalResult.stageId, time3D_s, 'nearest', 'extrap');

    windX_mps = zeros(size(time3D_s));
    windY_mps = zeros(size(time3D_s));
    for index = 1:numel(time3D_s)
        [windX_mps(index), windY_mps(index)] = windProfile(altitude_m(index), simulationOptions3D);
    end

    trajectory3D.time_s = time3D_s;
    trajectory3D.x_m = state3D(:,1);
    trajectory3D.y_m = state3D(:,2);
    trajectory3D.altitude_m = altitude_m;
    trajectory3D.vx_mps = state3D(:,3);
    trajectory3D.vy_mps = state3D(:,4);
    trajectory3D.velocityDown_mps = velocityDown_mps;
    trajectory3D.stageId = stageId;
    trajectory3D.windX_mps = windX_mps;
    trajectory3D.windY_mps = windY_mps;
    trajectory3D.theta_rad = state3D(:,5);
    trajectory3D.theta_deg = rad2deg(state3D(:,5));
    trajectory3D.thetaDot_radps = state3D(:,6);
    trajectory3D.horizontalDrift_m = hypot(state3D(:,1), state3D(:,2));
    trajectory3D.verticalResult = verticalResult;
    trajectory3D.options = simulationOptions3D;

    trajectory3D.summary.totalDescentTime_s = verticalResult.summary.totalDescentTime_s;
    trajectory3D.summary.touchdownVelocity_mps = verticalResult.summary.touchdownVelocity_mps;
    trajectory3D.summary.lateralDrift_m = trajectory3D.horizontalDrift_m(end);
    trajectory3D.summary.maximumSwingAngle_deg = max(abs(trajectory3D.theta_deg));
    trajectory3D.summary.finalX_m = trajectory3D.x_m(end);
    trajectory3D.summary.finalY_m = trajectory3D.y_m(end);
end

function simulationOptions3D = fillDefault3DOptions(simulationOptions3D)
    defaults.crosswindReferenceAltitude_m = 5000.0;
    defaults.crosswindReferenceSpeed_mps = 5.0;
    defaults.windDirection_deg = 90.0;             % 90 deg = +y direction
    defaults.freefallLateralTimeConstant_s = 25.0;
    defaults.drogueLateralTimeConstant_s = 10.0;
    defaults.mainLateralTimeConstant_s = 18.0;
    defaults.suspensionLength_m = 30.0;
    defaults.pendulumDampingRatio = 0.15;
    defaults.initialPendulumAngle_deg = 5.0;
    defaults.asymmetricForcingGain = 0.35;
    defaults.mainQuantityActive = 3;
    defaults.mainCanopyDeploymentDelays_s = [0, 0, 0];
    defaults.mainCanopyFailed = [false, false, false];
    defaults.animationEnabled = false;

    optionNames = fieldnames(defaults);
    for index = 1:numel(optionNames)
        name = optionNames{index};
        if ~isfield(simulationOptions3D, name) || isempty(simulationOptions3D.(name))
            simulationOptions3D.(name) = defaults.(name);
        end
    end
end

function stateDerivative = eom3D(time_s, stateVector, verticalResult, missionParameters, simulationOptions3D)
    altitude_m = interp1(verticalResult.time_s, verticalResult.altitude_m, time_s, 'linear', 'extrap');
    stageId = interp1(verticalResult.time_s, verticalResult.stageId, time_s, 'nearest', 'extrap');

    vx_mps = stateVector(3);
    vy_mps = stateVector(4);
    theta_rad = stateVector(5);
    thetaDot_radps = stateVector(6);

    [windX_mps, windY_mps] = windProfile(altitude_m, simulationOptions3D);

    lateralTimeConstant_s = lateralTimeConstantFromStage(stageId, simulationOptions3D);
    ax_mps2 = (windX_mps - vx_mps) / lateralTimeConstant_s;
    ay_mps2 = (windY_mps - vy_mps) / lateralTimeConstant_s;

    atmosphere = ISA_atmosphere(max(altitude_m,0));
    naturalFrequency_radps = sqrt(atmosphere.gravity_mps2 / simulationOptions3D.suspensionLength_m);
    dampingRatio = simulationOptions3D.pendulumDampingRatio;

    forcing_radps2 = asymmetricPendulumForcing(time_s, verticalResult, simulationOptions3D);
    thetaDDot_radps2 = -2*dampingRatio*naturalFrequency_radps*thetaDot_radps - ...
        naturalFrequency_radps^2*theta_rad + forcing_radps2;

    stateDerivative = [vx_mps; vy_mps; ax_mps2; ay_mps2; thetaDot_radps; thetaDDot_radps2];
end

function lateralTimeConstant_s = lateralTimeConstantFromStage(stageId, simulationOptions3D)
    if stageId < 0.5
        lateralTimeConstant_s = simulationOptions3D.freefallLateralTimeConstant_s;
    elseif stageId < 1.5
        lateralTimeConstant_s = simulationOptions3D.drogueLateralTimeConstant_s;
    else
        lateralTimeConstant_s = simulationOptions3D.mainLateralTimeConstant_s;
    end
end

function [windX_mps, windY_mps] = windProfile(altitude_m, simulationOptions3D)
    % Simple mission-editable profile: 0 at sea level, 5 m/s at 5 km,
    % saturating above reference altitude. Direction is set by windDirection_deg.
    altitudeFactor = min(max(altitude_m / simulationOptions3D.crosswindReferenceAltitude_m, 0.0), 1.0);
    windSpeed_mps = simulationOptions3D.crosswindReferenceSpeed_mps * altitudeFactor;
    direction_rad = deg2rad(simulationOptions3D.windDirection_deg);
    windX_mps = windSpeed_mps * cos(direction_rad);
    windY_mps = windSpeed_mps * sin(direction_rad);
end

function forcing_radps2 = asymmetricPendulumForcing(time_s, verticalResult, simulationOptions3D)
    % Uses main-riser tension imbalance from descent_2D post-processing as a
    % proxy for asymmetric disreefing / off-axis load.
    mainTime_s = verticalResult.events.mainTime_s;
    if isnan(mainTime_s) || time_s < mainTime_s
        forcing_radps2 = 0.0;
        return;
    end

    t1 = interp1(verticalResult.time_s, verticalResult.mainTension1_N, time_s, 'linear', 0.0);
    t2 = interp1(verticalResult.time_s, verticalResult.mainTension2_N, time_s, 'linear', 0.0);
    t3 = interp1(verticalResult.time_s, verticalResult.mainTension3_N, time_s, 'linear', 0.0);
    tensions = [t1, t2, t3];
    totalTension = sum(abs(tensions));

    if totalTension < 1.0
        imbalanceRatio = 0.0;
    else
        imbalanceRatio = (max(tensions) - min(tensions)) / totalTension;
    end

    forcing_radps2 = simulationOptions3D.asymmetricForcingGain * imbalanceRatio;
end
