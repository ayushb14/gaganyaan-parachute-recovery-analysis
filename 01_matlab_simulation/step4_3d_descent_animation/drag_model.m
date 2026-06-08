function dragOutput = drag_model(time_s, altitude_m, velocityDown_mps, missionParameters, stageState)
%DRAG_MODEL  Aerodynamic drag and parachute reefing model for Gaganyaan-type descent.
%
%   dragOutput = drag_model(time_s, altitude_m, velocityDown_mps, missionParameters, stageState)
%
%   SIGN CONVENTION
%   altitude_m         : positive upward from sea level [m]
%   velocityDown_mps   : positive downward [m/s]
%   drag force         : returned as a positive magnitude opposing velocity [N]
%   drag acceleration  : returned in down-positive axis [m/s^2]
%
%   INPUTS
%   time_s            : Current simulation time [s]. Scalar.
%   altitude_m        : Geometric altitude [m]. Scalar.
%   velocityDown_mps  : Downward velocity [m/s]. Scalar.
%   missionParameters : Struct. If [] or omitted, default public/assumed
%                       Gaganyaan-style values are used.
%   stageState        : Struct controlling active stages and time since deployment.
%                       If [] or omitted, capsule-only drag is used.
%
%   KEY OUTPUT FIELDS
%   dragOutput.totalDrag_N
%   dragOutput.totalCdA_m2
%   dragOutput.dynamicPressure_Pa
%   dragOutput.machNumber
%   dragOutput.components.capsule / drogue / main / acs
%   dragOutput.dragAccelerationDown_mps2
%   dragOutput.netAccelerationDown_mps2
%
%   MODEL FEATURES
%   - Capsule drag is always included.
%   - Drogue and main parachutes are activated by stageState booleans.
%   - Drogue reefing: default 0 -> 30% -> 100% effective area.
%   - Main reefing: default 0 -> 20% -> 60% -> 100% effective area.
%   - Main canopy delays and failures are supported for asymmetric disreefing
%     and 2-of-3 / 1-of-3 failure cases.
%   - Opening-shock pulse multiplier is output and can be included in the
%     equation of motion by setting missionParameters.aero.useOpeningShockInEom = true.
%
%   REQUIRED LOCAL FILE
%   ISA_atmosphere.m must be in the same MATLAB path.
%
%   Author: Ayush Bhatt project support file

    if nargin < 4 || isempty(missionParameters)
        missionParameters = defaultMissionParameters();
    else
        missionParameters = fillMissingMissionDefaults(missionParameters);
    end

    if nargin < 5 || isempty(stageState)
        stageState = defaultStageState(missionParameters);
    else
        stageState = fillMissingStageDefaults(stageState, missionParameters);
    end

    validateattributes(time_s, {'numeric'}, {'real','scalar','finite'}, mfilename, 'time_s', 1);
    validateattributes(altitude_m, {'numeric'}, {'real','scalar','finite'}, mfilename, 'altitude_m', 2);
    validateattributes(velocityDown_mps, {'numeric'}, {'real','scalar','finite'}, mfilename, 'velocityDown_mps', 3);

    atmosphere = ISA_atmosphere(altitude_m, stageState.densityScaleFactor);

    airDensity_kg_m3 = atmosphere.density_kg_m3;
    speedOfSound_mps = atmosphere.speedOfSound_mps;
    gravity_mps2 = atmosphere.gravity_mps2;

    dynamicPressure_Pa = 0.5 * airDensity_kg_m3 * velocityDown_mps^2;
    machNumber = abs(velocityDown_mps) / speedOfSound_mps;

    capsuleArea_m2 = referenceAreaFromDiameter(missionParameters.capsule.diameter_m);
    capsuleCdEffective = missionParameters.capsule.Cd * ...
        machCdMultiplier(machNumber, missionParameters.aero.enableTransonicCdCorrection);
    capsuleCdA_m2 = capsuleCdEffective * capsuleArea_m2;
    capsuleDrag_N = dynamicPressure_Pa * capsuleCdA_m2;

    acs = computeAcsContribution(dynamicPressure_Pa, missionParameters, stageState);
    drogue = computeDrogueContribution(dynamicPressure_Pa, missionParameters, stageState);
    main = computeMainContribution(dynamicPressure_Pa, missionParameters, stageState);

    quasiSteadyChuteDrag_N = acs.drag_N + drogue.drag_N + sum(main.dragPerCanopy_N);
    quasiSteadyDrag_N = capsuleDrag_N + quasiSteadyChuteDrag_N;

    openingShockMultiplier = max([acs.openingShockMultiplier, ...
                                  drogue.openingShockMultiplier, ...
                                  main.openingShockMultiplierPerCanopy(:)']);

    if missionParameters.aero.useOpeningShockInEom
        totalDrag_N = capsuleDrag_N + acs.drag_N * acs.openingShockMultiplier + ...
            drogue.drag_N * drogue.openingShockMultiplier + ...
            sum(main.dragPerCanopy_N .* main.openingShockMultiplierPerCanopy);
    else
        totalDrag_N = quasiSteadyDrag_N;
    end

    totalCdA_m2 = capsuleCdA_m2 + acs.CdA_m2 + drogue.CdA_m2 + sum(main.CdAPerCanopy_m2);

    if abs(velocityDown_mps) < 1e-12
        dragAccelerationDown_mps2 = 0.0;
    else
        dragAccelerationDown_mps2 = -sign(velocityDown_mps) * totalDrag_N / missionParameters.mass_kg;
    end

    netAccelerationDown_mps2 = gravity_mps2 + dragAccelerationDown_mps2;

    dragOutput.time_s = time_s;
    dragOutput.altitude_m = altitude_m;
    dragOutput.velocityDown_mps = velocityDown_mps;
    dragOutput.dynamicPressure_Pa = dynamicPressure_Pa;
    dragOutput.machNumber = machNumber;
    dragOutput.gravity_mps2 = gravity_mps2;
    dragOutput.airDensity_kg_m3 = airDensity_kg_m3;
    dragOutput.temperature_K = atmosphere.temperature_K;
    dragOutput.speedOfSound_mps = speedOfSound_mps;

    dragOutput.totalCdA_m2 = totalCdA_m2;
    dragOutput.totalDrag_N = totalDrag_N;
    dragOutput.quasiSteadyDrag_N = quasiSteadyDrag_N;
    dragOutput.quasiSteadyChuteDrag_N = quasiSteadyChuteDrag_N;
    dragOutput.openingShockMultiplier = openingShockMultiplier;
    dragOutput.dragAccelerationDown_mps2 = dragAccelerationDown_mps2;
    dragOutput.netAccelerationDown_mps2 = netAccelerationDown_mps2;

    dragOutput.components.capsule.drag_N = capsuleDrag_N;
    dragOutput.components.capsule.Cd = capsuleCdEffective;
    dragOutput.components.capsule.area_m2 = capsuleArea_m2;
    dragOutput.components.capsule.CdA_m2 = capsuleCdA_m2;

    dragOutput.components.acs = acs;
    dragOutput.components.drogue = drogue;
    dragOutput.components.main = main;

    dragOutput.stageState = stageState;
    dragOutput.missionParameters = missionParameters;
end

function missionParameters = defaultMissionParameters()
%DEFAULTMISSIONPARAMETERS  Public/assumed research baseline values.

    missionParameters.mass_kg = 6500.0;

    missionParameters.capsule.diameter_m = 3.5;
    missionParameters.capsule.height_m = 3.58;
    missionParameters.capsule.Cd = 0.70;

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

    missionParameters.aero.enableTransonicCdCorrection = true;
    missionParameters.aero.useOpeningShockInEom = false;
end

function stageState = defaultStageState(missionParameters)
%DEFAULTSTAGESTATE  Capsule-only default state.

    stageState.acsActive = false;
    stageState.drogueActive = false;
    stageState.mainActive = false;

    stageState.timeSinceAcsDeployment_s = -Inf;
    stageState.timeSinceDrogueDeployment_s = -Inf;
    stageState.timeSinceMainDeployment_s = -Inf;

    stageState.densityScaleFactor = 1.0;

    stageState.mainCanopyDeploymentDelays_s = zeros(1, missionParameters.main.quantity);
    stageState.mainCanopyFailed = false(1, missionParameters.main.quantity);
    stageState.mainQuantityActive = missionParameters.main.quantity;
end

function missionParameters = fillMissingMissionDefaults(missionParameters)
%FILLMISSINGMISSIONDEFAULTS  Allows user to pass only changed fields.

    defaultParameters = defaultMissionParameters();
    missionParameters = mergeStructs(defaultParameters, missionParameters);
end

function stageState = fillMissingStageDefaults(stageState, missionParameters)
%FILLMISSINGSTAGEDEFAULTS  Allows user to pass only changed stage fields.

    defaultState = defaultStageState(missionParameters);
    stageState = mergeStructs(defaultState, stageState);

    if numel(stageState.mainCanopyDeploymentDelays_s) ~= missionParameters.main.quantity
        stageState.mainCanopyDeploymentDelays_s = resizeRow(stageState.mainCanopyDeploymentDelays_s, missionParameters.main.quantity, 0.0);
    end

    if numel(stageState.mainCanopyFailed) ~= missionParameters.main.quantity
        stageState.mainCanopyFailed = resizeRow(stageState.mainCanopyFailed, missionParameters.main.quantity, false);
    end

    if isfield(stageState, 'mainQuantityActive') && ~isempty(stageState.mainQuantityActive)
        failedByQuantity = true(1, missionParameters.main.quantity);
        failedByQuantity(1:min(stageState.mainQuantityActive, missionParameters.main.quantity)) = false;
        stageState.mainCanopyFailed = stageState.mainCanopyFailed | failedByQuantity;
    end
end

function mergedStruct = mergeStructs(baseStruct, overrideStruct)
%MERGESTRUCTS  Recursively overlay overrideStruct onto baseStruct.

    mergedStruct = baseStruct;
    overrideFields = fieldnames(overrideStruct);

    for fieldIndex = 1:numel(overrideFields)
        fieldName = overrideFields{fieldIndex};
        if isstruct(overrideStruct.(fieldName)) && isfield(mergedStruct, fieldName) && isstruct(mergedStruct.(fieldName))
            mergedStruct.(fieldName) = mergeStructs(mergedStruct.(fieldName), overrideStruct.(fieldName));
        else
            mergedStruct.(fieldName) = overrideStruct.(fieldName);
        end
    end
end

function resizedArray = resizeRow(inputArray, desiredLength, fillValue)
%RESIZEROW  Resize vector to row vector with fill values.

    resizedArray = repmat(fillValue, 1, desiredLength);
    inputArray = inputArray(:).';
    copyLength = min(numel(inputArray), desiredLength);
    if copyLength > 0
        resizedArray(1:copyLength) = inputArray(1:copyLength);
    end
end

function area_m2 = referenceAreaFromDiameter(diameter_m)
%REFERENCEAREAFROMDIAMETER  Projected reference area of circular body/chute.

    area_m2 = pi * diameter_m^2 / 4.0;
end

function multiplier = machCdMultiplier(machNumber, enableTransonicCdCorrection)
%MACHCDMULTIPLIER  Smooth empirical Cd bump near transonic regime.
%
% This is intentionally mild and should be calibrated with CFD/test data.

    if ~enableTransonicCdCorrection
        multiplier = 1.0;
        return;
    end

    transonicBumpAmplitude = 0.12;
    transonicCenterMach = 0.95;
    transonicWidth = 0.25;
    multiplier = 1.0 + transonicBumpAmplitude * ...
        exp(-((machNumber - transonicCenterMach) / transonicWidth)^2);
end

function acs = computeAcsContribution(dynamicPressure_Pa, missionParameters, stageState)
%COMPUTEACSCONTRIBUTION  ACS parachutes normally act on apex cover, not CM.

    acs.areaFactor = 0.0;
    acs.CdA_m2 = 0.0;
    acs.drag_N = 0.0;
    acs.openingShockMultiplier = 1.0;
    acs.active = stageState.acsActive;

    if ~stageState.acsActive || ~missionParameters.acs.includeDragOnCrewModule
        return;
    end

    acs.areaFactor = multistageInflationFactor(stageState.timeSinceAcsDeployment_s, ...
        missionParameters.acs.reefingTimes_s, missionParameters.acs.reefingRatios, ...
        missionParameters.acs.fillTimeConstant_s);

    acsArea_m2 = referenceAreaFromDiameter(missionParameters.acs.diameter_m);
    acs.CdA_m2 = missionParameters.acs.quantity * missionParameters.acs.Cd * acsArea_m2 * acs.areaFactor;
    acs.drag_N = dynamicPressure_Pa * acs.CdA_m2;

    acs.openingShockMultiplier = openingShockPulseMultiplier(stageState.timeSinceAcsDeployment_s, ...
        missionParameters.acs.reefingTimes_s, missionParameters.acs.openingShockFactor, ...
        missionParameters.acs.fillTimeConstant_s);
end

function drogue = computeDrogueContribution(dynamicPressure_Pa, missionParameters, stageState)
%COMPUTEDROGUECONTRIBUTION  Two drogue parachutes with reefing model.

    drogue.areaFactor = 0.0;
    drogue.CdA_m2 = 0.0;
    drogue.drag_N = 0.0;
    drogue.openingShockMultiplier = 1.0;
    drogue.active = stageState.drogueActive;

    if ~stageState.drogueActive
        return;
    end

    drogue.areaFactor = multistageInflationFactor(stageState.timeSinceDrogueDeployment_s, ...
        missionParameters.drogue.reefingTimes_s, missionParameters.drogue.reefingRatios, ...
        missionParameters.drogue.fillTimeConstant_s);

    drogueArea_m2 = referenceAreaFromDiameter(missionParameters.drogue.diameter_m);
    drogue.CdA_m2 = missionParameters.drogue.quantity * missionParameters.drogue.Cd * drogueArea_m2 * drogue.areaFactor;
    drogue.drag_N = dynamicPressure_Pa * drogue.CdA_m2;

    drogue.openingShockMultiplier = openingShockPulseMultiplier(stageState.timeSinceDrogueDeployment_s, ...
        missionParameters.drogue.reefingTimes_s, missionParameters.drogue.openingShockFactor, ...
        missionParameters.drogue.fillTimeConstant_s);
end

function main = computeMainContribution(dynamicPressure_Pa, missionParameters, stageState)
%COMPUTEMAINCONTRIBUTION  Three main parachutes with delays/failures/reefing.

    main.active = stageState.mainActive;
    main.quantity = missionParameters.main.quantity;
    main.areaFactorPerCanopy = zeros(1, missionParameters.main.quantity);
    main.CdAPerCanopy_m2 = zeros(1, missionParameters.main.quantity);
    main.dragPerCanopy_N = zeros(1, missionParameters.main.quantity);
    main.openingShockMultiplierPerCanopy = ones(1, missionParameters.main.quantity);
    main.riserTensionPerCanopy_N = zeros(1, missionParameters.main.quantity);

    if ~stageState.mainActive
        return;
    end

    mainArea_m2 = referenceAreaFromDiameter(missionParameters.main.diameter_m);

    for canopyIndex = 1:missionParameters.main.quantity
        if stageState.mainCanopyFailed(canopyIndex)
            continue;
        end

        localTimeSinceDeploy_s = stageState.timeSinceMainDeployment_s - ...
            stageState.mainCanopyDeploymentDelays_s(canopyIndex);

        main.areaFactorPerCanopy(canopyIndex) = multistageInflationFactor(localTimeSinceDeploy_s, ...
            missionParameters.main.reefingTimes_s, missionParameters.main.reefingRatios, ...
            missionParameters.main.fillTimeConstant_s);

        main.CdAPerCanopy_m2(canopyIndex) = missionParameters.main.Cd * mainArea_m2 * ...
            main.areaFactorPerCanopy(canopyIndex);

        main.dragPerCanopy_N(canopyIndex) = dynamicPressure_Pa * main.CdAPerCanopy_m2(canopyIndex);

        main.openingShockMultiplierPerCanopy(canopyIndex) = openingShockPulseMultiplier(localTimeSinceDeploy_s, ...
            missionParameters.main.reefingTimes_s, missionParameters.main.openingShockFactor, ...
            missionParameters.main.fillTimeConstant_s);

        main.riserTensionPerCanopy_N(canopyIndex) = main.dragPerCanopy_N(canopyIndex) * ...
            main.openingShockMultiplierPerCanopy(canopyIndex);
    end
end

function areaFactor = multistageInflationFactor(timeSinceDeploy_s, reefingTimes_s, reefingRatios, fillTimeConstant_s)
%MULTISTAGEINFLATIONFACTOR  Smooth first-order canopy filling / disreefing model.
%
% Example:
%   timeSinceDeploy_s = 4, reefingTimes_s = [0 3 7], reefingRatios = [0.2 0.6 1]
%   gives transition from 0.2 to 0.6 after the first reef cut.

    if timeSinceDeploy_s < 0 || isinf(timeSinceDeploy_s) || isnan(timeSinceDeploy_s)
        areaFactor = 0.0;
        return;
    end

    reefingTimes_s = reefingTimes_s(:).';
    reefingRatios = reefingRatios(:).';

    if numel(reefingTimes_s) ~= numel(reefingRatios)
        error('reefingTimes_s and reefingRatios must have the same length.');
    end

    activeStageIndex = find(timeSinceDeploy_s >= reefingTimes_s, 1, 'last');
    if isempty(activeStageIndex)
        areaFactor = 0.0;
        return;
    end

    targetRatio = reefingRatios(activeStageIndex);
    if activeStageIndex == 1
        previousRatio = 0.0;
    else
        previousRatio = reefingRatios(activeStageIndex - 1);
    end

    elapsedSinceCut_s = timeSinceDeploy_s - reefingTimes_s(activeStageIndex);
    if fillTimeConstant_s <= 0
        exponentialFill = 1.0;
    else
        exponentialFill = 1.0 - exp(-elapsedSinceCut_s / fillTimeConstant_s);
    end

    areaFactor = previousRatio + (targetRatio - previousRatio) * exponentialFill;
    areaFactor = min(max(areaFactor, 0.0), 1.0);
end

function shockMultiplier = openingShockPulseMultiplier(timeSinceDeploy_s, reefingTimes_s, openingShockFactor, fillTimeConstant_s)
%OPENINGSHOCKPULSEMULTIPLIER  Short transient multiplier at deployment/disreef cuts.
%
% This is a low-order engineering approximation, not a full added-mass FSI model.
% It provides a pulse near each filling/disreefing event for peak-load studies.

    if timeSinceDeploy_s < 0 || isinf(timeSinceDeploy_s) || isnan(timeSinceDeploy_s)
        shockMultiplier = 1.0;
        return;
    end

    reefingTimes_s = reefingTimes_s(:).';
    pulseValues = zeros(size(reefingTimes_s));

    for cutIndex = 1:numel(reefingTimes_s)
        elapsed_s = timeSinceDeploy_s - reefingTimes_s(cutIndex);
        if elapsed_s >= 0
            if fillTimeConstant_s <= 0
                pulseValues(cutIndex) = 0.0;
            else
                pulseValues(cutIndex) = exp(-elapsed_s / fillTimeConstant_s);
            end
        end
    end

    shockMultiplier = 1.0 + (openingShockFactor - 1.0) * max(pulseValues);
end
