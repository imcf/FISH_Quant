function handles = FQ_TS_analyze_PSF_v3(handles,parameters) 

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
par_microscope    = handles.par_microscope;
fact_os           = handles.fact_os;

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
if not(isempty(handles.BGD_file_name))
    file_bgd       = fullfile(handles.BGD_path_name, handles.BGD_file_name);
    img_BGD_struct = load_stack_data_v7(file_bgd);    
    PSF_BGD        = img_BGD_struct.data;
    
elseif isfield(handles,'bgd_value')
    PSF_BGD = handles.bgd_value;
    
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
file_name_PSF                                                = fullfile(handles.PSF_path_name, handles.PSF_file_name);
parameters_PSF.par_crop_quant                                = par_crop_OS_quant;
parameters_PSF.par_crop_detect                               = par_crop_OS_detect;
[handles.img_PSF_OS_struct handles.PSF_OS_fit file_name_PSF] = PSF_3d_analyse_v8(file_name_PSF, parameters_PSF);


%- Further processing only if image of PSF is defined
if not(isempty(handles.img_PSF_OS_struct))

    [handles.PSF_path_name name ext]  = fileparts(file_name_PSF);
    handles.PSF_file_name = [name,ext];

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
    

    [handles.PSF_shift dum handles.PSF_shift_fit_summary handles.PSF_sum_pix] = PSF_3D_generate_shifted_v5(handles.img_PSF_OS_struct ,parameters_shift);
    handles.parameters_shift = parameters_shift;
else
    handles.PSF_shift = [];
    handles.parameters_shift = [];
    handles.PSF_shift_fit_summary = [];
    handles.PSF_sum_pix = [];
end
