function [rotated, newH, newW] = rotate_map(img, angle_deg)
%ROTATE_MAP Rotate an image by a specified angle (manual implementation).
%   [rotated, newH, newW] = rotate_map(img, angle_deg)
%
%   Positive angle_deg rotates the image counter-clockwise as displayed
%   on screen.  Uses vectorised inverse mapping with nearest-neighbour
%   sampling.  No Image Processing Toolbox functions are used.
%
%   Inputs:
%     img       - uint8 H x W x C image
%     angle_deg - rotation angle in degrees (positive = CCW on screen)
%
%   Outputs:
%     rotated - rotated uint8 image (may be larger than original)
%     newH    - height of rotated image
%     newW    - width  of rotated image

    % Trivial case
    if abs(angle_deg) < 0.001
        rotated = img;
        [newH, newW, ~] = size(img);
        return;
    end

    [H, W, C] = size(img);
    angle_rad = angle_deg * pi / 180;

    cx = (W + 1) / 2;          % original centre (column)
    cy = (H + 1) / 2;          % original centre (row)

    cosA = cos(angle_rad);
    sinA = sin(angle_rad);

    % --- Determine output image size ---
    % Transform the four corners of the original to find bounding box
    cornersC = [1, W, W, 1] - cx;
    cornersR = [1, 1, H, H] - cy;
    rotC =  cosA * cornersC + sinA * cornersR;
    rotR = -sinA * cornersC + cosA * cornersR;

    newW = ceil(max(rotC) - min(rotC)) + 1;
    newH = ceil(max(rotR) - min(rotR)) + 1;

    newcx = (newW + 1) / 2;
    newcy = (newH + 1) / 2;

    % --- Inverse mapping (vectorised) ---
    % 原生外积构造 meshgrid 网格以替代内置 meshgrid 函数
    outC = ones(newH, 1) * (1:newW);
    outR = (1:newH)' * ones(1, newW);

    dc = outC - newcx;
    dr = outR - newcy;

    srcC = round( cosA * dc - sinA * dr + cx);
    srcR = round( sinA * dc + cosA * dr + cy);

    valid = srcR >= 1 & srcR <= H & srcC >= 1 & srcC <= W;

    % --- Build output image ---
    rotated = uint8(zeros(newH, newW, C));

    validIdx = find(valid);
    linIdx   = srcR(validIdx) + (srcC(validIdx) - 1) * H;   % manual sub2ind

    for ch = 1:C
        channel    = img(:,:,ch);
        outChannel = uint8(zeros(newH, newW));
        outChannel(validIdx) = channel(linIdx);
        rotated(:,:,ch) = outChannel;
    end
end
