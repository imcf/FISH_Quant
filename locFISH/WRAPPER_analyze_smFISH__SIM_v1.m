%% SCRIPT: automated mRNA detection and feature calculation for simulations
%
%     =====================================================================
%     Copyright (C) 2018  Florian Mueller
%     Email: muellerf.research@gmail.com
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     For a copy a copy of the GNU General Public License
%     see <http://www.gnu.org/licenses/>.
%     =====================================================================

%% Define default parameters for GMM foci reconstruction and feature calculation.
%  Parameters can be changed by either modifying the content of this
%  function or by specifically changing one parameter after this function
%  call.
param = sim_fit_param_v1;


%% Specify the folders where the image files are stored that should be loaded
flag_recursive = 1;               % Should folder be searched recursively (1) or not (0)
[param.file_list, param.file_info, param.name_autosave] = sim_define_img_folders_v1(flag_recursive);


%% Load settings file and store in param structure
%  - Loads the default settings file '_FQ_settings_mature.text', located
%    in the same folder as this script.
%  - Contains detection settings and most importantly the detection
%    threshold. This threshold will change if different background images
%    and/or different intensity distributions for the single molecules will
%    be used. A new settings file has then be generated with FISH-quant,
%    which will replace the existing one. 
path_script                 = fileparts(which('WRAPPER_analyze_smFISH__SIM_v1')); % Get path of this script
FQ_obj_settings             = sim_fit_load_settings_v1(path_script);
param.settings_loaded       = FQ_obj_settings.settings;
param.par_microscope_loaded = FQ_obj_settings.par_microscope;


%% Analyze all files
%  Will loop over all images, detect spots, calculate localization
%  features, and return a table with the localization features of all
%  cells. 
table_feat_all =  sim_fit_all_v1(param);


%% Save table with all localization features
writetable(table_feat_all, fullfile(param.file_info.path_parent_localization,'localization_features.csv'),'Delimiter',';');
