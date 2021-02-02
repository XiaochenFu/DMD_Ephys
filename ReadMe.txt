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
Change the size of the light spot, move around  T
 
** Folder 2 for modulating firing rate **
One vi change driving current and move around
One vi for change the duration of the light and number of pulses
One matlab function that change the fraction of the mirrors --> done

** Folder Test for testing settings 
*** Trigger_DMD: 
Upload pattern --> Turn on LED --> Present pattern --> Turn off LED
Driving current: 10mA
Optometer: range 1mW, 1V = 30uW

*** Trigger_LED
Upload and present pattern --> Trigger LED

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
This script is designed to present light dot to get the receptive field  of the recording unit. We first define the center of the ROI. Then, analog input will be analysed continouly. 
If there's an abruct current increase, one pattern will be uploaded and presented. 
The light presentation can be random or inorder. The light presentation can be triggered by an external trigger from labview vi.
The shape of the light spot can be either round or square.
This can also be used to test the trigger out of DMD
The trigger can be both analog. Digital part is not tested yet digital 
### Trigger_and_Record.vi
Control part:
This is adapted from Test_AI_AO_v9_Exchange_digital_analog_output.vi. At the beginning of each trial, digital output will be set to high and the matlab will be triggered to upload the pattern to DMD. 
When upload is finished, LED will be turned on. 
Then a series of pulses will be sent to DMD. The pulse duration will be defined by Matlabb, but frequency will be defined in labview. 
After presentation, light will be turned off and the output to matlab will be switched to 0.
Recording part;
Trigger in and out to DMD, as well as the measurement from the optometer will be recorded. 


## Folder Test for testing settings
### ThreePulsePerROI.m
Based on Loop_Around_ROI.m. Now the 


## Important steps when change the stimuli
* Run the mapping file to make sure the camera is not moving
* Check how long it takes to upload the current pattern. Bigger dots takes longer time to load. 
ref. r = 50 pixel round spots take about 1.6s to 2s to load
* Run the Labview .vi file only when Matlab .m file say it's ready. 
ref, 0.9s 


## Note: In the future versions, the parameters will be defined only once. One log file should be generated once we run the scripts.

  