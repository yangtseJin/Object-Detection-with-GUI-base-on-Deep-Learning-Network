function bboxes = applyRegression(boxIn,reg, minSize, maxSize)
% APPLYREGRESSION对输入框应用框回归。
%
% 输入:
% boxIn       - 输入框/建议Nx4(格式为[x y w h])
% reg         - 由RCNN网络族计算的回归delta [dx dy dw dh]
% min/maxSize - 盒子的最小和最大尺寸
%
% 输出:
% bboxes      - 回归后的方框- Nx4(格式为[x y w h])

    x = reg(:,1);
    y = reg(:,2);
    w = reg(:,3);
    h = reg(:,4);

    % 中心的建议
    px = boxIn(:,1) + floor(boxIn(:,3)/2);
    py = boxIn(:,2) + floor(boxIn(:,4)/2);

    % 计算ground truth box的回归值 
    gx = boxIn(:,3).*x + px; % 中心位置
    gy = boxIn(:,4).*y + py;

    gw = boxIn(:,3) .* exp(w);
    gh = boxIn(:,4) .* exp(h);

    if nargin > 2
        % 回归可以将框推到用户定义范围之外。
        % 将boxes夹到最小/最大范围。
        % 这只在初始的最小/最大大小过滤之后进行。
        gw = min(gw, maxSize(2));
        gh = min(gh, maxSize(1));

        % 扩展到最小尺寸
        gw = max(gw, minSize(2));
        gh = max(gh, minSize(1));
    end

    % 转换为[x y w h]格式
    bboxes = [ gx - floor(gw/2) gy - floor(gh/2) gw gh];

    bboxes = double(round(bboxes));

end