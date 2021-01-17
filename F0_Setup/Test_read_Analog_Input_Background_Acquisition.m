% This example shows how to acquire data in the background using events and listeners.

% A background acquisition depends on events and listeners to allow your code to access data as the hardware acquires it and to react to any errors as they occur. For more information, see Events and Listeners — Concepts in the MATLAB Object-Oriented Programming documentation. Use events to acquire data in the background. In this example, you acquire data from an NI 9205 device with ID cDAQ1Mod1 using a listener and a DataAvailable event.

% Listeners execute a callback function when notified that the event has occurred. Use Session.addlistener to create a listener object that executes your callback function.

% Create an NI session object and an analog input 'Voltage' channel on cDAQ1Mod1:
clear
s = daq.createSession('ni');% Sample rate, 100 point per second. Default 1000
% s.Rate = 1000;
addAnalogInputChannel(s,'Dev2', 1, 'Voltage'); 
% Add the listener for the DataAvailable event and assign it to the variable lh:
lh = addlistener(s,'DataAvailable', @plotData); 
% For more information on events, see Events and Listeners — Concepts in the MATLAB Object-Oriented Programming documentation.

% Create a simple callback function to plot the acquired data and save it as plotData.m in your working directory:

% Here, src is the session object for the listener and event is a daq.DataAvailableInfo object containing the data and associated timing information.

% Acquire the data and see the plot update while MATLAB® is running:

startBackground(s);
% When the operation is complete, delete the listener:
pause(1)
delete (lh)
 function plotData(src,event)
     plot(event.TimeStamps, event.Data)
 end