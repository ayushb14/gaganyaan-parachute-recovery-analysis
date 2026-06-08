function figureHandles = plot_results_2D(descentResult, outputFolder)
%PLOT_RESULTS_2D  Generate Step 2 publication-style plots and save PNG files.

    if nargin < 2 || isempty(outputFolder)
        outputFolder = descentResult.missionParameters.outputFolder;
    end
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    set(0, 'DefaultAxesFontSize', 12);
    set(0, 'DefaultLineLineWidth', 1.8);

    figureHandles = struct();
    eventInfo = buildEventInfo(descentResult);

    %% 1. Altitude vs time
    figureHandles.altitudeTime = figure('Name','Altitude vs Time','Color','w');
    plot(descentResult.time_s, descentResult.altitude_m/1000, 'LineWidth', 2.0);
    grid on; xlabel('Time (s)'); ylabel('Altitude (km)');
    title('Gaganyaan-Type Descent: Altitude vs Time');
    addEventLines(eventInfo);
    saveFigure(figureHandles.altitudeTime, outputFolder, '01_altitude_vs_time.png');

    %% 2. Velocity vs time
    figureHandles.velocityTime = figure('Name','Velocity vs Time','Color','w');
    plot(descentResult.time_s, descentResult.velocityDown_mps, 'LineWidth', 2.0);
    grid on; xlabel('Time (s)'); ylabel('Downward Velocity (m/s)');
    title('Velocity vs Time with Deployment Events');
    addEventLines(eventInfo);
    saveFigure(figureHandles.velocityTime, outputFolder, '02_velocity_vs_time.png');

    %% 3. Dynamic pressure vs altitude
    figureHandles.qAltitude = figure('Name','Dynamic Pressure vs Altitude','Color','w');
    plot(descentResult.dynamicPressure_Pa/1000, descentResult.altitude_m/1000, 'LineWidth', 2.0);
    grid on; xlabel('Dynamic Pressure, q (kPa)'); ylabel('Altitude (km)');
    title('Dynamic Pressure vs Altitude');
    xline(12, '--', '12 kPa reference', 'LabelVerticalAlignment','bottom');
    saveFigure(figureHandles.qAltitude, outputFolder, '03_dynamic_pressure_vs_altitude.png');

    %% 4. Deceleration g-load vs time
    figureHandles.decelerationTime = figure('Name','Deceleration vs Time','Color','w');
    plot(descentResult.time_s, descentResult.decelerationUp_g, 'LineWidth', 2.0);
    grid on; xlabel('Time (s)'); ylabel('Upward Deceleration (g)');
    title('Deceleration / g-load vs Time');
    addEventLines(eventInfo);
    saveFigure(figureHandles.decelerationTime, outputFolder, '04_deceleration_vs_time.png');

    %% 5. Drag components vs time
    figureHandles.dragTime = figure('Name','Drag Components vs Time','Color','w');
    area(descentResult.time_s, [descentResult.capsuleDrag_N, descentResult.drogueDrag_N, descentResult.mainDrag_N]/1000);
    grid on; xlabel('Time (s)'); ylabel('Drag Force (kN)');
    title('Stacked Drag Contributions');
    legend('Capsule','Drogue','Main','Location','best');
    addEventLines(eventInfo);
    saveFigure(figureHandles.dragTime, outputFolder, '05_drag_components_vs_time.png');

    %% 6. Effective Cd vs Mach number
    capsuleReferenceArea_m2 = pi * descentResult.missionParameters.capsule.diameter_m^2 / 4;
    effectiveCd = descentResult.totalCdA_m2 ./ capsuleReferenceArea_m2;
    figureHandles.cdMach = figure('Name','Cd Effective vs Mach','Color','w');
    scatter(descentResult.machNumber, effectiveCd, 18, descentResult.altitude_m/1000, 'filled');
    grid on; colorbar; xlabel('Mach Number'); ylabel('Effective C_D using capsule reference area');
    title('Effective C_D vs Mach Number');
    saveFigure(figureHandles.cdMach, outputFolder, '06_cd_effective_vs_mach.png');

    %% 7. Velocity-altitude coloured by stage
    figureHandles.velocityAltitude = figure('Name','Velocity Altitude by Stage','Color','w');
    hold on; grid on;
    stageNames = {'Capsule/ACS','Drogue','Main'};
    for stageId = 0:2
        mask = descentResult.stageId == stageId;
        if any(mask)
            plot(descentResult.velocityDown_mps(mask), descentResult.altitude_m(mask)/1000, 'LineWidth', 2.0);
        end
    end
    xlabel('Downward Velocity (m/s)'); ylabel('Altitude (km)');
    title('Velocity-Altitude Trajectory by Stage');
    legend(stageNames, 'Location','best');
    saveFigure(figureHandles.velocityAltitude, outputFolder, '07_velocity_altitude_by_stage.png');

    %% 8. Energy dissipation vs time
    figureHandles.energyTime = figure('Name','Energy Removed vs Time','Color','w');
    plot(descentResult.time_s, descentResult.kineticEnergyRemoved_J/1e6, 'LineWidth', 2.0);
    grid on; xlabel('Time (s)'); ylabel('Kinetic Energy Removed (MJ)');
    title('Kinetic Energy Removed vs Time');
    addEventLines(eventInfo);
    saveFigure(figureHandles.energyTime, outputFolder, '08_energy_removed_vs_time.png');

    %% 9. Stage activation Gantt timeline
    figureHandles.gantt = figure('Name','Parachute Stage Timeline','Color','w');
    hold on; grid on;
    yNames = {'Capsule/ACS','Drogue','Main'};
    for stageId = 0:2
        mask = descentResult.stageId == stageId;
        if any(mask)
            xStart = min(descentResult.time_s(mask));
            xEnd = max(descentResult.time_s(mask));
            rectangle('Position', [xStart, stageId+0.65, xEnd-xStart, 0.7], 'FaceColor', [0.75 0.75 0.75], 'EdgeColor','k');
            text((xStart+xEnd)/2, stageId+1.0, yNames{stageId+1}, 'HorizontalAlignment','center');
        end
    end
    xlabel('Time (s)'); yticks(1:3); yticklabels(yNames); ylim([0.5 3.8]);
    title('Parachute Stage Activation Timeline');
    saveFigure(figureHandles.gantt, outputFolder, '09_stage_activation_gantt.png');
end

function eventInfo = buildEventInfo(descentResult)
    eventInfo.times = [descentResult.events.drogueTime_s, descentResult.events.mainTime_s, descentResult.events.touchdownTime_s];
    eventInfo.labels = {'Drogue deploy','Main deploy','Touchdown'};
end

function addEventLines(eventInfo)
    yLimits = ylim;
    for eventIndex = 1:numel(eventInfo.times)
        eventTime = eventInfo.times(eventIndex);
        if ~isnan(eventTime)
            xline(eventTime, '--', eventInfo.labels{eventIndex}, 'LabelOrientation','horizontal', ...
                'LabelVerticalAlignment','bottom');
        end
    end
    ylim(yLimits);
end

function saveFigure(figureHandle, outputFolder, fileName)
    filePath = fullfile(outputFolder, fileName);
    try
        exportgraphics(figureHandle, filePath, 'Resolution', 300);
    catch
        saveas(figureHandle, filePath);
    end
end
