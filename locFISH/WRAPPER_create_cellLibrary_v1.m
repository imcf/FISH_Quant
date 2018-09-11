%% MATLAB script to generate library of 3D cells and nuclei
%    Uses as an input the 3D detection of GAPDH performed with FISH-quant. 
%    Example files are provided in data_simulation/GAPDH_detection
%
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

clear cell_library_info

%% Parameters to be defined by the user

%- Text identifiers of smFISH (GAPHD), smFISH background, and DAPI image
%  - Identifier allow conversion of GADPHD image file into the file-name of 
%    the other channels. 
%  - Defined as a structure
%  - NOTE: field-name "smFISH" and 'BGD" is compulsory
%  - File-names for other channels (e.g. DAPI) can be defined as needed 
%  - Additional channels for different markers could be added
cell_library_info.file_ident = struct('smFISH','cy5', ...
                                'BGD','cy3', ...
                                'DAPI', 'dapi');

%- Pixel-size in nano-meter
cell_library_info.pixel_size_xy = 100;
cell_library_info.pixel_size_z  = 300;

%- Image dimensions in X and Y
cell_library_info.dim_X = 2048;  
cell_library_info.dim_Y = 2048; 
                                                      
%- NUCLEUS: position in the cell 
% Lower and upper limit expressed as percentage of maximum cell height
cell_library_info.nuc_z_min_rel = 0.07;   % Lower position of nucleus
cell_library_info.nuc_z_max_rel = 0.88;   % Upper position of nucleus                           
        

%% User defines FQ outline files and folder containing other channels
cell_library_info = cell_library_files_v1(cell_library_info);

%- Verify that FQ result files were specified
if isempty(cell_library_info.FQ_files); disp('No FQ result files define'); return; end

%- Verify that folders contain the images of other channels were specified
if isempty(cell_library_info.folder_images); disp('No folders for other channels defined'); return; end

 
%% Create cell library
cell_library_info.flag_crop_bgd = 1;    %- Should other channels be cropped (1) or not (0)
cell_library_info.pad_xy = 10;          %- Padding around each cell in XY before cropping to avoid filter artifacts
cell_library_info.verbose = 0;          %- Show more results (for debugging)
[cell_library_v2, cell_library_info ] = cell_library_create_v1(cell_library_info);


%% Save cell library
name_save = fullfile(cell_library_info.path_FQ_files,['cell_library_v2',cell_library_info.rand_string, '.mat']);
save(name_save, 'cell_library_v2','cell_library_info','-v7.3')
disp('Cell library saved:')
disp(name_save)
