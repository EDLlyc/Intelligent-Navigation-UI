function h = draw_iv(ax, iv, mapHeight, scale, rotAngle, origCenter, rotCenter, clickCB)
%DRAW_IV Draw an IV rectangle (with heading indicator) on map axes.
%   h = draw_iv(ax, iv, mapHeight, scale, rotAngle, origCenter, rotCenter)
%   h = draw_iv(ax, iv, mapHeight, scale, rotAngle, origCenter, rotCenter, clickCB)
%
%   Inputs:
%     ax         - axes handle to draw on
%     iv         - IV struct (from create_iv)
%     mapHeight  - map pixel height (803)
%     scale      - m/px (1.7)
%     rotAngle   - current map rotation in degrees
%     origCenter - [cx, cy] of original image centre
%     rotCenter  - [cx, cy] of rotated image centre
%     clickCB    - (optional) callback for ButtonDownFcn on the IV body
%
%   Output:
%     h - column vector of graphics handles (patch, line, text, arrowhead)

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

    % Heading-tip point (for direction indicator)
    headWx = iv.WorldX + halfL * 1.0 * cosA;
    headWy = iv.WorldY + halfL * 1.0 * sinA;

    % ----- Arrowhead triangle vertices in world coords -----
    % Arrow tip = heading point; base is perpendicular to heading
    % at ~30% of halfL from centre, with half-width = halfW * 0.8
    arrowBaseD = halfL * 0.30;          % distance from centre to arrow base
    arrowHalfW = halfW * 0.80;         % half-width of arrow base

    % Heading direction unit vector components are (cosA, sinA)
    % Perpendicular direction is (-sinA, cosA)
    arrowW = zeros(3, 2);  % 3 vertices: tip, base-left, base-right
    % Vertex 1: tip (same as heading point)
    arrowW(1,1) = headWx;
    arrowW(1,2) = headWy;
    % Vertex 2: base-left
    arrowW(2,1) = iv.WorldX + arrowBaseD * cosA - arrowHalfW * (-sinA);
    arrowW(2,2) = iv.WorldY + arrowBaseD * sinA - arrowHalfW * ( cosA);
    % Vertex 3: base-right
    arrowW(3,1) = iv.WorldX + arrowBaseD * cosA + arrowHalfW * (-sinA);
    arrowW(3,2) = iv.WorldY + arrowBaseD * sinA + arrowHalfW * ( cosA);

    % ----- Convert to pixel coordinates -----
    pixC = zeros(4,1);   % column (x in axes)
    pixR = zeros(4,1);   % row    (y in axes)
    for k = 1:4
        [pixR(k), pixC(k)] = world_to_pixel(worldC(k,1), worldC(k,2), mapHeight, scale);
    end
    [headR, headC_] = world_to_pixel(headWx, headWy, mapHeight, scale);
    [centR, centC]   = world_to_pixel(iv.WorldX, iv.WorldY, mapHeight, scale);

    % Convert arrowhead vertices to pixel coords
    arrPixC = zeros(3,1);
    arrPixR = zeros(3,1);
    for k = 1:3
        [arrPixR(k), arrPixC(k)] = world_to_pixel(arrowW(k,1), arrowW(k,2), mapHeight, scale);
    end

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
        % heading tip
        dc = headC_ - origCenter(1);  dr = headR - origCenter(2);
        headC_ =  cosM * dc + sinM * dr + rotCenter(1);
        headR  = -sinM * dc + cosM * dr + rotCenter(2);
        % centre
        dc = centC - origCenter(1);  dr = centR - origCenter(2);
        centC =  cosM * dc + sinM * dr + rotCenter(1);
        centR = -sinM * dc + cosM * dr + rotCenter(2);
        % arrowhead vertices
        for k = 1:3
            dc = arrPixC(k) - origCenter(1);
            dr = arrPixR(k) - origCenter(2);
            arrPixC(k) =  cosM * dc + sinM * dr + rotCenter(1);
            arrPixR(k) = -sinM * dc + cosM * dr + rotCenter(2);
        end
    end

    % ----- Draw -----
    h1 = patch(ax, pixC, pixR, faceClr, ...
        'FaceAlpha', 0.55, 'EdgeColor', faceClr * 0.55, 'LineWidth', 2);
    set(h1, 'HitTest', 'on');

    % Set click callback on IV body if provided
    if nargin >= 8 && ~isempty(clickCB)
        set(h1, 'ButtonDownFcn', clickCB);
    end

    h2 = plot(ax, [centC, headC_], [centR, headR], '-', ...
        'Color', [1 1 0.3], 'LineWidth', 2);
    set(h2, 'HitTest', 'off');

    h3 = text(ax, centC, centR - 14, sprintf('#%d', iv.ID), ...
        'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.1 0.1 0.15]);
    set(h3, 'HitTest', 'off');

    % Arrowhead triangle (filled, bright yellow-orange)
    h4 = patch(ax, arrPixC, arrPixR, [1 1 0], ...
        'FaceAlpha', 1.0, 'EdgeColor', [1 0.6 0], 'LineWidth', 1.5);
    set(h4, 'HitTest', 'off');

    h = [h1; h2; h3; h4];
end
