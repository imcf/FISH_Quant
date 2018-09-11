function path_results_localization = dlg_folder_locTable

%% Select folder where final localization table will be stored
disp('Please define folder where localization table should be stored.')
path_results_localization = uigetdir('Please define folder where final localization table will be stored.');
