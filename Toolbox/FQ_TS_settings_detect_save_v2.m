function [file_save, path_save] = FQ_TS_settings_detect_save_v2(file_name_full,img)

current_dir = pwd;


path_save = img.settings.TS_detect.path_save;

%% Ask for file-name if it's not specified
if isempty(file_name_full)    
    
    file_name_default_spot = '_FQ__settings_TS_DETECT.txt';
    [file_save,path_save] = uiputfile(file_name_default_spot,'File-name for TS detection settings');
    file_name_full = fullfile(path_save,file_save);
    
else   
    [dum, file_save,ext] = fileparts(file_name_full); 
    file_save = [file_save,ext];
end


%% Only write if FileName specified
if file_save ~= 0
           
    fid = fopen(fullfile(file_name_full),'w');
    %- Header 
    fprintf(fid,'FISH-QUANT\t%s\n', img.version);
    fprintf(fid,'SETTINGS FOR TRANSCRIPTION SITE DETECTION %s \n', date);       
     
    %- Experimental parameters    
    fprintf(fid,'\n# PARAMETERS\n');
    fprintf(fid,'img_det_type=%s\n', img.settings.TS_detect.img_det_type );
    fprintf(fid,'int_th=%g\n', img.settings.TS_detect.int_th );
    fprintf(fid,'dist_max_offset=%g\n', img.settings.TS_detect.dist_max_offset );
    fprintf(fid,'conn=%g\n', img.settings.TS_detect.conn );
    fprintf(fid,'dist_max_offset=%g\n', img.settings.TS_detect.dist_max_offset );
    fprintf(fid,'dist_max_offset_FISH_min_int=%g\n', img.settings.TS_detect.dist_max_offset_FISH_min_int );
    fprintf(fid,'N_max_TS_cell=%g\n', img.settings.TS_detect.N_max_TS_cell );
    fprintf(fid,'N_max_TS_total=%g\n', img.settings.TS_detect.N_max_TS_total );
    fprintf(fid,'status_only_in_nuc=%g\n', img.settings.TS_detect.status_only_in_nuc );
    fprintf(fid,'th_min_TS_DAPI=%g\n', img.settings.TS_detect.th_min_TS_DAPI );
    fprintf(fid,'min_dist=%g\n', img.settings.TS_detect.min_dist );
    fprintf(fid,'pixel_size_xy=%g\n', img.par_microscope.pixel_size.xy );
    fprintf(fid,'pixel_size_z=%g\n', img.par_microscope.pixel_size.z );
    fprintf(fid,'size_detect_xy_nm=%g\n', img.settings.TS_detect.size_detect.xy_nm);
    fprintf(fid,'size_detect_z_nm=%g\n', img.settings.TS_detect.size_detect.z_nm);
  
    %- Close file
    fclose(fid);
end

%- Go back to original folder
cd(current_dir)
