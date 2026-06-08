function monteCarloResult = monte_carlo(missionParameters, monteCarloOptions)
%MONTE_CARLO  Uncertainty analysis for Gaganyaan-type parachute descent.
%
%   monteCarloResult = monte_carlo(missionParameters, monteCarloOptions)
%
% Uncertainties included:
%   - Capsule, drogue, and main Cd: uniform +/- Cd uncertainty fraction
%   - Mass: uniform +/- mass uncertainty in kg
%   - Drogue and main deployment altitude: uniform +/- altitude jitter in m
%   - Density scale factor: uniform +/- density uncertainty fraction
%
% The module runs the existing descent_2D solver repeatedly and creates
% statistics suitable for publication-quality 95% confidence interval plots.

    if nargin < 1 || isempty(missionParameters)
        missionParameters = mission_parameters('PUBLIC_6500_RESEARCH');
    end
    if nargin < 2 || isempty(monteCarloOptions)
        monteCarloOptions = struct();
    end

    monteCarloOptions = fillDefaultMonteCarloOptions(monteCarloOptions);

    rng(monteCarloOptions.randomSeed);

    runCount = monteCarloOptions.runCount;
    resultCell = cell(runCount, 1);
    sampleTable = table('Size', [runCount, 11], ...
        'VariableTypes', {'double','double','double','double','double','double','double','double','double','double','double'}, ...
        'VariableNames', {'runIndex','capsuleCdScale','drogueCdScale','mainCdScale','mass_kg', ...
                          'densityScaleFactor','drogueDeployAltitudeOffset_m','mainDeployAltitudeOffset_m', ...
                          'touchdownVelocity_mps','totalDescentTime_s','peakDeceleration_g'});

    fprintf('\n--- Monte Carlo started: %d runs ---\n', runCount);

    for runIndex = 1:runCount
        sampledMission = missionParameters;
        simulationOptions = struct();

        capsuleCdScale = uniformScale(monteCarloOptions.cdUncertaintyFraction);
        drogueCdScale  = uniformScale(monteCarloOptions.cdUncertaintyFraction);
        mainCdScale    = uniformScale(monteCarloOptions.cdUncertaintyFraction);

        sampledMass_kg = missionParameters.mass_kg + uniformValue(monteCarloOptions.massUncertainty_kg);
        densityScaleFactor = uniformScale(monteCarloOptions.densityUncertaintyFraction);
        drogueDeployAltitudeOffset_m = uniformValue(monteCarloOptions.deploymentAltitudeJitter_m);
        mainDeployAltitudeOffset_m = uniformValue(monteCarloOptions.deploymentAltitudeJitter_m);

        sampledMission.capsule.Cd = missionParameters.capsule.Cd * capsuleCdScale;
        sampledMission.drogue.Cd  = missionParameters.drogue.Cd  * drogueCdScale;
        sampledMission.main.Cd    = missionParameters.main.Cd    * mainCdScale;

        sampledMission.outputFolder = missionParameters.outputFolder;

        simulationOptions.mainQuantityActive = missionParameters.main.quantity;
        simulationOptions.mainCanopyDeploymentDelays_s = zeros(1, missionParameters.main.quantity);
        simulationOptions.mainCanopyFailed = false(1, missionParameters.main.quantity);
        simulationOptions.massScaleFactor = sampledMass_kg / missionParameters.mass_kg;
        simulationOptions.densityScaleFactor = densityScaleFactor;
        simulationOptions.drogueDeployAltitudeOffset_m = drogueDeployAltitudeOffset_m;
        simulationOptions.mainDeployAltitudeOffset_m = mainDeployAltitudeOffset_m;

        resultCell{runIndex} = descent_2D(sampledMission, simulationOptions);

        sampleTable.runIndex(runIndex) = runIndex;
        sampleTable.capsuleCdScale(runIndex) = capsuleCdScale;
        sampleTable.drogueCdScale(runIndex) = drogueCdScale;
        sampleTable.mainCdScale(runIndex) = mainCdScale;
        sampleTable.mass_kg(runIndex) = sampledMass_kg;
        sampleTable.densityScaleFactor(runIndex) = densityScaleFactor;
        sampleTable.drogueDeployAltitudeOffset_m(runIndex) = drogueDeployAltitudeOffset_m;
        sampleTable.mainDeployAltitudeOffset_m(runIndex) = mainDeployAltitudeOffset_m;
        sampleTable.touchdownVelocity_mps(runIndex) = resultCell{runIndex}.summary.touchdownVelocity_mps;
        sampleTable.totalDescentTime_s(runIndex) = resultCell{runIndex}.summary.totalDescentTime_s;
        sampleTable.peakDeceleration_g(runIndex) = resultCell{runIndex}.summary.peakDeceleration_g;

        if mod(runIndex, max(1, floor(runCount/10))) == 0 || runIndex == runCount
            fprintf('Monte Carlo progress: %4d / %4d runs complete\n', runIndex, runCount);
        end
    end

    monteCarloResult.options = monteCarloOptions;
    monteCarloResult.samples = sampleTable;
    monteCarloResult.results = resultCell;
    monteCarloResult.statistics = computeMonteCarloStatistics(sampleTable);
    monteCarloResult.envelopes = computeMonteCarloEnvelopes(resultCell, missionParameters);
end

function options = fillDefaultMonteCarloOptions(options)
    if ~isfield(options, 'runCount')
        options.runCount = 1000;
    end
    if ~isfield(options, 'randomSeed')
        options.randomSeed = 42;
    end
    if ~isfield(options, 'cdUncertaintyFraction')
        options.cdUncertaintyFraction = 0.10;
    end
    if ~isfield(options, 'massUncertainty_kg')
        options.massUncertainty_kg = 50.0;
    end
    if ~isfield(options, 'deploymentAltitudeJitter_m')
        options.deploymentAltitudeJitter_m = 200.0;
    end
    if ~isfield(options, 'densityUncertaintyFraction')
        options.densityUncertaintyFraction = 0.03;
    end
    if ~isfield(options, 'altitudeGridCount')
        options.altitudeGridCount = 600;
    end
    if ~isfield(options, 'timeGridCount')
        options.timeGridCount = 600;
    end
end

function scale = uniformScale(fractionHalfWidth)
    scale = 1.0 + uniformValue(fractionHalfWidth);
end

function value = uniformValue(halfWidth)
    value = halfWidth * (2.0 * rand() - 1.0);
end

function statistics = computeMonteCarloStatistics(sampleTable)
    fields = {'touchdownVelocity_mps','totalDescentTime_s','peakDeceleration_g'};
    for fieldIndex = 1:numel(fields)
        fieldName = fields{fieldIndex};
        dataVector = sampleTable.(fieldName);
        statistics.(fieldName).mean = mean(dataVector);
        statistics.(fieldName).standardDeviation = std(dataVector);
        statistics.(fieldName).minimum = min(dataVector);
        statistics.(fieldName).maximum = max(dataVector);
        statistics.(fieldName).p025 = percentile1D(dataVector, 2.5);
        statistics.(fieldName).p050 = percentile1D(dataVector, 50.0);
        statistics.(fieldName).p975 = percentile1D(dataVector, 97.5);
    end
end

function envelopes = computeMonteCarloEnvelopes(resultCell, missionParameters)
    runCount = numel(resultCell);
    altitudeGrid_m = linspace(0.0, missionParameters.initial.altitude_m, 600).';

    maxTime_s = 0.0;
    for runIndex = 1:runCount
        maxTime_s = max(maxTime_s, resultCell{runIndex}.time_s(end));
    end
    timeGrid_s = linspace(0.0, maxTime_s, 600).';

    velocityByAltitude = NaN(numel(altitudeGrid_m), runCount);
    velocityByTime = NaN(numel(timeGrid_s), runCount);
    altitudeByTime = NaN(numel(timeGrid_s), runCount);
    decelByTime = NaN(numel(timeGrid_s), runCount);

    for runIndex = 1:runCount
        result = resultCell{runIndex};

        altitudeIncreasing = flipud(result.altitude_m(:));
        velocityIncreasing = flipud(result.velocityDown_mps(:));
        [uniqueAltitude_m, uniqueIndices] = unique(altitudeIncreasing, 'stable');
        uniqueVelocity_mps = velocityIncreasing(uniqueIndices);

        velocityByAltitude(:, runIndex) = interp1(uniqueAltitude_m, uniqueVelocity_mps, altitudeGrid_m, 'linear', NaN);
        velocityByTime(:, runIndex) = interp1(result.time_s, result.velocityDown_mps, timeGrid_s, 'linear', NaN);
        altitudeByTime(:, runIndex) = interp1(result.time_s, result.altitude_m, timeGrid_s, 'linear', NaN);
        decelByTime(:, runIndex) = interp1(result.time_s, result.decelerationUp_g, timeGrid_s, 'linear', NaN);
    end

    envelopes.altitudeGrid_m = altitudeGrid_m;
    envelopes.timeGrid_s = timeGrid_s;

    envelopes.velocityAltitude.mean = nanMeanAcrossRuns(velocityByAltitude);
    envelopes.velocityAltitude.p025 = nanPercentileAcrossRuns(velocityByAltitude, 2.5);
    envelopes.velocityAltitude.p975 = nanPercentileAcrossRuns(velocityByAltitude, 97.5);

    envelopes.velocityTime.mean = nanMeanAcrossRuns(velocityByTime);
    envelopes.velocityTime.p025 = nanPercentileAcrossRuns(velocityByTime, 2.5);
    envelopes.velocityTime.p975 = nanPercentileAcrossRuns(velocityByTime, 97.5);

    envelopes.altitudeTime.mean = nanMeanAcrossRuns(altitudeByTime);
    envelopes.altitudeTime.p025 = nanPercentileAcrossRuns(altitudeByTime, 2.5);
    envelopes.altitudeTime.p975 = nanPercentileAcrossRuns(altitudeByTime, 97.5);

    envelopes.decelerationTime.mean = nanMeanAcrossRuns(decelByTime);
    envelopes.decelerationTime.p025 = nanPercentileAcrossRuns(decelByTime, 2.5);
    envelopes.decelerationTime.p975 = nanPercentileAcrossRuns(decelByTime, 97.5);
end

function rowMean = nanMeanAcrossRuns(matrixValues)
    rowMean = NaN(size(matrixValues,1), 1);
    for rowIndex = 1:size(matrixValues,1)
        rowData = matrixValues(rowIndex, :);
        rowData = rowData(~isnan(rowData));
        if ~isempty(rowData)
            rowMean(rowIndex) = mean(rowData);
        end
    end
end

function rowPercentile = nanPercentileAcrossRuns(matrixValues, percentileValue)
    rowPercentile = NaN(size(matrixValues,1), 1);
    for rowIndex = 1:size(matrixValues,1)
        rowData = matrixValues(rowIndex, :);
        rowData = rowData(~isnan(rowData));
        if ~isempty(rowData)
            rowPercentile(rowIndex) = percentile1D(rowData, percentileValue);
        end
    end
end

function value = percentile1D(dataVector, percentileValue)
    sortedData = sort(dataVector(:));
    sortedData = sortedData(~isnan(sortedData));
    dataCount = numel(sortedData);

    if dataCount == 0
        value = NaN;
        return;
    elseif dataCount == 1
        value = sortedData(1);
        return;
    end

    fractionalIndex = 1.0 + (percentileValue/100.0) * (dataCount - 1.0);
    lowerIndex = floor(fractionalIndex);
    upperIndex = ceil(fractionalIndex);

    if lowerIndex == upperIndex
        value = sortedData(lowerIndex);
    else
        interpolationWeight = fractionalIndex - lowerIndex;
        value = sortedData(lowerIndex) * (1.0 - interpolationWeight) + sortedData(upperIndex) * interpolationWeight;
    end
end
