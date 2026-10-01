function spyderCalibration_APL(printPromptInfo,deviceType)
% deviceType: 1 for Spyder5, 2 for SpyderX (default), 5 for SpyderX2.
%    Written by Yang Zhang
%    2021-01-14 20:12:55
if ~exist('printPromptInfo','var')||isempty(printPromptInfo)
    printPromptInfo = 1;
end

if ~exist('deviceType','var')||isempty(deviceType)
    deviceType = 2;
end

if printPromptInfo
    cprintf([0 0 1],'Instruction:\nWe need to calibrate the device first by establishing the black level.\nNow make sure the lens cover of the photometer is fully closed. \nThen hit any key to proceed.\n');
    pause;
end


if spyderXDependCheck_APL(deviceType)
    cFolder      = fileparts(mfilename('fullpath'));

    if IsWin
        commandStr = ['"',fullfile(cFolder,'spotread.exe'),'" -e -O -x'];
    elseif IsLinux
        commandStr = ['"',fullfile(cFolder,'spotread'),'" -e -O -x'];
    else % mac ox
        commandStr = ['"',fullfile(cFolder,'spotreadsMac','spotread'),'" -e -O -x'];
    end


    [status, results] = system(commandStr);

    if status
        error([results,char(13),'Calibration failed, see the infomation above for details']);
    else
        fprintf('Calibration done!\n');
    end

else
    spyderXn('calibration',deviceType);
    fprintf('Calibration done!\n');
end