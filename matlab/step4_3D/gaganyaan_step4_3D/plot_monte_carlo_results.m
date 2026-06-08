function figureHandles = plot_monte_carlo_results(monteCarloResult, nominalResult, outputFolder)
%PLOT_MONTE_CARLO_RESULTS  Save publication-style Monte Carlo uncertainty plots.

    if nargin < 3 || isempty(outputFolder)
        outputFolder = fullfile(pwd, 'gaganyaan_step3_outputs');
    end
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    set(0, 'DefaultAxesFontSize', 12);
    set(0, 'DefaultLineLineWidth', 1.8);

    figureHandles = struct();
    envelopes = monteCarloResult.envelopes;
    samples = monteCarloResult.samples;

    %% 11. Monte Carlo velocity-altitude 95% confidence envelope
    figureHandles.velocityAltitudeEnvelope = figure('Name','Monte Carlo Velocity-Altitude Envelope','Color','w');
    hold on; grid on;
    plotShadedBand(envelopes.velocityAltitude.p025, envelopes.altitudeGrid_m/1000, ...
                   envelopes.velocityAltitude.p975, envelopes.altitudeGrid_m/1000);
    plot(envelopes.velocityAltitude.mean, envelopes.altitudeGrid_m/1000, 'k', 'LineWidth', 2.2);
    plot(nominalResult.velocityDown_mps, nominalResult.altitude_m/1000, '--', 'LineWidth', 1.8);
    xlabel('Downward Velocity (m/s)');
    ylabel('Altitude (km)');
    title('Monte Carlo 95% Confidence Envelope: Velocity vs Altitude');
    legend('95% confidence band','Monte Carlo mean','Nominal case','Location','best');
    saveFigure(figureHandles.velocityAltitudeEnvelope, outputFolder, '11_monte_carlo_velocity_altitude_95ci.png');

    %% 12. Monte Carlo altitude-time and velocity-time bands
    figureHandles.timeBands = figure('Name','Monte Carlo Time History Bands','Color','w');
    tiledlayout(2,1, 'TileSpacing','compact');

    nexttile; hold on; grid on;
    plotShadedBand(envelopes.timeGrid_s, envelopes.altitudeTime.p025/1000, ...
                   envelopes.timeGrid_s, envelopes.altitudeTime.p975/1000);
    plot(envelopes.timeGrid_s, envelopes.altitudeTime.mean/1000, 'k', 'LineWidth', 2.0);
    plot(nominalResult.time_s, nominalResult.altitude_m/1000, '--', 'LineWidth', 1.6);
    xlabel('Time (s)'); ylabel('Altitude (km)');
    title('Altitude-Time 95% Confidence Band');
    legend('95% band','Mean','Nominal','Location','best');

    nexttile; hold on; grid on;
    plotShadedBand(envelopes.timeGrid_s, envelopes.velocityTime.p025, ...
                   envelopes.timeGrid_s, envelopes.velocityTime.p975);
    plot(envelopes.timeGrid_s, envelopes.velocityTime.mean, 'k', 'LineWidth', 2.0);
    plot(nominalResult.time_s, nominalResult.velocityDown_mps, '--', 'LineWidth', 1.6);
    xlabel('Time (s)'); ylabel('Downward Velocity (m/s)');
    title('Velocity-Time 95% Confidence Band');
    legend('95% band','Mean','Nominal','Location','best');
    saveFigure(figureHandles.timeBands, outputFolder, '12_monte_carlo_time_history_95ci.png');

    %% 13. Output distributions
    figureHandles.histograms = figure('Name','Monte Carlo Output Distributions','Color','w');
    tiledlayout(3,1, 'TileSpacing','compact');

    nexttile;
    histogram(samples.touchdownVelocity_mps, 30);
    grid on; xlabel('Touchdown Velocity (m/s)'); ylabel('Count');
    title('Touchdown Velocity Distribution');

    nexttile;
    histogram(samples.totalDescentTime_s, 30);
    grid on; xlabel('Total Descent Time (s)'); ylabel('Count');
    title('Total Descent Time Distribution');

    nexttile;
    histogram(samples.peakDeceleration_g, 30);
    grid on; xlabel('Peak Deceleration (g)'); ylabel('Count');
    title('Peak Deceleration Distribution');
    saveFigure(figureHandles.histograms, outputFolder, '13_monte_carlo_output_histograms.png');

    %% 14. Deceleration-time uncertainty band
    figureHandles.decelerationBand = figure('Name','Monte Carlo Deceleration Band','Color','w');
    hold on; grid on;
    plotShadedBand(envelopes.timeGrid_s, envelopes.decelerationTime.p025, ...
                   envelopes.timeGrid_s, envelopes.decelerationTime.p975);
    plot(envelopes.timeGrid_s, envelopes.decelerationTime.mean, 'k', 'LineWidth', 2.0);
    plot(nominalResult.time_s, nominalResult.decelerationUp_g, '--', 'LineWidth', 1.6);
    xlabel('Time (s)'); ylabel('Upward Deceleration (g)');
    title('Deceleration 95% Confidence Band');
    legend('95% band','Mean','Nominal','Location','best');
    saveFigure(figureHandles.decelerationBand, outputFolder, '14_monte_carlo_deceleration_95ci.png');
end

function plotShadedBand(xLow, yLow, xHigh, yHigh)
    validMask = ~isnan(xLow) & ~isnan(yLow) & ~isnan(xHigh) & ~isnan(yHigh);
    if any(validMask)
        fill([xLow(validMask); flipud(xHigh(validMask))], ...
             [yLow(validMask); flipud(yHigh(validMask))], ...
             [0.80 0.80 0.80], 'EdgeColor','none', 'FaceAlpha',0.65);
    end
end

function saveFigure(figureHandle, outputFolder, fileName)
    filePath = fullfile(outputFolder, fileName);
    try
        exportgraphics(figureHandle, filePath, 'Resolution', 300);
    catch
        saveas(figureHandle, filePath);
    end
end
