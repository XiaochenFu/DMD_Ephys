% This script is used to map the projection from the DMD to camera. We
% randomly shine light dots, and input the coresponding coordinate in the
% camera. The traansformation from DMD coordinate to caera coordinate can
% be estimated by linear regression. The coefficiants for ransformaion will
% be saved into a file.
num_loop = 1;
num_loop_max = 100; % At most 100 dots can be tested. 
latency = 1;
x_start = 1;
x_end = 1080;
y_start = 1;
y_end = 1920;
radius = 50;
DataFileName = 'Apr21Mapping.mat';
%%=======================================================================%%


X_DMD = [];
Y_DMD = [];
X_Camera = [];
Y_Camera = [];
% initialize DMD
clear d
d = DMD('debug', 1);
while num_loop < num_loop_max
    % randomly blink a dot
    [xd,yd] = randomly_blink_a_dot(d, latency, x_start, x_end, y_start, y_end, radius);
    % If the dot can be seen, record the position at DMD and coordinate in
    % the camera. Otherwise, turn to another dot.
    prompt = 'Can you see the dot?\n y/n [y] \nEnter "s" to s\n';
    str = input(prompt,'s');
    if str == 'n'
    elseif str == 's'
        break
    else
        
        % Then ask the coordinate of the dot
        prompt = 'Enter the x coordinated of the centre of dot\n';
        xc = input(prompt);
        prompt = 'Enter the y coordinated of the centre of dot\n';
        yc = input(prompt);  
        if isempty(yc)
            continue
        else
            X_DMD = [X_DMD;xd];
            X_Camera = [X_Camera;xc];
            Y_DMD = [Y_DMD;yd];
            Y_Camera = [Y_Camera;yc];
        end
        
    end
    num_loop = num_loop + 1;
end
% sleep(d)

% Use linear regression to find the mapping. Suppose the center of the dot
% on DMD is (xd, yd), and the coresponding coordinate in camera is (xc,
% yc). Then we have
% xc = c1 + a1*xd + b1*yd
% yc = c1 + a2*xd + b2*yd
% a1, a2, b1, b2, c1, c2 will be saved as Coef1
% And
% xd = w1 + u1*xc + v1*yc
% yd = w2 + u2*xc + v2*yc
% u1, u2, v1, v2, w1, w2 will be saved as Coef2
md1 = fitlm([X_Camera,Y_Camera], X_DMD)
md2 = fitlm([X_Camera,Y_Camera], Y_DMD)
md3 = fitlm([X_DMD,Y_DMD], X_Camera)
md4 = fitlm([X_DMD,Y_DMD], Y_Camera)
% save Jan05Mapping.mat X_DMD X_Camera Y_DMD Y_Camera md1 md2 md3 md4 
save([pwd '/data/' DataFileName],'X_DMD', 'Y_DMD', 'X_Camera', 'Y_Camera', 'md1', 'md2', 'md3', 'md4')

function [x,y] = randomly_blink_a_dot(d, latency, x_start, x_end, y_start, y_end, radius)
% latency in second
x = randi([x_start+radius, x_end-radius],1,1);
y = randi([y_start+radius, y_end-radius],1,1);
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
I = ones(1920,1080);
[X,Y] = meshgrid(1:1080,1:1920);
X = (X-x).^2;
Y = (Y-y).^2;
I(X+Y>radius^2) = 0;
end

% function I = generate_square_spot(x, y, x_length, y_length)
% % Now you don't have to use int col and row!
% I = ones(1920,1080);
% [X,Y] = meshgrid(1:1080,1:1920);
% X = (X-x).^2;
% Y = (Y-y).^2;
% I(X+Y>radius^2) = 0;
% end