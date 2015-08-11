function [settings, file_good] = FQ_TS_detect_settings_load_v2(file_name,struct_store)
% Function to read in settings for analysis of FISH data
% Settings are stored in a simple format. Each property starts with the
% name followed by a '='and the actual value. There is NO space inbetween
% the equal sign and the identifier and the actual value!
%
% struct_store is the structure where the settings will be save. Can either
% be empty or a user defined structure. In FISH_QUANT the handles structure
% of the GUI will be the input. This way all the saved settings will be
% over-written while other will be untouched.

file_good = 0;

if isempty(struct_store)
    settings = {};
else
    settings = struct_store;
end

%- Status to indicate if background value was already read-in
status_bgd_read = 0;

%- Open file
fid  =  fopen(file_name,'r');


% Read in each line and check if one of the known identifiers is present.
% If yes, assign the corresponding value

if fid == -1
    warndlg('Settings file cannot be opened','FQ_TS_detect_settings_load_v2'); 
else

    %- Loop through file until end of file
    while not(feof(fid))

        %- Extract string of entire line
        C   = textscan(fid,'%s',1,'delimiter','\n');
        str =  char(C{1});

        %- Check if line indicates that we have a settings file for TS
        %  quantification
        ind_TS_sett = strfind(str, 'SETTINGS FOR TRANSCRIPTION SITE DETECTION'); 
        
        if ~isempty(ind_TS_sett)
            file_good = 1;
        end
        
        %- Is there and equal sign? Extract strings before and after
        k = strfind(str, '=');    
        str_tag = str(1:k-1);
        str_val = str(k+1:end);

        %- Compare identifier before the equal sign to known identifier
        switch str_tag

            case 'img_det_type'
                settings.img_det_type = (str_val);

            case 'int_th'
                settings.int_th = str2double(str_val);             
          
            case 'conn'
                settings.conn = str2double(str_val);  
            
            case 'status_only_in_nuc'
                settings.status_only_in_nuc = str2double(str_val);  
             
            case 'N_max_TS_cell'
                settings.N_max_TS_cell = str2double(str_val);               
             
            case 'N_max_TS_total'
                settings.N_max_TS_total = str2double(str_val);
            
            case 'th_min_TS_DAPI'
                settings.th_min_TS_DAPI = str2double(str_val);                
            
            case 'min_dist'
                settings.min_dist = str2double(str_val);  
             
            %- Offset distance for LacI
            case 'dist_max_offset'
                settings.dist_max_offset = str2double(str_val);      
            
            case 'dist_max_offset_FISH_min_int'
                settings.dist_max_offset_FISH_min_int = str2double(str_val);            
                
            %- Size of region: older version used a different identifier    
            case 'crop_image_xy_nm'
                settings.size_detect.xy_nm = str2double(str_val);               
             
            case 'crop_image_z_nm'
                settings.size_detect.z_nm = str2double(str_val);    
                
                
            case 'size_detect_xy_nm'
                settings.size_detect.xy_nm = str2double(str_val);               
             
            case 'size_detect_z_nm'
                settings.size_detect.z_nm = str2double(str_val);                  
       
        end      

    end
    
    fclose(fid);
end

%- Check if file was good otherwise return input
if file_good == 0
    warndlg('File did NOT contain settings for TS detection.','FQ_TS_detect_settings_load_v2'); 
    
    if isempty(struct_store)
        settings = {};
    else
        settings = struct_store;
    end
end

