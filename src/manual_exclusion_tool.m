%% manual_exclusion_tool.m — Interactive GUI for manual road mask correction
%   Run this script in MATLAB to draw polygons and manually correct the mask.
%   No toolboxes are required (uses standard image, ginput, and inpolygon).

projRoot = 'D:\UI_Project';
srcDir = fullfile(projRoot, 'src');
imgPath = fullfile(projRoot, 'MapForUI.jpg');
savePath = fullfile(srcDir, 'manual_exclusions.mat');

img = imread(imgPath);
[H, W, ~] = size(img);

% Initialize or load existing corrections
exclusion_mask = false(H, W);
inclusion_mask = false(H, W);

if exist(savePath, 'file')
    fprintf('Loading existing manual corrections from manual_exclusions.mat...\n');
    load(savePath, 'exclusion_mask', 'inclusion_mask');
end

[colsGrid, rowsGrid] = meshgrid(1:W, 1:H);

while true
    fprintf('\n==================================================\n');
    fprintf('   MATLAB Manual Road Mask Interactive Tool\n');
    fprintf('==================================================\n');
    fprintf('1. Draw EXCLUSION zone (Force Green - Remove Road)\n');
    fprintf('2. Draw INCLUSION zone (Force Purple - Keep Road)\n');
    fprintf('3. Clear all custom corrections\n');
    fprintf('4. Save and Exit\n');
    
    choice = input('Please select an option (1-4): ');
    
    if isempty(choice) || ~ismember(choice, 1:4)
        continue;
    end
    
    if choice == 4
        % Save and exit
        save(savePath, 'exclusion_mask', 'inclusion_mask');
        fprintf('Saved corrections to %s. Exiting tool.\n', savePath);
        
        % Run the export script automatically to show new results
        fprintf('Running verify_and_export.m to generate new road_comparison.png...\n');
        run(fullfile(projRoot, 'scripts', 'verify_and_export.m'));
        break;
    end
    
    if choice == 3
        exclusion_mask = false(H, W);
        inclusion_mask = false(H, W);
        if exist(savePath, 'file')
            delete(savePath);
        end
        fprintf('Cleared all corrections.\n');
        continue;
    end
    
    % Draw a zone (choice == 1 or 2)
    fig = figure('Name', 'Click points to outline polygon. Press Enter when done.', ...
                 'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none');
    
    % Compute the current road mask with manual edits applied
    baseMask = build_road_mask(img);
    currMask = baseMask;
    currMask(exclusion_mask) = false;
    currMask(inclusion_mask) = true;
    
    % Build the purple overlay (matching verify_and_export.m visualization)
    overlay = double(img);
    alpha = 0.45;
    maskD = double(currMask);
    overlay(:,:,1) = overlay(:,:,1).*(1-alpha*maskD) + 200*alpha*maskD;
    overlay(:,:,2) = overlay(:,:,2).*(1-alpha*maskD) + 50*alpha*maskD;
    overlay(:,:,3) = overlay(:,:,3).*(1-alpha*maskD) + 220*alpha*maskD;
    
    overlay = uint8(min(255, max(0, overlay)));
    image(overlay);
    axis image;
    hold on;
    title('Click points to define polygon. PRESS ENTER WHEN FINISHED.');
    
    % Get points from user with real-time visual feedback
    x = [];
    y = [];
    hPlot = plot(NaN, NaN, 'r-o', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
    while true
        [px, py] = ginput(1);
        if isempty(px) % Enter key finishes the polygon
            break;
        end
        x(end+1) = px;
        y(end+1) = py;
        
        % Draw the current polygon boundary
        if length(x) == 1
            set(hPlot, 'XData', x, 'YData', y);
        else
            set(hPlot, 'XData', [x, x(1)], 'YData', [y, y(1)]);
        end
    end
    close(fig);
    
    if length(x) < 3
        fprintf('A polygon requires at least 3 points. Operation cancelled.\n');
        continue;
    end
    
    % Close the polygon
    x(end+1) = x(1);
    y(end+1) = y(1);
    
    % Generate mask for this polygon
    polyMask = inpolygon(colsGrid, rowsGrid, x, y);
    
    if choice == 1
        exclusion_mask = exclusion_mask | polyMask;
        % Ensure exclusion takes precedence over inclusion
        inclusion_mask(polyMask) = false;
        fprintf('Added exclusion zone.\n');
    elseif choice == 2
        inclusion_mask = inclusion_mask | polyMask;
        exclusion_mask(polyMask) = false;
        fprintf('Added inclusion zone.\n');
    end
end
