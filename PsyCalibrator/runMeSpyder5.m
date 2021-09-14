deviceType = 1;
% raw measurement
Gamma_raw = gammaMeasure_APL(deviceType);
%make gamma corrected CLUT table
Gamma_fitted = makeCorrectedGammaTab_APL(Gamma_raw,false);

close all; % close all potential figures
% verification of the correction
gammaMeasure_APL(deviceType,[],[],[],Gamma_fitted.gammaTable,true,true);



