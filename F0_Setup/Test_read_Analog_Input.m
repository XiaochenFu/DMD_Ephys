clear 
devices = daq.getDevices;
s = daq.createSession('ni');
% Sample rate, 100 point per second. Default 1000
s.Rate = 100;
ch1 = addAnalogInputChannel(s,'Dev2', 1, 'Voltage'); 
% data = s.inputSingleScan;
% Every time, get signal for 1 second. The default value is 1 second 
s.DurationInSeconds = 2; 
% Read data for DurationInSeconds
[data,time] = s.startForeground;
plot(time,data);


% tic 
% while toc < 30
%     s.DurationInSeconds = 1;
%     [TrailType,~] = s.startBackground();
% end
