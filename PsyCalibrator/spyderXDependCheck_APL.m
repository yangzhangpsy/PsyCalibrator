function status = spyderXDependCheck_APL()
%    Check the dependences for spyderX via PsychHID equiped with bulk transfer
%    argout:
%    status  a double 0,1,2 for spyderX and have dependent environment, unsupported version of PsychHID, and wring driver for spyderX respectively
%
%    written by Yang Zhang
%    2022-12-22

persistent spyderXDependPsychHID_APL

if isempty(spyderXDependPsychHID_APL)
    status = 0;

    % Check PsychHID version
    v = PsychHID('Version');

    if v.build < 638479169 % mac 638479169 win 638515007
        status = 1;
    end

    % Check spyderX driver

    if ~status
        try
            spyderX('initial'); % to save the time
        catch
            % wrong driver or not spyderX
            status = 2;
        end
    end

     spyderXDependPsychHID_APL = status;
else
    status = spyderXDependPsychHID_APL;
end





