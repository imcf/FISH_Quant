function table_feat_all = smFISH_exp_analyze_v2(param)
%% FUNCTION. Analyze recursively all experimental data

%% Folder to save summary table of localization features
if ~isempty(param.features)
    %=== Specify where the summary localization table should be stored
    disp('Specify folder where table of localization features of all analyzed data will be stored')
    path_results_localization = dlg_folder_locTable();
    if path_results_localization == 0; return; end
end


%% Loop over all folders
table_feat_all = table;

param.flags.is_simulation = 0;
param.flags.analyze_summary = 0;  % Create summary plots allowing to judge quantification results


%% Search folder
folder_proc        = param.folder_proc;
%- Get file-list of recursive search of folder
if param.flag_recursive
    file_list   = subdir(folder_proc) ;
else
    file_list   = dir(folder_proc) ;
end

%-  Find all settings files, e.g. text files containing "_settings" in their name
file_list_name   = {file_list.name};

ind_setting_file      = cellfun(@(x) strfind(x, '_settings'), file_list_name, 'UniformOutput',false);
ind_setting_file      = cellfun(@(x) isempty(x), ind_setting_file);
setting_file_process  = {file_list_name{~ind_setting_file}};

%- Loop over all settings files that should be processed
for i_settings = 1:length(setting_file_process)
    
    %== Folder for results  = folder where settings are stored
    if param.flag_recursive
        settings_file = setting_file_process{i_settings};   
    else
        settings_file = setting_file_process{i_settings};
        settings_file = fullfile(folder_proc,settings_file);
    end
    
    path_proc     = fileparts(settings_file); 
   
    %== Load settings file and store in param structure
    FQ_obj_settings = FQ_img;
    status_sett    = FQ_obj_settings.load_settings(settings_file);
    
    if status_sett == 0
        errordlg('Settings file not found. Will exit!',mfilename)
        return
    end
    
    param.settings_loaded = FQ_obj_settings.settings;
    param.par_microscope_loaded = FQ_obj_settings.par_microscope;
        
    %=== Get all outline files 
    file_list_loop = dir(path_proc);
    
    %-  Find all settings files, e.g. text files containing "FQ_settings" in their name
    file_list_loop_name   = {file_list_loop.name};

    ind_outline           = cellfun(@(x) strfind(x,'_outline.txt'), file_list_loop_name, 'UniformOutput',false);
    ind_outline           = cellfun(@(x) isempty(x), ind_outline);
    outline_file_process  = {file_list_loop_name{~ind_outline}};
  
    %=== Set parameters for analysis function
    file_info.path_results              = path_proc;
    file_info.path_results_localization = path_proc;
    file_info.path_image                = path_proc ;
    
    %- Loop over files
    summary_image.image_name     = {};
    summary_image.cell_label     = {};
    summary_image.N_spots_simple = [];
    summary_image.N_spots_GMM    = [];
    summary_image.cell_area    = [];
    summary_image.cell_int_median    = [];
    summary_image.cell_int_mean    = [];
    summary_image.cell_int_std    = [];
    
    for i_file = 1:numel(outline_file_process)
        file_info.outline_name  = fullfile(path_proc,outline_file_process{i_file});
        table_feat_all = analyze_smFISH_v2(file_info,param,table_feat_all);
    end
    
    %- Function to plot summary - needs to be done
    %analyze_smFISH_summary_v1
    
    %- Close all file
    fclose('all');
end


%% Save entire localization table
if ~isempty(param.features)
    writetable(table_feat_all, fullfile(path_results_localization,'localization_features.csv'),'Delimiter',';');
end