function [TS_rec, Q_all] = TxSite_reconstruct_w_image_FUN_v3(img_TS,img_bgd,img_PSF,parameters)

%  flag_posWeight  ...  0  will not be recalculated
%                   ... >0 Number is exponent which will be applied to each 
%                          intensities to further enhance placement in brighter regions.
%                          
%  flag_psf that indicates how the PSF is calculated
%    1 ... with 3D Gaussian 
%    2 ... From actual image of a PSF
%
% v7
% - Extract amplitudes of PSF
%
% v8 Feb 8,2011
% - Pad image of PSF to avoid bad shifts with respect to image of TS
% - Add flag to place new mRNA at position with maximum intensity



%% Parameters
coord         = parameters.coord;
mRNA_prop     = parameters.mRNA_prop;
index_table   = parameters.index_table;
flags         = parameters.flags;
N_mRNA_MAX    = parameters.N_mRNA_MAX;
pixel_size_os = parameters.pixel_size_os;


%% Some house-keeping

%- Make sure that both images are double
img_TS  = double(img_TS);
img_bgd = double(img_bgd);

%- Dimension of the respective images
[dim_TS.Y dim_TS.X dim_TS.Z] = size(img_TS);

%- Linear representation of 3d matrix: Column-by-column (x,y) and then different z
img_TS_lin  = img_TS(:);
img_Fit     = img_bgd;
img_Fit_lin = img_Fit(:);


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


%= Reconstruction with only background      
resid  = img_TS_lin-img_Fit_lin;    
if     flags.quality == 1
    Q_It  = sum(resid.^2); 
    
elseif flags.quality == 2
    Q_It = sum(abs(resid));
end
      

% Number of mRNA and quality scor
iP = 1;
Q_all(iP,1)         = 0; 
Q_all(iP,2)         = Q_It; 

%- Other parameters
amp_all(iP)         = 0;
pos_TS(iP,:)        = [0 0 0];
img_rec{iP}.Fit_lin = img_Fit_lin;     
 

%= Loop over placement
for iP = 2:N_mRNA_MAX
    
     %== Update linear fit
     data_images.img_Fit_lin = img_Fit_lin;
    
     %== Calculate next PSF
     results_placement = PSF_place_image_v5(data_images,parameters);
     Q_It              = results_placement.Q_min;
     amp_loop          = results_placement.amp_loop;
     center            = results_placement.center;
     img_Fit_lin       = results_placement.img_Fit_lin;  
     par_shift         = results_placement.par_shift;
     
     %- Save parameters
     Q_all(iP,1)         = iP-1; 
     Q_all(iP,2)         = Q_It; 
     amp_all(iP)         = amp_loop;
     pos_TS(iP,:)        = [center.y_nm  + pixel_size_os.xy*par_shift{2}, ...
                            center.x_nm  + pixel_size_os.xy*par_shift{1}, ...
                            center.z_nm  + pixel_size_os.xy*par_shift{3}];
     img_rec{iP}.Fit_lin = img_Fit_lin;     
     iP = iP+1;       
     
end


%% Find best fit - minimum of quality score
[Q_min_val Q_min_ind] = min(Q_all(:,2));


%% Save results
TS_rec.Q_min  = Q_min_val;
TS_rec.N_mRNA = Q_all(Q_min_ind,1);
TS_rec.data   = reshape(img_rec{Q_min_ind}.Fit_lin,[data_images.dim_TS.Y data_images.dim_TS.X data_images.dim_TS.Z]);
TS_rec.pos    = pos_TS(2:Q_min_ind,:);
TS_rec.amp    = amp_all(2:Q_min_ind);


 
