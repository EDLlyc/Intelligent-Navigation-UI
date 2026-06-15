function [pathR, pathC] = road_path_bfs(roadMask, startR, startC, endR, endC)
%ROAD_PATH_BFS Find the shortest road path between two road pixels via Bidirectional BFS.
%   [pathR, pathC] = road_path_bfs(roadMask, startR, startC, endR, endC)
%
%   Uses bidirectional breadth-first search on the 8-connected road pixel grid
%   to find the shortest path with maximum speed and memory efficiency.
%
%   Returns column vectors pathR, pathC tracing the shortest path from
%   (startR, startC) to (endR, endC). Returns empty if no path exists.

    % Edge Case Guard: Start and End are the same point
    if startR == endR && startC == endC
        pathR = double(startR);
        pathC = double(startC);
        return;
    end

    [H, W] = size(roadMask);
    startIdx = int32(startR + (startC - 1) * H);
    endIdx = int32(endR + (endC - 1) * H);

    visited = zeros(H, W, 'int8'); % 0: unvisited, 1: forward, 2: backward
    parent_f = zeros(H, W, 'int32');
    parent_b = zeros(H, W, 'int32');

    maxQ = min(sum(roadMask(:)) + 2, H * W);
    q_f = zeros(maxQ, 1, 'int32');
    q_b = zeros(maxQ, 1, 'int32');
    
    head_f = 1; tail_f = 1;
    head_b = 1; tail_b = 1;

    q_f(tail_f) = startIdx;
    tail_f = tail_f + 1;
    visited(startIdx) = 1;

    q_b(tail_b) = endIdx;
    tail_b = tail_b + 1;
    visited(endIdx) = 2;

    dr = [ -1, -1, -1,  0,  0,  1,  1,  1 ];
    dc = [ -1,  0,  1, -1,  1, -1,  0,  1 ];

    found = false;
    meetingIdx = 0;

    while (head_f < tail_f) && (head_b < tail_b)
        % Expand the smaller queue (frontier) to minimize search space
        if (tail_f - head_f) <= (tail_b - head_b)
            % Expand forward
            currIdx = q_f(head_f);
            head_f = head_f + 1;
            
            cr = mod(currIdx - 1, H) + 1;
            cc = floor((currIdx - 1) / H) + 1;
            
            for k = 1:8
                nr = cr + dr(k);
                nc = cc + dc(k);
                if nr >= 1 && nr <= H && nc >= 1 && nc <= W
                    nIdx = nr + (nc - 1) * H;
                    if roadMask(nIdx)
                        if visited(nIdx) == 0
                            visited(nIdx) = 1;
                            parent_f(nIdx) = currIdx;
                            q_f(tail_f) = nIdx;
                            tail_f = tail_f + 1;
                        elseif visited(nIdx) == 2
                            meetingIdx = nIdx;
                            parent_f(meetingIdx) = currIdx;
                            found = true;
                            break;
                        end
                    end
                end
            end
        else
            % Expand backward
            currIdx = q_b(head_b);
            head_b = head_b + 1;
            
            cr = mod(currIdx - 1, H) + 1;
            cc = floor((currIdx - 1) / H) + 1;
            
            for k = 1:8
                nr = cr + dr(k);
                nc = cc + dc(k);
                if nr >= 1 && nr <= H && nc >= 1 && nc <= W
                    nIdx = nr + (nc - 1) * H;
                    if roadMask(nIdx)
                        if visited(nIdx) == 0
                            visited(nIdx) = 2;
                            parent_b(nIdx) = currIdx;
                            q_b(tail_b) = nIdx;
                            tail_b = tail_b + 1;
                        elseif visited(nIdx) == 1
                            meetingIdx = nIdx;
                            parent_b(meetingIdx) = currIdx;
                            found = true;
                            break;
                        end
                    end
                end
            end
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

    % Trace forward path
    trace_f = zeros(maxQ, 1, 'int32');
    idx_f = 1;
    curr = meetingIdx;
    trace_f(idx_f) = curr;
    while curr ~= startIdx
        curr = parent_f(curr);
        idx_f = idx_f + 1;
        trace_f(idx_f) = curr;
    end
    path_f = trace_f(idx_f:-1:1);

    % Trace backward path
    trace_b = zeros(maxQ, 1, 'int32');
    idx_b = 0;
    curr = parent_b(meetingIdx);
    while curr ~= endIdx && curr > 0
        idx_b = idx_b + 1;
        trace_b(idx_b) = curr;
        curr = parent_b(curr);
    end
    if curr == endIdx
        idx_b = idx_b + 1;
        trace_b(idx_b) = curr;
    end
    path_b = trace_b(1:idx_b);

    full_path_indices = double([path_f; path_b]);
    
    pathC = floor((full_path_indices - 1) / H) + 1;
    pathR = full_path_indices - (pathC - 1) * H;
end
