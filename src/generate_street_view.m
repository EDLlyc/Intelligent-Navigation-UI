function streetImg = generate_street_view(mapImage, centreR, centreC, ...
                                          roadAngle, mapHeight, scale)
%GENERATE_STREET_VIEW Create a pseudo-3D street view from a 2D map.
%   streetImg = generate_street_view(mapImage, centreR, centreC,
%                                     roadAngle, mapHeight, scale)
%
%   Generates a perspective-warped view of the map as if standing at the
%   specified road point and looking along the road direction.  Includes a
%   sky gradient and distance-based fog for visual realism.
%
%   Output: uint8 400 x 500 x 3 RGB image.

    outH = 400;
    outW = 500;
    streetImg = uint8(zeros(outH, outW, 3));

    viewLength = 200;      % metres ahead
    viewWidth  = 120;      % metres wide at closest

    % ---- Sky (top 35 %) ----
    skyH = round(outH * 0.35);
    for row = 1:skyH
        t = (row - 1) / max(skyH - 1, 1);
        streetImg(row, :, 1) = uint8(135 + 100 * t);
        streetImg(row, :, 2) = uint8(180 +  60 * t);
        streetImg(row, :, 3) = uint8(235 -  10 * t);
    end

    % ---- Ground (bottom 65 %) via inverse perspective mapping ----
    groundStart = skyH + 1;
    groundH     = outH - skyH;

    [wx0, wy0] = pixel_to_world(centreR, centreC, mapHeight, scale);

    angRad = roadAngle * pi / 180;
    cosA   = cos(angRad);
    sinA   = sin(angRad);

    [imgH, imgW, ~] = size(mapImage);
    colIdx = 1:outW;

    fogClr = [210 230 240];

    for gRow = 1:groundH
        outRow = groundStart + gRow - 1;
        t = 1 - (gRow - 1) / max(groundH - 1, 1);   % 1 at horizon, 0 at bottom

        dist  = 2 + viewLength * (t^3);
        % In true perspective, the visible width scales linearly with distance
        halfW = 3 + viewWidth * (dist / (2 + viewLength));

        frac    = (colIdx - 0.5) / outW - 0.5;
        lateral = frac * halfW * 2;

        wxArr = wx0 + dist * cosA - lateral * sinA;
        wyArr = wy0 + dist * sinA + lateral * cosA;

        prArr = round(mapHeight - wyArr / scale + 0.5);
        pcArr = round(wxArr / scale + 0.5);

        valid = prArr >= 1 & prArr <= imgH & pcArr >= 1 & pcArr <= imgW;
        vIdx  = find(valid);

        if ~isempty(vIdx)
            linIdx = prArr(vIdx) + (pcArr(vIdx) - 1) * imgH;
            for ch = 1:3
                channel = mapImage(:,:,ch);
                tmp = streetImg(outRow, :, ch);
                tmp(vIdx) = channel(linIdx);
                streetImg(outRow, :, ch) = tmp;
            end
        end

        % Fog effect
        fogAmt = t^1.5 * 0.55;
        if fogAmt > 0
            for ch = 1:3
                orig = double(streetImg(outRow, :, ch));
                streetImg(outRow, :, ch) = uint8(orig * (1 - fogAmt) + fogClr(ch) * fogAmt);
            end
        end
    end
end
