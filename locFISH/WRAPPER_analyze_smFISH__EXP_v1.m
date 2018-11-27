%%%%%% SCRIPT TO LAUNCH A BATCH FISH-quant ANALYSIS ON EXPERIMENTAL DATA
% Script to analyze data with a simple organization. Each data-set is
% contained in one folder, e.g. this folder has to contain the images, the
% outline files and the FQ settings files. 
%
%  1. Requires a simple folder structure. One folder contains different images
%     and their outlines, and ONE settings file. These settings will be
%     applied to all images in this folder. Different folders, e.g. from
%     different experiments can contain different settings. 
%
%  2. Script will then recursively search the specified parental folder
%     for (sub)folders containing a settings file. Each folder with a
%     settings file will be processed. 
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

%=== Parameters controling calculation of localization features.
%    Set to an empty structure "param.features =  {};"  to not calculate features
param.features = define_locFeat_param_v1();  % = {};


%%  Specify folder that should be processed
disp('Select the ANALYSIS folders that should be processed')
param.folder_proc = uigetdir; 
if param.folder_proc == 0; return; end 


%% Perform analysis
param.flag_recursive = 1;  %  Should specified folder be search recursively (1) or not (0)
table_feat_all = smFISH_exp_analyze_v2(param);
    