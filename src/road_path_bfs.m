function [pathR, pathC] = road_path_bfs(roadMask, startR, startC, endR, endC)
%ROAD_PATH_BFS Find the shortest road path between two road pixels via BFS.
%   [pathR, pathC] = road_path_bfs(roadMask, startR, startC, endR, endC)
%
%   Uses breadth-first search on the 8-connected road pixel grid.
%   Returns column vectors pathR, pathC tracing the shortest path from
%   (startR, startC) to (endR, endC).  Returns empty if no path exists.
%
%   Pre-allocates the queue for efficiency in MATLAB.

    % Edge Case Guard: Start and End are the same point
    if startR == endR && startC == endC
        pathR = double(startR);
        pathC = double(startC);
        return;
    end

    [H, W] = size(roadMask);

    visited = false(H, W);
    parentR = zeros(H, W, 'int16');
    parentC = zeros(H, W, 'int16');

    % Pre-allocate queue
    maxQ = min(sum(roadMask(:)) + 1, H * W);
    qR = zeros(maxQ, 1, 'int16');
    qC = zeros(maxQ, 1, 'int16');
    qHead = 1;
    qTail = 1;

    qR(qTail) = int16(startR);
    qC(qTail) = int16(startC);
    qTail = qTail + 1;
    visited(startR, startC) = true;

    % 8-connected neighbours
    dr = int16([-1 -1 -1  0  0  1  1  1]);
    dc = int16([-1  0  1 -1  1 -1  0  1]);

    found = false;

    while qHead < qTail
        cr = qR(qHead);
        cc = qC(qHead);
        qHead = qHead + 1;

        for k = 1:8
            nr = cr + dr(k);
            nc = cc + dc(k);

            if nr < 1 || nr > H || nc < 1 || nc > W
                continue;
            end
            if visited(nr, nc) || ~roadMask(nr, nc)
                continue;
            end

            visited(nr, nc) = true;
            parentR(nr, nc) = cr;
            parentC(nr, nc) = cc;

            if nr == endR && nc == endC
                found = true;
                break;
            end

            qR(qTail) = nr;
            qC(qTail) = nc;
            qTail = qTail + 1;
        end

        if found
            break;
        end
    end

    if ~found
        pathR = [];
        pathC = [];
        return;
    end

    % --- Trace back ---
    traceR = zeros(maxQ, 1, 'int16');
    traceC = zeros(maxQ, 1, 'int16');
    idx = 1;
    r = int16(endR);
    c = int16(endC);
    traceR(idx) = r;
    traceC(idx) = c;

    while r ~= startR || c ~= startC
        pr = parentR(r, c);
        pc = parentC(r, c);
        idx = idx + 1;
        traceR(idx) = pr;
        traceC(idx) = pc;
        r = pr;
        c = pc;
    end

    pathR = double(flipud(traceR(1:idx)));
    pathC = double(flipud(traceC(1:idx)));
end
