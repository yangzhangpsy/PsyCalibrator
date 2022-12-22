function dependStatus = spyderCalibration_APL(printPromptInfo, deviceType)
%    Written by Yang Zhang
%    2021-01-14 20:12:55
if ~exist('printPromptInfo','var')||isempty(printPromptInfo)
    printPromptInfo = 1;
end

if printPromptInfo
    cprintf([0 0 1],'Instruction:\nWe need to calibrate the device first by establishing the black level.\nNow make sure the lens cover of the photometer is fully closed. \nThen hit any key to proceed.\n');
    pause;
end

dependStatus = 0;
cFolder      = fileparts(mfilename('fullpath'));

if deviceType == 2
    % check/init spyderX
    dependStatus = spyderXDependCheck_APL;

    switch dependStatus
        case 1
            %  PsychHID is not the appropriate version, use spotread instead
            deviceType = 1;
        case 2
            % the driver is not datacolor SpyderX
            cprintf([0 0 1],['     **************************** Warning****************************                \n'...
                    'now PsyCalibrator can use PsychHID to control spyderX, which is better/faster than spotread, \n'...
                    'However, you are still using the customized argyll driver [showed SpyderX (argyll) in the Device Manager list]\n'...
                    'Please switch the driver back to "Datacolor SpyderX" to enable this new feature and remove this warning info\n '...
                    '[right-click and select Upate Driver, then select Search automatically for updated driver software]\n']);
    end
end

switch deviceType
    case 1
        % spyder5
        if IsWin
            commandStr = [fullfile(cFolder,'spotread.exe'),' -e -O -x'];
        elseif IsLinux
            commandStr = [fullfile(cFolder,'spotread'),' -e -O -x'];
        else % mac ox
            commandStr = [fullfile(cFolder,'spsotreadsMac','spotread'),' -e -O -x'];
        end
    case 2
        % spyderX
        spyderX('calibration');
    otherwise
        error('the curernt version of spyderCalibration_APL only supports spyder5[1] or spyderX[2]!');
end


[status, results] = system(commandStr);

if status
    error([results,char(13),'Calibration failed, see the infomation above for details']);
else
    fprintf('Calibration done!\n');
end