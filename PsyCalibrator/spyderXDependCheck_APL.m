function status = spyderXDependCheck_APL(deviceType)
%    Check the dependences for spyderX via PsychHID equiped with bulk transfer
%    deviceType: 1 for Spyder5, 2 for SpyderX (default), 5 for SpyderX2.
%    argout:
%    status  a double scale: 0,1,2 for spyderX with PsychHID, unsupported version of PsychHID, and wrong driver for spyderX, respectively
%
%    written by Yang Zhang
%    2022-12-22

persistent spyderXDependPsychHID_APL cachedDeviceType

if ~exist('deviceType','var')||isempty(deviceType)
    deviceType = 2;
end

if deviceType == 1
    status = 2; % Spyder5 uses spotread
    return
end

if isempty(spyderXDependPsychHID_APL)||~isequal(cachedDeviceType,deviceType)
    status = 0;
    cachedDeviceType = deviceType;

    % Check PsychHID version
    v = PsychHID('Version');

    if v.build < 638479169 % mac 631740375/638479169 win 602983213/638515007 linux 603172579/640684315
        status = 1;

        spyderXDependPsychHID_APL = status;
        return
    end

    % Check spyderX driver
    if ~status
        try
            spyderXn('initial',deviceType); % to save the time
        catch
            % wrong driver or not spyderX
            status = 2;
        end
    end

     spyderXDependPsychHID_APL = status;
else
    status = spyderXDependPsychHID_APL;
end





