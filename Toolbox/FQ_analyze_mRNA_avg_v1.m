function img = FQ_analyze_mRNA_avg_v1(img,parameters) 

% Function to analyze the PSF for TxSite quantification. Involves fitting
% the PSF and also resampling.


%== Get parameters describing stuff
if nargin > 1
    parameters_shift.flags.output  = parameters.flags.output;
    parameters_shift.flags.norm    = parameters.flags.norm;  
    par_crop_NS_detect             = parameters.par_crop_NS_detect;   % Set to same cropping as in FISH-QUANT
    par_crop_NS_quant              = parameters.par_crop_NS_quant;    % Set to size of cropping for TS quant   
    N_pix_sum                      = parameters.N_pix_sum;
else
    parameters_shift.flags.output = 0;
    parameters_shift.flags.norm   = 0;  
    par_crop_NS_detect    = [];
    par_crop_OS_detect    = [];
    par_crop_NS_quant     = [];
    par_crop_OS_quant     = []; 
    N_pix_sum.xy = 1;
    N_pix_sum.z = 1;
    
end

%== Get general parameters describing image
par_microscope    = img.par_microscope;
fact_os           = img.settings.avg_spots.fact_os;

pixel_size_os.xy  = par_microscope.pixel_size.xy / fact_os.xy;
pixel_size_os.z   = par_microscope.pixel_size.z  / fact_os.z;


%== Generate cropping areas for oversampling
if not(isempty(par_crop_NS_detect))
   par_crop_OS_detect.xy = par_crop_NS_detect.xy * fact_os.xy;
   par_crop_OS_detect.z  = par_crop_NS_detect.z * fact_os.z;  
end 
   
if not(isempty(par_crop_NS_quant))     
   par_crop_OS_quant.xy = par_crop_NS_quant.xy * fact_os.xy;
   par_crop_OS_quant.z  = par_crop_NS_quant.z * fact_os.z;          
end


%== Get background: either from file or as scalar (can also be 0)
if isfield(img.mRNA_prop,'BGD_file_name') && not(isempty(img.mRNA_prop.BGD_file_name))
    file_bgd       = fullfile(img.mRNA_prop.BGD_path_name, img.mRNA_prop.BGD_file_name);
    img_BGD_struct = load_stack_data_v7(file_bgd);    
    PSF_BGD        = img_BGD_struct.data;
    
elseif isfield(img.mRNA_prop,'bgd_value')
    PSF_BGD = img.mRNA_prop.bgd_value;
    
else
    PSF_BGD = 0;
end


%== Assign parameters
parameters_PSF.PSF_BGD        = PSF_BGD;
parameters_PSF.par_microscope = par_microscope;
parameters_PSF.pixel_size     = pixel_size_os;

%== Flags for analysis
parameters_PSF.flags.crop   = 1;
parameters_PSF.flags.output = 0;

%== Read in PSF and fit
file_name_PSF                               = fullfile(img.mRNA_prop.path_name, img.mRNA_prop.file_name);
parameters_PSF.par_crop_quant               = par_crop_OS_quant;
parameters_PSF.par_crop_detect              = par_crop_OS_detect;
[img.mRNA_prop.OS_struct, img.mRNA_prop.OS_fit] = PSF_3d_analyse_v8(file_name_PSF, parameters_PSF);

%- Further processing only if image of PSF is defined
if not(isempty(img.mRNA_prop.OS_struct))

    % ==== Generate shifted PSF for reconstruction if image is oversampled
    range_shift_xy = (0:1:fact_os.xy-1) - floor(fact_os.xy/2);
    range_shift_z  = (0:1:fact_os.z-1)  - floor(fact_os.z/2);

    parameters_shift.fact_os        = fact_os;
    parameters_shift.pixel_size_os  = pixel_size_os;
    parameters_shift.pixel_size     = par_microscope.pixel_size;
    parameters_shift.range_shift_xy = range_shift_xy;
    parameters_shift.range_shift_z  = range_shift_z;

    parameters_shift.par_microscope = par_microscope;
    parameters_shift.flags.crop     = 1;
    
    parameters_shift.par_crop_detect = par_crop_NS_detect;
    parameters_shift.par_crop_quant  = par_crop_NS_quant;  
    parameters_shift.N_pix_sum       = N_pix_sum;
    

    [img.mRNA_prop.PSF_shift, dum, img.mRNA_prop.PSF_shift_fit_summary, img.mRNA_prop.PSF_sum_pix] = PSF_3D_generate_shifted_v5(img.mRNA_prop.OS_struct,parameters_shift);
    img.mRNA_prop.parameters_shift = parameters_shift;
else
    img.mRNA_prop.PSF_shift = [];
    img.mRNA_prop.parameters_shift = [];
    img.mRNA_prop.PSF_shift_fit_summary = [];
    img.mRNA_prop.PSF_sum_pix = [];
end

%- Assign fitting parameters
img.mRNA_prop.sigma_xy           = img.mRNA_prop.OS_struct.PSF_fit.sigma_xy;
img.mRNA_prop.sigma_z            = img.mRNA_prop.OS_struct.PSF_fit.sigma_z;
img.mRNA_prop.amp_mean_fit_QUANT = img.mRNA_prop.OS_struct.PSF_fit.amp;
img.mRNA_prop.sum_pix            = img.mRNA_prop.PSF_sum_pix;

if isfield(img.mRNA_prop,'bgd_value')
    img.mRNA_prop.bgd_value          = img.mRNA_prop.bgd_value;
else
    img.mRNA_prop.bgd_value          = 0;
end
img.mRNA_prop.N_pix_sum          = (2*parameters.N_pix_sum.xy+1) * (2*parameters.N_pix_sum.xy+1)  * (2*parameters.N_pix_sum.z+1); 
