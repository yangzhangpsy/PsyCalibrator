function [XYZ] = spyderX(command)
persistent spyderData usbHandle
% The function is aimed to use PsychHID to control spyderX
%
% function used to communicate with spyderX
%  Usage:
%  argin: command string: 'initial', 'calibration', 'measure', or 'close'
%
%  argout:
%  XYZ: 1*3 double: the measured XYZ in 1931 CIEXYZ color coordinate: works only for measure command
%
%  Useage:
%  spyderX('initial');     % initialize SpyderX
%  spyderX('calibration'); % after capping up SpyderX, do zero point calibration.
%
%   %your codes maybe a for loop
%  XYZ = spyderX('measure'); % get a measure
%
%  spyderX('close'); % close and clean all info
%
%  Written by Yang Zhang, Soochow University
%  zhangyang873@gmail.com
%  2022-10-02


XYZ = [];

switch lower(command)
    
    case 'initial'
        usbHandle = PsychHID('OpenUSBDevice', hex2dec('085C'), hex2dec('0A00'));
        PsychHID('USBClaimInterface', usbHandle, 0); % to explicitly claim the inferface
        PsychHID('USBControlTransfer', usbHandle, double(0x02), 1, 0,   1, 0);    % clear feature Request
        PsychHID('USBControlTransfer', usbHandle, double(0x02), 1, 0, 129, 0);    % clear feature Request
        PsychHID('USBControlTransfer', usbHandle, double(0x41), 2, 2,   0, 0);    % URB_CONTROL out
        
        % get hardware version number
        % bulk Transfer format:
        %   0: cmd
        % 1:2: nonce = 0xffff & rand32(0)
        % 3:4: send size
        
        out = bulkTransfer(usbHandle, uint8([0xd9 0x42 0x33 0x00 0x00]), 28);
        spyderData.HWvn = decodeHWverNo(out);
        
        % get serial number
        out = bulkTransfer(usbHandle, uint8([0xc2 0x5c 0x37 0x00 0x00]), 42);
        spyderData.serNo = decodeSerNo(out);
        
        % get the factory Calibration data not the black calibration Data
        out = bulkTransfer(usbHandle, uint8([0xcb 0x05 0x73 0x00 0x01 0x00]), 47);
        spyderData.calibration = decodeCalibration(out);
        spyderData.isOpen = true; %#ok<*STRNU>
        
        % get Amb measure
        % for amb measure the integration time and gain setting are fixed to 0x65 and 0x10, respectively
        out = bulkTransfer(usbHandle, uint8([0xd4 0xa1 0xc5 0x00 0x02 0x65 0x10]), 11);
        spyderData.amb = decodeAmbCalibration(out);
        
        % measure setting up
        % the send[0]--- v1 0x03
        out = bulkTransfer(usbHandle, uint8([0xc3 0x29 0x27 0x00 0x01 spyderData.calibration.v1]), 15);
        spyderData.settUp = decodeSettUp(out);
        
    case 'calibration'
        % do zero point calibration
        if ~isfield(spyderData, 'isOpen') || ~spyderData.isOpen
            spyderX('initial'); % Now, automatically run the initial command
%            error('SpyderX did not initialized, please run spyderX(''initial''); first!');
        end
        
        
        PsychHID('USBControlTransfer', usbHandle, double(0x41),2, 2, 0, 0);    % URB_CONTROL out spyder reset
        v2 = dec2hex(spyderData.calibration.v2, 4);
        s1 = spyderData.settUp.s1;
        s2 = spyderData.settUp.s2;
        
        send = uint8([hex2dec(v2(1:2)),hex2dec(v2(1:2)),s1,s2]);
        % []
        out = bulkTransfer(usbHandle, uint8([0xd2 0x3f 0xb9 0x00 0x07 send]), 13);
        raw = decodeMeasure(out);
        
        spyderData.bcal = raw(1:3) - spyderData.settUp.s3(1:3);
        spyderData.isBlackCal = true;
        
        
    case 'measure'
        if ~isfield(spyderData, 'isOpen') || ~spyderData.isOpen
            error('SpyderX did not initialized, please run SpyderX(''initial''); first!');
        end
        
        if ~isfield(spyderData, 'isBlackCal') || ~spyderData.isBlackCal
            error('SpyderX did not carry out black calibration, please cap on spyderX and run SpyderX(''calibration''); first!');
        end
        
        PsychHID('USBControlTransfer', usbHandle, double(0x41),2, 2, 0, 0);    % URB_CONTROL out spyder reset
        % [0xd2 0x3f 0xb9 0x00 0x07 0x02 0xca 0x03 0xe1 0xa1 0xa1 0x00 ]
        v2 = dec2hex(spyderData.calibration.v2, 4);
        s1 = spyderData.settUp.s1;
        s2 = spyderData.settUp.s2;
        
        send = uint8([hex2dec(v2(1:2)),hex2dec(v2(1:2)),s1,s2]);
        % []
        out = bulkTransfer(usbHandle, uint8([0xd2 0x3f 0xb9 0x00 0x07 send]), 13);
        raw = decodeMeasure(out);
        
        raw(1:3) = raw(1:3) - spyderData.settUp.s3(1:3) - spyderData.bcal(1:3);
        
        XYZ = raw(1:3)*spyderData.calibration.matrix;
        
    case 'close'
        PsychHID('CloseUSBDevice',usbHandle);
        %    	spyderData.isOpen = false;
        clear spyderData usbHandle;
    otherwise
        error('command should be of [''initial'',''calibration'',''measure'',''close'']!');
end


end % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   sub-functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
function serNo = decodeSerNo(out)
%    decode the serial number info
serNo = char(out(10:17));
end

%%%%%%%%%%%%%%%%%%%%%%%%
% decode hardware No
%%%%%%%%%%%%%%%%%%%%%%%%
function HWvn = decodeHWverNo(out)
%    decode the hardware version number info
HWvn = char(out(6:9));
end


%%%%%%%%%%%%%%%%%%%%%%%%
% decode ambCalibration
%%%%%%%%%%%%%%%%%%%%%%%%
function amb = decodeAmbCalibration(out)
%    decode amb measure info
out(1:5) = [];
amb(1) = read_nORD_be(out(1:2));
amb(2) = read_nORD_be(out(3:4));
amb(3) = read_nORD_be(out(5));
amb(4) = read_nORD_be(out(6));
end

%%%%%%%%%%%%%%%%%%%%%%%%
% decode SettUp
%%%%%%%%%%%%%%%%%%%%%%%%
function settUp = decodeSettUp(out)
%    decode instrument info
out(1:5) = [];
settUp.s1(1) = read_nORD_be(out(1));
settUp.s2 = [read_nORD_be(out(2)), read_nORD_be(out(3)), read_nORD_be(out(4)), read_nORD_be(out(5))];
settUp.s3 = [read_nORD_be(out(6)), read_nORD_be(out(7)), read_nORD_be(out(8)), read_nORD_be(out(9))];
end

%%%%%%%%%%%%%%%%%%%%%%%%
% decode measure
%%%%%%%%%%%%%%%%%%%%%%%%
function raw = decodeMeasure(out)
%    decode measure info
out(1:5) = [];
raw = zeros(1,3);

for iCol = 1:4
    raw(iCol) = read_nORD_be(out(2*(iCol - 1) + (1:2) ));
end

end

%%%%%%%%%%%%%%%%%%%%%%%%
% decode Calibration
%%%%%%%%%%%%%%%%%%%%%%%%
function calibration = decodeCalibration(out)
%decode get factory calibration info
out(1:5) = [];

mat = zeros(3);
v1  = out(2);                 % 03
v2  = read_nORD_be(out(3:4)); % 02 ca
v3  = out(41);

k = 0;

for iRow = 1:3
    for iCol = 1:3
        mat(iRow, iCol) = read_IEEE754(out(k*4+5:k*4+5+4-1));
        k = k+1;
    end
    
end

calibration.matrix = mat;
calibration.v1 = v1;
calibration.v2 = v2;
calibration.v3 = v3;

calibration.ccmat = diag([1 1 1]);

end

%%%%%%%%%%%%%%%%%%%%%%%%
% read n ORD be
%%%%%%%%%%%%%%%%%%%%%%%%
function out = read_nORD_be(input)
out = hex2dec(sprintf('%s',transpose(dec2hex(input)) ));
end

%%%%%%%%%%%%%%%%%%%%%%%%
% read n ORD be
%%%%%%%%%%%%%%%%%%%%%%%%
function out = read_IEEE754(input)
% transform uint8 into IEEE754 flat
input = input(end:-1:1);

out = sprintf('%s',transpose(dec2bin(input,8)));

fraction = out(10:32);
exponent = out(2:9);

out = (-1)^out(1) * (1 + bin2dec(fraction)/2^23) * 2^(bin2dec(exponent)-127);
end

%%%%%%%%%%%%%%%%%%%%%%%%
% USB Bulk Transfer
%%%%%%%%%%%%%%%%%%%%%%%%
function out = bulkTransfer(usbHandle, cmd, outSize)
% cmd :[uint8]
% outSize : [double]
% 0x01 = 1
PsychHID('USBBulkTransfer', usbHandle, 1, numel(cmd), cmd);
%[countOrRecData] = PsychHID('USBBulkTransfer', usbHandle, endPoint, length [, outData][, timeOutMSecs=10000])


% get hardware version number
% 0x81 = 129
out = PsychHID('USBBulkTransfer', usbHandle, 129, outSize);
%[countOrRecData] = PsychHID('USBBulkTransfer', usbHandle, endPoint, length [, outData][, timeOutMSecs=10000])
end

