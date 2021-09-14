function applyGammaCorrection_APL(action,gammaData,whichScreen)
%    useage:
%
%    argins:
%        action                   [double]: 0 or 1 for reset back to linear CLUT or do gamma correction respectively
%        gammaData  [string/struct/matrix]:
%                                           if is a string, gammaData is the fullfilename of the be saved Gamma file;
%                                           if is a struct, gammaData is a struct with a field named gammaTable that records the gamma corrected CLUT;
%                                           if is a matrix, gammaData is a matrix that is the gamma corrected CLUT.
%
%        whichScreen              [double]: the index of the to be corrected screen (default is 0).
%
%    Written by Yang Zhang 10-Jan-2021
%    Soochow University

if ~exist('action','var')||isempty(action)
    action = 0; % 0, 1 for reset to linear and do gamma correction respectively
end

if ~exist('gammaData','var')||isempty(action)
    gammaData = [];
end

if ~exist('whichScreen','var')||isempty(whichScreen)
    whichScreen = 0;
end

try
    gammaTableBack = Screen('ReadNormalizedGammaTable', whichScreen);
    
    if action
        % do gamma correction
        if ischar(gammaData)
            %a filename contain the Gamma struct
            data = load(gammaData);
            
            try
                beTestedCLUT = data.Gamma.gammaTable;
            catch
                error('The file should contain a structure variable produced by makeCorrectedGammaTab_APL');
            end
        elseif isstruct(gammaData)
            % a gamma struct produced by makeCorrectedGammaTab_APL
            if isfield(gammaData,'gammaTable')
                beTestedCLUT = gammaData.gammaTable;
            else
                error('The input structure should has a field called gammaTable');
            end
        else
            %a 3*n matrix
            [nRows,nCols] = size(gammaData);
            
            if nRows == 3 || nCols == 3
                beTestedCLUT = gammaData;
            else
                error('The input matrix should be of the size 3*n or n*3.');
            end
        end
        
        Screen('LoadNormalizedGammaTable',whichScreen,beTestedCLUT);
    else
        % reset back to linear
        Screen('LoadNormalizedGammaTable',whichScreen,linspace(0,1,256)'*[1 1 1]);
    end
    
    
catch applyGammaCorrection_APL_error
    
    Screen('LoadNormalizedGammaTable',whichScreen,gammaTableBack);
    
    rethrow(applyGammaCorrection_APL_error);
    
end % main try

end % function