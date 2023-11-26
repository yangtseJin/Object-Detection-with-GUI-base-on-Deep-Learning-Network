function [bboxes, scores, labels, finalMasks] = detectMaskRCNN(dlnet, maskSubnet, image, params, executionEnvironment)

% detectMaskRCNN在经过训练的maskrcnn网络上运行预测
%
% 输入:
% dlnet      - 预训练的 MaskRCNN dlnetwork
% maskSubnet - 预训练的 mask branch of maskRCNN dlnetwork
% image      - 用来做预测的 RGB 图像  (H x W x 3)
% params     - MaskRCNN网络配置对象使用createNetworkConfiguration创建
%
% 输出:
% bboxes     - 格式化为NumDetections x4的最终边界框检测([x y w h])
% scores     - NumDetections x 1 分类得分
% labels     - NumDetections x 1分类类标签。
% finalMasks - 二进制对象掩码检测格式化为H x W x NumDetections



% 为预测准备输入图像
if(executionEnvironment == "gpu")
    image = gpuArray(image);
end
% 将图像投射到dlarray上
X = dlarray(single(image),'SSCB');
imageSize = size(image);


%%% 探测器的预测

% 目标检测输出
featureMapNode = 'res4b22_relu';
outputNodes = {'rpl', 'rcnnSoftmax', 'fcBoxDeltas'};
outputNodes = [outputNodes featureMapNode];

% 对输入运行预测
[bboxes, YRCNNClass, YRCNNReg, featureMap] = predict(...
                                        dlnet, X, 'Outputs', outputNodes);
                                    
% 从输出dlarrays中提取数据
bboxes = extractdata(bboxes)';
YRCNNClass = extractdata(YRCNNClass);
YRCNNReg = extractdata(YRCNNReg);

% 网络以[x1 y1 x2 y2]格式输出建议
% 转换为[x y w h]以进行进一步处理。
bboxes = vision.internal.cnn.boxUtils.x1y1x2y2ToXYWH(bboxes);

% 分类数据处理
% 计算预测得分
allScores = squeeze(YRCNNClass);
% 删除与背景相关的分数
bgIndex = strcmp(string(params.ClassNames),params.BackgroundClass);
allScores(bgIndex,:) = [];
scores = reshape(allScores',[],1);

numClasses = numel(params.ClassNames)-1; % 排除背景

% 为每个类复制每个建议框。
% boxes盒子被复制为[b1 b1 b1 b1 b2 b2 b2 ....]
bboxes = repmat(bboxes(:, 1:4), numClasses, 1);
numObservations = size(YRCNNReg,2);

 % 复制标签
 % 将标签分组为 [label1 label1 ... numObservation times, label2
 % label2.... numObservation times ...]'
classNames = categorical(params.ClassNames, params.ClassNames);
% 删除背景
classNames(classNames==params.BackgroundClass) = [];
classNames = removecats(classNames, params.BackgroundClass);

ind = (1:numel(classNames))';
labels = classNames(repelem(ind,numObservations,1));
labels = labels';


% 回归数据处理
reg = reshape(YRCNNReg, 4, numClasses, numObservations);
reg = permute(reg, [1 3 2]);
reg = reshape(reg, 4, [])';


% 应用回归
bboxes = applyRegression(bboxes, reg, params.MinSize, params.MaxSize);

% 过滤无效的预测
[bboxes, scores, labels] = filterBoxesAfterRegression(bboxes,scores,labels, imageSize);

% 筛选框夹住边缘上的框
bboxes = vision.internal.detector.clipBBox(bboxes,imageSize);

% 剪切后删除太小的框
tooSmall = any(bboxes(:,3:4) < params.MinSize,2);
bboxes(tooSmall,:) = [];
scores(tooSmall,:) = [];
labels(tooSmall,:) = [];
 

% 滤波器评分小于阈值
keep = scores >= params.Threshold;
bboxes = bboxes(keep,1:4);
scores = scores(keep,:);
labels = labels(keep,:);

% 执行 NMS
if params.SelectStrongest
    [bboxes, scores, labels] = selectStrongestBboxMulticlass(bboxes,scores,labels,...
        'RatioType', 'Min', 'OverlapThreshold', 0.7);
end

%%% Mask分割

% 为掩膜预测准备最终的bboc检测
bboxesX1Y1 = vision.internal.cnn.boxUtils.xywhToX1Y1X2Y2(bboxes);
roiIn = dlarray([bboxesX1Y1 ones(size(bboxesX1Y1,1),1)]', "SSCB");

mask = predict(maskSubnet, roiIn, featureMap);

bboxes = gather(bboxes);
mask = gather(squeeze(extractdata(mask)));

finalMasks = false([imageSize(1) imageSize(2) size(bboxes,1)]);

% 调整大小并插入masks
for i = 1:size(bboxes,1)
    m = imresize(mask(:,:,i), [bboxes(i,4) bboxes(i,3)],'cubic') > 0.5 ;
    finalMasks(bboxes(i,2):bboxes(i,2)+bboxes(i,4)-1, ...
                bboxes(i,1):bboxes(i,1)+bboxes(i,3)-1, i) = m;
end


end



