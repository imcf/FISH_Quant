function table_feat_all = smFISH_exp_analyze_batch_v2(param)
%% FUNCTION. Analyze recursively all experimental data

folder_list       = param.folder_list;
setting_identifier = param.setting_identifier;

%% Loop over all folders
table_feat_all = table;

param.flags.is_simulation = 0;
param.flags.analyze_summary = 0;  % Create summary plots allowing to judge quantification results


for i_folder = 1:length(folder_list)
    
    %- Get file-list of recursive search of folder
    file_list   = subdir(folder_list{i_folder}) ;     
    
    %-  Find all settings files, e.g. text files containing "FQ_settings" in their name
    file_name_cell   = {file_list.name};
    
    ind_setting_file = cellfun(@(x) strfind(x, '_settings'), file_name_cell, 'UniformOutput',false);
    ind_setting_file = cellfun(@(x) isempty(x), ind_setting_file);
    setting_file     = {file_name_cell{~ind_setting_file}};
        
    %- Select the ones that should be processed, those are the ones that
    %contain the search string in their FULL file name
    if ~isempty(setting_identifier)
        ind_setting_process = cellfun(@(x) strfind(x, setting_identifier), setting_file, 'UniformOutput',false);
        ind_setting_process = cellfun(@(x) isempty(x), ind_setting_process);
        setting_file_process = {setting_file{~ind_setting_process}};
    else
        setting_file_process = setting_file;
    end
    
    %- Loop over all settings files that should be processed
    for i_settings = 1:length(setting_file_process)
        
        disp('Processing settings file')
        disp(setting_file_process{i_settings})
        
        %== Folder for results  = folder where settings are stored
        settings_file = setting_file_process{i_settings};
        path_result   = fileparts(settings_file);
       
        %== Load settings file and store in param structure
        FQ_obj_settings = FQ_img;
        status_sett    = FQ_obj_settings.load_settings(settings_file);

        if status_sett == 0
            errordlg('Settings file not found. Will exit!',mfilename)
            return
        end

        param.settings_loaded = FQ_obj_settings.settings;
        param.par_microscope_loaded = FQ_obj_settings.par_microscope;
  
        %- Folder with outlines = replace the last level in folder hierachy
        %  by FQ_outlines
        
        name_split    = strsplit(settings_file,filesep);
        path_outline  = {name_split{1:end-2}};
        path_outline  = strjoin(path_outline, filesep);
        path_outline  = fullfile(path_outline, 'FQ_outlines');
        
        disp('Looking for outlines in folder:')
        disp(path_outline)
        
        %- Folder with images
        path_image = strrep(path_outline, 'Analysis', 'Acquisition'); 
        path_image = strsplit(path_image,filesep);
        path_image = {path_image{1:end-1}};
        path_image = strjoin(path_image, filesep);
                
        %=== Get all outline files by recersive    search 
        outline_names = dir(path_outline);
        
        disp([outline_names(:).name])
        
        %- Remove folders
        isub = [outline_names(:).isdir]; % returns logical vector
        outline_names = {outline_names(~isub).name}';
        
        %- Only consider files ending with outline.txt
        is_outline      = cellfun(@(x) ~isempty(regexp(x,'.*outline.txt')), outline_names);    
        outline_names    = outline_names(is_outline);
        
        %=== Set parameters for analysis function
        file_info.path_results              = path_result;
        file_info.path_results_localization = path_result;
        file_info.path_image    = path_image ;
        
        %- Loop over files
        summary_image.image_name     = {};
        summary_image.cell_label     = {};
        summary_image.N_spots_simple = [];
        summary_image.N_spots_GMM    = [];
        summary_image.cell_area    = [];
        summary_image.cell_int_median    = [];
        summary_image.cell_int_mean    = [];
        summary_image.cell_int_std    = [];
        
        for i_file = 1:numel(outline_names)
            file_info.outline_name  = fullfile(path_outline,outline_names{i_file});
            table_feat_all = analyze_smFISH_v2(file_info,param,table_feat_all);    
        end
        
        %- Function to plot summary - needs to be done
        %analyze_smFISH_summary_v1
        
        %- Close all file
        fclose('all');
    end
end