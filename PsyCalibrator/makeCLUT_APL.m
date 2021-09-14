function [lut,lumfiltered,flare,fit]=makeCLUT_APL(lum,numluttbl,display_flg,addedTitleStr)
% Created    : "2012-04-09 22:42:06 Yang"
% Last Update: "2014-04-23 16:01:05 Yang"
% Simplified by Yang Zhang 2020-12-01 from the ApplyGammaCorrection in Mcalibrator2 toolbox written by Hiroshi Ben
epsilon = 0.01;
% check input variables
if ~exist('numluttbl','var') || isempty(numluttbl)
    numluttbl = 256;
end
if ~exist('display_flg','var') || isempty(display_flg)
    display_flg = true;
end
if ~exist('addedTitleStr','var') || isempty(addedTitleStr)
    addedTitleStr = '';
end

% initialize luminance input
if size(lum,2) == 2
    lum =lum';
end % set lum to [2(graylevel,luminance) x n] matrix

org_lum = lum; % store the original data

% applying monotonic increase filter
raw_lum = lum(2,:);

% step1, spline smoothing
lum(2,:) = smoothn(lum(2,:));

% step2, monotonic filter & test monotonic increase
checkmono = 0;
while checkmono == 0
    [lum(2,:),exitflag] = mc_ToMonotonic(lum(2,:));
    if exitflag == 1 || exitflag == 0
        break;
    end
    checkmono = mc_CheckMonotoneIncrease(lum(2,:));
end


% flare correction
[lum(2,:),leaked_light,minlum_org,maxlum_org]=ApplyFlareCorrection(lum(2,:));
maxlum = maxlum_org-minlum_org;
minlum = 0;

% get the filtered luminance
lumfiltered = lum;
flare       = leaked_light;

if 128<=size(lum,2)
    lum_sparce = lum(:,1:3:end);
elseif 64<= size(lum,2) && size(lum,2) < 128
    lum_sparce = lum(:,1:2:end);
else
    lum_sparce = lum;
end
idx = find(diff(lum_sparce(2,:)) <= epsilon);
lum_sparce(:,idx+1) = [];


% fitting the model
fit = spline(lum_sparce(1,:),lum_sparce(2,:),lum(1,:));

% to monotonic
if find(diff(fit)<0)
    % monotonic increase filter
    checkmono = 0;
    while checkmono == 0
        [fit(1,:),exitflag] = mc_ToMonotonic(fit);
        if exitflag == 1 || exitflag == 0, break; end
        checkmono = mc_CheckMonotoneIncrease(fit);
    end
    tmp = fit; tmp(tmp<0)=0; fit=tmp;
end

% initialize LUT related variables
interval = (maxlum-minlum)/(numluttbl-1);
lut      = zeros(2,numluttbl);
lut(1,:) = (1:1:numluttbl)-1;
vals     = min(fit)*ones(1,numluttbl-1);

% generating CLUT
vals     = spline(lum_sparce(2,:),lum_sparce(1,:),minlum:interval:maxlum);
lut(2,:) = spline(lum(1,:),lum(2,:),vals);


% generate CLUT using the model curve fitted to the actual measurements
lut(1,:) = vals;

% filtering generated CLUT by robust spline when it does not monotonically increase
%if strcmpi(method,'cbs') || strcmpi(method,'poly') || strcmpi(method,'log') || strcmpi(method,'lin')
tmp=lut(1,:); tmp(tmp<org_lum(1,1))=org_lum(1,1); tmp(tmp>org_lum(1,end))=org_lum(1,end); lut(1,:)=tmp;
if find(diff(lut(1,:))<0)
    % spline smoothing
    %lut(1,:)=smoothn(lut(1,:),'robust'); % robust constrain
    lut(1,:)=smoothn(lut(1,:));
    % monotonic increase filter
    checkmono=0;
    while checkmono==0
        [lut(1,:),exitflag]=mc_ToMonotonic(lut(1,:));
        if exitflag==1 || exitflag==0, break; end
        checkmono = mc_CheckMonotoneIncrease(lut(1,:));
    end
    tmp=lut(1,:); tmp(tmp<org_lum(1,1))=org_lum(1,1); tmp(tmp>org_lum(1,end))=org_lum(1,end); lut(1,:)=tmp;
end

% put back corrected luminance to the actual values, required for correct wrong luminance values
lut(2,:)  = lut(2,:)+minlum_org;
%lut(2,:) = lut(2,:)./100;
maxlum    = maxlum+minlum_org;
minlum    = minlum_org;

% plotting the results
if display_flg
    scrsz = get(0,'ScreenSize');
    f1    = figure('Name',sprintf('Mcalibrator2 Gamma correction result: cubic spline: %s',addedTitleStr),...
        'NumberTitle','off',...
        'Position',[scrsz(3)/5,scrsz(4)/4,2*scrsz(3)/3,scrsz(4)/2]);
    
    subplot(3,4,[1:2,5:6]);
    hold on;
    
    lumline(1) = plot(org_lum(1,:),raw_lum,'go','LineWidth',1);
    lumline(2) = plot(org_lum(1,:),lum(2,:)+minlum,'bo','LineWidth',2);
    lumline(3) = plot(org_lum(1,:),fit+minlum,'r-','LineWidth',2);
    set(gca,'XLim',[org_lum(1,1),org_lum(1,end)]);
    set(gca,'YLim',[minlum-2,maxlum+2]);
    xlabel('Normalized RGB [0.0-1.0]');
    ylabel('Luminance');
    legend(lumline,{'Measured','Filtered','Fitted'},'Location','SouthEast');
    title(sprintf(['Gamma correction results (cubic spline):',addedTitleStr]));
    
    subplot(3,4,[3:4,7:8]);
    hold on;
    lutline(1) = plot(1:1:numluttbl,lut(1,:),'mo-','LineWidth',2);
    set(gca,'XLim',[0,numluttbl+1]);
    set(gca,'YLim',[0,1]);
    xlabel('#Lut ID');
    ylabel('Normalized RGB [0.0-1.0]');
    legend(lutline,{'CLUT'},'Location','SouthEast');
    title(sprintf('Gamma correction results (cubic spline)'));
    
    subplot(3,4,9:10); hold on;
    %bar(org_lum(1,:),fit-lum(2,:),'FaceColor',[0,0,0]);
    bar(org_lum(1,:),fit-org_lum(2,:)+minlum,'FaceColor',[0,0,0]);
    set(gca,'XLim',[org_lum(1,1),org_lum(1,end)]); %set(gca,'XLim',[0,1]);
    xlabel('Normalized RGB [0.0-1.0]');
    ylabel('Residuals');
    title('Residuals');
    
    subplot(3,4,11:12); hold on;
    plot(linspace(org_lum(1,1),org_lum(1,end),size(lut,2)),lut(2,:),'-','Color',[0,0,0]);
    set(gca,'XLim',[org_lum(1,1),org_lum(1,end)]); %set(gca,'XLim',[0,1]);
    xlabel('Normalized RGB [0.0-1.0]');
    ylabel('Luminance');
    title('RGB vs. Luminance');
    
    set(f1,'PaperPositionMode','auto');
end

% finishing
beepsnd=sin(2*pi*0.2*(0:900));
try % if this script can write data to sound device
    sound(beepsnd,22000);
catch makeCLUT_APL_error
    % do nothing
end


end


%% subfunctions

function [output,exitflag] = mc_ToMonotonic(input)

% June 10 2012, Hiroshi Ban

try
    %if exist('lsqlin','file') % if optimization toolbox is installed
    % sophisticated, but not suitable for some luminance data
    % if some problems happened, use the codes below instead
    n        = length(input);
    C        = eye(n);
    D        = input;
    A        = diag(ones(n,1),0) - diag(ones(n-1,1),1);
    A(end,:) = [];
    b        = zeros(n-1,1);
    
    opts  = optimset('lsqlin');
    opts.LargeScale = 'off';
    opts.Display    = 'none';
    opts.MaxIter    =100;
    [output,dummy1,dummy2,exitflag] = lsqlin(C,D,A,b,[],[],[],[],[],opts);
    
catch
    max_repeat =100;
    [m,n]      = size(input);
    output     = input;
    checkmono  = 0;
    repetition = 1;
    while checkmono==0 && repetition<=max_repeat
        for mm=1:1:m
            for nn=1:1:n-1
                if output(mm,nn)>output(mm,nn+1)
                    if nn==1
                        output(mm,nn)=2*output(mm,nn+1)-output(mm,nn+2);
                    else
                        output(mm,nn)=(output(mm,nn-1)+output(mm,nn+1))/2;
                    end
                end
            end
        end
        
        % check the last & last-1 values, June 14 2008 by H.Ban
        for mm=1:1:m
            if output(m,end)<output(m,end-1)
                output(m,end)=2*output(m,end-1)-output(m,end-2);
            end
        end
        checkmono = mc_CheckMonotoneIncrease(output);
        disp('Repetition: %03d/%03d',repetition,max_repeat);
        repetition=repetition+1;
    end
    
    if repetition>100
        exitflag = 0;
    else
        exitflag = 1;
    end
    
end % if ~exist('lsqlin','file') % if optimization toolbox is installed

end % subfunction

function checkmono = mc_CheckMonotoneIncrease(output)

% June 10 2012, Hiroshi Ban

[m,n] = size(output);
resid = zeros(m,n-1);

for mm=1:1:m
    resid(mm,:)=diff(output);
end

idx=find(resid<0,1);

if ~isempty(idx)
    checkmono = 0;
else
    checkmono = 1;
end

end % sub function


function [corr_val,flare,min_val,max_val]=ApplyFlareCorrection(input_val)

% Applies flare-correction to the measured luminance data.
% function [cor_val,flare,min_val,max_val]=ApplyFlareCorrection(input_val)
% Apply Flare-correction on the measured luminance values
%
% [input]
% input_val : raw lum or xyY values, [1 (CIE1931 Y) x n] or [3 (CIE1931 x,y,Y) x n] matrix
%             The input_val should be sorted in ascending order based on the corresponding video input values.
%             Further, input_val should be processed by monotonic-increase filter.
%
% [output]
% corr_val  : Flare-corrected lum or xyY values, [1 x n] or [3 x n] matrix
% flare     : subtracted lum or xyY values, [1 x n] or [3 x n] matrix
% min_val   : minimum value of input_val
% max_val   : maximum value of input_val
%
%
% Created    : "2012-04-09 23:39:09 ban"
% Last Update: "2013-12-11 17:45:19 ban"

% apply flare-correction
[m,n]=size(input_val);
if m==1 % CIE1931 Y (luminance) only
    flare    = input_val(1);%min(input_val);
    corr_val = input_val-flare;
    min_val  = flare;
    max_val  = input_val(n);%max(input_val);
elseif m==3 % CIE1931 xyY
    XYZ                       = xyY2XYZ(input_val); % transform CIE1931 xyY to XYZ
    flare                     = repmat(XYZ(:,1),1,n);%min(input_val,[],2);
    XYZ                       = XYZ-flare;
    corr_val                  = XYZ2xyY(XYZ);
    corr_val(corr_val<0)      = 0;
    corr_val(isnan(corr_val)) = 0;
    min_val                   = flare(:,1);
    max_val                   = input_val(:,n);%max(input_val,[],2);
    flare                     = XYZ2xyY(flare);
else
    error('input_val should be raw lum or xyY values ([1 (CIE1931 Y) x n] or [3 (CIE1931 x,y,Y) x n]). Check input variable.');
end

end % sub function

