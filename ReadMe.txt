# DMD_ephys
% Jan 7, 2021
% By Xiaochen Fu

## This folder contain the following 
** Folder 0 for setup **
A fast way to map DMD coordinate and camera --> done
A fast program to check whether camera and DMD has moved. Should run before every experiment --> done
 
** Folder 1 for stimuli **
A control vi to coordinate DMD and recording. Maybe one pulse for matlab, one for light and analyse
A function can quickly process current ephys recording?
A .m file that can loop light dots around the recoding site.
Input: center of the recording site, size of the dot, number of area we want (e.g. 10x10), steps between two dots, current mapping from DMD --> camera, random or not. Save the coordination of the stimuli (with time?)
Change the size of the light spot, move around
 
** Folder 2 for modulating firing rate **
One vi change driving current and move around
One vi for change the duration of the light and number of pulses
One matlab function that change the fraction of the mirrors --> done

** DataBackup
Temperally save data inside



## Folder 0 for setup
### Map_DMD_Camera.m
This script is used to map the projection from the DMD to camera. We randomly shine light dots, and input the coresponding coordinate in the camera. The traansformation from DMD coordinate to caera coordinate can be estimated by linear regression. The coefficiants for ransformaion will be saved into a file
### Test_DMD_Camera.m
This script is used to quickly test the postion of the light path. Run the script and input the postion under the camera you want, a light spot will be blinking there.
### Test_read_Analog_Input.m
This script is used to test whetehr matlab can read analog input for a defined duration of time e.g 2s
### Test_read_Analog_Input_Background_Acquisition.m (might be removed in the future)
Test Event listener
### Test_read_Analog_Trigger.m
We need to read the trigger continouly from the analog input. Data stream every bufferTimeSpan second will be saved into a buffer. Then we will see whether there's a voltage step. If yes, something will be printed

## Folder 1 for stimuli 
### Loop_Around_ROI_notrigger.m
This script is designed to present light dot to get the receptive field of the recording unit. Each tiem, a light spot near the ROI will be uploaded, ordered or randomly.
### Loop_Around_ROI.m
This script is designed to present light dot to get the receptive field  of the recording unit. We first define the center of the ROI. Then, analog input will be analysed continouly. If there's an abruct current increase, one pattern will be uploaded and presented. 
The light presentation can be random or inorder. The light presentation can be triggered by an external trigger from labview vi.
The shape of the light spot can be either round or square.


## Note: In the future versions, the parameters will be defined only once. One log file should be generated once we run the scripts.

