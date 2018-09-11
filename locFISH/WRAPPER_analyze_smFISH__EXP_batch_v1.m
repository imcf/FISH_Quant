%%%%%% SCRIPT TO LAUNCH THE BATCH ANALYSIS ON EXPERIMENTAL DATA
% Consult user manual for details on how data should be organized. 
%
%  1. User specifies one (or more) Analysis folders which will be recursively
%     searched for settings files to be processed.
%
%  2. These settings files contain the string '_settings' and the user 
%     can specify additional strings that should be contained in the full 
%     file-name of the settings to restrict the analysis (e.g to a certain date). 
%
%  3. Settings files are usually generated with FQ_detect. The saved
%     settings files contain the version number of the analysis script
%     (this file!) and the date when they were generated. 
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

%% Define different default parameters for analysis
%  Parameters can be changed in respective functions

%=== Parameter controlling the GMM to analyze mRNA blobs
param.GMM = define_GMM_param_v1();

%=== Parameters controling calculation of localization features
param.features = define_locFeat_param_v1();


%% Select folders that should be searched for settings files that will be processed

%===  Specify ANALYSIS folders that should be processed
disp('Select the ANALYSIS folders that should be processed')
param.folder_list = uipickfiles; 
if ~iscell(param.folder_list); return; end 

%=== Specify string that has to be contained in the FULL file name of settings
%    file to be considered in analysis. If string is empty, all settings
%    files will be used.
param.setting_identifier = dlg_str_settings('FQ_results');
if isempty(param.setting_identifier); return; end

%=== Specify where localization table should be stored
path_results_localization = dlg_folder_locTable();
if path_results_localization == 0; return; end


%% Analyze all images
table_feat_all = smFISH_exp_analyze_batch_v2(param);


%% Save entire localization table
writetable(table_feat_all, fullfile(path_results_localization,'localization_features.csv'),'Delimiter',';');
    