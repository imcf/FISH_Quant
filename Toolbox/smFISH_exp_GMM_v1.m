function smFISH_exp_GMM_v1(param)
%% FUNCTION. Analyze experimental data with the GMM


%% Search folder
folder_proc = param.folder_proc;
file_list   = dir(folder_proc) ;

%-  Find all settings files, e.g. text files containing "_settings" in their name
file_list_name   = {file_list.name};
ind_outlines      = cellfun(@(x) strfind(x, param.txt_outlines), file_list_name, 'UniformOutput',false);
ind_outlines      = cellfun(@(x) isempty(x), ind_outlines);
files_process  = {file_list_name{~ind_outlines}};

%- Loop over all settings files that should be processed
for i_file = 1:length(files_process)
       
    
    %== Load settings file and store in param structure
    if isempty(param.txt_settings)
        settings_file = fullfile(folder_proc,'FQ_settings_mature.txt');
    else
        settings_file = fullfile(folder_proc,strrep(files_process{i_file},param.txt_outlines,param.txt_settings));
    end
    
    FQ_obj_settings = FQ_img;
    status_sett    = FQ_obj_settings.load_settings(settings_file);
    
    if status_sett == 0
        errordlg('Settings file not found. Will exit!',mfilename)
        return
    end
    
    %== Save parameters
    param.settings_loaded = FQ_obj_settings.settings;
    param.par_microscope_loaded = FQ_obj_settings.par_microscope;
    param.flags.is_simulation = 0;
    param.flags.analyze_summary = 0;  % Create summary plots allowing to judge quantification results

    %== Create folder to save results
    [~,name_base] = fileparts(files_process{i_file});
    folder_save = fullfile(folder_proc,name_base);
    mkdir(folder_save)
    
    %=== Process file
    file_info.path_results = folder_save;
    file_info.path_image   = folder_proc ;
    file_info.outline_name = fullfile(folder_proc,files_process{i_file});
    
    analyze_smFISH_v2(file_info,param,{});

end

