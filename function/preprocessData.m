function data = preprocessData(data, targetSize)
% 调整图像的大小并将像素缩放到0和1之间，也要缩放相应的边框


for ii = 1:size(data,1)
    I = data{ii,1};
    imgSize = size(I);
    
    % 将单通道输入图像转换为3通道
    if numel(imgSize) < 3 
        I = repmat(I,1,1,3);
    end
    bboxes = data{ii,2};

    I = im2single(imresize(I,targetSize(1:2)));
    scale = targetSize(1:2)./imgSize(1:2);
    bboxes = bboxresize(bboxes,scale);
    
    data(ii, 1:2) = {I, bboxes};
end
end