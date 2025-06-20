function Gamma = gammaMeasure_APL(deviceType, inputRects,whichScreen,outputFilename,beTestedCLUT,skipInputScreenInfo,skipCalibration,beTestedRGBs,LeaveTime,nMeasures)

% Do gamma table measurement via spyder5/X or ColorCal MKII
% Usage: Gamma = gammaMeasure_APL(deviceType, inputRects,whichScreen,outputFilename,beTestedCLUT,skipInputScreenInfo,beTestedRGBs,LeaveTime,nMeasures)
% Or:
% argins:
%            deviceType: the type of the measure device (1,2,3,4,5 for Spyder 5, Spyder X, CRS's ColorCal MKII , PR670, and Spyder X2 respectively)
%            inputRects: 4*n maxtrix for n Rects of the to be tested areas (default: 500*500 rect at the center of the last screen)
%           whichScreen: index of the to be tested monitor [default max(Screen(''Screens''))]
%        outputFilename: filename of the display calibration data file
%          beTestedCLUT: to be tested Color Lookup Table (CLUT, default: linear line)
%   skipInputScreenInfo: whether to skip the inputing of the monitor info (default: false)
%       skipCalibration: whether to skip the calibration of the device (default: false)
%          beTestedRGBs: to be tested RGBs, 1,2, or a n-row by 3-column matrix for gray, RGB channels, or customized RGBs respectively
%             LeaveTime: how many seconds to leave the room (0-60): (default: 10)
%             nMeasures: how many measures for each RGB
%
%
% Yang Zhang
% Attention and Perception Laboratory
% Department of Psychology, Soochow University
% 2020/12/18 9:16:50

persistent myCorrectionMatrix, myDeviceType

% ---- check input arguments ----/
if ~exist('deviceType','var')||isempty(deviceType)
    deviceType = 1;
end

if ~exist('inputRects','var')||isempty(inputRects)
    inputRects = [];
end

if ~exist('whichScreen','var')||isempty(whichScreen)
    whichScreen = max(Screen('Screens'));
end

if ~exist('skipInputScreenInfo','var')||isempty(skipInputScreenInfo)
    skipInputScreenInfo = false;
end

if ~exist('skipCalibration','var')||isempty(skipCalibration)
    skipCalibration = false;
end

if ~exist('outputFilename','var')||isempty(outputFilename)
    outputFilename = 'Gamma.mat';
end

if ~exist('beTestedRGBs','var')||isempty(beTestedRGBs)
    beTestedRGBs = 1;
end

isCustomizedClut = true;
myDeviceType = deviceType;

if ~exist('beTestedCLUT','var')||isempty(beTestedCLUT)
    beTestedCLUT     = linspace(0,1,256)'*[1 1 1];
    isCustomizedClut = false;
end

if ~exist('LeaveTime','var')||isempty(LeaveTime)
    LeaveTime = 10;
end

if ~exist('nMeasures','var')||isempty(nMeasures)
    nMeasures = 1;
end

%--------------------------------\

if isCustomizedClut
    [path,filenameonly,suffix] = fileparts(outputFilename);
    
    outputFilename = fullfile(path,[filenameonly,'_verification',suffix]);
end

% Screen information
if ~skipInputScreenInfo
    Gamma.DisDes           = input('Enter monitor''s brand name (you can skip these questions by pressing the enter key): ','s');
    Gamma.DisMod           = input('Enter monitor''s model number: ','s');
    Gamma.DisSer           = input('Enter monitor''s serial number: ','s');
    Gamma.DisBri           = input('Enter monitor''s brightness: ','s');
    Gamma.DisCon           = input('Enter monitor''s contrast: ','s');
    Gamma.ColorTemperature = input('Enter color temporature (e.g., 9600): ','s');
    Gamma.whichDesktop     = input('Enter computer name: ','s');
    Gamma.OS               = input('What''s the operation system (e.g., XP): ','s');
    Gamma.GPU              = input('What''s the brand of graphical card: ','s');
    
else
    Gamma.DisDes           = '';
    Gamma.DisMod           = '';
    Gamma.DisSer           = '';
    Gamma.DisBri           = '';
    Gamma.DisCon           = '';
    Gamma.RGBGain          = [];
    Gamma.ColorTemperature = [];
    Gamma.GPU              = '';
    Gamma.OS               = '';
    Gamma.whichdesktop     = '';
    
end
%%%%%%%%%%%%%
% begin
%%%%%%%%%%%%%
KbName('UnifyKeyNames');
try
    commandwindow;
    %%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'Verbosity', 0);
    
    fullRect = Screen('Rect', whichScreen);
    
    if isempty(inputRects)
        perperialRect = CenterRectOnPoint([0 0 500 500],fullRect(3)/2,fullRect(4)/2);
    else
        perperialRect = inputRects;
    end
    
    if numel(perperialRect) == 4
        perperialRect = perperialRect(:);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    if numel(beTestedRGBs) == 1
        switch beTestedRGBs
            case 1
                grays = (0:255)'*[1,1,1];
                grays = grays([1:4:255,size(grays,1)],:);
                
                data  = grays;
            case 2
                grays = (0:255)'*[1,1,1];
                grays = grays([1:4:255,size(grays,1)],:);
                
                [greens,reds,blues]  = deal(zeros(255,3));
                
                reds(:,1) = (1:255)';
                reds = reds([1:4:255,size(reds,1)],:);
                
                greens(:,2) = (1:255)';
                greens = greens([1:4:255,size(greens,1)],:);
                
                blues(:,3) = (1:255)';
                blues = blues([1:4:255,size(blues,1)],:);
                
                data  = [grays;reds;greens;blues];
            otherwise
                error('beTestedRGBs should be of 1 or 2 or a n*3 matrix!');
        end
        
    else
        if size(beTestedRGBs,2) ~= 3
            error('beTestedRGBs should be of 1 or 2 or a n*3 matrix!');
        end
        
        data = beTestedRGBs;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    Stimuli.White = WhiteIndex(whichScreen);%
    Stimuli.Black = BlackIndex(whichScreen); %
    Stimuli.Gray  = [128,128,128];%(Stimuli.White+Stimuli.Black)/2;
    
    pause;
    
    gammaTableBack = Screen('ReadNormalizedGammaTable', whichScreen);
    
    [w,ScreenRect] = Screen('OpenWindow',whichScreen,Stimuli.Gray,[],32);
    
    Screen('LoadNormalizedGammaTable',whichScreen,beTestedCLUT);
    
    %%%% start %%%%%
    HideCursor;
    ifi         = Screen('GetFlipInterval', w);
    refreshRate = 1/ifi;
    %%%%%%%%%%%%%%%%
    
    Screen('TextSize',w,30);
    Screen('TextStyle',w,0);%0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend
    Screen(w,'TextFont','Verdana');
    
    EscapeKey = KbName('ESCAPE');
    
    Priority(MaxPriority(whichScreen));
    
    %---- in case there is no correction matrix for ColorCal2   ----/
    if deviceType == 3 && isempty(myCorrectionMatrix)
        skipCalibration = false;
    end
    %---------------------------------------------------------------\
    
    if ~skipCalibration
        if deviceType == 4
            DrawFormattedText(w,'For photometer of PR670, no calibration is need.\n please waiting for 5 sec so that we could initialize the device. \n','center','center',Stimuli.White);
            Screen('Flip',w);
            abortExp(whichScreen,gammaTableBack,EscapeKey);
            WaitSecs(5);
        else
            DrawFormattedText(w,'We need to calibrate the device first by establishing the black level.\n Now make sure the lens cover of the photometer is fully closed. \n Then hit any key to proceed.','center','center',Stimuli.White);
            Screen('Flip',w);
            abortExp(whichScreen,gammaTableBack,EscapeKey);
            KbPressWait;
        end
        
        % ---- calibrate the device ----/
        switch deviceType
            case {1,2,5}
                % do measure or calibration(if necessary) once
                spyderCalibration_APL(0);
                
                if ismember(deviceType, [2,5]) && spyderXDependCheck_APL == 2
                    % the driver is not datacolor SpyderX
                    cprintf([0 0 1],['=========================================== Warning ============================================\n'...
                        'now PsyCalibrator can use PsychHID to control spyderX/X2, which is better/faster than spotread, \n'...
                        'However, you are still using the customized argyll driver [showed SpyderX/X2 (argyll) in the Device Manager list]\n'...
                        'Please switch the driver back to "Datacolor SpyderX/X2" to enable this new feature and remove this warning info\n '...
                        '[right-click and select Upate Driver, then select Search automatically for updated driver software]\n'...
                        '*================================================================================================\n']);
                end
                
            case 3
                if IsWin
                    [~,myCorrectionMatrix] = ColorCal2_SlowWin_APL('initialize');
                else
                    [~,myCorrectionMatrix] = ColorCal2_APL('initialize');
                end
            case 4
                % PR670 do not need calibration, so we just initialize it
                PR670init;
            otherwise
                error('DeviceType should be either 1, 2, 3,4 , or 5, for Spyder 5, Spyder X, CRS''s ColorCal MKII, PR670, and Spyder X2, respectively');
        end
        %------------------------------\
    end
    
    
    for iLoc = 1:size(perperialRect,2)
        Screen('FillRect',w,Stimuli.Gray,ScreenRect);
        
        currentRect = perperialRect(:,iLoc)';
        
        ovalLength  = min(abs([currentRect(3) - currentRect(1), currentRect(4) - currentRect(2)]));
        
        Screen('FillRect', w,Stimuli.White,currentRect);
        Screen('FillOval', w,Stimuli.Gray, CenterRectOnPoint ([0 0 ovalLength ovalLength],(currentRect(1)+currentRect(3))/2,(currentRect(2)+currentRect(4))/2),ovalLength + 10);
        Screen('DrawLine', w,Stimuli.Black, currentRect(1), currentRect(2),  currentRect(3), currentRect(4),1);
        Screen('DrawLine', w,Stimuli.Black, currentRect(1), currentRect(4),  currentRect(3), currentRect(2),1);
        
        if deviceType == 4
            DrawFormattedText(w,'To start the measurement,  focus the photometer''s black spot at the center cross point. \n Hit any key to continue...','center',ScreenRect(4)*0.8,Stimuli.White);
        else
            DrawFormattedText(w,'Device calibration done!\nTo start the measurement, open the lens cover and focus the photometer at the center. \n Hit any key to continue...','center',ScreenRect(4)*0.8,Stimuli.White);
        end
        
        Screen('Flip',w);
        
        abortExp(whichScreen,gammaTableBack,EscapeKey);
        
        InitialStr = ['The automatic measurement will start in ',num2str(LeaveTime),' seconds!'];
        
        Screen('FillRect',w,[0 0 0],ScreenRect);
        DrawFormattedText(w,InitialStr,'center',ScreenRect(4)*0.8,Stimuli.White);
        KbPressWait;
        
        abortExp(whichScreen,gammaTableBack,EscapeKey);
        Screen('Flip',w);
        
        abortExp(whichScreen,gammaTableBack,EscapeKey);
        WaitSecs(LeaveTime);
        
        fprintf('========== Begin measurement =============\n');
        
        [xyY,usedRGBs] = deal(zeros(size(data,1)*nMeasures,3));
        
        for iRGB = 1:size(data,1)
            abortExp(whichScreen,gammaTableBack,EscapeKey);
            
            Screen('FillRect',w,Stimuli.Gray,ScreenRect);
            Screen('FillRect',w,data(iRGB,:),currentRect);
            Screen('Flip',w);
            
            for iM = 1:nMeasures
                
                if iM == 1
                    WaitSecs(0.1);
                end
                
                abortExp(w,gammaTableBack,EscapeKey);
                
                switch deviceType
                    case {1,2,5}
                        % spyder 5 or X
                        cxyY = spyderRead_APL(refreshRate, 1);
                    case 3
                        % colorCal MKll
                        if IsWin
                            cxyY = ColorCal2_SlowWin_APL('measure',1,myCorrectionMatrix);
                        else
                            cxyY = ColorCal2_APL('measure',1,myCorrectionMatrix);
                        end
                        
                    case 4
                        % PR670
                        xyz  = PR670measxyz;
                        cxyY = XYZToxyY(xyz)';
                    otherwise
                        % do nothing here
                end
                xyY((iRGB-1)*nMeasures + iM,:)  = mean(cxyY,1);
                
                usedRGBs((iRGB-1)*nMeasures + iM,:) = data(iRGB,:);
                fprintf('iRGB %3d:%4d %4d %4d: iMeasure:%4d xyY: %5.3f %5.3f %5.3f\n',iRGB,data(iRGB,1),data(iRGB,2),data(iRGB,3),iM,xyY(iRGB,1),xyY(iRGB,2),xyY(iRGB,3));
                
            end
            
            %========= measure end==============
        end % iRGB
        
        
        
        beep;
        
        if iLoc == size(perperialRect,2)
            fprintf('=============================================================\n');
            fprintf('               All test locations finished  !\n');
            fprintf('=============================================================\n');
        else
            fprintf('=============================================================\n');
            fprintf('Change to the next location, then press any key to continue...\n'  );
            pause;
        end
        
        Gamma.allxyY{iLoc}= [usedRGBs,xyY];
    end% Iloc
    
    Priority(0);
    
    xyY = [usedRGBs,xyY];
    
    
    Screen('CloseAll');
    Screen('LoadNormalizedGammaTable',whichScreen,gammaTableBack);
    ShowCursor;
    
    
    Gamma.RGBxyY           = xyY;
    Gamma.RGB              = usedRGBs;
    Gamma.screenResolution = ScreenRect(3:4);
    Gamma.refreshRate      = refreshRate;
    Gamma.clut             = beTestedCLUT;
    Gamma.gammaTable       = beTestedCLUT;
    
    save(outputFilename,'Gamma');
    fprintf('----------------------------\n');
    fprintf('Data have been saved!\n');
    fprintf('----------------------------\n');
    
    if isCustomizedClut
        plotVerificationDataAll(xyY);
    end
    
    if deviceType == 4
        PR670close;
    end
    
catch gammaMeasure_APL_error
    
    sca;
    
    if deviceType == 4
        PR670close;
    end
    save gammaMeasure_APL_debug;
    Screen('LoadNormalizedGammaTable',whichScreen,linspace(0,1,256)'*[1 1 1]);
    ShowCursor;
    Priority(0);
    rethrow(gammaMeasure_APL_error);
end % try

end % end  for function



function abortExp(whichScreen,gammaTableBack,EscapeKey)
[~,~,keyCode] = KbCheck;

if keyCode(EscapeKey)
    sca;
    ShowCursor;
    Priority(0);
    Screen('LoadNormalizedGammaTable',whichScreen,gammaTableBack);
    error('Test aborted by the experimenter!');
end

end

function plotVerificationDataAll(xyY)

minLum = min(xyY(:,6));
maxLum = max(xyY(:,6));

xyY(:,1:3) = xyY(:,1:3)/255;

figure('Name','Gamma correction verification results');

xlabel('Normalized RGB [0.0-1.0]');
ylabel('Luminance');

hold on;

legendStr = {};
lumline   = [];
% grey
grayIdx  = xyY(:,1)==xyY(:,2) & xyY(:,1)==xyY(:,3);
if sum(grayIdx) > 1
    data = xyY(grayIdx,:);
    
    xIndex = 1;
    betas = regress(data(:,6),[data(:,xIndex),ones(size(data,1),1)]);
    lumline(end+1) = plot(data(:,xIndex),data(:,6),'ko','LineWidth',2);
    lumline(end+1) = plot(data(:,xIndex),[data(:,xIndex),ones(size(data,1),1)]*betas,'k-','LineWidth',2);
    set(gca,'XLim',[0,1]);
    set(gca,'YLim',[minLum-1,maxLum+1]);
    
    legendStr{end+1} ='Grey: measured';
    legendStr{end+1} ='Grey: linear fitted line';
end
% RED
redIdx  = xyY(:,2)== 0 & xyY(:,3)== 0;
if sum(redIdx) > 1
    data = xyY(redIdx,:);
    
    xIndex = 1;
    betas = regress(data(:,6),[data(:,xIndex),ones(size(data,1),1)]);
    lumline(end+1) = plot(data(:,xIndex),data(:,6),'ro','LineWidth',2);
    lumline(end+1) = plot(data(:,xIndex),[data(:,xIndex),ones(size(data,1),1)]*betas,'r-','LineWidth',2);
    set(gca,'XLim',[0,1]);
    set(gca,'YLim',[minLum-1,maxLum+1]);
    
    legendStr{end+1} ='Red: measured';
    legendStr{end+1} ='Red: linear fitted line';
end
% GREEN
greenIdx  = xyY(:,1)== 0 & xyY(:,3)== 0;
if sum(greenIdx) > 1
    data = xyY(greenIdx,:);
    
    xIndex = 2;
    betas = regress(data(:,6),[data(:,xIndex),ones(size(data,1),1)]);
    lumline(end+1) = plot(data(:,xIndex),data(:,6),'go','LineWidth',2);
    lumline(end+1) = plot(data(:,xIndex),[data(:,xIndex),ones(size(data,1),1)]*betas,'g-','LineWidth',2);
    set(gca,'XLim',[0,1]);
    set(gca,'YLim',[minLum-1,maxLum+1]);
    
    legendStr{end+1} ='Green: measured';
    legendStr{end+1} ='Green: linear fitted line';
end
% BLUE
blueIdx  = xyY(:,1)== 0 & xyY(:,2)== 0;
if sum(greenIdx) > 1
    data = xyY(blueIdx,:);
    
    xIndex = 3;
    betas = regress(data(:,6),[data(:,xIndex),ones(size(data,1),1)]);
    lumline(end+1) = plot(data(:,xIndex),data(:,6),'bo','LineWidth',2);
    lumline(end+1) = plot(data(:,xIndex),[data(:,xIndex),ones(size(data,1),1)]*betas,'b-','LineWidth',2);
    set(gca,'XLim',[0,1]);
    set(gca,'YLim',[minLum-1,maxLum+1]);
    
    legendStr{end+1} ='Blue: measured';
    legendStr{end+1} ='Blue: linear fitted line';
end

legend(lumline,legendStr,'Location','NorthWest','box','off');
title('Gamma correction verification results');
hold off;
end