%%%%%% SCRIPT TO LAUNCH A BATCH FISH-quant ANALYSIS ON EXPERIMENTAL DATA
% Script to analyze data with a simple organization. Each data-set is
% contained in one folder, e.g. this folder has to contain the images, the
% outline files and the FQ settings files. 
%
%  1. Requires a simple folder structure. One folder contains different images
%     and their outlines. You have to specify how to identify these
%     outline files, e.g. often their name ends with '__outlines.txt'
%
%  2. FQ settings are either defined by ONE file, which has to be called 'FQ_settings_mature.txt',
%     or by one setting file per outline. In this case, a text string has to be 
%     specified that allows to convert the outline file into the settings
%     file, e.g.'__settings_MATURE.txt' 
%
%  2. Script will then search the folder for outline files and process
%     each outline. Results will be stored in a newly created subfolder 
%     with the same name as the outline. 
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

%%  Specify folder that should be processed
param.GMM = define_GMM_param_v1(); %=== Parameter controlling the GMM to analyze mRNA blobs
disp('Select the ANALYSIS folders that should be processed')
param.folder_proc = uigetdir; 
if param.folder_proc == 0; return; end 


%% Perform analysis
param.txt_outlines = '__outlines.txt';
param.txt_settings = '__settings_MATURE.txt';

smFISH_exp_GMM_v1(param);
    