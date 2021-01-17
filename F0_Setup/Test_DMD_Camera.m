% This script is used to quickly test the postion of the light path. Run
% the script and input the postion under the camera you want, a light spot
% will be blinking there.

DataFileName = 'Jan13Mapping.mat';
num_loop = 1;
num_loop_max = 100; % At most 100 dots can be tested. 
latency = 1;
radius = 50;

load([pwd '/data/' DataFileName])
X1 = [];
Y1 = [];
X2 = [];
Y2 = [];
% initialize DMD
clear d
d = DMD('debug', 1);
while num_loop < num_loop_max
    % Ask to input the coordinate of the roi
    prompt = 'Enter the x coordinated of the centre of dot\n';
    x2 = input(prompt);
    prompt = 'Enter the y coordinated of the centre of dot\n';
    y2 = input(prompt);
    % Predict the position using fitted model
    x1 = predict(md1,[x2 y2]);
    y1 = predict(md2,[x2 y2]);
    if x1>0 && x1<1080
        if y1>0 && y1<1080
            blink_a_defined_dot(d, latency, round(x1), round(y1), radius)
        else
            error('Dot is out of DMD')
        end
    else
        error('Dot is out of DMD')
    end
    % If the dot can be seen, record the position at DMD and coordinate in
    % the camera. Otherwise, turn to another dot.
    
    prompt = 'Do you want another dot? y/n [y]';
    str = input(prompt,'s');
    if str == 'n'
        break
    else
        X1 = [X1;x1];
        X2 = [X2;x2];
        Y1 = [Y1;y1];
        Y2 = [Y2;y2];
    end
    num_loop = num_loop + 1;
end



prompt = 'Enter file name if you want to save the data';
str = input(prompt,'s');
if isempty(str)
    fprintf('Data not saved')
else
    save([pwd '/data/' DataFileName],'X1', 'Y1', 'X2', 'Y2', 'md1', 'md2', 'md3', 'md4')
end





function blink_a_defined_dot(d, latency, x, y, radius)
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


function I = generate_round_spot(x, y, radius)
% Now you don't have to use int col and row!
I = ones(1920,1080);
[X,Y] = meshgrid(1:1080,1:1920);
X = (X-x).^2;
Y = (Y-y).^2;
I(X+Y>radius^2) = 0;
end