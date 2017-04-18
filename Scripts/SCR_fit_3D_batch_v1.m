%% 3D batch processing
% Process outlines files in batch mode


%% Define all outlines
[file_name, path_outlines] = uigetfile({'*.txt'},'Select outlines that should be processed','MultiSelect','on');

if ~iscell(file_name)
    dum = file_name;
    clear file_name
    file_name = {dum};
end

if file_name{1} == 0; return; end


%% Get folder name for images
path_image = uigetdir(path_outlines);
if path_image == 0; return; end


%% Get all results folders that should be processed
folder_results = uipickfiles('REFilter','^')';

if ~iscell(folder_results)
    dum=folder_results;
    folder_results={dum};
end
    

%% Loop over all files

%- Results
img = FQ_img;

%- Assign folders
parameters.path_name_outline = path_outlines;
parameters.path_name_list    = path_outlines;
parameters.path_name_image   = path_image;

%- Names for filtering
parameters.name_filtered.string_search  = '';
parameters.name_filtered.string_replace = '_filtered_batch';

%- Flags controlling the use/saving of filtered images
parameters.flags.filtered_use  = 0;     % Check if a filtered image with default name is present, if yes, use it.
parameters.flags.filtered_save = 0;     % Save fittered images

%- Same outline for all images
parameters.flags.outline_unique_enable = 0;

%- Loop over folder
for i_folder = 1:numel(folder_results)
    
    %- Get name of folder
    folder_loop = folder_results{i_folder};

    %- Load settings
    file_sett = '_FQ_settings_MATURE.txt';
    status_sett = img.load_settings(fullfile(folder_loop,file_sett));
    
    if status_sett == 0
        disp('== No FQ settings file found.')
        fprintf('Expected folder: %s\n',folder_loop)
        fprintf('Expected file  : %s\n',file_sett)
        return
    else
        disp('== FQ settings loaded.')
    end
    img.file_names.settings = file_sett;
    
    %- Loop over files
    for i_file = 1:numel(file_name)

        %- Get file-name
        file_loop = file_name{i_file};
        parameters.file_name_load = fullfile(file_loop);
        
        %- Call fitting routine
        status_fit = img.proc_mature_all(parameters);
        
        if status_fit
        
            %== Save results
            [dum, name_base] = fileparts(img.file_names.raw);
            name_save = [name_base, '__BATCH.txt'];

            %- General parameters
            par_save.par_microscope      = img.par_microscope;
            par_save.path_save           = folder_loop;
            par_save.path_name_image     = path_image;
            par_save.file_names          = img.file_names;
            par_save.version             = img.version;
            par_save.flag_type           = 'spots';  
            par_save.flag_th_only        = 0;

            img.file_names.settings = file_sett;

            img.save_results(fullfile(folder_loop,name_save),par_save);
        else
            disp('File could not be fit')
            disp(file_loop)
        end
    end
end