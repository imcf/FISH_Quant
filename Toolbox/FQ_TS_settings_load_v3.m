function [img,file_good] = FQ_TS_settings_load_v3(file_name,img)
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

%- Status to indicate if background value was already read-in
status_bgd_read = 0;

%- Open file
fid  =  fopen(file_name,'r');


% Read in each line and check if one of the known identifiers is present.
% If yes, assign the corresponding value

if fid == -1
    warndlg('Settings file cannot be opened','FQ_TS_settings_load_v3'); 
    disp(file_name)    
    
else

    %- Loop through file until end of file
    while not(feof(fid))

        %- Extract string of entire line
        C   = textscan(fid,'%s',1,'delimiter','\n');
        str =  char(C{1});

        %- Check if line indicates that we have a settings file for TS quantification
        ind_TS_sett = strfind(str, 'SETTINGS FOR TRANSCRIPTION SITE QUANTIFICATION'); 
        
        if ~isempty(ind_TS_sett)
            file_good = 1;
        end
        
        
        %- Is there and equal sign? Extract strings before and after
        k = strfind(str, '=');    
        str_tag = str(1:k-1);
        str_val = str(k+1:end);

        %- Compare identifier before the equal sign to known identifier
        switch str_tag
                
           case 'FLAG_quant_simple_only' 
                img.settings.TS_quant.flags.quant_simple_only = str2double(str_val);    
   
              case 'PSF_path_name'                  
                img.mRNA_prop.path_name = (str_val); 
                
              case 'PSF_file_name'
                img.mRNA_prop.file_name = (str_val);               
                
              case 'PSF_BGD_value'    
                img.mRNA_prop.bgd_value = str2double(str_val);  
                     
               case 'BGD_path_name'                  
                img.mRNA_prop.BGD_path_name = (str_val); 
            
              case 'BGD_file_name'
                img.mRNA_prop.BGD_file_name = (str_val);                
                
              case 'AMP_path_name'                  
                img.mRNA_prop.AMP_path_name = (str_val); 
                
              case 'AMP_file_name'
                img.mRNA_prop.AMP_file_name = (str_val);     
                
               case 'flag_amp_quant'
                img.settings.TS_quant.flags.amp_quant = str_val; 
                
 
            %== Various flags to control the quantification    
            case 'FLAG_placement'
                img.settings.TS_quant.flags.placement = str2double(str_val);    

            case 'FLAG_quality'
                img.settings.TS_quant.flags.quality = str2double(str_val); 

            case 'FLAG_posWeight'
                img.settings.TS_quant.flags.posWeight = str2double(str_val);   

            case 'FLAG_crop'
                img.settings.TS_quant.flags.crop = str2double(str_val); 

            case 'FLAG_psf'
                img.settings.TS_quant.flags.psf = str2double(str_val); 
                
            case 'FLAG_shift'
                img.settings.TS_quant.flags.shift = str2double(str_val);    

                  
            case 'N_reconstruct'
                img.settings.TS_quant.N_reconstruct = str2double(str_val);      
          
            case 'N_run_prelim'
                img.settings.TS_quant.N_run_prelim = str2double(str_val);
            
            case 'crop_image_xy_nm'
                img.settings.TS_quant.crop_image.xy_nm= str2double(str_val);      
          
            case 'crop_image_z_nm'
                img.settings.TS_quant.crop_image.z_nm = str2double(str_val);            

            case 'crop_image_xy_pix'
                img.settings.TS_quant.crop_image.xy_pix= str2double(str_val);      
          
            case 'crop_image_z_pix'
                img.settings.TS_quant.crop_image.z_pix = str2double(str_val);                  

            case 'factor_Q_ok'
                img.settings.TS_quant.factor_Q_ok = str2double(str_val);  
            
                                
           %== Background of transcription site        
           case 'FLAG_bgd_local'
                img.settings.TS_quant.flags.bgd_local = str2double(str_val);                  
               
           case 'bgd_auto_N_bins'    
                img.settings.TS_quant.bgd_N_bins = str2double(str_val);  
              
           case 'bgd_auto_fact_min'
                img.settings.TS_quant.bgd_fact_min = str2double(str_val);        
                
           case 'bgd_auto_fact_max'
                img.settings.TS_quant.bgd_fact_max = str2double(str_val);  
                
            case 'TS_BGD_value'
                if isfield(settings.parameters_quant,'BGD')
                    if isfield(settings.parameters_quant.BGD,'amp') 
                        
                        %- Avoid appending to existing definition form earlier settings
                        if status_bgd_read == 1
                            settings.parameters_quant.BGD.amp = [settings.parameters_quant.BGD.amp,str2double(str_val)];
                        else
                            settings.parameters_quant.BGD.amp = str2double(str_val);
                            status_bgd_read = 1;
                        end
                    end
                else
                    settings.parameters_quant.BGD.amp = str2double(str_val);
                    status_bgd_read = 1;
                end            
                         
           %== Region to sum of pixels               
           case 'OPT_QUANT_REG_PIX_SUM_XY'            
                img.settings.TS_quant.N_pix_sum.xy= str2double(str_val);

           case 'OPT_QUANT_REG_PIX_SUM_Z'
                img.settings.TS_quant.N_pix_sum.z = str2double(str_val);     
              
        end      

    end
    
    fclose(fid);
end


%==== Make sure that all parameters are assigned
if ~isfield(img.settings.TS_quant.flags,'quant_simple_only')
    img.settings.TS_quant.flags.quant_simple_only = 1;
end

%- Check if file was good otherwise return input
if file_good == 0
    warndlg('File did NOT contain settings for TS quantification.','FQ_TS_settings_load_v3'); 
    
    if isempty(struct_store)
        settings = {};
    else
        settings = struct_store;
    end
end
