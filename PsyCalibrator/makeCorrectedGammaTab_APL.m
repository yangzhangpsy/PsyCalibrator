function Gamma = makeCorrectedGammaTab_APL(Gamma,isPlot)


% argin:
% 	Gamma     [Struct Or string]: Struct: a struct produced by gammaMeasure_APL
%								: Or a string for a filename of the saved Gamma Data, will automatically save the result as the input filename plot a suffix '_fitted'.
% 	isPlot 		       [boolean]: whether plot the result or not

% argout:
% 	Gamma  [Struct]: a new Gamma Struct
%
% Written by Yang Zhang
% Fri Jan  1 00:22:19 2011
% Attention and Perception lab
% Soochow University, China

helpStr ={'argin:'
    '	Gamma     [Struct Or string]: a struct produced by gammaMeasure_APL'
    '								:if is a string, will automatically save the result as the input filename plot a suffix ''_fitted''.'
    '	isPlot 		       [boolean]: whether plot the result or not'
    ''
    'argout:'
    '	Gamma  [Struct]: a new Gamma Struct	'};

if nargin < 1
    for iRow = 1:numel(helpStr)
        disp(helpStr);
    end
    
    if nargout > 0
        Gamma = [];
    end
end


if ischar(Gamma)
    filename = Gamma;
    
    disp(['Input is char type; try to load the file: ',filename]);
    load(filename);
end


if ~exist('isPlot','var')||isempty(isPlot)
    isPlot = true;
end


warning off;

RGBxyY          = Gamma.RGBxyY;
greyIdx      = RGBxyY(:,1)==RGBxyY(:,2)&RGBxyY(:,1)==RGBxyY(:,3);
greyLum      = RGBxyY(greyIdx,[1,6]);
greyLum(:,1) = greyLum(:,1)/255;
greyLum      = squeezeData_bcl(greyLum);

[greyLut,noused,greyFlare,greyFit] = makeCLUT_APL(greyLum,256,isPlot,'grey');
%%%%%%% for red Channel:

redIdx      = RGBxyY(:,2)==0&RGBxyY(:,3)==0;
redLum      = RGBxyY(redIdx,[1,6]);
redLum(:,1) = redLum(:,1)/255;

redLum = squeezeData_bcl(redLum);
if size(redLum,1) > 2
    [redLut,noused,redFlare,redFit] = makeCLUT_APL(redLum,256,isPlot,'red channel');
end
%%%%%% for green channel:
greenIdx      = RGBxyY(:,1)==0&RGBxyY(:,3)==0;
greenLum      = RGBxyY(greenIdx,[2,6]);
greenLum(:,1) = greenLum(:,1)/255;

greenLum = squeezeData_bcl(greenLum);
if size(greenLum,1) > 2
    [greenLut,noused,greenFlare,greenFit] = makeCLUT_APL(greenLum,256,isPlot,'green channel');
end
%%%%%% for blue channel:
blueIdx      = RGBxyY(:,1)==0&RGBxyY(:,2)==0;
blueLum      = RGBxyY(blueIdx,[3,6]);
blueLum(:,1) = blueLum(:,1)/255;

blueLum = squeezeData_bcl(blueLum);
if size(blueLum,1) > 2
    [blueLut,noused,blueFlare,blueFit]=makeCLUT_APL(blueLum,256,isPlot,'blue channel');
end

Gamma.RGBxyY = [RGBxyY(greyIdx,:);RGBxyY(redIdx,:);RGBxyY(greenIdx,:);RGBxyY(blueIdx,:)];


Gamma.grey.Lum   = greyLum;
Gamma.grey.Lut   = greyLut;
Gamma.grey.Fit   = greyFit;
Gamma.grey.Flare = greyFlare;

if size(redLum,1) > 2
    Gamma.red.Lum   = redLum;
    Gamma.red.Lut   = redLut;
    Gamma.red.Fit   = redFit;
    Gamma.red.Flare = redFlare;
end

if size(greenLum,1) > 2
    Gamma.green.Lum   = greenLum;
    Gamma.green.Lut   = greenLut;
    Gamma.green.Fit   = greenFit;
    Gamma.green.Flare = greenFlare;
end

if size(blueLum,1) > 2
    Gamma.blue.Lum   = blueLum;
    Gamma.blue.Lut   = blueLut;
    Gamma.blue.Fit   = blueFit;
    Gamma.blue.Flare = blueFlare;
end

if isfield(Gamma,'gammaTable')
    Gamma.gammaTableBk = Gamma.gammaTable;
end

Gamma.gammaTable = repmat(greyLut(1,:)',[1,3]);

warning on;


%---- save the gamma corrected data ----/
if exist('filename','var')
    [FilePath,filenameonly] = fileparts(filename);
    
    save(fullfile(FilePath,[filenameonly,'_fitted']),'Gamma');
end
%---------------------------------------\


end % end of main function




%%%%%%%%%%%%%%%%%%%%%%
%  subfunction
%%%%%%%%%%%%%%%%%%%%%%


function tdata = squeezeData_bcl(data)

[a,b,c] = unique(data(:,1),'rows');
tdata   = [];

%--- for same RGBs, use the mean of the measured xyY --/
for iValue = 1:length(a)
    tdata = [tdata;mean(data(c==iValue,:),1)];
end
%------------------------------------------------------\


end
