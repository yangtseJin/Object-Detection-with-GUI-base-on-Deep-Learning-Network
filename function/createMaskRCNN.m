function dlnet = createMaskRCNN(numClasses, params, featureExtractor) 
% 创建Mask RCNN网络

validatestring(featureExtractor, {'resnet101', 'resnet50'});
%创建 FasterRCNN 网络并将其修改成 MaskRCNN
lgraph = fasterRCNNLayers(params.ImageSize, numClasses, params.AnchorBoxes,  featureExtractor);

switch(featureExtractor)
    case 'resnet50'
        detectorFeatureLayer = 'activation_49_relu';
        inputLayerName = 'input_1';
    case 'resnet101'
        detectorFeatureLayer = 'res5c_relu';
        inputLayerName = 'data';
    otherwise
        error('Unsupported feature extraction network');
end

inputLayer = imageInputLayer(params.ImageSize,'Normalization', 'rescale-symmetric', 'Max', 255, 'Min', 0, 'name','input');

lgraph = lgraph.replaceLayer(inputLayerName, inputLayer);

% 减少损失层
lgraph = lgraph.removeLayers(lgraph.OutputNames);

rpnSftmax = layer.RPNSoftmax('rpnSoftmax');
% 将RPN softmax与自定义层交换
lgraph = lgraph.replaceLayer('rpnSoftmax', rpnSftmax);

% 将 Mask Head 加入到 Faster RCNN
maskHead = createMaskHead(numClasses, params);

lgraph = lgraph.addLayers(maskHead);

lgraph = lgraph.connectLayers(detectorFeatureLayer, 'mask_tConv1');

% 将RegionProposalLayer替换为自定义RPL
customRegionProposal = layer.RegionProposal('rpl', params.AnchorBoxes, params);
lgraph = lgraph.replaceLayer('regionProposal', customRegionProposal);

% 将roiMaxpooling替换为roiAlign
roiAlign = roiAlignLayer([14 14], 'Name', 'roiAlign', 'ROIScale', params.ScaleFactor(1));
lgraph = lgraph.replaceLayer('roiPooling', roiAlign);

% 转换为dlnet
dlnet = dlnetwork(lgraph);
    
    
end
    
    
function layers = createMaskHead(numClasses, params)

    if(params.ClassAgnosticMasks)
        numMaskClasses = 1;
    else
        numMaskClasses = numClasses;
    end

    tconv1 = transposedConv2dLayer(2, 256,'Stride',2, 'Name', 'mask_tConv1' );

    conv1 = convolution2dLayer(1, numMaskClasses, 'Name', 'mask_Conv1','Padding','same' );

    sig1 = sigmoidLayer('Name', 'mask_sigmoid1');

    layers = [tconv1 conv1 sig1];  
end

