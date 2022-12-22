function status = spyderXDependCheck_APL()
%    Check the dependences for spyderX via PsychHID equiped with bulk transfer
%    written by Yang Zhang
%    2022-12-22

    status = 0;

    % Check PsychHID version
    v = PsychHID('Version');

    if v.build < 638515007
        status = 1;
    end

    % Check spyderX driver

    if ~status
        try
            % usbHandle = PsychHID('OpenUSBDevice', hex2dec('085C'), hex2dec('0A00'));
            % PsychHID('CloseUSBDevice',usbHandle);
            spyderX('initial'); % to save the time
        catch
            status = 2;
        end
    end


