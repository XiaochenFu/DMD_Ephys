% 1. generate the spot and save into a 1920*1080*n matrix.
% 2. every time there's a trigger, upload transformed pattern (1080xd920).
% 3. save current time, current pattern (function, x, y, size) or image
% Current function XF_prepMultiBMp.m have some pronlem, need to fix

%%  ------------------Note---------------------- %%
% 1. Digital trigger seems to be not availiable. Will be removed
% 2. test pattern not implanted
% 3. Loop the defined grid

% 1). Loop around a defined ROI, present round /square dots
% 2). segment DMD and present square dots

%%



% This script is designed to present light dot to get the receptive field
% of the recording unit. We first define the center of the ROI. Then,
% analog input will be analysed continouly. If there's an abruct current
% increase, one pattern will be uploaded and presented.

% A csv file will be created automaticaaly to record the current time and
% the spot position

% the number of pulses, duration and the dark time of
% light pulses will be saved in the .mat file.

% The light presentation will can be triggered by an external trigger from
% labview vi.

clear
%-------------------Temporal profile of light spot------------------------%
% Define the light pulse for each ROI
latency = 0.08; % in seconds
DarkTime = 0.00; % in seconds. The time between trigger and presentation
% when the trigger is not working
num_pulse = 0; % number of pulses. If 0, the light will keep blinking.
triggerIn = 1;
%% -----------------Define the light spot --------------------- %%
% % -----------------Define the light spot from camera--------------------- %
% DataFileName = 'Apr28Mapping.mat';
% % Enter the center of the 'receptive field' we want to explore
% ROI_xc = 300;
% ROI_yc = 300;
% % The number of light dots will be num_step_x*num_step_y
% num_step_x = 3; % need to be odd
% num_step_y = 3; % need to be odd
% % Define the distance between two dots
% step_xc = 0;
% step_yc = 0;
% RandomOrNot = 1; % if 1, present the spots randomly
% % SpotGenFun = 'generate_square_spot';side_length = 100;
% SpotGenFun = 'generate_round_spot';radius = 40;
% MaxTime = 30; % min. stop the listener if the script is running tooooo long

% -----------------Define the light spot from DMD--------------------- % 
x_start = 5;
x_end = 8;
num_step_x = 4;

y_start = 7;
y_end = 10;
num_step_y = 4;

RandomOrNot = 0; % if 1, present the spots randomly
SpotGenFun = 'generate_grid_Ver2';
spot_position_X_DMD = [];
spot_position_Y_DMD = [];
grid_size = 120;
MaxTime = 30; % min. stop the listener if the script is running tooooo long

%-----------------Define the light spot from testpattern------------------%
% #Not tested yet
% SpotGenFun = 'testPattern';
% Pattern_Adresses = 7;
% Pattern Adresses:
%   0 = Solid field
%   1 = Horizontal ramp
%   2 = Vertical ramp
%   3 = Horizontal lines
%   4 = Diagonal lines
%   5 = Vertical lines
%   6 = Grid
%   7 = Checkerboard
%   8 = RGB ramp
%   9 = Color bars
%   10 = Step bars

%% -----------------------For Reading Trigger from NI---------------------- %%
Trigger_Type = "Analog";
% Trigger_Type = "Digital"; % Not tested yet
deviceID = 'Dev2';
measurementType = 'Voltage';
channelID = 1;




%%====================================================================== %%
CurrentFolder = pwd;
idcs = strfind(CurrentFolder,filesep);
ParentFolder = CurrentFolder(1:idcs(end)-1);
%creat log file
t = datestr(datetime);
t(t=='-')=[];
t(t==' ')='_';
t(t==':')=[];
TempDataFile = sprintf('Test_%s.mat',t);
ResultSaving = sprintf('%s/DataBackup/Test_%s.csv',ParentFolder,t);
%-------------------------------Load Data---------------------------------%
if sum(strcmp(SpotGenFun,{'generate_round_spot','generate_square_spot'}))
    load([ParentFolder '/F0_Setup/data/' DataFileName])
    % creat a array of coordiantes of the light spots. If random, shuffle the
    % dots. Otherwise, present one by one.
    if ~mod(num_step_x,2)
        error('num_step_x need to be odd')
    end
    if ~mod(num_step_y,2)
        error('num_step_y need to be odd')
    end
    % spot_position = zeros(num_step_x, num_step_y);
    x_start = ROI_xc - (num_step_x+1)/2 * step_xc;
    x_end = ROI_xc + (num_step_x+1)/2 * step_xc;
    x = linspace(x_start,x_end,num_step_x);
    y_start = ROI_yc - (num_step_y+1)/2 * step_yc;
    y_end = ROI_yc + (num_step_y+1)/2 * step_yc;
    y = linspace(y_start,y_end,num_step_y);
    [X,Y] = meshgrid(x,y);
    if RandomOrNot == 1 % if random,
        idx = randperm(num_step_x*num_step_y);
        spot_position_X_Camera = X(:);
        spot_position_X_Camera = spot_position_X_Camera(idx);
        spot_position_Y_Camera = Y(:);
        spot_position_Y_Camera = spot_position_Y_Camera(idx);
    elseif RandomOrNot == 0
        idx = 1:(num_step_x*num_step_y);
        spot_position_X_Camera = X(:);
        spot_position_X_Camera = spot_position_X_Camera(idx);
        spot_position_Y_Camera = Y(:);
        spot_position_Y_Camera = spot_position_Y_Camera(idx);
    else
        error('RandomOrNot should be 1 or 0')
    end
end

if strcmp(SpotGenFun,'generate_grid_Ver2')
    x = linspace(x_start,x_end,num_step_x);
    y = linspace(y_start,y_end,num_step_y);
   [X,Y] = meshgrid(x,y);
    if RandomOrNot == 1 % if random,
        idx = randperm(num_step_x*num_step_y);
        spot_position_X_DMD = X(:);
        spot_position_X_DMD = spot_position_X_DMD(idx);
        spot_position_Y_DMD = Y(:);
        spot_position_Y_DMD = spot_position_Y_DMD(idx);
    elseif RandomOrNot == 0
        idx = 1:(num_step_x*num_step_y);
        spot_position_X_DMD = X(:);
        spot_position_X_DMD = spot_position_X_DMD(idx);
        spot_position_Y_DMD = Y(:);
        spot_position_Y_DMD = spot_position_Y_DMD(idx);
    else
        error('RandomOrNot should be 1 or 0')
    end
end

%---------------------------Generate patterns-----------------------------%
switch SpotGenFun
    case 'generate_round_spot'
        spotConfig.radius = radius;
        spotConfig.idx = idx;
        spotConfig.spot_position_X_Camera = spot_position_X_Camera;
        spotConfig.spot_position_Y_Camera = spot_position_Y_Camera;
        spotConfig.md1 = md1;
        spotConfig.md2 = md2;
        spotConfig.SpotGenFun = SpotGenFun;
        spotConfig.triggerIn = triggerIn;
    case 'generate_square_spot'
        spotConfig.side_length = side_length;
        spotConfig.idx = idx;
        spotConfig.spot_position_X_Camera = spot_position_X_Camera;
        spotConfig.spot_position_Y_Camera = spot_position_Y_Camera;
        spotConfig.md1 = md1;
        spotConfig.md2 = md2;
        spotConfig.SpotGenFun = SpotGenFun;
        spotConfig.triggerIn = triggerIn;
    case 'testPattern'
        latency = 0;
        DarkTime = 0;
        num_pulse = 0;
        fprintf('\nDMD will not be triggered!!!!!\n')
    case 'generate_grid_Ver2'
        spotConfig.idx = idx;
        spotConfig.spot_position_X_DMD = spot_position_X_DMD;
        spotConfig.spot_position_Y_DMD = spot_position_Y_DMD;
        spotConfig.grid_size = grid_size;
        spotConfig.SpotGenFun = SpotGenFun;
        spotConfig.triggerIn = triggerIn;
end

spotConfig.latency = latency;
spotConfig.DarkTime = DarkTime;
spotConfig.num_pulse = num_pulse;
%-------------------------------------------------------------------------%





% initialize DMD
clear d
d = DMD('debug', 1);
% When trigger from the control is sent, loop over the dots
clear s
devices = daq.getDevices;
s = daq.createSession('ni');
% Set acquisition rate, in scans/second
s.Rate = 1000;

switch Trigger_Type
    case "Analog"
        addAnalogInputChannel(s,deviceID, channelID, measurementType);
    case "Digital"
        addDigitalChannel(s,deviceID,channelID,measurementType);
end

trigConfig.Channel = 1;
trigConfig.Level = 1;
trigConfig.Slope = 20;
bufferTimeSpan = double(s.NotifyWhenDataAvailableExceeds)/s.Rate*3;
bufferSize =  round(bufferTimeSpan * s.Rate);
tic

%-------------------------------------------------------------------------%
% Add a listener, so when data is availiable from the ni device, the data
% can be processed with a callback function
dataListener = addlistener(s, 'DataAvailable', @(src,event) UploadPatternAnalogTrigger(src, event, bufferSize, trigConfig, spotConfig, d,ResultSaving));
% Add a listener for acquisition error events which might occur during background acquisition
errorListener = addlistener(s, 'ErrorOccurred', @(src,event) disp(getReport(event.Error)));
% Start continuous background data acquisition
s.IsContinuous = true;
startBackground(s);
% while s.IsRunning
%     pause(1);
% end

fprintf('Ready to run Labview vi')
sss = input('Prese sss to stop\n','s');
if sss == 'sss'
    d.sleep()
    delete(dataListener);delete(errorListener);delete(s)% Disconnect from hardware
    % Save the positions in the default folder
    save([ParentFolder '/DataBackup/' TempDataFile])
else
    fprintf('\nPlease stop EventListener and SAVE DATA manually')
    
    % Save the positions in the default folder
    save([ParentFolder '/DataBackup/' TempDataFile])
end

if  toc> MaxTime*60 % Stop the experiment after 30min
    d.sleep()
    delete(dataListener);delete(errorListener);delete(s)% Disconnect from hardware
    % Save the positions in the default folder
    save([ParentFolder '/DataBackup/' TempDataFile])
    error('You are running the script for too long!')
end



function UploadPatternAnalogTrigger(src, event, bufferSize,trigConfig, spotConfig, d, ResultSaving)
% Here, src is the session object for the listener and event is a
% daq.DataAvailableInfo object containing the data and associated timing
% information.


% The incoming data (event.Data and event.TimeStamps) is stored in a
% persistent buffer (dataBuffer), which is sized to allow triggered data
% capture.

% Since multiple calls to dataCapture will be needed for a triggered
% capture, a trigger condition flag (trigActive) and a corresponding
% data timestamp (trigMoment) are used as persistent variables.
% Persistent variables retain their values between calls to the function.
persistent dataBuffer trigActive  ii

% If dataCapture is running for the first time, initialize persistent vars
if event.TimeStamps(1)==0
    dataBuffer = [];          % data buffer
    trigActive = false;       % trigger condition flag
    prevData = [];            % last data point from previous callback execution
    ii = 1;
else
    prevData = dataBuffer(end, :);
end

% Store continuous acquisition data in persistent FIFO buffer dataBuffer
latestData = [event.TimeStamps, event.Data];
dataBuffer = [dataBuffer; latestData];
numSamplesToDiscard = size(dataBuffer,1) - bufferSize;
if (numSamplesToDiscard > 0)
    dataBuffer(1:numSamplesToDiscard, :) = [];
end


% Analyze latest acquired data until trigger condition is met. After enough
% data is acquired for a complete capture, as specified by the capture
% timespan, extract the capture data from the data buffer and save it to a
% base workspace variable.
idx = spotConfig.idx;
SpotGenFun = spotConfig.SpotGenFun;
if ii>idx
    ii = 1;
    fprintf('\nAll dots are uploaded, please press Ctrl + C to stop!!\n')
    fprintf('\nOr the dots will be looped! \n')
end

if ~trigActive
    % State: "Looking for trigger event"
    [trigActive, ~] = trigDetect(prevData, latestData, trigConfig);
else
    
    % If spot is defined by camera, calculate  the position on the DMD. If
    % the spot is already defined by the DMD, just present pattern
    
    switch SpotGenFun
        case 'generate_round_spot'
            md1 = spotConfig.md1;
            md2 = spotConfig.md2;
            spot_position_X_Camera = spotConfig.spot_position_X_Camera;
            spot_position_Y_Camera = spotConfig.spot_position_Y_Camera;
            spot_position_X_DMD = predict(md1,[spot_position_X_Camera(ii) spot_position_Y_Camera(ii)]);
            spot_position_Y_DMD = predict(md2,[spot_position_X_Camera(ii) spot_position_Y_Camera(ii)]);
        case 'generate_square_spot'
            md1 = spotConfig.md1;
            md2 = spotConfig.md2;
            spot_position_X_Camera = spotConfig.spot_position_X_Camera;
            spot_position_Y_Camera = spotConfig.spot_position_Y_Camera;
            spot_position_X_DMD = predict(md1,[spot_position_X_Camera(ii) spot_position_Y_Camera(ii)]);
            spot_position_Y_DMD = predict(md2,[spot_position_X_Camera(ii) spot_position_Y_Camera(ii)]);
        case 'testPattern'
            error('Not implanted yet')
        case 'generate_grid_Ver2'
            spot_position_X_DMD = spotConfig.spot_position_X_DMD(ii);
            spot_position_Y_DMD = spotConfig.spot_position_Y_DMD(ii);
    end
    
    blink_a_defined_dot(d, spotConfig, spot_position_X_DMD, spot_position_Y_DMD);
    % Record the current time and the spot position in the csv file
    time = datestr(clock);
    stim_t = num2str(time);
    stim_t(stim_t==':')=[];
    stim_t = stim_t(end-5:end);
    
    switch SpotGenFun
        case 'generate_round_spot'
            Time_CameraXY = [str2num(stim_t) spot_position_X_Camera(ii) spot_position_Y_Camera(ii)];
            if ii == 1
                dlmwrite(ResultSaving,Time_CameraXY,'delimiter',',','precision',6)
            else
                dlmwrite(ResultSaving,Time_CameraXY,'-append','delimiter',',','precision',6)
            end
        case 'generate_square_spot'
            Time_CameraXY = [str2num(stim_t) spot_position_X_Camera(ii) spot_position_Y_Camera(ii)];
            if ii == 1
                dlmwrite(ResultSaving,Time_CameraXY,'delimiter',',','precision',6)
            else
                dlmwrite(ResultSaving,Time_CameraXY,'-append','delimiter',',','precision',6)
            end
        case 'testPattern'
            error('Not implanted yet')
        case 'generate_grid_Ver2'
            Time_DMD_XY = [str2num(stim_t) spot_position_X_DMD spot_position_Y_DMD];
            if ii == 1
                dlmwrite(ResultSaving,Time_DMD_XY,'delimiter',',','precision',6)
            else
                dlmwrite(ResultSaving,Time_DMD_XY,'-append','delimiter',',','precision',6)
            end
    end

    %     writematrix(Time_CameraXY,ResultSaving,'WriteMode','append'); % not
    %     yet supported in R2019A.......
    ii = ii+1;
    % Reset trigger flag, to allow for a new triggered data capture
    trigActive = false;
end
end



function blink_a_defined_dot(d, spotConfig, x, y)
% latency in second
% stop the current pattern and upload the dot. The dot will be blinking
% every ~ second, where ~ is the latency

d.patternControl(0)

latency = spotConfig.latency;
darkTime = spotConfig.DarkTime;
SpotGenFun = spotConfig.SpotGenFun;
num_pulse = spotConfig.num_pulse;
switch SpotGenFun
    case 'generate_round_spot'
        radius = spotConfig.radius;
        BMP = generate_round_spot(x, y, radius);
    case 'generate_square_spot'
        side_length = spotConfig.side_length;
        BMP = generate_square_spot(x, y, side_length);
    case 'generate_grid_Ver2'
        grid_size = spotConfig.grid_size;
        BMP = generate_grid_Ver2(x, y, grid_size);
end

% BMP1 = XF_prepMultiBMP(BMP');
BMP1 = prepBMP(BMP');

d.setMode()
idx             = 0;    % pattern index
exposureTime    = latency*1000000;  % exposure time in �s microsecond?
clearAfter      = 1;    % clear pattern after exposure
bitDepth        = 1;    % desired bit depth (1 corresponds to bitdepth of 1)
leds            = 1;    % select which color to use
triggerIn       = spotConfig.triggerIn;    % wait for trigger or cuntinue
darkTime        = darkTime*1000000;    % dark time after exposure in �s
triggerOut      = 1;    % use trigger2 as output
patternIdx      = 0;    % image pattern index
bitPosition     = 0;    % bit position in image pattern
d.definePattern2(idx,exposureTime, clearAfter, bitDepth, ...
    leds, triggerIn, darkTime, triggerOut, patternIdx, bitPosition);
% d.definePattern2(0,latency*1000000, 1, 1, 1, 0, latency*1000000, 0, 0, 0)
% set the number of images to be uploaded to one
d.numOfImages(1, num_pulse)
% initialize the pattern upload
d.initPatternLoad(0, size(BMP1,1))
% do the upload
d.XF_uploadPattern(BMP1)
% set the dmd state to play
d.patternControl(2)
end

function [trigDetected, trigMoment] = trigDetect(prevData, latestData, trigConfig)
%trigDetect Detect if trigger condition is met in acquired data
%   [trigDetected, trigMoment] = trigDetect(prevData, latestData, trigConfig)
%   Returns a detection flag (trigDetected) and the corresponding timestamp
%   (trigMoment) of the first data point which meets the trigger condition
%   based on signal level and slope specified by the trigger parameters
%   structure (trigConfig).
%   The input data (latestData) is an N x M matrix corresponding to N acquired
%   data scans, with the timestamps as the first column, and channel data
%   as columns 2:M. The previous data point prevData (1 x M vector of timestamp
%   and channel data) is used to determine the slope of the first data point.
%
%   trigConfig.Channel = index of trigger channel in data acquisition object channels
%   trigConfig.Level   = signal trigger level (V)
%   trigConfig.Slope   = signal trigger slope (V/s)

% Condition for signal trigger level
trigCondition1 = latestData(:, 1+trigConfig.Channel) > trigConfig.Level;

data = [prevData; latestData];

% Calculate slope of signal data points
% Calculate time step from timestamps
dt = latestData(2,1)-latestData(1,1);
slope = diff(data(:, 1+trigConfig.Channel))/dt;

% Condition for signal trigger slope
trigCondition2 = slope > trigConfig.Slope;

% If first data block acquired, slope for first data point is not defined
if isempty(prevData)
    trigCondition2 = [false; trigCondition2];
end

% Combined trigger condition to be used
trigCondition = trigCondition1 & trigCondition2;

trigDetected = any(trigCondition);
trigMoment = [];
if trigDetected
    % Find time moment when trigger condition has been met
    trigTimeStamps = latestData(trigCondition, 1);
    trigMoment = trigTimeStamps(1);
end
end



function [x,y] = randomly_blink_a_dot(d, latency, darkTime, x_start, x_end, y_start, y_end, radius)
% Randomly blink a dot in a defined range

% latency in second
x = randi([x_start+radius, x_end-radius],1,1);
y = randi([y_start+radius, y_end-radius],1,1);
% stop the current pattern and upload the dot. The dot will be blinking
% every ~ second, where ~ is the latency
pause(0.1)
d.patternControl(0)
BMP = generate_round_spot(x, y, radius);
% BMP1 = XF_prepMultiBMP(BMP');
BMP1 = prepBMP(BMP');

d.setMode()
idx             = 0;    % pattern index
exposureTime    = latency*1000000;  % exposure time in �s microsecond?
clearAfter      = 1;    % clear pattern after exposure
bitDepth        = 1;    % desired bit depth (1 corresponds to bitdepth of 1)
leds            = 1;    % select which color to use
triggerIn       = 0;    % wait for trigger or cuntinue
darkTime        = darkTime*1000000;    % dark time after exposure in �s
triggerOut      = 1;    % use trigger2 as output
patternIdx      = 0;    % image pattern index
bitPosition     = 0;    % bit position in image pattern
d.definePattern2(idx,exposureTime, clearAfter, bitDepth, ...
    leds, triggerIn, darkTime, triggerOut, patternIdx, bitPosition);
% d.definePattern2(1,latency*1000000, 1, 1, 1, 0, 0, 0, 0, 1)
% set the number of images to be uploaded to one
d.numOfImages(1, 0)
% initialize the pattern upload
d.initPatternLoad(0, size(BMP1,1))
% do the upload
d.XF_uploadPattern(BMP1)
% set the dmd state to play
d.patternControl(2)
end


function I = generate_square_spot(x, y, side_length)
% Now you don't have to use int col and row!
I = ones(1920,1080);
[X,Y] = meshgrid(1:1080,1:1920);
X = (X-x).^2;
Y = (Y-y).^2;
I(X>side_length^2/4) = 0;
I(Y>side_length^2/4) = 0;
end

function I = generate_round_spot(x, y, radius)
% Now you don't have to use int col and row!
I = ones(1920,1080);
[X,Y] = meshgrid(1:1080,1:1920);
X = (X-x).^2;
Y = (Y-y).^2;
I(X+Y>radius^2) = 0;
end
function I = generate_grid_Ver2(col, row, size)
% Now you don't have to use int col and row!
I = ones(1920,1080);
[X,Y] = meshgrid(1:1080,1:1920);
Y = Y/size;%ceil(Y/size);
X = X/size;%ceil(X/size);
I(X<=col-1) = 0;
I(X>col) = 0;
I(Y <= row-1) = 0;
I(Y>row) = 0;
end
