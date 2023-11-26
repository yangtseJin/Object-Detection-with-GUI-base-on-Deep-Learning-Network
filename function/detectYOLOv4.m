function [bboxes, scores, labels] = detectYOLOv4(dlnet, image, anchors, classNames, executionEnvironment)
% detectYOLOv4 是基于预训练的yolov4网络进行预测。
%
% 输入
% dlnet                - 预训练的 yolov4 网络模型.
% image                - 输入的 RGB 图像. (H x W x 3)
% anchors              - 锚点，用于预训练模型的训练。
% classNames           - 在检测中使用的类名。
% executionEnvironment - 运行预测网络的环境 
%                        可以指定cpu, gpu, 或 auto.
%
% 输出:
% bboxes     - 格式化为NumDetections x4 类型的最终边界框检测([x y w h])
% scores     - NumDetections x 1类型的分类的得分。
% labels     - NumDetections x 1类型的分类标签。


% 获取网络的输入大小
inputSize = dlnet.Layers(1).InputSize;

% 对输入图像进行预处理
[img, scale] = preprocess(image, inputSize);

% 转换为dlarray
dlInput = dlarray(img, 'SSCB');

% 如果GPU可用，则将数据转换为gpuArray
if (executionEnvironment == "auto" && canUseGPU) || executionEnvironment == "gpu"
    dlInput = gpuArray(dlInput);
end

% 对输入图像进行预测
outFeatureMaps = cell(length(dlnet.OutputNames), 1);
[outFeatureMaps{:}] = predict(dlnet, dlInput);

% 对输出特征映射应用后处理
[bboxes,scores,labels] = postprocess(outFeatureMaps, anchors, ...
    inputSize, scale, classNames);
end