function [PSF_shift_all N_PSF_shift summary_par_fit PSF_sum_avg] = PSF_3D_generate_shifted_v5(img_PSF,parameters)

%% Parameters

%== For shifting
fact_os        = parameters.fact_os;
pixel_size_os  = parameters.pixel_size_os;
pixel_size     = parameters.pixel_size;
range_shift_xy = parameters.range_shift_xy;
range_shift_z  = parameters.range_shift_z;

%== For fitting
par_crop_detect = parameters.par_crop_detect;
par_crop_quant  = parameters.par_crop_quant;
par_microscope  = parameters.par_microscope;
flags           = parameters.flags;


%== For sum of pixels
N_pix_sum       = parameters.N_pix_sum;



%% Generate different PSF' with shifting them in all possible direction
N_PSF = length(range_shift_xy)*length(range_shift_xy)*length(range_shift_z);

%- Pre-allocate space
PSF_shift_all = struct('data', [],'max', [],'PSF_fit_quant', [],'PSF_fit_detect', [], ...
                       'par_shift', [],'index_shift', [],'PSF_fit_OS',[]);      
PSF_shift_all(N_PSF).data = 1;

            
%- Loop over all differnt shifts
fprintf('Analysing placement: (of %d):     1',N_PSF);

ind_PSF = 1;
for i_x = 1:length(range_shift_xy)    
    for i_y = 1:length(range_shift_xy)        
        for i_z = 1:length(range_shift_z)  

            fprintf('\b\b\b\b%4i',ind_PSF); 
            
            % === CREATE SHIFTED IMAGE
            
            %- Shift over-sampled image
            par_shift                 = {range_shift_xy(i_x),range_shift_xy(i_y),range_shift_z(i_z)};
            [psf_os_shift dum dim_os] = PSF_3D_os_shift_v1(img_PSF.data,fact_os,pixel_size_os,par_shift);    

            %- Dimension and subregion of image in normal sampling
            dim_rec.Y = floor(dim_os.X/fact_os.xy); 
            dim_rec.X = floor(dim_os.X/fact_os.xy); 
            dim_rec.Z = floor(dim_os.Z/fact_os.z); 

            range_rec.X_nm = (1:dim_rec.X)*pixel_size.xy;
            range_rec.Y_nm = (1:dim_rec.Y)*pixel_size.xy;
            range_rec.Z_nm = (1:dim_rec.Z)*pixel_size.z;

            %- Calculate image in normal sampling
            PSF_shift.data  = PSF_3D_reconstruct_from_os_v1(psf_os_shift,range_rec,fact_os,0);    
            
            if flags.norm == 1
                if ind_PSF == 1
                    I_norm = sum(PSF_shift.data(:));
                    
                else
                    I_data = sum(PSF_shift.data(:));
                    PSF_shift.data = PSF_shift.data * I_norm / I_data;
                end
            end           

            %== Sum of pixel intensity around center
            [dim_PSF.Y dim_PSF.X dim_PSF.Z] = size(PSF_shift.data);
            [PSF_max_int PSF_max_int_IND] = max(PSF_shift.data(:));
            [ind_Y ind_X ind_Z] = ind2sub(size(PSF_shift.data), PSF_max_int_IND);

            min_Y = ind_Y - N_pix_sum.xy;
            min_X = ind_X - N_pix_sum.xy;
            min_Z = ind_Z - N_pix_sum.z;

            max_Y = ind_Y + N_pix_sum.xy;
            max_X = ind_X + N_pix_sum.xy;
            max_Z = ind_Z + N_pix_sum.z;

            flag_OK = 1;

            if min_Y < 1 || min_X < 1 || min_Z < 1 || ...
               max_Y > dim_PSF.Y || max_X > dim_PSF.X || max_Z > dim_PSF.Z 

                flag_OK  = 0;

            end

            if flag_OK
                PSF_sub = PSF_shift.data(min_Y:max_Y,min_X:max_X,min_Z:max_Z);
                PSF_sum = sum(PSF_sub(:));
            else
                PSF_sum = 0;
            end

            
            %== Fit with 3D Gaussian
            parameters_fit.pixel_size      = pixel_size;
            parameters_fit.par_microscope  = par_microscope;
            parameters_fit.flags           = flags;
            
            %-- [1] Same cropping as used for detection
            parameters_fit.par_crop         = par_crop_detect;
            [PSF_fit_detect]                = PSF_3D_Gauss_fit_v8(PSF_shift,parameters_fit);    
           
            %-- [2] Same cropping as used for TS quantification
            parameters_fit.par_crop         = par_crop_quant;
            [PSF_fit_quant PSF_shift_quant] = PSF_3D_Gauss_fit_v8(PSF_shift,parameters_fit); 
            
            %=== Save everything
            PSF_shift_all(ind_PSF).data        = PSF_shift.data;
            PSF_shift_all(ind_PSF).max         = PSF_shift_quant.max;
            
            PSF_shift_all(ind_PSF).PSF_fit_quant.sigma_xy        = PSF_fit_quant.sigma_xy ;
            PSF_shift_all(ind_PSF).PSF_fit_quant.sigma_z         = PSF_fit_quant.sigma_z;
            PSF_shift_all(ind_PSF).PSF_fit_quant.amp             = PSF_fit_quant.amp;
            PSF_shift_all(ind_PSF).PSF_fit_quant.bgd             = PSF_fit_quant.bgd;
           
            PSF_shift_all(ind_PSF).PSF_fit_detect.sigma_xy        = PSF_fit_detect.sigma_xy ;
            PSF_shift_all(ind_PSF).PSF_fit_detect.sigma_z         = PSF_fit_detect.sigma_z;
            PSF_shift_all(ind_PSF).PSF_fit_detect.amp             = PSF_fit_detect.amp;
            PSF_shift_all(ind_PSF).PSF_fit_detect.bgd             = PSF_fit_detect.bgd;
            
            PSF_shift_all(ind_PSF).par_shift   = par_shift;
            PSF_shift_all(ind_PSF).index_shift = [i_x, i_y,i_z];            
            
            PSF_shift_all(ind_PSF).PSF_fit_OS.sigma_xy = img_PSF.PSF_fit.sigma_xy ;
            PSF_shift_all(ind_PSF).PSF_fit_OS.sigma_z  = img_PSF.PSF_fit.sigma_z;
            PSF_shift_all(ind_PSF).PSF_fit_OS.amp      = img_PSF.PSF_fit.amp;
            PSF_shift_all(ind_PSF).PSF_fit_OS.bgd      = img_PSF.PSF_fit.bgd;                       

            PSF_shift_all(ind_PSF).sum_pix = PSF_sum;
            PSF_sum_all(ind_PSF,1) = PSF_sum;
            
            
            %=== All fitting parameters
            par_fit_crop_QUANT_all(ind_PSF,:)  = [PSF_fit_quant.sigma_xy  PSF_fit_quant.sigma_z  PSF_fit_quant.amp  PSF_fit_quant.bgd];
            par_fit_crop_DETECT_all(ind_PSF,:) = [PSF_fit_detect.sigma_xy PSF_fit_detect.sigma_z PSF_fit_detect.amp PSF_fit_detect.bgd];
    
           
            %=== Update counter
            ind_PSF = ind_PSF+1;  
            
        end
    end
end
fprintf('\n');
N_PSF_shift         = ind_PSF -1;

par_fit_crop_QUANT_avg  = mean(par_fit_crop_QUANT_all,1);
par_fit_crop_DETECT_avg = mean(par_fit_crop_DETECT_all,1);

summary_par_fit.crop_QUANT_AVG = par_fit_crop_QUANT_avg;
summary_par_fit.crop_QUANT_ALL = par_fit_crop_QUANT_all;

summary_par_fit.crop_DETECT_AVG = par_fit_crop_DETECT_avg;
summary_par_fit.crop_DETECT_ALL = par_fit_crop_DETECT_all;

PSF_sum_avg = mean(PSF_sum_all);

