function spyderXn(CMD)
    persistent myDeviceType

    if isempty(myDeviceType)
        myDeviceType = 2; % spyderX
    end

    switch myDeviceType
        case 1
            spyderX(CMD);
        case 5
            spyderX2(CMD);
        otherwise
            error('Currently, spyderXn supports only spyderX [2] and spyderX2 [5].');
    end

