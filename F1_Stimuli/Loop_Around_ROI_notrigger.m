% This script is designed to present light dot to get the receptive field
% of the recording unit. Each tiem, a light spot near the ROI will be
% uploaded, ordered or randomly.

% Data is saved by default in the folder 'DataBackup', with the date and
% time. 

% In the sister MC paper, square dots are used and presented for 200 ms in 
% 500-ms trials
 

clear

DataFileName = 'Feb10Mapping.mat';

ROI_x2 = 500;
ROI_y2 = 500;
num_step_x = 3; % need to be odd
num_step_y = 3; % need to be odd
step_x2 = 30;
step_y2 = 30;
RandomOrNot = 1; % if 1, present the spots randomly
% RoundOrSquare = 'Round';
RoundOrSquare = 'Square';
side_length = 100;
num_pulse = 3; % number of pulses. If 0, the light will keep blinking.
triggerIn = 0;
CurrentFolder = pwd;
idcs = strfind(CurrentFolder,filesep);
ParentFolder = CurrentFolder(1:idcs(end)-1);
load([ParentFolder '/F0_Setup/data/' DataFileName])
latency = 0.5;
DarkTime = 0.5; 

radius = 50;
% The light presentation every 2 second
latency_between_blinks = 2;

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
y_start = ROI_y2 - (num_step_y+1)/2 * step_y2;
y_end = ROI_y2 + (num_step_y+1)/2 * step_y2;
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

% initialize DMD
clear d
d = DMD('debug', 1);
% When trigger from the control is sent, loop over the dots

for i = 1:length(idx)
    spot_position_X2 = spotConfig.spot_position_X2;
    spot_position_Y2 = spotConfig.spot_position_Y2;
    spot_position_x1 = predict(md1,[spot_position_X2(i) spot_position_Y2(i)]);
    spot_position_y1 = predict(md2,[spot_position_X2(i) spot_position_Y2(i)]);
    
    
    blink_a_defined_dot(d, spotConfig, spot_position_x1, spot_position_y1);
    pause(latency_between_blinks)
    formatSpec = '(%d, %d)';
    fprintf(formatSpec,spot_position_X2(i),spot_position_Y2(i))
end



% Save the positions in the default folder
time = datestr(now, 'yyyy_mm_dd');
filename = sprintf('Optimization_%s.mat',time);
save([ParentFolder '/DataBackup/' DataFileName])




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


% d.display(BMP')
BMP1 = prepBMP(BMP');

% BMP1 = XF_prepMultiBMP(BMP'); %#### Simthing wrong with this file
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


function I = generate_round_spot(x, y, radius)
% Now you don't have to use int col and row!
I = ones(1920,1080);
[X,Y] = meshgrid(1:1080,1:1920);
X = (X-x).^2;
Y = (Y-y).^2;
I(X+Y>radius^2) = 0;
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

