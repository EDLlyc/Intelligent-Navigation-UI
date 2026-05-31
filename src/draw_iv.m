function h = draw_iv(ax, iv, mapHeight, scale, rotAngle, origCenter, rotCenter, isSelected, isHovered)
%DRAW_IV Draw an IV using basic line primitives only.
%   h = draw_iv(ax, iv, mapHeight, scale, rotAngle, origCenter, rotCenter)
%
%   Inputs:
%     ax         - axes handle to draw on
%     iv         - IV struct (from create_iv)
%     mapHeight  - map pixel height (803)
%     scale      - m/px (1.7)
%     rotAngle   - current map rotation in degrees
%     origCenter - [cx, cy] of original image centre
%     rotCenter  - [cx, cy] of rotated image centre
%
%   Output:
%     h - column vector of graphics handles

    % ----- Colour palette (cycles by IV id) -----
    palette = [ ...
        0.30 0.60 1.00; ...
        1.00 0.40 0.40; ...
        0.35 0.85 0.45; ...
        1.00 0.75 0.20; ...
        0.75 0.40 0.90; ...
        0.20 0.85 0.85];
    cidx = mod(iv.ID - 1, size(palette, 1)) + 1;
    faceClr = palette(cidx, :);

    % ----- IV half-dimensions in metres (scaled) -----
    halfL = (iv.Length * iv.ScaleFactor) / 2;   % along heading
    halfW = (iv.Width  * iv.ScaleFactor) / 2;   % perpendicular

    % Corner offsets in local frame (heading = +x)
    local = [-halfL, -halfW;
              halfL, -halfW;
              halfL,  halfW;
             -halfL,  halfW];

    % ----- Rotate by heading angle (world coords) -----
    iv_rad = iv.Angle * pi / 180;
    cosA = cos(iv_rad);
    sinA = sin(iv_rad);

    worldC = zeros(4, 2);   % [wx, wy] per corner
    for k = 1:4
        worldC(k,1) = iv.WorldX + cosA * local(k,1) - sinA * local(k,2);
        worldC(k,2) = iv.WorldY + sinA * local(k,1) + cosA * local(k,2);
    end

    % Heading-tip points (for direction indicator triangle)
    % 保证箭头在 1x 缩放下也足够大（最小长度 30 米，约屏幕 18 像素）
    aLen = max(halfL * 2.5, 30); 
    aWid = max(halfW * 2.0, 12);
    arrow_local = [
        aLen, 0;                    % Front tip
        aLen - aWid, -aWid * 0.7;   % Left back
        aLen - aWid,  aWid * 0.7    % Right back
    ];
    arrowW = zeros(3, 2);
    for k = 1:3
        arrowW(k,1) = iv.WorldX + cosA * arrow_local(k,1) - sinA * arrow_local(k,2);
        arrowW(k,2) = iv.WorldY + sinA * arrow_local(k,1) + cosA * arrow_local(k,2);
    end

    % ----- Convert to pixel coordinates -----
    pixC = zeros(4,1);   % column (x in axes)
    pixR = zeros(4,1);   % row    (y in axes)
    for k = 1:4
        [pixR(k), pixC(k)] = world_to_pixel(worldC(k,1), worldC(k,2), mapHeight, scale);
    end
    
    arrowC = zeros(3,1);
    arrowR = zeros(3,1);
    for k = 1:3
        [arrowR(k), arrowC(k)] = world_to_pixel(arrowW(k,1), arrowW(k,2), mapHeight, scale);
    end
    [centR, centC] = world_to_pixel(iv.WorldX, iv.WorldY, mapHeight, scale);

    % ----- Apply map rotation (original -> rotated pixel space) -----
    if abs(rotAngle) > 0.001
        mapRad = rotAngle * pi / 180;
        cosM = cos(mapRad);
        sinM = sin(mapRad);
        for k = 1:4
            dc = pixC(k) - origCenter(1);
            dr = pixR(k) - origCenter(2);
            pixC(k) =  cosM * dc + sinM * dr + rotCenter(1);
            pixR(k) = -sinM * dc + cosM * dr + rotCenter(2);
        end
        % heading arrow
        for k = 1:3
            dc = arrowC(k) - origCenter(1);  dr = arrowR(k) - origCenter(2);
            arrowC(k) =  cosM * dc + sinM * dr + rotCenter(1);
            arrowR(k) = -sinM * dc + cosM * dr + rotCenter(2);
        end
        % centre
        dc = centC - origCenter(1);  dr = centR - origCenter(2);
        centC =  cosM * dc + sinM * dr + rotCenter(1);
        centR = -sinM * dc + cosM * dr + rotCenter(2);
    end

    if nargin < 8, isSelected = false; end
    if nargin < 9, isHovered = false; end

    % ----- Configure line style based on Selected/Hovered status -----
    if isSelected
        edgeClr = [1 0.85 0];
        lineWidth = 3.5;
    elseif isHovered
        edgeClr = [1 0.6 0.1];
        lineWidth = 2.0;
    else
        edgeClr = faceClr;
        lineWidth = 1.5;
    end

    % ----- Draw outline and heading indicator -----
    polyC = [pixC; pixC(1)];
    polyR = [pixR; pixR(1)];
    h1 = plot(ax, polyC, polyR, '-', 'Color', edgeClr, 'LineWidth', lineWidth);
    set(h1, 'HitTest', 'off');

    h2 = plot(ax, [centC arrowC(1)], [centR arrowR(1)], '-', ...
        'Color', [1 0.1 0.1], 'LineWidth', max(1.5, lineWidth));
    set(h2, 'HitTest', 'off');

    h3 = plot(ax, [arrowC; arrowC(1)], [arrowR; arrowR(1)], '-', ...
        'Color', [1 0.3 0.1], 'LineWidth', 1.2);
    set(h3, 'HitTest', 'off');

    h = [h1; h2; h3];
end

