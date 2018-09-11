function [file_list, file_info, name_autosave] = sim_define_img_folders_v1(flag_recursive)

file_list = [];
file_info = [];
name_autosave = [];

disp('Please define folder where images are stored.')
path_parent = uigetdir('Please define folder where images are stored.');
if path_parent == 0; return; end

if flag_recursive
    string_search = fullfile(path_parent,'**','*.tif');
    file_list_dir     = rdir(string_search);
else
    string_search = fullfile(path_parent,'*.tif');
    file_list_dir     = dir(string_search);
end

%- Which files to keep?
ind_keep = true(length(file_list_dir),1);

for iFile=1:length(file_list_dir)
    
   %- Ignore maximum intensity projections 
   if strfind(file_list_dir(iFile).name,'MAX_')
       ind_keep(iFile) = false;
   end
end

file_list = file_list_dir(ind_keep);

%- Generate folders to save detection results and localization features
path_results = fullfile(path_parent,'_results_detection');
if ~exist(path_results); mkdir(path_results); end

path_results_localization = fullfile(path_parent,'_results_localization');
if ~exist(path_results_localization); mkdir(path_results_localization); end

file_info.path_parent              = path_parent;
file_info.path_parent_results      = path_results;
file_info.path_parent_localization = path_results_localization;

name_autosave = fullfile(path_results,'_auto_save.mat');
