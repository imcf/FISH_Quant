function FQ3_outline_replace_color_v2(parameters)
% SCRIPT TO GENERATE OUTLINE FILES FOR SECOND COLOR
%
% Script is useful for dual-color FISH experiments. Outlines are defined in
% one color and can then be automatically be generated for the second color.
% Same positions for cells and Txsites will be used. 
%
% Script will for each outline
%   - Generate a new outline file changing the name of FISH image
%   - Rename the FISH images to the second color
%
% The files will be saved in a subfolder named 'outlines_NEW', where NEW 
% is specified by the identifier for the second channel. 
%
% === Naming examaple
% DAPI is [sample name]_channel_DAPI_[img number]
% Cy3  is [sample name]_channel_CY3_[img number]
% Cy5  is [sample name]_channel_CY5_[img number]
%
% Example: 
% Cy3: XYZ_channel_CY3_001.tif
% Cy5: XYZ_channel_CY5_001.tif
%
% Outlines are defined for Cy3, e.g. XYZ_channel_CY3_001.tif. New
% outline will be called XYZ_channel_CY5_001.tif with the proper
% reference to the FISH image. Will be save in the subfolder 
% 'outlines__channel_CY5'

% ==== NOTES
% Best used in CELL-MODE (see Matlab help file). This allows executing 
% one block with code after the other. 


%% Define how the renaming should occur

%- Get parameters
name_str = parameters.name_str;

%% Get wavelength
if isfield(parameters,'Em') && ~isempty(parameters.Em)
    Em       = parameters.Em;
    Ex       = parameters.Ex;
else
    Em = [];
end

%% Get outline names
if isfield(parameters,'outlines_list') && ~isempty(parameters.outlines_list)
    outlines_list   = parameters.outlines_list;
    folder_outlines = parameters.folder_outlines;
else
    [outlines_list,folder_outlines] = uigetfile({'*.txt'},'Select outline files','MultiSelect', 'on');
end

if ~iscell(outlines_list)
    dum =outlines_list; 
    outlines_list = {dum};
end


%% Convert files
if outlines_list{1} ~= 0

    img = FQ_img;
    
    %=== Generate subfolder to save new outline files
    subfolder = ['outlines_',name_str.new];
    folder_save = fullfile(folder_outlines,subfolder);
    is_dir = exist(folder_save,'dir'); 
    if is_dir == 0
       mkdir(folder_save)
    end


    %=== Make cell out of list of filenames if only one is defined
    if ~iscell(outlines_list)
        dum =outlines_list; 
        outlines_list = {dum};
    end
    N_files = length(outlines_list);

    %=== Loop over all files

    for i_file =  1:N_files

        file_name      = outlines_list{i_file};
        file_name_full = fullfile(folder_outlines,file_name);

        %== Load region file and extract outlines of cells
        disp(' ')
        disp(['=== Analysing file: ', file_name])
       
        %- Generate new FQ object
        img         = img.reinit;
        status_open = img.load_results(file_name_full,[]);   
  
        if status_open.outline == 0
            disp('File cannot be opened','mfilename'); 
        else

            %- New name for image
            name_image_old = img.file_names.raw;
            name_image_new = strrep(name_image_old, name_str.old, name_str.new);
            disp(['Old name of image: ', name_image_old])
            disp(['New name of image: ', name_image_new])
            img.file_names.raw = name_image_new;

            %- Replace wavelength
            if ~isempty(Em)
                img.par_microscope.Ex = Ex;
                img.par_microscope.Em = Em;
            end
            
            %- New name for file
            file_name_new = strrep(file_name, name_str.old, name_str.new);


            %- Parameters to save results
            parameters.path_save           = folder_outlines;
            parameters.path_name_image     = img.path_names.img;
            parameters.version             = img.version;
            parameters.flag_type           = 'outline'; 
       
            [file_name_results, path_save] = img.save_results(fullfile(folder_save, file_name_new),parameters);

            disp(['Outline file saved as: ', file_name_results])
        end
    end
end