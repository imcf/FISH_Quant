function [file_save, path_save] = FQ_save_settings_v1(file_name_full,img)


%% == Ask for file-name if it's not specified
if isempty(file_name_full)    
    
    %- Get name of image
    file_name_default_spot = '_FQ_settings_MATURE.txt';

    %- Get file-name
    [file_save ,path_save] = uiputfile(file_name_default_spot,'File-name for detection settings');
    file_name_full         = fullfile(path_save,file_save);
    
else   
    [path_save, file_save,ext] = fileparts(file_name_full); 
    file_save            = [file_save,ext];
end


%% ==  Write only if file name specified
if file_save ~= 0
    
    %- Open file       
    fid = fopen(fullfile(file_name_full),'w');
    
    %- Header 
    fprintf(fid,'FISH-QUANT\t%s\n', img.version);
    fprintf(fid,'ANALYSIS SETTINGS %s \n', date);       
    
    %- Experimental parameters    
    fprintf(fid,'\n# EXPERIMENTAL PARAMETERS\n');
    fprintf(fid,'lambda_EM=%g\n',  img.par_microscope.Em);
    fprintf(fid,'lambda_Ex=%g\n',  img.par_microscope.Ex);
    fprintf(fid,'NA=%g\n',         img.par_microscope.NA);
    fprintf(fid,'RI=%g\n',         img.par_microscope.RI);
    fprintf(fid,'Microscope=%s\n', img.par_microscope.type);
    fprintf(fid,'Pixel_XY=%g\n',   img.par_microscope.pixel_size.xy);
    fprintf(fid,'Pixel_Z=%g\n',    img.par_microscope.pixel_size.z);
    
    fprintf(fid,'PSF_THEO_XY=%g\n', img.PSF_theo.xy_nm);
    fprintf(fid,'PSF_THEO_Z=%g\n',  img.PSF_theo.z_nm);

    %- Settings for filtering
    fprintf(fid,'\n# FILTERING\n');
    fprintf(fid,'Filter_method=%s\n',  img.settings.filter.method);
    
    switch img.settings.filter.method
        
        case '3D_2xGauss'
            fprintf(fid,'Kernel_bgd_xy=%g\n', img.settings.filter.kernel_size.bgd_xy);
            fprintf(fid,'Kernel_bgd_z=%g\n',  img.settings.filter.kernel_size.bgd_z);

            fprintf(fid,'Kernel_psf_xy=%g\n', img.settings.filter.kernel_size.psf_xy);
            fprintf(fid,'Kernel_psf_z=%g\n',  img.settings.filter.kernel_size.psf_z);
         
            
        case '3D_LoG'
            fprintf(fid,'LoG_H=%g\n', img.settings.filter.LoG_H);
            fprintf(fid,'LoG_sigma=%g\n',  img.settings.filter.LoG_sigma);
    end
    
    
    %- Settings for pre-detection
    fprintf(fid,'\n# PRE-DETECTION\n');
    fprintf(fid,'Detect_Mode=%s\n',img.settings.detect.method);
    fprintf(fid,'Detect_Thresh_int=%g\n',   img.settings.detect.thresh_int);
    
    fprintf(fid,'Detect_Score=%s\n',img.settings.detect.score); 
    fprintf(fid,'Detect_Thresh_score=%g\n', img.settings.detect.thresh_score); 
    
    fprintf(fid,'Detect_Region_XY=%g\n',    img.settings.detect.reg_size.xy);
    fprintf(fid,'Detect_Region_Z=%g\n',     img.settings.detect.reg_size.z);
    
    fprintf(fid,'Detect_FLAG_reg_pos_sep=%g\n', img.settings.detect.flags.reg_pos_sep);
    fprintf(fid,'Detect_Region_Z_sep=%g\n', img.settings.detect.reg_size.z_sep);
    fprintf(fid,'Detect_Region_XY_sep=%g\n', img.settings.detect.reg_size.xy_sep);

    fprintf(fid,'Detect_FLAG_reg_smaller=%g\n', img.settings.detect.flags.region_smaller);
    fprintf(fid,'flag_detect_region=%g\n',img.settings.detect.flags.detect_region);
     
     %- Settings for fitting
    fprintf(fid,'\n# Fitting \n');
    fprintf(fid,'N_spots_fit_max=%g\n', img.settings.fit.N_spots_fit_max);
    
    %-- settings for fit
    fprintf(fid,'\n# RESTRICTION OF FITTING PARAMETERS\n');   
    fprintf(fid,'sigma_xy_min=%g\n',  img.settings.fit.limits.sigma_xy_min);
    fprintf(fid,'sigma_xy_max=%g\n',  img.settings.fit.limits.sigma_xy_max);
    
    fprintf(fid,'sigma_z_min=%g\n',  img.settings.fit.limits.sigma_z_min);
    fprintf(fid,'sigma_z_max=%g\n',  img.settings.fit.limits.sigma_z_max);
 
    
    %==== Settings for thresholding
    fprintf(fid,'\n# THRESHOLDING OF DETECTED SPOTS\n');
    
    %- Minimum distance between spots
    fprintf(fid,'Spots_min_dist=%g\n', img.settings.thresh.Spots_min_dist); 
    
    
    %- Thresholding based on estimated fitting parameters 
    thresh   = img.settings.thresh;
    
    if not(isempty(thresh)) && isfield(thresh,'sigmaxy')
    
        if thresh.sigmaxy.lock 
            fprintf(fid,'SPOTS_TH_sigmaXY_min=%g\n',   thresh.sigmaxy.min_th);
            fprintf(fid,'SPOTS_TH_sigmaXY_max=%g\n',   thresh.sigmaxy.max_th); 
        end

        if thresh.sigmaz.lock    
            fprintf(fid,'SPOTS_TH_sigmaZ_min=%g\n',   thresh.sigmaz.min_th);
            fprintf(fid,'SPOTS_TH_sigmaZ_max=%g\n',   thresh.sigmaz.max_th); 
        end

        if thresh.amp.lock       
            fprintf(fid,'SPOTS_TH_amp_min=%g\n',   thresh.amp.min_th);
            fprintf(fid,'SPOTS_TH_amp_max=%g\n',   thresh.amp.max_th); 
        end

        if thresh.bgd.lock       
            fprintf(fid,'SPOTS_TH_bgd_min=%g\n',   thresh.bgd.min_th);
            fprintf(fid,'SPOTS_TH_bgd_max=%g\n',   thresh.bgd.max_th); 
        end
        
        if isfield(thresh,'pos_z')
            if thresh.pos_z.lock       
                fprintf(fid,'SPOTS_TH_pos_z_min=%g\n',   thresh.pos_z.min_th);
                fprintf(fid,'SPOTS_TH_pos_z_max=%g\n',   thresh.pos_z.max_th); 
            end
        end       
        
        if isfield(thresh,'int_raw')
            if thresh.int_raw.lock       
                fprintf(fid,'SPOTS_TH_int_raw_min=%g\n',   thresh.int_raw.min_th);
                fprintf(fid,'SPOTS_TH_int_raw_max=%g\n',   thresh.int_raw.max_th); 
            end
        end

        
        if isfield(thresh,'int_filt')
            if thresh.int_filt.lock       
                fprintf(fid,'SPOTS_TH_int_filt_min=%g\n',   thresh.int_filt.min_th);
                fprintf(fid,'SPOTS_TH_int_filt_max=%g\n',   thresh.int_filt.max_th); 
            end
        end
        
        
        %- Settings for Averaging
        fprintf(fid,'\n# AVERAGING\n');
        fprintf(fid,'AVG_Region_XY=%g\n',   img.settings.avg_spots.crop.xy);
        fprintf(fid,'AVG_Region_Z=%g\n',    img.settings.avg_spots.crop.z);
        fprintf(fid,'AVG_OS_XY=%g\n',       img.settings.avg_spots.fact_os.xy );
        fprintf(fid,'AVG_OS_Z=%g\n',        img.settings.avg_spots.fact_os.z);    

        if isfield(img.settings.avg_spots,'bgd_sub')
            fprintf(fid,'AVG_bgd_sub=%g\n',img.settings.avg_spots.bgd_sub);
        else
            fprintf(fid,'AVG_bgd_sub=%g\n',1); 
        end

    end

    fclose(fid);
else
    file_save = [];
    
end
