function filtered_mask = filter_isolated_roads(mask, startR, startC)
%FILTER_ISOLATED_ROADS Filter out road pixels that cannot reach the core starting point.
%   filtered_mask = filter_isolated_roads(mask, startR, startC)
%
%   Inputs:
%     mask   - logical H x W road binary mask
%     startR - scalar, starting row coordinate (Row = 517)
%     startC - scalar, starting column coordinate (Col = 468)
%
%   Output:
%     filtered_mask - logical H x W, only containing connected road network pixels

    [H, W] = size(mask);
    filtered_mask = false(H, W);
    
    % 1. 临时桥接机制 (使用最原生的 3x3 边界切片位运算 OR 进行膨胀，不使用任何 conv2)
    padded = false(H + 2, W + 2);
    padded(2:end-1, 2:end-1) = mask;
    dilated = false(H, W);
    for dr = -1:1
        for dc = -1:1
            dilated = dilated | padded((2+dr):(H+1+dr), (2+dc):(W+1+dc));
        end
    end
    
    % 2. 容错起点探测 (若起点 (startR, startC) 没有被判定为道路，往外探测 5x5 区域找最近的道路点)
    actualStartR = startR;
    actualStartC = startC;
    
    if ~dilated(startR, startC)
        % 手动使用双重循环构建 5x5 的相对偏移网格，不使用 meshgrid
        dr_grid = zeros(25, 1);
        dc_grid = zeros(25, 1);
        grid_idx = 1;
        for r_offset = -2:2
            for c_offset = -2:2
                dr_grid(grid_idx) = r_offset;
                dc_grid(grid_idx) = c_offset;
                grid_idx = grid_idx + 1;
            end
        end
        dist = dr_grid.^2 + dc_grid.^2;
        
        % 手写冒泡排序，对 25 个距离值对应的索引进行排序
        sortIdx = 1:25;
        for i = 1:24
            for j = i+1:25
                if dist(sortIdx(i)) > dist(sortIdx(j))
                    temp = sortIdx(i);
                    sortIdx(i) = sortIdx(j);
                    sortIdx(j) = temp;
                end
            end
        end
        
        found_nearest = false;
        for k = 1:length(sortIdx)
            nr = startR + dr_grid(sortIdx(k));
            nc = startC + dc_grid(sortIdx(k));
            if nr >= 1 && nr <= H && nc >= 1 && nc <= W
                if dilated(nr, nc)
                    actualStartR = nr;
                    actualStartC = nc;
                    found_nearest = true;
                    break;
                end
            end
        end
        
        % 如果周围 5x5 内完全没有道路，说明当前路网完全中断，直接返回全空掩膜
        if ~found_nearest
            return;
        end
    end
    
    % 3. 广度优先搜索 (BFS) 连通性分析
    % 预分配队列空间以极大提升速度，队列最大容量限制在图像大小内
    visited = false(H, W);
    qR = zeros(H * W, 1, 'int32');
    qC = zeros(H * W, 1, 'int32');
    
    qHead = 1;
    qTail = 1;
    
    % 起点入队
    qR(qTail) = int32(actualStartR);
    qC(qTail) = int32(actualStartC);
    visited(actualStartR, actualStartC) = true;
    qTail = qTail + 1;
    
    % 8-邻域方向向量
    dr = int32([-1 -1 -1  0  0  1  1  1]);
    dc = int32([-1  0  1 -1  1 -1  0  1]);
    
    % BFS 主搜索循环 (防死循环：visited 控制每个节点仅处理一次)
    while qHead < qTail
        cr = qR(qHead);
        cc = qC(qHead);
        qHead = qHead + 1;
        
        for k = 1:8
            nr = cr + dr(k);
            nc = cc + dc(k);
            
            if nr >= 1 && nr <= H && nc >= 1 && nc <= W
                if dilated(nr, nc) && ~visited(nr, nc)
                    visited(nr, nc) = true;
                    qR(qTail) = nr;
                    qC(qTail) = nc;
                    qTail = qTail + 1;
                end
            end
        end
    end
    
    % 4. 还原过滤：在提取出的主连通域中，只保留原始 mask 中已判断出的像素
    % 这样既利用了膨胀跨越断点，又避免了加粗路网边界导致精确度下降
    filtered_mask = mask & visited;
end
