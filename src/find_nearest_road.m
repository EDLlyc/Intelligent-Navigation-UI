function [roadR, roadC] = find_nearest_road(r, c, roadMask)
%FIND_NEAREST_ROAD Find the closest road pixel to an arbitrary point.
%   [roadR, roadC] = find_nearest_road(r, c, roadMask)
%
%   Performs an expanding-square search from (r, c) until a road pixel is
%   found.  Used by OR-5 (Path Planning) to snap arbitrary map clicks to
%   the road network.
%
%   Optimized to check only the border ring pixels directly without 
%   redundant nested loops and skips, achieving massive speedups.

    [H, W] = size(roadMask);
    r = round(r);
    c = round(c);

    % Already on road?
    if r >= 1 && r <= H && c >= 1 && c <= W && roadMask(r, c)
        roadR = r;
        roadC = c;
        return;
    end

    maxRadius = max(H, W);
    for radius = 1:maxRadius
        % 1. Top and Bottom edges (full width of the square border)
        % For row r-radius and r+radius, col ranges from c-radius to c+radius
        cols = c-radius:c+radius;
        
        % Top edge check
        nr1 = r - radius;
        if nr1 >= 1 && nr1 <= H
            validCols = cols(cols >= 1 & cols <= W);
            idx = find(roadMask(nr1, validCols), 1);
            if ~isempty(idx)
                roadR = nr1;
                roadC = validCols(idx);
                return;
            end
        end
        
        % Bottom edge check
        nr2 = r + radius;
        if nr2 >= 1 && nr2 <= H
            validCols = cols(cols >= 1 & cols <= W);
            idx = find(roadMask(nr2, validCols), 1);
            if ~isempty(idx)
                roadR = nr2;
                roadC = validCols(idx);
                return;
            end
        end
        
        % 2. Left and Right edges (excluding the corners already checked)
        % For col c-radius and c+radius, row ranges from r-radius+1 to r+radius-1
        rows = r-radius+1:r+radius-1;
        
        % Left edge check
        nc1 = c - radius;
        if nc1 >= 1 && nc1 <= W
            validRows = rows(rows >= 1 & rows <= H);
            idx = find(roadMask(validRows, nc1), 1);
            if ~isempty(idx)
                roadR = validRows(idx);
                roadC = nc1;
                return;
            end
        end
        
        % Right edge check
        nc2 = c + radius;
        if nc2 >= 1 && nc2 <= W
            validRows = rows(rows >= 1 & rows <= H);
            idx = find(roadMask(validRows, nc2), 1);
            if ~isempty(idx)
                roadR = validRows(idx);
                roadC = nc2;
                return;
            end
        end
    end

    % Fallback (should never happen on a valid map)
    roadR = r;
    roadC = c;
end
