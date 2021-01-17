% We need to read the trigger continouly from the analog input. Data stream
% every bufferTimeSpan second will be saved into a buffer. Then we will see
% whether there's a voltage step. If yes, something will be printed 

% Analog input 1, (screw 3 and 4. The inout are connected to AO2)
clc
clear s
devices = daq.getDevices;
s = daq.createSession('ni');
% Set acquisition rate, in scans/second
s.Rate = 100;
ch1 = addAnalogInputChannel(s,'Dev2', 1, 'Voltage'); % Change the channel name
% Add a listener, so when data is availiable from the ni device, the data
% can be processed with a callback function 
trigConfig.Channel = 1;
trigConfig.Level = 1;
trigConfig.Slope = 20;
bufferTimeSpan = double(s.NotifyWhenDataAvailableExceeds)/s.Rate*3;
bufferSize =  round(bufferTimeSpan * s.Rate);
tic 
while toc<20
dataListener = addlistener(s, 'DataAvailable', @(src,event) ProcessData(src, event, bufferSize, trigConfig));
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

function ProcessData(src, event, bufferSize,trigConfig)
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
persistent dataBuffer trigActive trigMoment

% If dataCapture is running for the first time, initialize persistent vars
if event.TimeStamps(1)==0
    dataBuffer = [];          % data buffer
    trigActive = false;       % trigger condition flag
    trigMoment = [];          % data timestamp when trigger condition met
    prevData = [];            % last data point from previous callback execution
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

if ~trigActive
    % State: "Looking for trigger event"
    [trigActive, trigMoment] = trigDetect(prevData, latestData, trigConfig);
else
    fprintf("I'm triggered\n")
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