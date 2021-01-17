% This file is still messy


% This script is designed to present light dot to get the receptive field
% of the recording unit. We first define the center of the ROI. Then,
% analog input will be analysed continouly. If there's an abruct current
% increase, one pattern will be uploaded and presented. 

% The light presentation will can be triggered by an external trigger from
% labview vi.

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
RoundOrSquare = 'Round';
% RoundOrSquare = 'Square'; % Not implanted yet.
DataFileName = 'Jan12Mapping.mat';
CurrentFolder = pwd;
idcs = strfind(CurrentFolder,filesep);
ParentFolder = CurrentFolder(1:idcs(end)-1);
load([ParentFolder '/F0_Setup/data/' DataFileName])
latency = 0.5;
radius = 50;
side_length = 50;



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
spotConfig.spot_position_X2 = spot_position_X2;
spotConfig.spot_position_Y2 = spot_position_Y2;
spotConfig.md1 = md1;
spotConfig.md2 = md2;
spotConfig.RoundOrSquare = RoundOrSquare;
switch RoundOrSquare
    case 'Round'
        spotConfig.radius = radius;
    case 'Square'
        spotConfig.side_length = side_length;
end

tic
while  toc<20 
dataListener = addlistener(s, 'DataAvailable', @(src,event) UploadPatternWhenTriggered(src, event, bufferSize, trigConfig, spotConfig, d));
% Add a listener for acquisition error events which might occur during background acquisition
% errorListener = addlistener(s, 'ErrorOccurred', @(src,event) disp(getReport(event.Error)));
% Start continuous background data acquisition
s.IsContinuous = true;
startBackground(s);
while s.IsRunning
    pause(1);
end
delete(dataListener);
delete(errorListener);
% Disconnect from hardware
delete(s)
end

% Save the positions in the default folder
time = datestr(now, 'yyyy_mm_dd');
filename = sprintf('Optimization_%s.mat',time);
save([ParentFolder '/DataBackup/' DataFileName])


function UploadPatternWhenTriggered(src, event, bufferSize,trigConfig, spotConfig, d)
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
    RoundOrSquare = spotConfig.RoundOrSquare;
    spot_position_X2 = spotConfig.spot_position_X2;
    spot_position_Y2 = spotConfig.spot_position_Y2;
    latency = spotConfig.latency;
    x1 = predict(md1,[spot_position_X2(ii) spot_position_Y2(ii)]);
    y1 = predict(md2,[spot_position_X2(ii) spot_position_Y2(ii)]);
    switch RoundOrSquare
        case 'Round'
            radius = spotConfig.radius;
            blink_a_defined_dot_round(d, latency, x1, y1, radius);
        case 'Square'
            side_length = spotConfig.side_length;
            blink_a_defined_dot_square(d, latency, x1, y1, side_length);
    end
    
    
    ii = ii+1;
    
    % Reset trigger flag, to allow for a new triggered data capture
    trigActive = false;
end


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

function blink_a_defined_dot_round(d, latency, x, y, radius)
% latency in second
% stop the current pattern and upload the dot. The dot will be blinking
% every ~ second, where ~ is the latency

d.patternControl(0)
BMP = generate_round_spot(x, y, radius);
BMP1 = XF_prepMultiBMP(BMP');

d.setMode()
d.definePattern2(0,latency*1000000, 1, 1, 1, 0, latency*1000000, 0, 0, 0)
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

function blink_a_defined_dot_square(d, latency, x, y, side_length)
% latency in second
% stop the current pattern and upload the dot. The dot will be blinking
% every ~ second, where ~ is the latency

d.patternControl(0)
BMP = generate_square_spot(x, y, side_length);
BMP1 = XF_prepMultiBMP(BMP');

d.setMode()
d.definePattern2(0,latency*1000000, 1, 1, 1, 0, latency*1000000, 0, 0, 0)
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

function [x,y] = randomly_blink_a_dot(d, latency, x_start, x_end, y_start, y_end, radius)
% latency in second
x = randi([x_start+radius, x_end-radius],1,1);
y = randi([y_start+radius, y_end-radius],1,1);
% stop the current pattern and upload the dot. The dot will be blinking
% every ~ second, where ~ is the latency
pause(0.1)
d.patternControl(0)
BMP = generate_round_spot(x, y, radius);
BMP1 = XF_prepMultiBMP(BMP');

d.setMode()
d.definePattern2(0,latency*1000000, 1, 1, 1, 0, latency*1000000, 0, 0, 0)
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
