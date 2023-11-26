function anchors = getAnchors(modelName)
% getAnchors函数返回在指定的预训练YOLOv4模型的训练中使用的anchors。


if isequal(modelName, 'YOLOv4-coco')
    anchors.anchorBoxes = [16 12; 36 19; 28 40;...
                        75 36; 55 76; 146 72;...
                        110 142; 243 192; 401 459];
    anchors.anchorBoxMasks = {[1,2,3]
                            [4,5,6]
                            [7,8,9]};
elseif isequal(modelName, 'YOLOv4-tiny-coco')
    anchors.anchorBoxes = [82 81; 169 135; 319 344;...
                        27 23; 58 37; 82 81];
    anchors.anchorBoxMasks = {[1,2,3]
                            [4,5,6]};
end
end