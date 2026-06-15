function localImg = local_map_view(mapImage, centreR, centreC, radiusPix)
%LOCAL_MAP_VIEW Extract a circular local map centred on a given pixel.
%   localImg = local_map_view(mapImage, centreR, centreC, radiusPix)
%
%   The output is a square RGB image of side 2*R+1 with pixels outside the
%   circle set to black, strictly conforming to the specified radius.
%
%   Inputs:
%     mapImage  - uint8 H x W x 3 map image
%     centreR   - centre row in the map (pixels)
%     centreC   - centre column in the map (pixels)
%     radiusPix - radius of the local view in pixels
%
%   Output:
%     localImg  - uint8 (2R+1) x (2R+1) x 3 image with circular mask

    [H, W, C] = size(mapImage);
    R = round(radiusPix);
    if R < 1
        R = 1;
    end

    centreR = round(centreR);
    centreC = round(centreC);

    outSize = 2 * R + 1;
    localImg = uint8(zeros(outSize, outSize, C));

    % --- Determine the overlap between the circle bounding box and the map ---
    rMin = max(1, centreR - R);
    rMax = min(H, centreR + R);
    cMin = max(1, centreC - R);
    cMax = min(W, centreC + R);

    if rMin > rMax || cMin > cMax
        return;   % completely outside the map
    end

    % Where does the extracted region sit in the output buffer?
    outRstart = R + 1 - (centreR - rMin);
    outRend   = outRstart + (rMax - rMin);
    outCstart = R + 1 - (centreC - cMin);
    outCend   = outCstart + (cMax - cMin);

    localImg(outRstart:outRend, outCstart:outCend, :) = ...
        mapImage(rMin:rMax, cMin:cMax, :);

    % --- Apply circular mask ---
    % 原生外积构造 meshgrid 网格以替代内置 meshgrid 函数
    xx = ones(outSize, 1) * (1:outSize);
    yy = (1:outSize)' * ones(1, outSize);
    centre = R + 1;
    circMask = ((xx - centre).^2 + (yy - centre).^2) <= R^2;

    for ch = 1:C
        channel = localImg(:,:,ch);
        channel(~circMask) = 0;
        localImg(:,:,ch) = channel;
    end
end
