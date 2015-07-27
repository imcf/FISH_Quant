function [iP, Q_all] = TxSite_reconstruct_w_image_FUN_est_N_v3(img_TS,img_bgd,img_PSF,parameters)

% Function to determine the number of mRNA's which will be tested
% Makes use of the property that the residuals look like a U. Determines
% the N_mRNA where the residuals are again as high as at the beginning,
% i.e. when no mRNA was placed.
%
%
%  flag_posWeight  ...  0  will not be recalculated
%                   ... >0 Number is exponent which will be applied to each 
%                          intensities to further enhance placement in
%                          brighter regions.
%
%  flag_psf that indicates how the PSF is calculated
%    1 ... with 3D Gaussian 
%    2 ... From actual image of a PSF
%
%  flag_placement    ... Flag to indicate how position is calculated
%   1 ... random
%   2 ... at maximum position of weight
%
%  flag_quality
%   1 ... ssr
%   2 ... sum of absolute residuals
%
% v2 01/11/11
% - flag_psf added
%
% v3 Feb 8,2011
% - Pad image of PSF to avoid bad shifts with respect to image of TS
% - Add flag to place new mRNA at position with maximum intensity
% - Add flag to allow output (show reconstruction after each placement, also indicate the number of reconstruction after which output should be displayed)
% - Avoid placement in already bright regions.
% - Flag to indicate if ssr or absolute residuals shoul be used
%
% v5 March 28,2011
% - Different random number generator for amplitude to consider skewness and kurtosis  


%% Parameters
coord       = parameters.coord;
mRNA_prop   = parameters.mRNA_prop;
index_table = parameters.index_table;
flags       = parameters.flags;


%% Some housekeeping

%- Make sure that both images are double
img_TS  = double(img_TS);
img_bgd = double(img_bgd);

%- Dimension of the respective images
[dim_TS.Y dim_TS.X dim_TS.Z] = size(img_TS);

%- Linear representation of 3d matrix: Column-by-column (x,y) and then different z
img_TS_lin  = img_TS(:);
img_Fit     = img_bgd;

%- Calculate the position weighting vector
img_Fit_lin       = img_Fit(:);


%% Residuals, sum of residuals, squares sum of residuals
resid_N0  = img_TS_lin-img_Fit_lin;
asr_N0    = sum(abs(resid_N0));
ssr_N0    = sum(resid_N0.^2);
 
if     flags.quality == 1
    Q_N0 = ssr_N0;
    Q_It = 0.5*ssr_N0;
elseif flags.quality == 2
    Q_N0 = asr_N0;
    Q_It = 0.5*asr_N0;
end


%% Loop through specified number of TS

%== PARAMETERS
parameters.flags       = flags;
parameters.mRNA_prop   = mRNA_prop;
parameters.index_table = index_table;

%== Image data
data_images.img_TS_lin  = img_TS_lin;
data_images.dim_TS      = dim_TS;
data_images.coord       = coord;
data_images.img_PSF     = img_PSF;


%=== Assign without any placement
Q_all(1) = Q_N0;
iP  = 2;

%=== Loop until better
while Q_It < Q_N0

     %== Update linear fit
     data_images.img_Fit_lin = img_Fit_lin;
         
     %== Calculate next PSF
     results_placement = PSF_place_image_v5(data_images,parameters);
     Q_It              = results_placement.Q_min;
     img_Fit_lin       = results_placement.img_Fit_lin;
     
     
%      disp([num2str(results_placement.amp_loop,'%10.2f')      , '  ', ... 
%            num2str(results_placement.fit_amp,'%10.2f')       , '  ', ...
%            num2str(results_placement.factor_scale)           , '  ', ...
%            num2str(max(results_placement.psf_new(:)),'%10.2f') , '  ', ...
%            num2str(results_placement.Q_min_in)               , '  ', ...
%            num2str(results_placement.int_max_psf)            , '  ', ...
%            num2str(max(img_Fit_lin(:)),'%10.2f')              ])
  

     %- Save parameters
     Q_all(iP,1) = Q_It;   
     iP = iP+1;   
      
         
    %=== Plot images 
    if not(isempty(flags.output)) &&  sum(flags.output == iP-1)
        
        %- Get parameters for plot
        Q_img_lin   = results_placement.Q_img_lin;
        center      = results_placement.center;
        ind         = results_placement.ind;
        
        Q_img    = reshape(Q_img_lin,size(img_TS));
        img_Fit  = reshape(img_Fit_lin,size(img_TS));
        
        %- Generate projections
        img_proj_max_xy  = max(img_TS,[],3);
        img_proj_max_yz  = squeeze(max(img_TS,[],2))';  
        img_proj_max_xz  = squeeze(max(img_TS,[],1))';

        img_fit_proj_max_xy  = max(img_Fit,[],3);
        img_fit_proj_max_yz  = squeeze(max(img_Fit,[],2))';  
        img_fit_proj_max_xz  = squeeze(max(img_Fit,[],1))';
        
        PSF_proj_max_xy  = max(results_placement.psf_new ,[],3);
        PSF_proj_max_yz  = squeeze(max(results_placement.psf_new ,[],2))';  
        PSF_proj_max_xz  = squeeze(max(results_placement.psf_new ,[],1))';
        
        Q_img = Q_img.*(Q_img>0);
        Q_proj_max_xy  = max(Q_img,[],3);
        Q_proj_max_yz  = squeeze(max(Q_img,[],2))';  
        Q_proj_max_xz  = squeeze(max(Q_img,[],1))';

        disp(' ')
        disp(['Iteration # ',num2str(iP-1)])
        disp(['Pos max (y,x,z): ',num2str(ind.y), ', ', num2str(ind.x), ', ',num2str(ind.z)])
        disp(['Q-score: ',num2str(round(results_placement.Q_min))])
 
        
        %=== Plot histogram of residuals
        figure, hist(Q_img(:),200)
        title('Histogram of residuals')
        
        
        %=== Images
        X_nm = coord.X_nm;
        Y_nm = coord.Y_nm;
        Z_nm = coord.Z_nm;
        
        figure    
        %- Actual image
        subplot(3,4,1), hold on
        imshow(img_proj_max_xy,[ ],'XData',X_nm,'YData',Y_nm)
        plot(center.x_nm,center.y_nm,'+g')
        hold off
        title('TS - XY')
        colorbar
        axis image

        subplot(3,4,5), hold on
        imshow(img_proj_max_yz,[ ],'XData',Y_nm,'YData',Z_nm);
        plot(center.y_nm,center.z_nm,'+g')
        hold off
        title('TS - YZ')
        colorbar
        axis image

        subplot(3,4,9), hold on
        imshow(img_proj_max_xz,[ ],'XData',X_nm,'YData',Z_nm);
        plot(center.x_nm,center.z_nm,'+g')
        hold off
        title('TS - XZ')
        colorbar
        axis image

        %- Fit
        subplot(3,4,2), hold on
        imshow(img_fit_proj_max_xy,[ ],'XData',X_nm,'YData',Y_nm)
        plot(center.x_nm,center.y_nm,'+g')
        hold off
        title(['Fit - XY : ', num2str(iP-1), ' placements'])
        colorbar
        axis image

        subplot(3,4,6), hold on
        imshow(img_fit_proj_max_yz,[ ],'XData',Y_nm,'YData',Z_nm);
        plot(center.y_nm,center.z_nm,'+g')
        hold off
        title('Fit - YZ')
        colorbar
        axis image

        subplot(3,4,10), hold on
        imshow(img_fit_proj_max_xz,[ ],'XData',X_nm,'YData',Z_nm);
        plot(center.x_nm,center.z_nm,'+g')
        hold off
        title('Fit - XZ')
        colorbar
        axis image

        %- PSF from loop
        subplot(3,4,3)
        imshow(PSF_proj_max_xy,[ ],'XData',X_nm,'YData',Y_nm)
        title('PSF - XY')
        colorbar
        axis image

        subplot(3,4,7)
        imshow(PSF_proj_max_yz,[ ],'XData',Y_nm,'YData',Z_nm);
        title('PSF - YZ')
        colorbar
        axis image

        subplot(3,4,11)
        imshow(PSF_proj_max_xz,[ ],'XData',X_nm,'YData',Z_nm);
        title('PSF - XZ')
        colorbar
        axis image
        
        %- Quality score
        subplot(3,4,4)
        imshow(Q_proj_max_xy,[ ],'XData',X_nm,'YData',Y_nm)
        title('Quality - XY')
        colorbar
        axis image

        subplot(3,4,8)
        imshow(Q_proj_max_yz,[ ],'XData',Y_nm,'YData',Z_nm);
        title('Quality- YZ')
        colorbar
        axis image

        subplot(3,4,12)
        imshow(Q_proj_max_xz,[ ],'XData',X_nm,'YData',Z_nm);
        title('Quality - XZ')
        colorbar
        axis image
    end
    
end




