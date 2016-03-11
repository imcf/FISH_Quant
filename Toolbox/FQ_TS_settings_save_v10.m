function [file_save, path_save] = FQ_TS_settings_save_v10(file_name_full,img)

current_dir = pwd;

%% Ask for file-name if it's not specified
if isempty(file_name_full)    
   
    [file_save,path_save] = uiputfile('_FQ__settings_NASCENT.txt','File-name for TS quantification settings');
    file_name_full        = fullfile(path_save,file_save);
    
else   
    [path_save, file_save,ext] = fileparts(file_name_full); 
    file_save = [file_save,ext];
end


%% Only write if FileName specified
if file_save ~= 0
    
    fid = fopen(fullfile(file_name_full),'w');
    %- Header 
    fprintf(fid,'FISH-QUANT\t%s\n', img.version);
    fprintf(fid,'SETTINGS FOR TRANSCRIPTION SITE QUANTIFICATION %s \n', date);       
       
    
    %- Name of PSF and BGD
    fprintf(fid,'\n# DESCRIPTION OF PSF AND BGD \n');
    
    fprintf(fid,'PSF_path_name=%s\n', img.mRNA_prop.path_name);
    fprintf(fid,'PSF_file_name=%s\n', img.mRNA_prop.file_name);
  
    %- General settings
    fprintf(fid,'FLAG_quant_simple_only=%g\n',  img.settings.TS_quant.flags.quant_simple_only);
    fprintf(fid,'crop_image_xy_pix=%g\n', img.settings.TS_quant.crop_image.xy_pix);
    fprintf(fid,'crop_image_z_pix=%g\n',  img.settings.TS_quant.crop_image.z_pix);
  
    %- Size of region to sum of pixels
    fprintf(fid,'\n# REGION to sum of pixels \n'); 
    fprintf(fid,'OPT_QUANT_REG_PIX_SUM_XY=%g\n',  img.settings.TS_quant.N_pix_sum.xy );
    fprintf(fid,'OPT_QUANT_REG_PIX_SUM_Z=%g\n',   img.settings.TS_quant.N_pix_sum.z );
       
    %== TS superposition approach
    if ~img.settings.TS_quant.flags.quant_simple_only 
      
        fprintf(fid,'AMP_path_name=%s\n', img.mRNA_prop.AMP_path_name);
        fprintf(fid,'AMP_file_name=%s\n', img.mRNA_prop.AMP_file_name);

        %- How to treat distribution of amplitudes
        fprintf(fid,'flag_amp_quant=%s\n', img.settings.TS_quant.flags.amp_quant);
        
        %-- BGD
        fprintf(fid,'BGD_path_name=%s\n', img.mRNA_prop.BGD_path_name);
        fprintf(fid,'BGD_file_name=%s\n', img.mRNA_prop.BGD_file_name);  
        fprintf(fid,'PSF_BGD_value=%g\n', img.mRNA_prop.bgd_value); 

        %- Settings for detection: FLAGS
        fprintf(fid,'\n# SETTINGS FOR QUANTIFICATION \n');   

        fprintf(fid,'FLAG_placement=%g\n', img.settings.TS_quant.flags.placement);
        fprintf(fid,'FLAG_quality=%g\n',   img.settings.TS_quant.flags.quality);
        fprintf(fid,'FLAG_posWeight=%g\n', img.settings.TS_quant.flags.posWeight);       
        fprintf(fid,'FLAG_crop=%g\n',      img.settings.TS_quant.flags.crop);
        fprintf(fid,'FLAG_psf=%g\n',       img.settings.TS_quant.flags.psf);    
        fprintf(fid,'FLAG_shift=%g\n',     img.settings.TS_quant.flags.shift); 

        %- Settings for detection: PARAMETERs
        fprintf(fid,'N_reconstruct=%g\n',    img.settings.TS_quant.N_reconstruct);
        fprintf(fid,'N_run_prelim=%g\n',     img.settings.TS_quant.N_run_prelim);
        fprintf(fid,'factor_Q_ok=%g\n',      img.settings.TS_quant.factor_Q_ok);

        %- Background estimation of transcription site
        fprintf(fid,'\n# SETTINGS FOR BACKGROUND of TxSite \n'); 
        fprintf(fid,'FLAG_bgd_local=%g\n',   img.settings.TS_quant.flags.bgd_local); 
        if img.settings.TS_quant.flags.bgd_local == 0 
            fprintf(fid,'TS_BGD_value=%g\n', img.settings.TS_quant.BGD.amp); 
        end
        fprintf(fid,'bgd_auto_N_bins=%g\n',   img.settings.TS_quant.bgd_N_bins);               
        fprintf(fid,'bgd_auto_fact_min=%g\n', img.settings.TS_quant.bgd_fact_min);     
        fprintf(fid,'bgd_auto_fact_max=%g\n', img.settings.TS_quant.bgd_fact_max);     

    end

    fclose(fid);
end

%- Go back to original folder
cd(current_dir)
