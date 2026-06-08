function descentResult = descent_2D(missionParameters, simulationOptions)
%DESCENT_2D  1-DOF vertical descent using ode45 and altitude events.
%
%   descentResult = descent_2D(missionParameters)
%   descentResult = descent_2D(missionParameters, simulationOptions)
%
% Stages:
%   0: capsule / ACS interval from start to drogue deployment altitude
%   1: drogue active from drogue deployment to main deployment altitude
%   2: main active from main deployment to touchdown
%
% State vector:
%   y(1) = altitude above sea level [m]
%   y(2) = downward velocity [m/s]

    if nargin < 1 || isempty(missionParameters)
        missionParameters = mission_parameters();
    end

    if nargin < 2 || isempty(simulationOptions)
        simulationOptions = struct();
    end

    simulationOptions = fillDefaultSimulationOptions(simulationOptions, missionParameters);

    initialState = [missionParameters.initial.altitude_m; missionParameters.initial.velocityDown_mps];
    currentState = initialState;
    currentTimeOffset_s = 0.0;
    segmentList = {};

    % Stage 0: capsule-only / ACS phase, until drogue deployment altitude.
    if currentState(1) > missionParameters.events.drogueDeployAltitude_m
        segment = solveStageSegment(missionParameters, simulationOptions, currentState, ...
            currentTimeOffset_s, 0, missionParameters.events.drogueDeployAltitude_m);
        segmentList{end+1} = segment; %#ok<AGROW>
        currentState = segment.stateHistory(end,:).';
        currentTimeOffset_s = segment.time_s(end);
    end

    % Stage 1: drogue active, until main deployment/drogue release altitude.
    if currentState(1) > missionParameters.events.mainDeployAltitude_m
        segment = solveStageSegment(missionParameters, simulationOptions, currentState, ...
            currentTimeOffset_s, 1, missionParameters.events.mainDeployAltitude_m);
        segmentList{end+1} = segment; %#ok<AGROW>
        currentState = segment.stateHistory(end,:).';
        currentTimeOffset_s = segment.time_s(end);
    end

    % Stage 2: main active, until touchdown.
    if currentState(1) > missionParameters.events.touchdownAltitude_m
        segment = solveStageSegment(missionParameters, simulationOptions, currentState, ...
            currentTimeOffset_s, 2, missionParameters.events.touchdownAltitude_m);
        segmentList{end+1} = segment; %#ok<AGROW>
    end

    descentResult = combineSegments(segmentList);
    descentResult = postProcessDescent(descentResult, missionParameters, simulationOptions);
    descentResult.missionParameters = missionParameters;
    descentResult.simulationOptions = simulationOptions;
end

function simulationOptions = fillDefaultSimulationOptions(simulationOptions, missionParameters)
    if ~isfield(simulationOptions, 'mainQuantityActive')
        simulationOptions.mainQuantityActive = missionParameters.main.quantity;
    end
    if ~isfield(simulationOptions, 'mainCanopyDeploymentDelays_s')
        simulationOptions.mainCanopyDeploymentDelays_s = zeros(1, missionParameters.main.quantity);
    end
    if ~isfield(simulationOptions, 'mainCanopyFailed')
        simulationOptions.mainCanopyFailed = false(1, missionParameters.main.quantity);
    end
    if ~isfield(simulationOptions, 'densityScaleFactor')
        simulationOptions.densityScaleFactor = 1.0;
    end
    if ~isfield(simulationOptions, 'massScaleFactor')
        simulationOptions.massScaleFactor = 1.0;
    end
    if ~isfield(simulationOptions, 'drogueDeployAltitudeOffset_m')
        simulationOptions.drogueDeployAltitudeOffset_m = 0.0;
    end
    if ~isfield(simulationOptions, 'mainDeployAltitudeOffset_m')
        simulationOptions.mainDeployAltitudeOffset_m = 0.0;
    end
end

function segment = solveStageSegment(missionParameters, simulationOptions, initialState, timeOffset_s, stageId, targetAltitude_m)

    localMissionParameters = missionParameters;
    localMissionParameters.mass_kg = missionParameters.mass_kg * simulationOptions.massScaleFactor;

    if stageId == 0
        targetAltitude_m = missionParameters.events.drogueDeployAltitude_m + simulationOptions.drogueDeployAltitudeOffset_m;
    elseif stageId == 1
        targetAltitude_m = missionParameters.events.mainDeployAltitude_m + simulationOptions.mainDeployAltitudeOffset_m;
    end

    odeOptions = odeset('RelTol', missionParameters.solver.relativeTolerance, ...
        'AbsTol', missionParameters.solver.absoluteTolerance, ...
        'Events', @(localTime_s, stateVector) altitudeEvent(localTime_s, stateVector, targetAltitude_m));

    [localTime_s, stateHistory] = ode45(@(localTime_s, stateVector) ...
        equationsOfMotion(localTime_s, stateVector, localMissionParameters, simulationOptions, stageId), ...
        [0, missionParameters.solver.maximumStageTime_s], initialState, odeOptions);

    segment.time_s = localTime_s + timeOffset_s;
    segment.localTime_s = localTime_s;
    segment.stateHistory = stateHistory;
    segment.stageId = stageId * ones(size(localTime_s));
end

function stateDerivative = equationsOfMotion(localTime_s, stateVector, missionParameters, simulationOptions, stageId)

    altitude_m = max(stateVector(1), 0.0);
    velocityDown_mps = stateVector(2);

    stageState = buildStageState(stageId, localTime_s, missionParameters, simulationOptions);
    dragOutput = drag_model(localTime_s, altitude_m, velocityDown_mps, missionParameters, stageState);

    altitudeRate_mps = -velocityDown_mps;
    velocityRate_mps2 = dragOutput.netAccelerationDown_mps2;

    stateDerivative = [altitudeRate_mps; velocityRate_mps2];
end

function stageState = buildStageState(stageId, localTime_s, missionParameters, simulationOptions)

    stageState = struct();
    stageState.acsActive = false;
    stageState.drogueActive = false;
    stageState.mainActive = false;

    stageState.timeSinceAcsDeployment_s = -Inf;
    stageState.timeSinceDrogueDeployment_s = -Inf;
    stageState.timeSinceMainDeployment_s = -Inf;

    stageState.densityScaleFactor = simulationOptions.densityScaleFactor;
    stageState.mainCanopyDeploymentDelays_s = simulationOptions.mainCanopyDeploymentDelays_s;
    stageState.mainCanopyFailed = simulationOptions.mainCanopyFailed;
    stageState.mainQuantityActive = simulationOptions.mainQuantityActive;

    if stageId == 0
        stageState.acsActive = true;
        stageState.timeSinceAcsDeployment_s = localTime_s;
    elseif stageId == 1
        stageState.drogueActive = true;
        stageState.timeSinceDrogueDeployment_s = localTime_s;
    elseif stageId == 2
        stageState.mainActive = true;
        stageState.timeSinceMainDeployment_s = localTime_s;
    end

    % Guard vector sizes.
    if numel(stageState.mainCanopyDeploymentDelays_s) ~= missionParameters.main.quantity
        stageState.mainCanopyDeploymentDelays_s = zeros(1, missionParameters.main.quantity);
    end
    if numel(stageState.mainCanopyFailed) ~= missionParameters.main.quantity
        stageState.mainCanopyFailed = false(1, missionParameters.main.quantity);
    end
end

function [value, isTerminal, direction] = altitudeEvent(~, stateVector, targetAltitude_m)
    value = stateVector(1) - targetAltitude_m;
    isTerminal = 1;
    direction = -1;
end

function descentResult = combineSegments(segmentList)

    time_s = [];
    localTime_s = [];
    altitude_m = [];
    velocityDown_mps = [];
    stageId = [];

    for segmentIndex = 1:numel(segmentList)
        segment = segmentList{segmentIndex};
        if segmentIndex == 1
            copyIndices = 1:numel(segment.time_s);
        else
            copyIndices = 2:numel(segment.time_s); % remove duplicated boundary point
        end

        time_s = [time_s; segment.time_s(copyIndices)]; %#ok<AGROW>
        localTime_s = [localTime_s; segment.localTime_s(copyIndices)]; %#ok<AGROW>
        altitude_m = [altitude_m; segment.stateHistory(copyIndices,1)]; %#ok<AGROW>
        velocityDown_mps = [velocityDown_mps; segment.stateHistory(copyIndices,2)]; %#ok<AGROW>
        stageId = [stageId; segment.stageId(copyIndices)]; %#ok<AGROW>
    end

    descentResult.time_s = time_s;
    descentResult.localTime_s = localTime_s;
    descentResult.altitude_m = altitude_m;
    descentResult.velocityDown_mps = velocityDown_mps;
    descentResult.stageId = stageId;
end

function descentResult = postProcessDescent(descentResult, missionParameters, simulationOptions)

    sampleCount = numel(descentResult.time_s);

    fieldsToZero = {'dynamicPressure_Pa','machNumber','totalDrag_N','totalCdA_m2', ...
        'netAccelerationDown_mps2','decelerationUp_g','airDensity_kg_m3','gravity_mps2', ...
        'capsuleDrag_N','drogueDrag_N','mainDrag_N','acsDrag_N','mainTension1_N', ...
        'mainTension2_N','mainTension3_N','openingShockMultiplier'};

    for fieldIndex = 1:numel(fieldsToZero)
        descentResult.(fieldsToZero{fieldIndex}) = zeros(sampleCount,1);
    end

    for sampleIndex = 1:sampleCount
        stageState = buildStageState(descentResult.stageId(sampleIndex), ...
            descentResult.localTime_s(sampleIndex), missionParameters, simulationOptions);

        localMissionParameters = missionParameters;
        localMissionParameters.mass_kg = missionParameters.mass_kg * simulationOptions.massScaleFactor;

        dragOutput = drag_model(descentResult.localTime_s(sampleIndex), ...
            max(descentResult.altitude_m(sampleIndex),0), ...
            descentResult.velocityDown_mps(sampleIndex), localMissionParameters, stageState);

        descentResult.dynamicPressure_Pa(sampleIndex) = dragOutput.dynamicPressure_Pa;
        descentResult.machNumber(sampleIndex) = dragOutput.machNumber;
        descentResult.totalDrag_N(sampleIndex) = dragOutput.totalDrag_N;
        descentResult.totalCdA_m2(sampleIndex) = dragOutput.totalCdA_m2;
        descentResult.netAccelerationDown_mps2(sampleIndex) = dragOutput.netAccelerationDown_mps2;
        descentResult.decelerationUp_g(sampleIndex) = max(-dragOutput.netAccelerationDown_mps2 / 9.80665, 0.0);
        descentResult.airDensity_kg_m3(sampleIndex) = dragOutput.airDensity_kg_m3;
        descentResult.gravity_mps2(sampleIndex) = dragOutput.gravity_mps2;
        descentResult.capsuleDrag_N(sampleIndex) = dragOutput.components.capsule.drag_N;
        descentResult.acsDrag_N(sampleIndex) = dragOutput.components.acs.drag_N;
        descentResult.drogueDrag_N(sampleIndex) = dragOutput.components.drogue.drag_N;
        descentResult.mainDrag_N(sampleIndex) = sum(dragOutput.components.main.dragPerCanopy_N);
        descentResult.openingShockMultiplier(sampleIndex) = dragOutput.openingShockMultiplier;

        tensions = dragOutput.components.main.riserTensionPerCanopy_N;
        if numel(tensions) >= 1, descentResult.mainTension1_N(sampleIndex) = tensions(1); end
        if numel(tensions) >= 2, descentResult.mainTension2_N(sampleIndex) = tensions(2); end
        if numel(tensions) >= 3, descentResult.mainTension3_N(sampleIndex) = tensions(3); end
    end

    effectiveMass_kg = missionParameters.mass_kg * simulationOptions.massScaleFactor;
    descentResult.kineticEnergy_J = 0.5 * effectiveMass_kg .* descentResult.velocityDown_mps.^2;
    descentResult.initialKineticEnergy_J = descentResult.kineticEnergy_J(1);
    descentResult.kineticEnergyRemoved_J = max(descentResult.initialKineticEnergy_J - descentResult.kineticEnergy_J, 0);

    descentResult.summary.totalDescentTime_s = descentResult.time_s(end);
    descentResult.summary.touchdownVelocity_mps = descentResult.velocityDown_mps(end);
    descentResult.summary.peakDeceleration_g = max(descentResult.decelerationUp_g);
    descentResult.summary.maxDynamicPressure_kPa = max(descentResult.dynamicPressure_Pa) / 1000;

    drogueMask = descentResult.stageId == 1;
    mainMask = descentResult.stageId == 2;
    if any(drogueMask)
        descentResult.summary.peakDrogueDeceleration_g = max(descentResult.decelerationUp_g(drogueMask));
    else
        descentResult.summary.peakDrogueDeceleration_g = 0.0;
    end
    if any(mainMask)
        descentResult.summary.peakMainDeceleration_g = max(descentResult.decelerationUp_g(mainMask));
    else
        descentResult.summary.peakMainDeceleration_g = 0.0;
    end

    descentResult.events.drogueTime_s = firstTimeAtStage(descentResult, 1);
    descentResult.events.mainTime_s = firstTimeAtStage(descentResult, 2);
    descentResult.events.touchdownTime_s = descentResult.time_s(end);
end

function stageTime_s = firstTimeAtStage(descentResult, stageId)
    stageIndex = find(descentResult.stageId == stageId, 1, 'first');
    if isempty(stageIndex)
        stageTime_s = NaN;
    else
        stageTime_s = descentResult.time_s(stageIndex);
    end
end
