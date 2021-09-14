function [CIExyY,myCorrectionMatrix] = ColorCal2_APL(command,samples,myCorrectionMatrix)

% useage:
%
% inputs:
%
%	 command                 [string]:       the command should be of either 'initialize' or 'measure'
%	 samples                 [double]:       number of measures
%	 myCorrectionMatrix      [double matrix]: the calibration Matrix used to correct the return value
%
% outputs:
%	 CIExyY         [1*3 double]  measured color values
%	 myCorrectionMatrix [matrix]   correction Matrix used to transform the raw data to CIExyY
%
%
%
% demo:
% before measure the xyY, we have to initialize it first via
%
% [CIExyY,myCorrectionMatrix] = ColorCal2_APL('initialize');
%
% or
%
% [CIExyY,myCorrectionMatrix] = ColorCal2_APL('initialize');
%
% and then measure it via:
%
% [CIExyY,myCorrectionMatrix] = ColorCal2_APL('measure',1,myCorrectionMatrix);
%
% or
%
% [CIExyY,myCorrectionMatrix] = ColorCal2_APL('measure',1,myCorrectionMatrix);
%
% Shows how to make measurements using the ColorCAL II CDC interface.
% This script calls several other separate functions which are included
% below.
%
% CIExyY returns the XYZ values for each measurement (each row
% represents a different measurement).
%
%
% adapted from C.Arnold Dec 2011 and Written by yang 2017/9/23 17:46:33
% 1) replaced the serial with IOPort to add support for linux
%
 % Added a ERROR check for the zero calibration. 
 % added. by Yang Zhang Fri Aug 24 02:13:38 2018  Soochow University, China

if nargin < 1
    helpStr = { 'useage: '
        ' '
        'inputs: '
        ' '
        '    command                 [string]:       the command should be of either ''initialize'' or ''measure'' '
        '    samples                 [double]:       number of measures  '
        '    myCorrectionMatrix      [double matrix]:the calibration Matrix used to correct the return values  '
        ' '
        'outputs: '
        '    CIExyY         [1*3 double]  measured color values '
        '    myCorrectionMatrix [matrix]   correction Matrix used to transform the raw data to CIExyY '
        ' '
        ' '
        ' '
        'demo: '
        'before measure the xyY, we have to initialize it first via '
        ' '
        '[CIExyY,myCorrectionMatrix] = ColorCal2_APL(''initialize''); '
        ' '
        'or  '
        ' '
        '[CIExyY,myCorrectionMatrix] = ColorCal2_APL(''initialize''); '
        ' '
        'and then measure it via: '
        ' '
        '[CIExyY,myCorrectionMatrix] = ColorCal2_APL(''measure'',1,myCorrectionMatrix); '
        ' '
        'or  '
        ' '
        '[CIExyY,myCorrectionMatrix] = ColorCal2_APL(''measure'',1,myCorrectionMatrix); '
        ' '
        'Shows how to make measurements using the ColorCAL II CDC interface. '
        'This script calls several other separate functions which are included '
        'below. '
        ' '
        'CIExyY returns the XYZ values for each measurement (each row '
        'represents a different measurement). '
        ' '
        ' '
        'revised by yang 2017/9/23 17:46:33 '
        '1) replaced the serial with IOPort to add support for linux '
        '2) removed the argin ''ColorCALIICDCPort'' since we don''t need anymore!'};
    
    for iRow = 1:numel(helpStr)
        disp(helpStr{iRow});
    end
    CIExyY             = [];
    myCorrectionMatrix = [];
    
    return;
end



if ~exist('command','var')||isempty(command)
    command = 'initialize';
end

if ~exist('samples','var')||isempty(samples)
    samples = 5;
end

if ~exist('myCorrectionMatrix','var')||isempty(myCorrectionMatrix)
    myCorrectionMatrix = [];
end


CIExyY = [];


if strcmpi(command(1),'i')||isempty(myCorrectionMatrix)
    % First, the ColorCAL II should have its zero level calibrated. This can
    % simply be done by placing one's hand over the ColorCAL II sensor to block
    % all light.
     isSuccessed = ColorCal2('ZeroCalibration');

     if ~isSuccessed
        error('failed to do the Zero Calibration! Perhaps too much light.Ensure sensor is covered, then try again!');
    end
    % Confirm the calibration is complete. Position the ColorCAL II to take a
    % measurement from the screen.
    
    % Obtains the XYZ colour correction matrix specific to the ColorCAL II
    % being used, via the CDC port. This is a separate function (see further
    % below in this script).
    myCorrectionMatrix = ColorCal2('ReadColorMatrix');
    myCorrectionMatrix = myCorrectionMatrix(1:3,:);
end % added by yang


if strcmpi(command(1),'m')
    % Cycle through each sample.
    transformedValues = zeros(samples,3);
    for iSample = 1:samples
        s = ColorCal2('MeasureXYZ');
        transformedValues(iSample, 1:3) = myCorrectionMatrix * [s.x s.y s.z]';
        
    end
    
    % Convert recorded XYZ values into CIE xyY values using PsychToolbox
    % supplied function XYZToxyY (included at the bottom of the script).
    CIExyY = XYZToxyY(transformedValues')';
    
end



function [xyY] = XYZToxyY(XYZ)
% [xyY] = XYZToxyY(XYZ)
%
% Compute chromaticity and luminance from tristimulus values.
%
% 8/24/09  dhb  Speed it up vastly for large arrays.

denom = sum(XYZ,1);
xy    = XYZ(1:2,:)./denom([1 1]',:);
xyY   = [xy ; XYZ(2,:)];



