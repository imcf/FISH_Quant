function cell_library_info = cell_library_files_v1(cell_library_info)
% Define files necessary to create cell library
%  - User defines FISH-quant outlines files (of GAPDH detection) and
%    folders containing images of other channels (e.g. background or DAPI).


%% Specify FQ detection results that should be loaded
disp('Select GAPDH FQ result files that should be processed')
[FQ_files, path_FQ_files] = uigetfile({'*.txt'},'Select GAPDH FQ result files that should be processed','MultiSelect','on');

if ~iscell(FQ_files)
    dum = FQ_files;
    clear file_name
    FQ_files = {dum};
end

if FQ_files{1}==0
    cell_library_info.FQ_files = {};
    return; 
end

%% Specify folder where images are stored - for background and DAPI
disp('Specify folder where DAPI and BGD images are stored')
folder_images = uigetdir('Specify folder where DAPI and BGD images are stored');
if folder_images==0 
    cell_library_info.folder_images = '';
    return; 
end

%- Define folder to save cropped images
folder_crop_save = fullfile(folder_images,'cropped_img');

if exist(folder_crop_save)
    
    %- Create random string    
    %[temp1, rand_string] = fileparts(tempname);
    %rand_string = ['_',rand_string];    
    rand_string = ['_',datestr(datetime('now'),'yymmdd_HHMM')];
    
    %- Generate random string
    folder_crop_save = fullfile(folder_images,['cropped_img',rand_string]);
    
else
    rand_string = '';
end

%- Create folder to save cropped images
disp(['Cropped images will be saved in folder: ' folder_crop_save])
mkdir(folder_crop_save);

%% Return 
cell_library_info.FQ_files      = FQ_files;
cell_library_info.path_FQ_files = path_FQ_files;
cell_library_info.folder_images = folder_images;
cell_library_info.rand_string   = rand_string;
cell_library_info.folder_crop_save = folder_crop_save;

