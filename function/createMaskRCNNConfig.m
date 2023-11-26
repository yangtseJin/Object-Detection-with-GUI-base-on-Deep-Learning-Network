function params = createMaskRCNNConfig(imageSize, numClasses, classNames)
% createNetworkConfiguration创建maskRCNN训练和检测
% 配置参数



    % 网络参数
    params.ImageSize = imageSize;
    params.NumClasses = numClasses;
    params.ClassNames = classNames;
    params.BackgroundClass = 'background';
    params.ROIAlignOutputSize = [14 14]; % ROIAlign 输出格式大小
    params.MaskOutputSize = [14 14]; 
    params.ScaleFactor = [0.0625 0.0625]; % 特征大小与图像大小之比
    params.ClassAgnosticMasks = true;   
        
    % 特征大小与图像大小之比
    params.PositiveOverlapRange = [0.6 1.0];
    params.NegativeOverlapRange = [0.1 0.6];
       
    % Region Proposal网络参数
    params.AnchorBoxes = [[32 16];
                          [64 32];
                          [128 64];
                          [256 128];
                          [512 256];
                          [32 32];
                          [64 64];
                          [128 128];
                          [256 256];
                          [512 512];
                          [16 32];
                          [32 64];
                          [64 128];
                          [128 256];
                          [256 512]];
    params.NumAnchors = size(params.AnchorBoxes,1);
    params.NumRegionsToSample = 200;
    % NMS阈值
    params.OverlapThreshold = 0.7;
    params.MinScore = 0;
    params.NumStrongestRegionsBeforeProposalNMS = 3000;
    params.NumStrongestRegions = 1000;
    params.BoxFilterFcn = @(a,b,c,d)fasterRCNNObjectDetector.filterBBoxesBySize(a,b,c,d);
    params.RPNClassNames = {'Foreground', 'Background'};
    params.RPNBoxStd   = [1 1 1 1];
    params.RPNBoxMean  = [0 0 0 0];

    params.RandomSelector = vision.internal.rcnn.RandomSelector();
    params.StandardizeRegressionTargets = false;
    params.MiniBatchPadWithNegatives = true;
    params.ProposalsOutsideImage = 'clip';
    params.BBoxRegressionNormalization = 'valid';
    params.RPNROIPerImage = params.NumRegionsToSample;
    params.CategoricalLookup = reshape(categorical([1 2 3],[1 2],params.RPNClassNames),[],1);
       
    % 检测参数
    params.DetectionsOnBorder = 'clip';
    params.Threshold = 0.5;
    params.SelectStrongest = true;
    params.MinSize     = [1 1];
    params.MaxSize     = [inf inf];
