%% COLLECT_STEP_OUTPUTS
% Copies selected result files from Step 2, Step 3, and Step 4 output folders
% into a single final_report_assets folder.
%
% EDIT THESE PATHS according to your local extracted folders before running.

clear; clc;

step2OutputFolder = "D:\Downloads\gaganyaan_step2_descent2D\gaganyaan_step2_descent2D\gaganyaan_step2_outputs";
step3OutputFolder = "D:\Downloads\gaganyaan_step3_montecarlo\gaganyaan_step3_montecarlo\gaganyaan_step3_outputs";
step4OutputFolder = "D:\Downloads\gaganyaan_step4_3D\gaganyaan_step4_3D\gaganyaan_step4_outputs";

finalAssetFolder = fullfile(pwd, "final_report_assets");
if ~exist(finalAssetFolder, 'dir')
    mkdir(finalAssetFolder);
end

sourceFolders = [step2OutputFolder, step3OutputFolder, step4OutputFolder];

for folderIndex = 1:numel(sourceFolders)
    currentFolder = sourceFolders(folderIndex);
    if ~exist(currentFolder, 'dir')
        warning('Folder not found: %s', currentFolder);
        continue;
    end

    pngFiles = dir(fullfile(currentFolder, '*.png'));
    csvFiles = dir(fullfile(currentFolder, '*.csv'));
    gifFiles = dir(fullfile(currentFolder, '*.gif'));
    allFiles = [pngFiles; csvFiles; gifFiles];

    for fileIndex = 1:numel(allFiles)
        sourceFile = fullfile(allFiles(fileIndex).folder, allFiles(fileIndex).name);
        destinationFile = fullfile(finalAssetFolder, allFiles(fileIndex).name);
        copyfile(sourceFile, destinationFile);
    end
end

fprintf('\nCollected outputs into: %s\n', finalAssetFolder);
