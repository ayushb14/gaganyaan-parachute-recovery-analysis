function plot_results_3D(trajectory3D, asymmetric3D, failureCases, outputFolder)
%PLOT_RESULTS_3D  Publication-style Step 4 plots and optional animation.

    if nargin < 4 || isempty(outputFolder)
        outputFolder = fullfile(pwd, 'gaganyaan_step4_outputs');
    end
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    set(0, 'DefaultAxesFontSize', 12);
    set(0, 'DefaultLineLineWidth', 1.8);

    %% 1. 3D trajectory
    figure('Name','Step 4: 3D Descent Trajectory','Color','w');
    hold on; grid on; box on;
    plot3(trajectory3D.x_m, trajectory3D.y_m, trajectory3D.altitude_m/1000, 'LineWidth', 2.2);
    xlabel('Downrange x (m)'); ylabel('Crossrange y (m)'); zlabel('Altitude (km)');
    title('3D Descent Trajectory with Wind Drift');
    view(38, 24);
    exportgraphics(gcf, fullfile(outputFolder, '15_3d_descent_trajectory.png'), 'Resolution', 200);

    %% 2. Horizontal drift vs time
    figure('Name','Step 4: Drift vs Time','Color','w');
    plot(trajectory3D.time_s, trajectory3D.horizontalDrift_m, 'LineWidth', 2.0);
    grid on; xlabel('Time (s)'); ylabel('Horizontal drift (m)');
    title('Horizontal Drift vs Time');
    exportgraphics(gcf, fullfile(outputFolder, '16_horizontal_drift_time.png'), 'Resolution', 200);

    %% 3. Pendulum oscillation
    figure('Name','Step 4: Pendulum Oscillation','Color','w');
    plot(trajectory3D.time_s, trajectory3D.theta_deg, 'LineWidth', 2.0);
    grid on; xlabel('Time (s)'); ylabel('Swing angle \theta (deg)');
    title('Parachute-Capsule Pendulum Oscillation');
    exportgraphics(gcf, fullfile(outputFolder, '17_pendulum_angle_time.png'), 'Resolution', 200);

    %% 4. Wind profile encountered
    figure('Name','Step 4: Wind History','Color','w');
    windSpeed = hypot(trajectory3D.windX_mps, trajectory3D.windY_mps);
    plot(windSpeed, trajectory3D.altitude_m/1000, 'LineWidth', 2.0);
    grid on; xlabel('Wind speed (m/s)'); ylabel('Altitude (km)');
    title('Wind Profile Encountered During Descent');
    exportgraphics(gcf, fullfile(outputFolder, '18_wind_profile.png'), 'Resolution', 200);

    %% 5. Asymmetric disreefing: riser tensions
    figure('Name','Step 4: Asymmetric Riser Tensions','Color','w');
    hold on; grid on; box on;
    vertical = asymmetric3D.verticalResult;
    plot(vertical.time_s, vertical.mainTension1_N/1000, 'LineWidth', 1.8);
    plot(vertical.time_s, vertical.mainTension2_N/1000, 'LineWidth', 1.8);
    plot(vertical.time_s, vertical.mainTension3_N/1000, 'LineWidth', 1.8);
    xlabel('Time (s)'); ylabel('Riser tension (kN)');
    title('Asymmetric Main Disreefing: Riser Tension Per Main Chute');
    legend('Main 1','Main 2 delayed','Main 3','Location','best');
    exportgraphics(gcf, fullfile(outputFolder, '19_asymmetric_riser_tensions.png'), 'Resolution', 200);

    %% 6. Asymmetric tilt response
    figure('Name','Step 4: Asymmetric Tilt Response','Color','w');
    plot(asymmetric3D.time_s, asymmetric3D.theta_deg, 'LineWidth', 2.0);
    grid on; xlabel('Time (s)'); ylabel('Swing / tilt proxy (deg)');
    title('Capsule Tilt Proxy During 0.5 s Asymmetric Main Disreefing');
    exportgraphics(gcf, fullfile(outputFolder, '20_asymmetric_tilt_response.png'), 'Resolution', 200);

    %% 7. Failure cases velocity-altitude
    figure('Name','Step 4: Main Failure Mode Velocity-Altitude','Color','w');
    hold on; grid on; box on;
    plot(failureCases.all3.verticalResult.velocityDown_mps, failureCases.all3.verticalResult.altitude_m/1000, 'LineWidth', 2.0);
    plot(failureCases.twoOf3.verticalResult.velocityDown_mps, failureCases.twoOf3.verticalResult.altitude_m/1000, 'LineWidth', 2.0);
    plot(failureCases.oneOf3.verticalResult.velocityDown_mps, failureCases.oneOf3.verticalResult.altitude_m/1000, 'LineWidth', 2.0);
    xlabel('Downward velocity (m/s)'); ylabel('Altitude (km)');
    title('Main Parachute Failure Mode Comparison');
    legend('3 mains nominal','2 of 3 mains','1 of 3 mains','Location','best');
    exportgraphics(gcf, fullfile(outputFolder, '21_failure_modes_velocity_altitude.png'), 'Resolution', 200);

    %% 8. Simple canopy visualization snapshot at main phase
    figure('Name','Step 4: Canopy Snapshot','Color','w');
    hold on; grid on; axis equal; box on;
    plot3(trajectory3D.x_m, trajectory3D.y_m, trajectory3D.altitude_m/1000, 'k', 'LineWidth', 1.5);
    snapshotIndex = find(trajectory3D.stageId == 2, 1, 'first');
    if ~isempty(snapshotIndex)
        drawCanopySnapshot(trajectory3D.x_m(snapshotIndex), trajectory3D.y_m(snapshotIndex), ...
            trajectory3D.altitude_m(snapshotIndex)/1000, 25.0/1000);
    end
    xlabel('x (m)'); ylabel('y (m)'); zlabel('Altitude (km)');
    title('3D Trajectory with Simplified Main Canopy Snapshot');
    view(40, 25);
    exportgraphics(gcf, fullfile(outputFolder, '22_canopy_snapshot.png'), 'Resolution', 200);
end

function drawCanopySnapshot(x_m, y_m, z_km, diameter_km)
    [az, el] = meshgrid(linspace(0, 2*pi, 30), linspace(0, pi/2, 12));
    radius = diameter_km/2;
    x = x_m + radius*cos(az).*sin(el)*1000;
    y = y_m + radius*sin(az).*sin(el)*1000;
    z = z_km + radius*cos(el);
    surf(x, y, z, 'FaceAlpha', 0.35, 'EdgeAlpha', 0.15);
end
