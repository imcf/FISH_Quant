function param = sim_fit_param_v1

%% Parameter controlling the GMM to analyze mRNA blobs
param.GMM.GMM_thresh_size    = 3;    %  Indicate the minimum number of mRNAs an aggregate must contain such that the results of the GMM are considered.
param.GMM.th_fact_intensity  = 1.5;  % Pre-processing - spots must be x-times brighter than median of all spots
param.GMM.PSF_space_sampling = 5;    % Grid-size to pre-cal PSF on a finer grid

%- Filter parameters for Gaussian Filter to estimate background
param.GMM.kernel_size.bgd_xy = 5;
param.GMM.kernel_size.bgd_z  = 5;
param.GMM.kernel_size.psf_xy = 0;  %  Set to 0 to speed up filter
param.GMM.kernel_size.psf_z  = 0;  %  Set to 0 to speed up filter

%- Various flags determining how GMM works
param.GMM.flags.fit_region   = 'CC'; % Specify what part of the cropped image should be fit
                                     %  'entire' for entire image
                                     %  'CC'     only pixels that were identified by connected componentspre-detection
param.GMM.flags.fit_all   = 0;       %  Flag: indicate if all spots are considered for GMM (1) or only the one that pass the pre-processing (0).
param.GMM.flags.show_GMM  = 0 ;      %  Flag: show results of GMM for each cell
param.GMM.flags.save_plot   = 1;     %  Flag: indicate if an image with results of the GMM should be saved (1=yes).
param.GMM.flags.GMM_parameter = 0;   %  Flag: specify how parameters describing mRNAs are obtained (1 = from entire image, 0 = from each cell)

param.GMM.n_spots_GMM_min     = 80;   % Minimum number of spots a cell must have to consider only the spots from the cell, otherwise the entire image is considered
param.GMM.z_score_th          = 500;  % Maximum (modified) z-score to select fitting estimates (for outlier removal with Median Absolute Deviation (MAD))

%% Parameters for localization feature calculations
param.features.ripley.correction         = 1;  % Edge correction, 0=none, 1=renormalized border spot count, 2=spots at border are not considered
param.features.ripley.space              = 1;  % Spacing for Ripley's K-function
param.features.ripley.dist_interest      = 40; % Characteristic distance for the blob features (distance to which Ripley's k-function is considered)
param.features.cell_ext.disk_size = [15 30 45 60];  % Opening used to compare mRNA counts in cell extension to rest of the cell
param.features.morph_opening_in_2D = 1; % Morphological opening is performed in 2D (after projection) or not.