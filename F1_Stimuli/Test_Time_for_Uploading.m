% Test_Time_for_Uploading.m This script is used to identify the parameter
% 'time for uploading' in the labview vi. The time needed will be printed
% at the matlab command window. 
% Adapted form Loop_Around_ROI.m

tic
% Enter the center of the 'receptive field' we want to explore
ROI_x2 = 659;
ROI_y2 = 511;
% The number of light dots will be num_step_x*num_step_y
num_step_x = 3; % need to be odd
num_step_y = 3; % need to be odd
% Define the distance between two dots
step_x2 = 50;
step_y2 = 50;
RandomOrNot = 0; % if 1, present the spots randomly

DataFileName = 'Feb03Mapping.mat';
CurrentFolder = pwd;
idcs = strfind(CurrentFolder,filesep);
ParentFolder = CurrentFolder(1:idcs(end)-1);    
load([ParentFolder '/F0_Setup/data/' DataFileName])

% Define the light pulse for each ROI
latency = 0.5; % in seconds
DarkTime = 0.3; % in seconds. The time between two light pulse
num_pulse = 0; % number of pulses. If 0, the light will keep blinking.
radius = 400;
side_length = 50;
triggerIn = 1;
RoundOrSquare = 'Round';
% RoundOrSquare = 'Square';
MaxTime = 30; % min. stop the listener if the script is running tooooo long

%creat log file
t = datestr(datetime);
% t = num2str(time)
t(t=='-')=[]
t(t==' ')='_'
t(t==':')=[]
TempDataFile = sprintf('Test_%s.mat',t);
TempSpotFile = sprintf('%s/DataBackup/Test_%s.csv',ParentFolder,t);
% eval(sprintf('diary %s/DataBackup/%s', ParentFolder, t))

% creat a array of coordiantes of the light spots. If random, shuffle the
% dots. Otherwise, present one by one.

if ~mod(num_step_x,2)
    error('num_step_x need to be odd')
end
if ~mod(num_step_y,2)
    error('num_step_y need to be odd')
end
% spot_position = zeros(num_step_x, num_step_y);
x_start = ROI_x2 - (num_step_x+1)/2 * step_x2;
x_end = ROI_x2 + (num_step_x+1)/2 * step_x2;
x = linspace(x_start,x_end,num_step_x);
y_start = ROI_x2 - (num_step_y+1)/2 * step_y2;
y_end = ROI_x2 + (num_step_y+1)/2 * step_y2;
y = linspace(y_start,y_end,num_step_y);
[X,Y] = meshgrid(x,y);
if RandomOrNot == 1 % if random,
    idx = randperm(num_step_x*num_step_y);
    spot_position_X2 = X(:);
    spot_position_X2 = spot_position_X2(idx);
    spot_position_Y2 = Y(:);
    spot_position_Y2 = spot_position_Y2(idx);
elseif RandomOrNot == 0
    idx = 1:(num_step_x*num_step_y);
    spot_position_X2 = X(:);
    spot_position_X2 = spot_position_X2(idx);
    spot_position_Y2 = Y(:);
    spot_position_Y2 = spot_position_Y2(idx);
else
    error('RandomOrNot should be 1 or 0')
end
% initialize DMD
clear d
d = DMD('debug', 1);
% When trigger from the control is sent, loop over the dots
clear s
devices = daq.getDevices;
s = daq.createSession('ni');
% Set acquisition rate, in scans/second
s.Rate = 1000;
ch1 = addAnalogInputChannel(s,'Dev2', 1, 'Voltage'); % Change the channel name
% Add a listener, so when data is availiable from the ni device, the data
% can be processed with a callback function
trigConfig.Channel = 1;
trigConfig.Level = 1;
trigConfig.Slope = 20;
bufferTimeSpan = double(s.NotifyWhenDataAvailableExceeds)/s.Rate*3;
bufferSize =  round(bufferTimeSpan * s.Rate);
spotConfig.idx = idx;
spotConfig.latency = latency;
spotConfig.DarkTime = DarkTime;
spotConfig.num_pulse = num_pulse;
spotConfig.spot_position_X2 = spot_position_X2;
spotConfig.spot_position_Y2 = spot_position_Y2;
spotConfig.md1 = md1;
spotConfig.md2 = md2;
spotConfig.RoundOrSquare = RoundOrSquare;
spotConfig.triggerIn = triggerIn;
switch RoundOrSquare
    case 'Round'
        spotConfig.radius = radius;
    case 'Square'
        spotConfig.side_length = side_length;
end

dataListener = addlistener(s, 'DataAvailable', @(src,event) UploadPatternWhenTriggered(src, event, bufferSize, trigConfig, spotConfig, d,TempSpotFile));
% Add a listener for acquisition error events which might occur during background acquisition
errorListener = addlistener(s, 'ErrorOccurred', @(src,event) disp(getReport(event.Error)));
% Start continuous background data acquisition
s.IsContinuous = true;
startBackground(s);
% while s.IsRunning
%     pause(1);
% end
toc
fprintf('\nTime to run vi\n')
fprintf('Ready to run Labview vi\n')
sss = input('Prese sss to stop\n','s');



if sss == 'sss'
    d.sleep()
    delete(dataListener);delete(errorListener);delete(s)% Disconnect from hardware
    % Save the positions in the default folder
    save([ParentFolder '/DataBackup/' TempDataFile])
    diary off
else
    fprintf('\nPlease stop EventListener and SAVE DATA manually')
    
    % Save the positions in the default folder
    save([ParentFolder '/DataBackup/' TempDataFile])
end

% if  toc> MaxTime*60 % Stop the experiment after 30min
%     d.sleep()
%     delete(dataListener);delete(errorListener);delete(s)% Disconnect from hardware
%     % Save the positions in the default folder
%     save([ParentFolder '/DataBackup/' TempDataFile])
%     diary off
%     error('You are running the script for too long!')
% end
% 


function UploadPatternWhenTriggered(src, event, bufferSize,trigConfig, spotConfig, d, TempSpotFile)

tic
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
md1 = spotConfig.md1;
md2 = spotConfig.md2;
if ii>idx
    ii = 1;
    fprintf('\nAll dots are uploaded, please press Ctrl + C to stop!!\n')
    fprintf('\nOr the dots will be looped! \n')
end

if ~trigActive
    % State: "Looking for trigger event"
    [trigActive, ~] = trigDetect(prevData, latestData, trigConfig);
else
    
    spot_position_X2 = spotConfig.spot_position_X2;
    spot_position_Y2 = spotConfig.spot_position_Y2;
    
    spot_position_x1 = predict(md1,[spot_position_X2(ii) spot_position_Y2(ii)]);
    spot_position_y1 = predict(md2,[spot_position_X2(ii) spot_position_Y2(ii)]);
    blink_a_defined_dot(d, spotConfig, spot_position_x1, spot_position_y1);
    toc
    fprintf('Time for upload')
    % Record the current time and the spot position in the csv file
    time = datestr(clock);
    stim_t = num2str(time);
    stim_t(stim_t==':')=[];
    stim_t = stim_t(end-5:end);
    Time_CameraXY = [str2num(stim_t) spot_position_X2(ii) spot_position_Y2(ii)];
    if ii == 1
        dlmwrite(TempSpotFile,Time_CameraXY,'delimiter',',','precision',6)
    else
        dlmwrite(TempSpotFile,Time_CameraXY,'-append','delimiter',',','precision',6)
    end
    
    
%     writematrix(Time_CameraXY,TempSpotFile,'WriteMode','append'); % not
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
RoundOrSquare = spotConfig.RoundOrSquare;
num_pulse = spotConfig.num_pulse;
switch RoundOrSquare
    case 'Round'
        radius = spotConfig.radius;
        BMP = generate_round_spot(x, y, radius);
    case 'Square'
        side_length = spotConfig.side_length;
        BMP = generate_square_spot(x, y, side_length);
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
