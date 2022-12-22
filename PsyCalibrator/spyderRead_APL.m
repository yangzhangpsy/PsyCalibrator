function xyY = spyderRead_APL(refreshRate, nMeasures)
% under linux, before runing this function, install the argyll first via the following commands in the terminal:
% sudo apt-get install argyll
% although it works, it do cost much more time than colorCal by around 8000 ms for each measures
% written by Yang Zhang, at 18:56 on 20 May 2019
% 2019/5/22 13:00:37

try

    if ~exist('refreshRate','var')|| isempty(refreshRate)
        refreshRate = [];
    end

    if ~exist('nMeasures','var')|| isempty(nMeasures)
        nMeasures = 5;
    end

    cFolder    = fileparts(mfilename('fullpath'));
    
    if IsWin
        commandStr = [fullfile(cFolder,'spotread.exe'),' -e -O -x -N'];
    elseif IsLinux
        commandStr = [fullfile(cFolder,'spotread'),' -e -O -x -N'];
    else % mac ox
        commandStr = [fullfile(cFolder,'spsotreadsMac','spotread'),' -e -O -x -N'];
    end
    
    xyY      = zeros(nMeasures,3);

    
    if exist('refreshRate','var')&&~isempty(refreshRate)
        commandStr = [commandStr,' -Y R:', sprintf('%-3.2f',refreshRate)];
    end

    for iM = 1:nMeasures
        nMaxMeasures = 1;
        XYZ = [];

        while isempty(XYZ)&& nMaxMeasures < 2 % try two times in maxmium
            if spyderXDependCheck_APL
                % ---- do it again -----/
                [noused,out] = system(commandStr);

                iStart       = strfind(out, 'Result is XYZ:');
                XYZ          = sscanf(out(iStart:end), 'Result is XYZ: %f %f %f');
                %-----------------------\
            else
                XYZ = spyderX('measure')';
            end

            nMaxMeasures = nMaxMeasures + 1;
        end
        xyY(iM,:) = XYZToxyY(XYZ)';

    end
    
    
catch spyderRead_APL_error
    save spyderRead_APL_debug;
    disp('For linux install driver: sudo apt-get install argyll');
    rethrow(spyderRead_APL_error);
end