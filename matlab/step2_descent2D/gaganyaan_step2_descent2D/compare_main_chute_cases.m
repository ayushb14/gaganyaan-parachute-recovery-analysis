function comparisonResult = compare_main_chute_cases(missionParameters, outputFolder)
%COMPARE_MAIN_CHUTE_CASES  Compare 3-main, 2-main, and 1-main touchdown cases.

    if nargin < 1 || isempty(missionParameters)
        missionParameters = mission_parameters();
    end
    if nargin < 2 || isempty(outputFolder)
        outputFolder = missionParameters.outputFolder;
    end
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    activeMainCounts = [3, 2, 1];
    caseLabels = {'3 mains nominal','2 mains redundancy','1 main failure'};
    caseResults = cell(size(activeMainCounts));

    for caseIndex = 1:numel(activeMainCounts)
        options = struct();
        options.mainQuantityActive = activeMainCounts(caseIndex);
        caseResults{caseIndex} = descent_2D(missionParameters, options);
    end

    figureHandle = figure('Name','Main Chute Redundancy Comparison','Color','w');
    hold on; grid on;
    for caseIndex = 1:numel(activeMainCounts)
        plot(caseResults{caseIndex}.velocityDown_mps, caseResults{caseIndex}.altitude_m/1000, 'LineWidth', 2.0);
    end
    xlabel('Downward Velocity (m/s)');
    ylabel('Altitude (km)');
    title('Main Parachute Redundancy: Velocity-Altitude Comparison');
    legend(caseLabels, 'Location','best');
    try
        exportgraphics(figureHandle, fullfile(outputFolder, '10_main_chute_redundancy_comparison.png'), 'Resolution', 300);
    catch
        saveas(figureHandle, fullfile(outputFolder, '10_main_chute_redundancy_comparison.png'));
    end

    fprintf('\n--- Main chute redundancy comparison ---\n');
    for caseIndex = 1:numel(activeMainCounts)
        fprintf('%s: touchdown velocity = %.2f m/s, total time = %.2f s, peak decel = %.2f g\n', ...
            caseLabels{caseIndex}, caseResults{caseIndex}.summary.touchdownVelocity_mps, ...
            caseResults{caseIndex}.summary.totalDescentTime_s, ...
            caseResults{caseIndex}.summary.peakDeceleration_g);
    end

    comparisonResult.activeMainCounts = activeMainCounts;
    comparisonResult.caseLabels = caseLabels;
    comparisonResult.caseResults = caseResults;
end
