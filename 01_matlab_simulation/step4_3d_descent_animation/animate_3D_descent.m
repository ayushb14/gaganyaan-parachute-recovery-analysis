function animationFiles = animate_3D_descent(trajectory3D, outputFolder, animationOptions)
%ANIMATE_3D_DESCENT  Create a real 3D time animation for the parachute descent.
%
% Usage:
%   animationFiles = animate_3D_descent(nominal3D, outputFolder);
%
% Inputs:
%   trajectory3D     Struct returned by descent_3D.m
%   outputFolder     Folder where GIF/AVI will be saved
%   animationOptions Optional struct:
%       .frameCount              Number of animation frames, default 240
%       .gifFileName             Default '23_3d_descent_animation.gif'
%       .aviFileName             Default '23_3d_descent_animation.avi'
%       .saveGif                 true/false, default true
%       .saveAvi                 true/false, default true
%       .playInFigure            true/false, default true
%       .visualCanopyScale       Visual scale for canopy only, default 8
%       .frameDelay_s            GIF frame delay, default 0.04
%
% Notes:
%   Axes are in metres. Canopy is visually enlarged by visualCanopyScale so
%   it is visible compared with the 15 km vertical trajectory. This does not
%   change the simulation data.

    if nargin < 2 || isempty(outputFolder)
        outputFolder = fullfile(pwd, 'gaganyaan_step4_outputs');
    end
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    if nargin < 3 || isempty(animationOptions)
        animationOptions = struct();
    end

    animationOptions = fillAnimationDefaults(animationOptions);

    gifPath = fullfile(outputFolder, animationOptions.gifFileName);
    aviPath = fullfile(outputFolder, animationOptions.aviFileName);

    animationFiles = struct();
    animationFiles.gifPath = gifPath;
    animationFiles.aviPath = aviPath;

    time_s = trajectory3D.time_s(:);
    x_m = trajectory3D.x_m(:);
    y_m = trajectory3D.y_m(:);
    altitude_m = trajectory3D.altitude_m(:);
    velocityDown_mps = trajectory3D.velocityDown_mps(:);
    theta_deg = trajectory3D.theta_deg(:);
    stageId = trajectory3D.stageId(:);

    validIndex = altitude_m >= 0 & ~isnan(x_m) & ~isnan(y_m) & ~isnan(altitude_m);
    time_s = time_s(validIndex);
    x_m = x_m(validIndex);
    y_m = y_m(validIndex);
    altitude_m = altitude_m(validIndex);
    velocityDown_mps = velocityDown_mps(validIndex);
    theta_deg = theta_deg(validIndex);
    stageId = stageId(validIndex);

    frameCount = min(animationOptions.frameCount, numel(time_s));
    frameTimes = linspace(time_s(1), time_s(end), frameCount);

    xFrame_m = interp1(time_s, x_m, frameTimes, 'linear');
    yFrame_m = interp1(time_s, y_m, frameTimes, 'linear');
    zFrame_m = interp1(time_s, altitude_m, frameTimes, 'linear');
    vFrame_mps = interp1(time_s, velocityDown_mps, frameTimes, 'linear');
    thetaFrame_deg = interp1(time_s, theta_deg, frameTimes, 'linear');
    stageFrame = interp1(time_s, stageId, frameTimes, 'nearest');

    horizontalMargin_m = max(200, 0.15*max(hypot(x_m, y_m)));
    xLimits = [min(x_m)-horizontalMargin_m, max(x_m)+horizontalMargin_m];
    yLimits = [min(y_m)-horizontalMargin_m, max(y_m)+horizontalMargin_m];
    zLimits = [0, max(altitude_m)*1.05];

    figureHandle = figure('Name','Animated 3D Gaganyaan Descent','Color','w');
    axesHandle = axes('Parent', figureHandle);
    hold(axesHandle, 'on');
    grid(axesHandle, 'on');
    box(axesHandle, 'on');
    view(axesHandle, 42, 24);
    xlabel(axesHandle, 'Downrange x (m)');
    ylabel(axesHandle, 'Crossrange y (m)');
    zlabel(axesHandle, 'Altitude (m)');
    title(axesHandle, 'Animated 3D Descent: Capsule + Parachute System');
    xlim(axesHandle, xLimits);
    ylim(axesHandle, yLimits);
    zlim(axesHandle, zLimits);

    % Plot the full trajectory as a light reference line, then animate the
    % travelled path and vehicle/canopy marker.
    plot3(axesHandle, x_m, y_m, altitude_m, ':', 'LineWidth', 1.0);
    travelledLine = plot3(axesHandle, nan, nan, nan, 'k-', 'LineWidth', 2.0);
    capsuleMarker = plot3(axesHandle, nan, nan, nan, 'ko', 'MarkerSize', 7, 'MarkerFaceColor', 'k');
    windArrow = quiver3(axesHandle, 0, 0, 0, 0, 0, 0, 0, 'LineWidth', 1.5, 'MaxHeadSize', 1.5);
    infoText = text(axesHandle, xLimits(1), yLimits(1), zLimits(2)*0.95, '', 'FontSize', 11, 'FontWeight', 'bold');

    canopySurface = [];
    riserLines = gobjects(4,1);
    for riserIndex = 1:numel(riserLines)
        riserLines(riserIndex) = plot3(axesHandle, nan, nan, nan, 'LineWidth', 1.0);
    end

    if animationOptions.saveAvi
        videoWriter = VideoWriter(aviPath, 'Motion JPEG AVI');
        videoWriter.FrameRate = max(1, round(1/animationOptions.frameDelay_s));
        open(videoWriter);
    else
        videoWriter = [];
    end

    for frameIndex = 1:frameCount
        currentX_m = xFrame_m(frameIndex);
        currentY_m = yFrame_m(frameIndex);
        currentZ_m = zFrame_m(frameIndex);
        currentStage = stageFrame(frameIndex);

        set(travelledLine, 'XData', xFrame_m(1:frameIndex), ...
                           'YData', yFrame_m(1:frameIndex), ...
                           'ZData', zFrame_m(1:frameIndex));
        set(capsuleMarker, 'XData', currentX_m, 'YData', currentY_m, 'ZData', currentZ_m);

        if isgraphics(canopySurface)
            delete(canopySurface);
        end
        for riserIndex = 1:numel(riserLines)
            if isgraphics(riserLines(riserIndex))
                set(riserLines(riserIndex), 'XData', nan, 'YData', nan, 'ZData', nan);
            end
        end

        stageName = stageNameFromId(currentStage);
        [canopyDiameter_m, riserLength_m] = canopyGeometryFromStage(currentStage);
        if canopyDiameter_m > 0
            [canopyX_m, canopyY_m, canopyZ_m, riserAnchorPoints] = canopySurfaceGeometry( ...
                currentX_m, currentY_m, currentZ_m, canopyDiameter_m, riserLength_m, animationOptions.visualCanopyScale);
            canopySurface = surf(axesHandle, canopyX_m, canopyY_m, canopyZ_m, ...
                'FaceAlpha', 0.35, 'EdgeAlpha', 0.12);

            for riserIndex = 1:size(riserAnchorPoints,1)
                set(riserLines(riserIndex), 'XData', [currentX_m, riserAnchorPoints(riserIndex,1)], ...
                                            'YData', [currentY_m, riserAnchorPoints(riserIndex,2)], ...
                                            'ZData', [currentZ_m, riserAnchorPoints(riserIndex,3)]);
            end
        end

        % Wind arrow near current capsule point.
        windScale = 40;
        windX_mps = interp1(time_s, trajectory3D.windX_mps(validIndex), frameTimes(frameIndex), 'linear');
        windY_mps = interp1(time_s, trajectory3D.windY_mps(validIndex), frameTimes(frameIndex), 'linear');
        set(windArrow, 'XData', currentX_m, 'YData', currentY_m, 'ZData', currentZ_m, ...
            'UData', windScale*windX_mps, 'VData', windScale*windY_mps, 'WData', 0);

        set(infoText, 'String', sprintf(['t = %.1f s | h = %.0f m | V_d = %.1f m/s\n', ...
            'Stage: %s | Swing = %.1f deg | Canopy visual scale = %.1fx'], ...
            frameTimes(frameIndex), currentZ_m, vFrame_mps(frameIndex), stageName, ...
            thetaFrame_deg(frameIndex), animationOptions.visualCanopyScale));

        drawnow;

        frame = getframe(figureHandle);
        if animationOptions.saveGif
            [indexedImage, colorMap] = rgb2ind(frame2im(frame), 256);
            if frameIndex == 1
                imwrite(indexedImage, colorMap, gifPath, 'gif', 'LoopCount', inf, 'DelayTime', animationOptions.frameDelay_s);
            else
                imwrite(indexedImage, colorMap, gifPath, 'gif', 'WriteMode', 'append', 'DelayTime', animationOptions.frameDelay_s);
            end
        end
        if animationOptions.saveAvi
            writeVideo(videoWriter, frame);
        end
    end

    if animationOptions.saveAvi
        close(videoWriter);
    end

    if ~animationOptions.playInFigure
        close(figureHandle);
    end
end

function animationOptions = fillAnimationDefaults(animationOptions)
    defaults.frameCount = 240;
    defaults.gifFileName = '23_3d_descent_animation.gif';
    defaults.aviFileName = '23_3d_descent_animation.avi';
    defaults.saveGif = true;
    defaults.saveAvi = true;
    defaults.playInFigure = true;
    defaults.visualCanopyScale = 8.0;
    defaults.frameDelay_s = 0.04;

    names = fieldnames(defaults);
    for index = 1:numel(names)
        if ~isfield(animationOptions, names{index}) || isempty(animationOptions.(names{index}))
            animationOptions.(names{index}) = defaults.(names{index});
        end
    end
end

function stageName = stageNameFromId(stageId)
    if stageId < 0.5
        stageName = 'Capsule / pre-drogue';
    elseif stageId < 1.5
        stageName = 'Drogue phase';
    else
        stageName = 'Main parachute phase';
    end
end

function [canopyDiameter_m, riserLength_m] = canopyGeometryFromStage(stageId)
    if stageId < 0.5
        canopyDiameter_m = 0;
        riserLength_m = 0;
    elseif stageId < 1.5
        canopyDiameter_m = 5.8;
        riserLength_m = 18.0;
    else
        canopyDiameter_m = 25.0;
        riserLength_m = 30.0;
    end
end

function [canopyX_m, canopyY_m, canopyZ_m, riserAnchorPoints] = canopySurfaceGeometry( ...
    capsuleX_m, capsuleY_m, capsuleZ_m, canopyDiameter_m, riserLength_m, visualCanopyScale)

    visualRadius_m = 0.5 * canopyDiameter_m * visualCanopyScale;
    visualRiser_m = riserLength_m * visualCanopyScale;

    canopyCenterX_m = capsuleX_m;
    canopyCenterY_m = capsuleY_m;
    canopyCenterZ_m = capsuleZ_m + visualRiser_m;

    [azimuth, elevation] = meshgrid(linspace(0, 2*pi, 36), linspace(0, pi/2, 14));
    canopyX_m = canopyCenterX_m + visualRadius_m*cos(azimuth).*sin(elevation);
    canopyY_m = canopyCenterY_m + visualRadius_m*sin(azimuth).*sin(elevation);
    canopyZ_m = canopyCenterZ_m + 0.45*visualRadius_m*cos(elevation);

    anchorAngles = deg2rad([45, 135, 225, 315]);
    riserAnchorPoints = zeros(numel(anchorAngles),3);
    for index = 1:numel(anchorAngles)
        riserAnchorPoints(index,1) = canopyCenterX_m + visualRadius_m*cos(anchorAngles(index));
        riserAnchorPoints(index,2) = canopyCenterY_m + visualRadius_m*sin(anchorAngles(index));
        riserAnchorPoints(index,3) = canopyCenterZ_m;
    end
end
