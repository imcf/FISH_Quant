function WRAPPER_cell_label_to_FQ_v1(parameters)

% WRAPPER FUNCTION TO CONVERT segmentation results  
% (CellProfiler, CellCognition, ...) into FISH-quant outline files. 

%Adjust parameters in first part to experimental settings.
% Then run script from command line by typing it's name.
%
% ==== NOTES
% Can also be used in CELL-MODE (see Matlab help file). This allows executing 
% one block with code after the other. 



%% ======= Definition of parameters

if  isfield(parameters,'par_microscope')
    
    par_microscope = parameters.par_microscope;
    
else
    %== Experimental parameters
    par_microscope.pixel_size.xy = 103;             % Pixel-size [XY]
    par_microscope.pixel_size.z  = 300;             % Pixel-size [Z]
    par_microscope.RI            = 1.515;           % Refractive index
    par_microscope.NA            = 1.4;             % Numeric aperture NA
    par_microscope.Em            = 660;             % Emission wavelength
    par_microscope.Ex            = 650;             % Excitation wavelength    
    par_microscope.type          = 'widefield';  
   
    
end

if isfield(parameters,'names_struct')

    names_struct = parameters.names_struct;
else
    %- Identifiers for actual images
    names_struct.suffix.DAPI = '_dapi';          %- Identifier for DAPI images
    names_struct.suffix.FISH = '_CY3';           %- Identifier for FISH images

    %- Identifiers for masks
    names_struct.suffix.nuc  = '_MASK_nuc.tif';   %- Suffix of CellProfiler for nucleus
    names_struct.suffix.cell = '_MASK_cell.tif';   %- Suffix of CellProfiler for cells

end


%== Suffix and extension
names_struct.ext_image = '.tif';      %- Extension for images (FISH, DAPI)
names_struct.ext_mask  = '.tif';      %- Extension for CellProfiler masks


    

%% Get files with results 

files_proc = parameters.files_proc;

switch files_proc.input_type
    
    %- Scan directories
    case 'dir'
   
        %- Get parameters
        path_scan  = files_proc.path_scan;
        img_ext    = '.tif';

        %- Make sure that there is a dot in front of the file extension
        if ~strcmp(img_ext(1),'.')
            img_ext = ['.',img_ext];
        end

        %- Scan directory
        if files_proc.flag_folder_rec
            string_search = fullfile(path_scan,'**',['*',img_ext]);
            file_list     = rdir(string_search);
            path_name     = '';
        else
            string_search = fullfile(path_scan,['*',img_ext]);
            file_list     = dir(string_search);   
            path_name     = path_scan;
        end

        %- Return if no files were found
        if isempty(file_list)
            disp('== NO files found when searching directory')
            disp('File extensions are CASE sensitive')
            disp(['Search string: ', string_search])
            return

        else
            %- Convert to same format as if a list of names was presented
            file_list_short = struct('name',{file_list.name});
            file_names   = squeeze(struct2cell(file_list_short));
        end
    
    case 'file'
        
        file_names = files_proc.file_name_all;
        path_name  = files_proc.path_name;
    
end



%% == Convert outline files
parameters.par_microscope = par_microscope;
parameters.version        = 'v3';
parameters.names_struct   = names_struct;
parameters.file_names     = file_names;
parameters.path_name      = path_name;

parameters.flag_bgd           = 'index_0';     % Background corresponds to region with value 0

cell_label_to_FQ_v1(parameters);

