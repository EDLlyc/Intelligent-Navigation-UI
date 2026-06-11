function streetImg = generate_street_view(mapImage, centreR, centreC, ...
                                          roadAngle, mapHeight, scale)
%GENERATE_STREET_VIEW Create a pseudo-3D street view from a 2D map.
%   streetImg = generate_street_view(mapImage, centreR, centreC,
%                                     roadAngle, mapHeight, scale)
%
%   Generates a perspective-warped view of the map as if standing at the
%   specified road point and looking along the road direction. Includes a
%   sky gradient and distance-based fog for visual realism.
%   All calculations are hand-written and fully vectorised for maximum speed.
%
%   Output: uint8 400 x 500 x 3 RGB image.

    outH = 400;
    outW = 500;
    W_out = outW;
    H_out = outH;
    focal_length = 330.0; % Focal length for natural FOV at 500x400

    % 1. Camera Intrinsic Parameters
    A = [focal_length, 0, W_out / 2;
         0, focal_length, H_out / 2;
         0, 0, 1];

    pixel_to_m = scale;

    % 2. Camera Center in World Coordinate System (Origin at bottom-left)
    x_c = (centreC - 0.5) * scale;
    y_c = (mapHeight - centreR + 0.5) * scale;
    z_c = 1.6; % Camera height (1.6 meters, vehicle dashcam eye-level)
    O_c = [x_c; y_c; z_c];

    % 3. Camera Facing Direction (Yaw and Pitch)
    % In MATLAB, roadAngle is counter-clockwise from East.
    % In Python demo, pan_deg is clockwise from North.
    pan_deg = 90 - roadAngle;
    tilt_deg = -10.0; % Pitch down slightly to look at the ground

    pan = pan_deg * pi / 180;
    tilt = tilt_deg * pi / 180;

    % Base-Vector rotation matrix setup (Camera to World)
    n_c = [cos(tilt) * sin(pan);
           cos(tilt) * cos(pan);
           sin(tilt)];
       
    u_c = [sin(pan + pi/2);
           cos(pan + pi/2);
           0.0];
       
    v_c = cross(n_c, u_c);

    R_cw = [u_c, v_c, n_c];

    % 4. Ray Casting Mesh Grid
    [u_grid, v_grid] = meshgrid(0:W_out-1, 0:H_out-1);
    A_inv = inv(A);
    hom_coords = [u_grid(:)'; v_grid(:)'; ones(1, H_out * W_out)];
    
    % Rays in camera frame and world frame
    rays_c = A_inv * hom_coords;
    rays_w = R_cw * rays_c;

    % Find intersection with Z_w = 0 ground plane
    t = -O_c(3) ./ (rays_w(3, :) + 1e-6);
    valid = t > 0;

    % Intersection points in WCS
    x_w = O_c(1) + t .* rays_w(1, :);
    y_w = O_c(2) + t .* rays_w(2, :);

    % Convert WCS coordinates back to map pixels
    u_map = round(x_w / pixel_to_m + 0.5);
    v_map = round(mapHeight - y_w / pixel_to_m + 0.5);

    % Bound checking
    [imgH, imgW, ~] = size(mapImage);
    in_bounds = (u_map >= 1) & (u_map <= imgW) & (v_map >= 1) & (v_map <= imgH);
    final_valid = valid & in_bounds;

    final_valid = reshape(final_valid, H_out, W_out);
    u_map = reshape(u_map, H_out, W_out);
    v_map = reshape(v_map, H_out, W_out);

    % 5. Render Sky Background
    streetImg = uint8(zeros(H_out, W_out, 3));
    for row = 1:outH
        t_sky = (row - 1) / max(outH - 1, 1);
        streetImg(row, :, 1) = uint8(135 + 100 * t_sky);
        streetImg(row, :, 2) = uint8(180 +  60 * t_sky);
        streetImg(row, :, 3) = uint8(235 -  10 * t_sky);
    end

    % 6. Map Ground Texture
    [rows_indices, cols_indices] = find(final_valid);
    if ~isempty(rows_indices)
        out_lin_idx = rows_indices + (cols_indices - 1) * H_out;
        map_r = v_map(out_lin_idx);
        map_c = u_map(out_lin_idx);
        map_lin_idx = map_r + (map_c - 1) * imgH;
        
        for ch = 1:3
            map_ch = mapImage(:,:,ch);
            out_ch = streetImg(:,:,ch);
            out_ch(out_lin_idx) = map_ch(map_lin_idx);
            streetImg(:,:,ch) = out_ch;
        end
    end

    % 7. Exponential Distance-based Fog Effect
    t_mat = reshape(t, H_out, W_out);
    fogAmt = (t_mat / 220).^1.2 * 0.60;
    fogAmt(~final_valid) = 0;
    fogAmt = min(0.60, max(0, fogAmt));

    fogClr = [210, 230, 240];
    for ch = 1:3
        ch_data = double(streetImg(:,:,ch));
        ch_data = ch_data .* (1 - fogAmt) + fogClr(ch) * fogAmt;
        streetImg(:,:,ch) = uint8(ch_data);
    end
end
