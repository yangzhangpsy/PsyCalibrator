function setupPath_APL()
%get the current file path
cPath = fileparts(mfilename('fullpath'));
% added the current folder into the search paths of MATLAB
addpath(genpath(cPath));
% permanently save the search paths
savepath;

end