%A demonstration for color measurement via spyderX/X2:
%
% To measure color (xyY coordinates), we need three steps:
% 1) black calibration;
% 2) measure;

nMeausres = 5; % definition of the number of measurements
refreshRate = 120; % definition of the refresh rate of the screen


%step1: do the black calibration while closing up the cover of spyderX
cprintf([0 0 1],' Instruction:\nWe need to calibrate the device first by establishing the black level.\nNow make sure the lens cover of the photometer is fully closed. \nThen hit any key to proceed.\n');
pause;
spyderCalibration_APL(0);

%sometimes, you need to nest the following code in your loop
for iMeasure = 1: nMeausres
  %Step2: do measurement
  % insert the control of the screen stimuli code over here, maybe PTB.
  cxyY = spyderRead_APL(refreshRate, 1);
end

