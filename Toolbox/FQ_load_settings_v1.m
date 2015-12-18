function [img, status] = FQ_load_settings_v1(file_name,img)
% Function to read in settings for analysis of FISH data
% Settings are stored in a simple format. Each property starts with the
% name followed by a '='and the actual value. There is NO space inbetween
% the equal sign and the identifier and the actual value!
%
% struct_store is the structure where the settings will be save. Can either
% be empty or a user defined structure. In FISH_QUANT the FQ_img object
% will be the input. This way all the saved settings will be
% over-written while not defined ones will be untouched.


status = 1;

%- Open file
fid  =  fopen(file_name,'r');

% Read in each line and check if one of the known identifiers is present.
% If yes, assign the corresponding value

if fid == -1
    warndlg('Settings file cannot be opened. See Command window for more details',mfilename)
    disp(' ')
    disp('=== Settings file for mature mRNA detection cannot be opened');
    disp('Maybe folder is not set correctly?')
    disp(file_name)
    status = 0;
else

    %- Loop through file until end of file
    while not(feof(fid))

        %- Extract string of entire line
        C   = textscan(fid,'%s',1,'delimiter','\n');
        str =  char(C{1});

        
        %- Is there and equal sign? Extract strings before and after
        k = strfind(str, '=');    
        str_tag = str(1:k-1);
        str_val = str(k+1:end);


        %- Compare identifier before the equal sign to known identifier
        switch str_tag

            %- FQ version
            case 'version'
                img.version = str_val;

            %- Microscope parameters
            case 'lambda_EM'
                img.par_microscope.Em = str2double(str_val);

            case 'lambda_Ex'
                img.par_microscope.Ex = str2double(str_val);             

            case 'NA'            
                img.par_microscope.NA = str2double(str_val);            

            case 'RI'
                img.par_microscope.RI = str2double(str_val);            

            case 'Microscope'
                img.par_microscope.type = str_val;   

            case 'Pixel_XY'    
                img.par_microscope.pixel_size.xy = str2double(str_val);                 

            case 'Pixel_Z' 
                img.par_microscope.pixel_size.z = str2double(str_val); 

            case 'status_3D' 
                img.status_3D = str2double(str_val); 
              
             % === Filtering: 2XGauss      
             case 'Filter_method'            
                img.settings.filter.method            = str_val;
            
             case 'Kernel_bgd_xy'            
                img.settings.filter.kernel_size.bgd_xy = str2double(str_val);
                
            case 'Kernel_bgd_z'            
                img.settings.filter.kernel_size.bgd_z = str2double(str_val);    

            case 'Kernel_psf_xy'
                img.settings.filter.kernel_size.psf_xy = str2double(str_val);

            case 'Kernel_psf_z'
                img.settings.filter.kernel_size.psf_z = str2double(str_val);                
    
            case 'LoG_H'
                img.settings.filter.LoG_H = str2double(str_val);

            case 'LoG_sigma'
                img.settings.filter.LoG_sigma = str2double(str_val);                
    

            % === Detection 
            case 'Detect_Mode'    
                img.settings.detect.method = str_val;
                                    
            case 'Detect_Thresh_int'
                img.settings.detect.thresh_int = str2double(str_val);      
                
            case 'Detect_Score'    
                img.settings.detect.score = str_val; 
            
            case 'Detect_Thresh_score'
                img.settings.detect.thresh_score = str2double(str_val); 
                         
            case 'Detect_Region_XY'
                img.settings.detect.reg_size.xy = str2double(str_val);             

            case 'Detect_Region_Z'            
                img.settings.detect.reg_size.z = str2double(str_val);            
     
            case 'Detect_FLAG_reg_pos_sep'    
                img.settings.detect.flags.reg_pos_sep = str2double(str_val);               
                    
            case 'Detect_Region_XY_sep'    
                img.settings.detect.reg_size.xy_sep = str2double(str_val);  
                
            case 'Detect_Region_Z_sep'    
                img.settings.detect.reg_size.z_sep = str2double(str_val);     
          
                
            case 'Detect_FLAG_reg_smaller'
                img.settings.detect.flags.region_smaller = str2double(str_val);   
                        
            case 'flag_detect_region'    
                img.settings.detect.flags.detect_region = str2double(str_val);     
                      
                
            % ==== Fitting     
            case 'N_spots_fit_max'
                img.settings.fit.N_spots_fit_max = str2double(str_val); 
                
            case 'Spots_min_dist'    
                img.settings.thresh.Spots_min_dist = str2double(str_val);               
            
                
            % === Restriction of fitted parameters    
            case 'sigma_xy_min'
                img.settings.fit.limits.sigma_xy_min = str2double(str_val);

            case 'sigma_xy_max'    
                img.settings.fit.limits.sigma_xy_max = str2double(str_val);
                
            case 'sigma_z_min'
                img.settings.fit.limits.sigma_z_min = str2double(str_val);

            case 'sigma_z_max'    
                img.settings.fit.limits.sigma_z_max = str2double(str_val);    
                            

            %== Thresholding - after fitting
            case 'SPOTS_TH_sigmaXY_min'
                img.settings.thresh.sigmaxy.min_th = str2double(str_val);
                img.settings.thresh.sigmaxy.lock      = 1;

            case 'SPOTS_TH_sigmaXY_max'    
                img.settings.thresh.sigmaxy.max_th = str2double(str_val);
                img.settings.thresh.sigmaxy.lock      = 1;

             case 'SPOTS_TH_sigmaZ_min'
                img.settings.thresh.sigmaz.min_th = str2double(str_val);
                img.settings.thresh.sigmaz.lock      = 1;

            case 'SPOTS_TH_sigmaZ_max'    
                img.settings.thresh.sigmaz.max_th = str2double(str_val);
                img.settings.thresh.sigmaz.lock      = 1;    

           case 'SPOTS_TH_amp_min'
                img.settings.thresh.amp.min_th = str2double(str_val);
                img.settings.thresh.amp.lock      = 1;

            case 'SPOTS_TH_amp_max'    
                img.settings.thresh.amp.max_th = str2double(str_val);
                img.settings.thresh.amp.lock      = 1;    

           case 'SPOTS_TH_bgd_min'
                img.settings.thresh.bgd.min_th = str2double(str_val);
                img.settings.thresh.bgd.lock      = 1;

            case 'SPOTS_TH_bgd_max'    
                img.settings.thresh.bgd.max_th = str2double(str_val);
                img.settings.thresh.bgd.lock      = 1;              

            case 'SPOTS_TH_score_min'
                img.settings.thresh.score.min_th = str2double(str_val);
                img.settings.thresh.score.lock     = 1;

            case 'SPOTS_TH_score_max'    
                img.settings.thresh.score.max_th = str2double(str_val);
                img.settings.thresh.score.lock     = 1;                      

            case 'SPOTS_TH_iter_min'
                img.settings.thresh.iter.min_th = str2double(str_val);
                img.settings.thresh.iter.lock     = 1;

            case 'SPOTS_TH_iter_max'    
                img.settings.thresh.iter.max_th = str2double(str_val);
                img.settings.thresh.iter.lock      = 1;   

            case 'SPOTS_TH_resNorm_min'
                img.settings.thresh.resNorm.min_th = str2double(str_val);
                img.settings.thresh.resNorm.lock     = 1;

            case 'SPOTS_TH_resNorm_max'    
                img.settings.thresh.resNorm.max_th = str2double(str_val);
                img.settings.thresh.resNorm.lock     = 1;    
            
            case 'SPOTS_TH_pos_z_min'
                img.settings.thresh.pos_z.min_th = str2double(str_val);
                img.settings.thresh.pos_z.lock      = 1;

            case 'SPOTS_TH_pos_z_max'    
                img.settings.thresh.pos_z.max_th = str2double(str_val);
                img.settings.thresh.pos_z.lock      = 1;     

            case 'SPOTS_TH_int_raw_min'
                img.settings.thresh.int_raw.min_th = str2double(str_val);
                img.settings.thresh.int_raw.lock      = 1;

            case 'SPOTS_TH_int_raw_max'    
                img.settings.thresh.int_raw.max_th = str2double(str_val);
                img.settings.thresh.int_raw.lock      = 1; 
                
            case 'SPOTS_TH_int_filt_min'
                img.settings.thresh.int_filt.min_th = str2double(str_val);
                img.settings.thresh.int_filt.lock      = 1;

            case 'SPOTS_TH_int_filt_max'    
                img.settings.thresh.int_filt.max_th = str2double(str_val);
                img.settings.thresh.int_filt.lock      = 1; 

           
            %== Averaging of spots   
            case 'AVG_Region_XY'            
                img.settings.avg_spots.crop.xy = str2double(str_val);            

            case 'AVG_Region_Z'
                img.settings.avg_spots.crop.z = str2double(str_val);            

            case 'AVG_OS_XY'
                img.settings.avg_spots.fact_os.xy = str2double(str_val);   

            case 'AVG_OS_Z'    
                img.settings.avg_spots.fact_os.z = str2double(str_val);   
                
            case 'AVG_bgd_sub'    
                img.settings.avg_spots.flags.bgd = str2double(str_val);                                  
      
                
        end      

    end
    
    fclose(fid);
end


