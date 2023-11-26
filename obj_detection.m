function varargout = obj_detection(varargin)
% OBJ_DETECTION MATLAB code for obj_detection.fig
%      OBJ_DETECTION, by itself, creates a new OBJ_DETECTION or raises the existing
%      singleton*.
%
%      H = OBJ_DETECTION returns the handle to a new OBJ_DETECTION or the handle to
%      the existing singleton*.
%
%      OBJ_DETECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OBJ_DETECTION.M with the given input arguments.
%
%      OBJ_DETECTION('Property','Value',...) creates a new OBJ_DETECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before obj_detection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to obj_detection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help obj_detection

% Last Modified by GUIDE v2.5 15-Jun-2022 12:29:24

% Begin initialization code - DO NOT EDIT
addpath('function');
clear global variable;
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @obj_detection_OpeningFcn, ...
                   'gui_OutputFcn',  @obj_detection_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before obj_detection is made visible.
function obj_detection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to obj_detection (see VARARGIN)

% Choose default command line output for obj_detection
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes obj_detection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = obj_detection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in LoadImg.
function LoadImg_Callback(hObject, eventdata, handles)
% hObject    handle to LoadImg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Predictor;
[filename, pathname] = uigetfile({'*.jpg';'*.png'},'读取图片文件'); %选择图片文件
if isequal(filename,0)   %判断是否选择了图片
   msgbox('没有选择任何图片');
else
   pathfile=fullfile(pathname, filename);  %获得图片路径
    Predictor.Mat=imread(pathfile);
   Predictor.Mat_name=filename;
   Predictor.STATE=0;   %表示读入的是图片
   axes(handles.axes1);
   set(handles.Img0,'string','原图');
   set(handles.ImgLabel0,'string',filename,'visible','on');
   imshow(Predictor.Mat);
   %初始化图片展示区
   cla(handles.axes2,'reset');
   set(handles.axes2,'xtick',[],'ytick',[],'box','on');
   %初始化标签区域
   set(handles.edit1,'string','-');
   set(handles.edit2,'string','');
   set(handles.edit3,'string','');
   set(handles.edit4,'string','');
   set(handles.GivenLabelText,'string','-');
   set(handles.edit5,'string','-');
   set(handles.ImgLabel1,'string','-','visible','off');
end



% --- Executes on button press in LoadVideo.
function LoadVideo_Callback(hObject, eventdata, handles)
% hObject    handle to LoadVideo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Predictor;
[filename, pathname] = uigetfile({'*.avi';'*.mp4'},'读取视频文件');
if isequal(filename,0) 
   msgbox('没有选择任何视频');
else
    %初始化图片展示区
    cla(handles.axes2,'reset');
    set(handles.axes2,'xtick',[],'ytick',[],'box','on');
    %初始化标签区域
    set(handles.edit1,'string','-');
    set(handles.edit2,'string','');
    set(handles.edit3,'string','');
    set(handles.edit4,'string','');
    set(handles.GivenLabelText,'string','-');
    set(handles.edit5,'string','-');
    set(handles.Img1,'string','图1','visible','on');
    set(handles.ImgLabel1,'string','-','visible','off');
    pathfile=fullfile(pathname, filename);
    Predictor.Video=VideoReader(pathfile);
    Predictor.STATE=1; %读入的是视频
    Predictor.Video.CurrentTime=1; % 设置读入视频的播放起点
    nFrame = Predictor.Video.NumberOfFrame;
    axes(handles.axes1);
    set(handles.Img0,'string','原文件');
    set(handles.ImgLabel0,'string',filename);
    while(hasFrame(Predictor.Video))
        Predictor.Mat=readFrame(Predictor.Video);
        imshow(Predictor.Mat);
        pause(0.005);
    end
end


% --- Executes on button press in ObjDetec.
function ObjDetec_Callback(hObject, eventdata, handles)
% hObject    handle to ObjDetec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% dataPath = 'models';
global img_yolov4;
global Predictor;
if (Predictor.STATE==0) %读取的是图片
    if (get(handles.checkbox_YOLOv4,'value')==1)
        modelName = 'YOLOv4-coco';        %导入YOLOv4模型
        model = load(['models/', modelName, '.mat']);
%                 model = load('./models/YOLOv4-coco.mat');
        net = model.net;
%         img=Predictor.Mat; %若要保存原图，则取消此句注释，并注释下一句
        img =imresize( Predictor.Mat,[240 320]); % 设置图像大小，使图像能够显示清楚
        classNames =getCOCOClassNames;        % 获得 COCO 数据集的分类名
        anchors=getAnchors(modelName);    % 获得预训练模型训练时使用的anchors
        executionEnvironment = 'auto';        % 设置检测模式
        [bboxes, scores, labels] = detectYOLOv4(net, img, anchors, classNames, executionEnvironment);
        % 可视化结果
        annotations = string(labels) + ": " + string(scores);
        img_yolov4 = insertObjectAnnotation(img, 'rectangle', bboxes, annotations);
        % 显示在图片显示区域
        axes(handles.axes2);
        imshow(img_yolov4);
        set(handles.ImgLabel1,'string','YOLOv4识别结果','visible','on');
        num_detect = length(scores);
        set(handles.edit1,'string',num_detect);
        %获得图片中目标识别的标签和置信度，并输入
        calss_label=[];
        confidence=[];
        for j=1:length(labels)
            calss_label_temp=labels(j);
            calss_label=[calss_label,calss_label_temp];
            confidence_temp=scores(j);
            confidence=[confidence confidence_temp];
        end
        set(handles.edit2,'string',calss_label);
        set(handles.edit3,'string',confidence);
    end
    %使用AlexNet识别
    if (get(handles.checkbox_AlexNet,'value')==1)
        img = Predictor.Mat;
        figure('name','AlexNet识别结果');
        %调用AlexNet模型，前提是安装了Deep Learning Toolbox并且已经装载AlexNet
        net=alexnet;
        sz = net.Layers(1).InputSize;
        img = imresize(img,sz(1:2));
        [label,conf] = classify(net,img);
        imshow(img);
        title(sprintf('%s %.2f',char(label),max(conf)));
    end
    %使用AlexNet迁移学习识别
    if (get(handles.checkbox_ANTransfered,'value')==1)
        %装载net文件， 调用AlexNet_TransferLearning模型
        load('models/AlexNet_TransferLearning.mat');
        img = Predictor.Mat;
        img = imresize(img,[227,227]);
        [label,conf] = classify(net,img);
        figure('name','AlexNet迁移学习识别结果');
        imshow(img);
        title(sprintf('%s %.2f',char(label),max(conf)));
    end
    %使用MaskRCNN识别
    if (get(handles.checkbox_MaskRCNN,'value')==1)
        % 调用maskrcnn预训练模型，
        model = load('models/maskrcnn_pretrained_person_car.mat');
        net = model.net;
        img = Predictor.Mat;
        % 提取Mask分割sub-network
        maskSubnet = extractMaskNetwork(net);
        if canUseGPU
            executionEnvironment = "gpu";
        else
            executionEnvironment = "cpu";
        end
        % 定义用于推断的图像的目标大小
        targetSize = [700 700 3];
        % 设定尺寸为目标大小。
        imgSize = size(img);
        [~, maxDim] = max(imgSize);
        resizeSize = [NaN NaN];
        resizeSize(maxDim) = targetSize(maxDim);
        img = imresize(img, resizeSize);
        % 设置网络参数
        trainImgSize = [800 800 3];
        classNames = {'person', 'car', 'background'};
        numClasses = 2;
        % 创建网络参数结构
        params = createMaskRCNNConfig(trainImgSize, numClasses, classNames);
        % 检测物体和它们的masks
        [boxes, scores, labels, masks] = detectMaskRCNN(net, maskSubnet, img, params, executionEnvironment);
        if(isempty(masks))
            overlayedImage = img;
        else
            overlayedImage = insertObjectMask(img, masks);
        end    
        figure('name','MaskRCNN识别结果');
        imshow(overlayedImage);
%         annotations = string(labels) + ": " + string(scores);
       showShape("rectangle", gather(boxes), "Label", labels, "LineColor",'r');
    end
    
elseif (Predictor.STATE==1) %读取的是视频
    modelName = 'YOLOv4-coco';
    model = load(['models/', modelName, '.mat']);
    net = model.net;
    nFrame = Predictor.Video.NumberOfFrame;
    Predictor.Video.CurrentTime=0.5;
    set(handles.Img1,'string','YOLOv4视频识别');
    axes(handles.axes2);

    while  hasFrame(Predictor.Video)
        img=readFrame(Predictor.Video);
        img=imresize(img,[240 320]);
        classNames =getCOCOClassNames;  % 获取COCO数据集的类名。
        anchors=getAnchors(modelName);  % 获得预训练模型训练时使用的锚点。
        executionEnvironment = 'auto';   % 设置执行环境，'auto'为自动识别环境，若有gpu则会使用gpu，'gpu'为指定使用gpu
        [bboxes, scores, labels] = detectYOLOv4(net, img, anchors, classNames, executionEnvironment);
        % Visualize detection results.
        annotations = string(labels) + ": " + string(scores);
        img = insertObjectAnnotation(img, 'rectangle', bboxes, annotations);
        set(handles.Img1,'string','视频1');
        imshow(img);
        num_detect = length(scores);
        set(handles.edit1,'string',num_detect);
        calss_label=[];
        confidence=[];
        for j=1:length(labels)
            calss_label_temp=labels(j);
            calss_label=[calss_label calss_label_temp];
            confidence_temp=scores(j);
            confidence=[confidence confidence_temp];
        end
        set(handles.edit2,'string',calss_label);
        set(handles.edit3,'string',confidence);
        time_label=[num2str(Predictor.Video.CurrentTime),'s','/',num2str(Predictor.Video.Duration),'s'];
        set(handles.ImgLabel1,'string',time_label,'visible','on');
        pause(1/Predictor.Video.FrameRate);   %若觉得播放速度过快，可以设置播放速度
        
    end
    msgbox('视频识别完毕,请重新加载!','完成');
    set(handles.ImgLabel1,'string','-','visible','off');
end

% --- Executes on button press in ShowGivenLabel.
function ShowGivenLabel_Callback(hObject, eventdata, handles)
% hObject    handle to ShowGivenLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global img_yolov4;
global Predictor;
if (Predictor.STATE==0) %读取的是图片
        choosen_label=get(handles.GivenLabelText,'string');
        modelName = 'YOLOv4-coco';
        model = load(['models/', modelName, '.mat']);
        net = model.net;
        % 设置图片为网络规定的大小
        img_yolov4 =imresize( Predictor.Mat,[240 320]);
        classNames =getCOCOClassNames;
        anchors=getAnchors(modelName);
        executionEnvironment = 'auto';
        [bboxes, scores, labels] = detectYOLOv4(net, img_yolov4, anchors, classNames, executionEnvironment);
        % 可视化结果
        given_label_count=0;
        calss_label=[];
        confidence=[];
        for i=1:length(labels)
            if (labels(i)==choosen_label)
                annotations = string(labels(i)) + ": " + string(scores(i));
                img_yolov4 = insertObjectAnnotation(img_yolov4, 'rectangle', bboxes(i,:), annotations);
                given_label_count=given_label_count+1;
                calss_label_temp=labels(i);
                calss_label=[calss_label,calss_label_temp];
                confidence_temp=scores(i);
                confidence=[confidence confidence_temp];
            end
        end
        axes(handles.axes2);
        imshow(img_yolov4);
        set(handles.ImgLabel1,'string','YOLOv4识别指定标签结果','visible','on');
        num_detect = given_label_count;
        set(handles.edit5,'string',num_detect);
        set(handles.edit4,'string',confidence);
else
    msgbox('显示指定标签功能只支持图片！','错误');
end


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2


% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2


% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton3


% --- Executes on button press in checkbox_YOLOv4.
function checkbox_YOLOv4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_YOLOv4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_YOLOv4


% --- Executes on button press in checkbox_AlexNet.
function checkbox_AlexNet_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_AlexNet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_AlexNet


% --- Executes on button press in checkbox_ANTransfered.
function checkbox_ANTransfered_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_ANTransfered (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_ANTransfered


% --- Executes on button press in checkbox_MaskRCNN.
function checkbox_MaskRCNN_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_MaskRCNN (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_MaskRCNN


% --- Executes on button press in SaveImg.
function SaveImg_Callback(hObject, eventdata, handles)
% hObject    handle to SaveImg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global img_yolov4;
global Predictor;
if (Predictor.STATE==0)
    if (size(img_yolov4)~=0)
        filename=Predictor.Mat_name;
        filename=[filename,'yolov4识别结果','.jpg'];
        imwrite(img_yolov4,filename,'jpg');
        msgbox('图片保存成功！','完成');
    else
        errordlg('请选择图片并处理！','错误');
    end
else
    errordlg('只能保存图片！','错误');
end

% --- Executes on button press in Clear.
function Clear_Callback(hObject, eventdata, handles)
% hObject    handle to Clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% %初始化图片展示区
cla(handles.axes1,'reset');
cla(handles.axes2,'reset');
set(handles.axes1,'xtick',[],'ytick',[],'box','on');
set(handles.axes2,'xtick',[],'ytick',[],'box','on');
%初始化标签区域
set(handles.edit1,'string','-');
set(handles.edit2,'string','');
set(handles.edit3,'string','');
set(handles.edit4,'string','');
set(handles.GivenLabelText,'string','-');
set(handles.edit5,'string','-');
set(handles.Img0,'string','图0','visible','on');
set(handles.Img1,'string','图1','visible','on');
set(handles.ImgLabel0,'string','-','visible','off');
set(handles.ImgLabel1,'string','-','visible','off');
clear all;



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function GivenLabelText_Callback(hObject, eventdata, handles)
% hObject    handle to GivenLabelText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of GivenLabelText as text
%        str2double(get(hObject,'String')) returns contents of GivenLabelText as a double


% --- Executes during object creation, after setting all properties.
function GivenLabelText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GivenLabelText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit4_Callback(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit4 as text
%        str2double(get(hObject,'String')) returns contents of edit4 as a double


% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function ObjDetec_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ObjDetec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
