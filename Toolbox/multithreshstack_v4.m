function [nout, thresholds, CC_all] = multithreshstack_v4(img,parameters)

% This function will count the number of mRNAs for a user defined number of thresholds
% (default is 100) from 0 up to the maximum intensity of the input image.

% Get label with labelmatrix(CC);

%- Get parameters
conn        = parameters.conn;
thresholds  = parameters.thresholds;

%-- Thresholds if they are not defined
if isempty(thresholds)
    
    th_int_min  = parameters.th_int_min;
    th_int_max  = parameters.th_int_max;
    nTH         = parameters.nTH;
    thresholds = linspace(th_int_min,th_int_max,nTH);
    
    if thresholds(2) - thresholds(1) < 1
        thresholds = parameters.th_int_min:1:parameters.th_int_max;
        warndlg(['Spacing of thresholds smaller than 1. Will set # of tested values to ', num2str(length(thresholds)), ' such that spacing is 1.'])               
   end
     
end


%- Number of thresholds to compute
nTH = length(thresholds);
if nTH > 1
    fprintf('Computing threshold (of %d):    1',nTH);
end

for i_th = 1:nTH
  
  %- Apply threshold
  th_loop = thresholds(i_th);
  bwl = img > th_loop & img;

  %- Find particles
  CC = bwconncomp(bwl,conn);
  
  %- Outputs
  nout(i_th)   = CC.NumObjects;
  CC_all{i_th} = CC;
  if nTH > 1; fprintf('\b\b\b%3i',i_th); end
  
end;

 if nTH > 1; fprintf('\n'); end


