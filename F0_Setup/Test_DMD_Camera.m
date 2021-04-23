% This script is used to quickly test the postion of the light path. Run
% the script and input the postion under the camera you want, a light spot
% will be blinking there.

DataFileName = 'Apr21Mapping.mat';
num_loop = 1;
num_loop_max = 100; % At most 100 dots can be tested. 
latency = 1;
radius = 50;

load([pwd '/data/' DataFileName])
X_DMD = [];
Y_DMD = [];
X_Camera = [];
Y_Camera = [];
% initialize DMD
clear d
d = DMD('debug', 1);
while num_loop < num_loop_max
    % Ask to input the coordinate of the roi
    prompt = 'Enter the x coordinated of the centre of dot\n';
    xc = input(prompt);
    prompt = 'Enter the y coordinated of the centre of dot\n';
    yc = input(prompt);
    % Predict the position using fitted model
    xd = predict(md1,[xc yc]);
    yd = predict(md2,[xc yc]);
    if xd>0 && xd<1080
        if yd>0 && yd<1920
            blink_a_defined_dot(d, latency, round(xd), round(yd), radius)
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
        X_DMD = [X_DMD;xd];
        X_Camera = [X_Camera;xc];
        Y_DMD = [Y_DMD;yd];
        Y_Camera = [Y_Camera;yc];
    end
    num_loop = num_loop + 1;
end



prompt = 'Enter file name if you want to save the data';
str = input(prompt,'s');
if isempty(str)
    fprintf('Data not saved')
else
    save([pwd '/data/' DataFileName],'X_DMD', 'Y_DMD', 'X_Camera', 'Y_Camera', 'md1', 'md2', 'md3', 'md4')
end





function blink_a_defined_dot(d, latency, x, y, radius)
% latency in second
% stop the current pattern and upload the dot. The dot will be blinking
% every ~ second, where ~ is the latency

d.patternControl(0)
BMP = generate_round_spot(x, y, radius);
% BMP1 = XF_prepMultiBMP(BMP');
BMP1 = prepBMP(BMP');
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