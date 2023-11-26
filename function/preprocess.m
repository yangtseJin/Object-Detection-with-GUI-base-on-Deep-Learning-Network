function [output, scale] = preprocess(image, netInputSize)
% 预处理函数对输入图像进行预处理。


inputSize = [size(image,1),size(image,2)];
scale = inputSize./netInputSize(1:2);

output = im2single(imresize(image,netInputSize(1:2)));
end