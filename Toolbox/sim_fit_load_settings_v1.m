function FQ_obj_settings = sim_fit_load_settings_v1(path_script)

FQ_obj_settings = FQ_img;

%=== Get settings file
%    Here the example settings file from FISH-sim is loaded.
name_settings  = '_FQ_settings_mature__locFISH.txt';
path_sett      = fullfile(path_script);

status_sett   = FQ_obj_settings.load_settings(fullfile(path_sett,name_settings));

if status_sett == 0;
    warndlg('Settings file not found. Are you sure that you copied all necessary data to FISH-loc folder? New file can be defined',mfilename)
     [file_sett,path_sett] = uigetfile(name_settings);
     status_sett    = FQ_obj_settings.load_settings(fullfile(path_sett,name_settings));
end

if status_sett == 0
     errordlg('Not settings defined.')
    return
end
    
