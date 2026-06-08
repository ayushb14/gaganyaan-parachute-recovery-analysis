% MAIN_STEP3  Monte Carlo uncertainty runner for Gaganyaan-type parachute descent.
%
% Run this file only after Step 2 is working.
% For quick testing, set monteCarloOptions.runCount = 100.
% For the research-level run, keep it at 1000.

clear; clc; close all;

missionParameters = mission_parameters('PUBLIC_6500_RESEARCH');
missionParameters.outputFolder = fullfile(pwd, 'gaganyaan_step3_outputs');

if ~exist(missionParameters.outputFolder, 'dir')
    mkdir(missionParameters.outputFolder);
end

% Nominal baseline for comparison.
nominalOptions = struct();
nominalOptions.mainQuantityActive = 3;
nominalOptions.densityScaleFactor = 1.0;
nominalOptions.massScaleFactor = 1.0;
nominalResult = descent_2D(missionParameters, nominalOptions);

% Monte Carlo settings.
monteCarloOptions = struct();
monteCarloOptions.runCount = 1000;
monteCarloOptions.randomSeed = 42;
monteCarloOptions.cdUncertaintyFraction = 0.10;
monteCarloOptions.massUncertainty_kg = 50.0;
monteCarloOptions.deploymentAltitudeJitter_m = 200.0;
monteCarloOptions.densityUncertaintyFraction = 0.03;

monteCarloResult = monte_carlo(missionParameters, monteCarloOptions);
plot_monte_carlo_results(monteCarloResult, nominalResult, missionParameters.outputFolder);

% Save summary and sample tables.
writetable(monteCarloResult.samples, fullfile(missionParameters.outputFolder, 'step3_monte_carlo_samples.csv'));
summaryTable = buildSummaryTable(monteCarloResult);
writetable(summaryTable, fullfile(missionParameters.outputFolder, 'step3_monte_carlo_summary.csv'));

fprintf('\n============================================\n');
fprintf(' GAGANYAAN MONTE CARLO UNCERTAINTY SUMMARY\n');
fprintf('============================================\n');
fprintf(' Runs:                         %d\n', monteCarloOptions.runCount);
fprintf(' Touchdown velocity mean:      %.2f m/s\n', monteCarloResult.statistics.touchdownVelocity_mps.mean);
fprintf(' Touchdown velocity 95%% CI:    %.2f to %.2f m/s\n', ...
    monteCarloResult.statistics.touchdownVelocity_mps.p025, monteCarloResult.statistics.touchdownVelocity_mps.p975);
fprintf(' Total descent time mean:      %.2f s\n', monteCarloResult.statistics.totalDescentTime_s.mean);
fprintf(' Total descent time 95%% CI:    %.2f to %.2f s\n', ...
    monteCarloResult.statistics.totalDescentTime_s.p025, monteCarloResult.statistics.totalDescentTime_s.p975);
fprintf(' Peak deceleration mean:       %.2f g\n', monteCarloResult.statistics.peakDeceleration_g.mean);
fprintf(' Peak deceleration 95%% CI:     %.2f to %.2f g\n', ...
    monteCarloResult.statistics.peakDeceleration_g.p025, monteCarloResult.statistics.peakDeceleration_g.p975);
fprintf(' Output folder:                %s\n', missionParameters.outputFolder);
fprintf('============================================\n');

fprintf('\nStep 3 complete. Check the output folder for Monte Carlo PNG plots and CSV data.\n');

function summaryTable = buildSummaryTable(monteCarloResult)
    metricNames = {'touchdownVelocity_mps'; 'totalDescentTime_s'; 'peakDeceleration_g'};
    meanValues = zeros(numel(metricNames),1);
    standardDeviationValues = zeros(numel(metricNames),1);
    minimumValues = zeros(numel(metricNames),1);
    maximumValues = zeros(numel(metricNames),1);
    p025Values = zeros(numel(metricNames),1);
    p050Values = zeros(numel(metricNames),1);
    p975Values = zeros(numel(metricNames),1);

    for metricIndex = 1:numel(metricNames)
        metricName = metricNames{metricIndex};
        stats = monteCarloResult.statistics.(metricName);
        meanValues(metricIndex) = stats.mean;
        standardDeviationValues(metricIndex) = stats.standardDeviation;
        minimumValues(metricIndex) = stats.minimum;
        maximumValues(metricIndex) = stats.maximum;
        p025Values(metricIndex) = stats.p025;
        p050Values(metricIndex) = stats.p050;
        p975Values(metricIndex) = stats.p975;
    end

    summaryTable = table(metricNames, meanValues, standardDeviationValues, minimumValues, maximumValues, ...
        p025Values, p050Values, p975Values, ...
        'VariableNames', {'metric','mean','standardDeviation','minimum','maximum','p025','p050','p975'});
end
