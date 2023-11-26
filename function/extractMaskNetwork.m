function maskNet = extractMaskNetwork(net)
% 从预先训练的maskrcnn网络中提取掩码子网

    roiInput = imageInputLayer([5 1000 1], 'Name', 'roiInput', 'Normalization', 'none');
    
    featureInput = imageInputLayer([50 50 1024], 'Name', 'featureInput', 'Normalization', 'none');

    
    lgraph = layerGraph(net);
    
    % 提取掩码子网，删除所有骨干层，rpn层
    % 以及方框回归和分类标题
    
    for i = 1: numel(lgraph.Layers)
        backboneLayers{i} = lgraph.Layers(i).Name;
        if (strcmp(lgraph.Layers(i).Name, 'res4b22_relu'))
            break;
        end
    end
    
    rpnLayers = {'rpnConv3x3', 'rpnRelu', 'rpnConv1x1BoxDeltas', 'rpnConv1x1ClsScores', 'rpnSoftmax','rpl'};
    
    bboxHeads = {'pool5', 'rcnnFC', 'rcnnSoftmax', 'fcBoxDeltas' };
    
    layersToRemove = [backboneLayers, rpnLayers, bboxHeads];
    
    for idx = 1:numel(layersToRemove)
        lgraph = lgraph.removeLayers(layersToRemove{idx});
    end

    % 加入输入层
    lgraph = lgraph.addLayers(roiInput);
    lgraph = lgraph.addLayers(featureInput);
    
    lgraph = lgraph.connectLayers('roiInput', 'roiAlign/roi');
    lgraph = lgraph.connectLayers('featureInput', 'roiAlign/in');
    
    maskNet = dlnetwork(lgraph);

end