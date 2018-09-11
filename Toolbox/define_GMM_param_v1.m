function GMM_param = define_GMM_param_v1
% FUNCION. Defines the different parameters used in the GMM analysis. 

GMM_param.GMM_thresh_size    = 3;    % Indicate the minimum number of mRNAs an aggregate must contain such that the results of the GMM are considered.
GMM_param.th_fact_intensity  = 1.5;  % Pre-processing - spots must be x-times brighter than median of all spots
GMM_param.PSF_space_sampling = 5;    % Grid-size to pre-cal PSF on a finer grid

%- Filter parameters for Gaussian Filter to estimate background
GMM_param.kernel_size.bgd_xy = 5;
GMM_param.kernel_size.bgd_z  = 5;
GMM_param.kernel_size.psf_xy = 0;  %  Set to 0 to speed up filter
GMM_param.kernel_size.psf_z  = 0;  %  Set to 0 to speed up filter

%- Various flags determining how GMM works
GMM_param.flags.fit_region   = 'CC'; % Specify what part of the cropped image should be fit
%                                   'entire' for entire image
%                                   'CC'     only pixels that were identified by connected componentspre-detection
GMM_param.flags.fit_all       = 0;  %  Flag: indicate if all spots are considered for GMM (1) or only the one that pass the pre-processing (0).
GMM_param.flags.show_GMM      = 0 ;   %  Show results of GMM for each cell
GMM_param.flags.save_plot     = 1;    %  Flag: indicate if an image with results of the GMM should be saved (1=yes).
GMM_param.flags.GMM_parameter = 0;    %  Flag: specify how parameters describing mRNAs are obtained (1 = from entire image, 0 = from each cell)

GMM_param.n_spots_GMM_min     = 80;   % Minimum number of spots a cell must have to consider only the spots from the cell, otherwise the entire image is considered
GMM_param.z_score_th          = 500;  % Maximum (modified) z-score to select fitting estimates (for outlier removal with Median Absolute Deviation (MAD))