function XYZ = spyderXn(CMD,deviceType)
% deviceType: 2 for SpyderX (default), 5 for SpyderX2.

    if ~exist('deviceType','var')||isempty(deviceType)
        deviceType = 2; % spyderX
    end

    switch deviceType
        case 2
            XYZ = spyderX(CMD);
        case 5
            XYZ = spyderX2(CMD);
        otherwise
            error('Currently, spyderXn supports only spyderX [2] and spyderX2 [5].');
    end

