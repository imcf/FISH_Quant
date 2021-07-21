function status_file_ok = FQ3_detect_fit_v1(img,parameters)


%- Default output in case something goes wrong
status_file_ok = 0;


%- File-name and path
path_name_list       = parameters.path_name_list;
path_name_image      = parameters.path_name_image;
path_name_outline    = parameters.path_name_outline;
file_name_load       = parameters.file_name_load;

%- Names for filtering
name_filtered        = parameters.name_filtered;

%- FLAGS
flags = parameters.flags;

%- Create folder to save outlines
path_name_outline_save = fullfile(path_name_outline,'_batch');
if ~exist(path_name_outline_save,'dir')
   mkdir(path_name_outline_save)
end


%========================================================================== 
% Load data
%==========================================================================

%== Determine what type of file will be processed
[dum, dum, ext] = fileparts(file_name_load);

%-- Load data from outline definition file
if strcmpi(ext,'.txt') 
    
    %- Keep settings
    settings_old       = img.settings;
    par_microscope_old = img.par_microscope;
    
    %- Try to open file - catch corrupted files
    try
        status_open = img.load_results(fullfile(path_name_list,file_name_load),path_name_image);  
        [dum, name_image_base,ext_img] = fileparts(file_name_load);
    catch err
        disp(err)
        status_open.outline = 0;
    end
    
    %- Reassign settings in case they were changes
    img.settings       = settings_old;
    img.par_microscope = par_microscope_old;
    
    %- Outline file can't be opened
    if status_open.outline ~= 1
       disp('>>> Outline could not be opened');
       disp(['Folder: ',path_name_list])
       disp(['File  : ',file_name_load])  
       return
    end

    %- Image can't be opened
    if status_open.img ~= 1
       disp('>>> Image could not be opened');       
       disp(['Folder: ',path_name_image])
       disp(['File  : ',img.file_names.raw]) 
       return
    end

%- Load image files 
elseif strcmpi(ext,'.tif') || strcmpi(ext,'.stk') || strcmpi(ext,'.tiff') || strcmpi(ext,'.TIF')
    
    status_file = img.load_img(fullfile(path_name_list,file_name_load),'raw');
    
    if ~status_file
       disp('=== Image (raw) could not be opened');       
       disp(['Folder: ',path_name_list])
       disp(['File  : ',file_name_load]) 
       return   
    end
    
    [dum, name_image_base,ext_img] = fileparts(file_name_load);
    
    %- Make one cell out of image
    img.make_one_cell(1);
end


%== Check if image is empty
if isempty(img.raw)
    disp(' WARNING: no image file found - maybe folder for images is not defined!');
    return
end

%========================================================================== 
%=== Process file
%========================================================================== 


%- Check if same outline should be used for all images
if flags.outline_unique_enable
     img.cell_prop = deal(parameters.cell_prop_loaded);
end


%========================================================================== 
% Filter image
%==========================================================================

status_img_filt_new = 0;   % Indicate if a newly filtered image is present
status_use_filtered = 0;   % Indicate if filtered image should be used

%- Try to load filtered image
if flags.filtered_use 

    %- Check if filtered image is specified in file-name
    if isempty(img.file_names.filtered)

        %- If search string is empty then simply add replacement string
        if isempty(name_filtered.string_search)
            file_name_filtered = [name_image_base,name_filtered.string_replace,ext_img];
            flag_good = 1;
        else

            modifiedStr = strrep(name_image_base, name_filtered.string_search, name_filtered.string_replace);

            if strcmp(modifiedStr,name_image_base)
                flag_good = 0;
            else
                flag_good = 1;
                file_name_filtered = [modifiedStr,ext_img];
            end            

        end

        if flag_good
            disp(['No filtered image defined in outline file. Attempt to load image with default name: ' ,file_name_filtered])
            status_attempt_load = 1;
        else
            disp('Search string not found - default name of filtered image cant be generated!')
            status_attempt_load = 0;
            status_use_filtered = 0;  % - Will filter image with next check
        end
    
    %- Name of filtered image defined 
    else
        file_name_filtered  = img.file_names.filtered;
        status_attempt_load = 1;
    end

    
    %- Load filtered image
    if status_attempt_load
        status_file = img.load_img(fullfile(path_name_image,file_name_filtered),'filt');
    
        if ~status_file
           disp('=== Image (filtered) could not be opened');       
           disp(['Folder: ',path_name_image])
           disp(['File  : ',file_name_filtered]) 
           status_use_filtered = 0;
        else
           status_use_filtered = 1;
           img.file_names.filtered = file_name_filtered;
           
        end
    end
end

%- Filter image    
if not(status_use_filtered)
    
    flag.output = 0;
    status_filter = img.filter(flag);%(img.settings.filter.method,img.settings.filt.kernel_size,flag_filter);
    
    %- Continue only if filtering was succesfull
    if not(status_filter)
        return
    end
    
    %- Indicate that filtered image is new
    status_img_filt_new       = 1;
end


%- Save only a new image!
if flags.filtered_save && status_img_filt_new

    current_dir = pwd;
    cd(path_name_image)

    %- Save filtered image
    [dum, name_file]    = fileparts(img.file_names.raw); 
    file_name_FILT      = [name_file,'_filtered_batch.tif'];
    file_name_FILT_full = fullfile(path_name_image,file_name_FILT);

    %- Make sure file doesn't exit - otherwise planes will be simply added
    if not(exist(file_name_FILT_full,'file'))

        img.save_img(file_name_FILT_full,'filt');        
        disp(['Filtered image will be saved with file-name: ' ,file_name_FILT])
    else
        disp(['Filtered image will NOT be saved. File already present: ' ,file_name_FILT])
    end
 
    %- Save new outline definition
    [dum, name_base_outline] = fileparts(file_name_load); 

    if isempty(strfind(name_base_outline,'outline'))
        file_name_OUTLINE        = [name_base_outline,'_outline_batch.txt'];
    else
        file_name_OUTLINE        = [name_base_outline,'_batch.txt'];
    end

    file_name_OUTLINE_full   = fullfile(path_name_outline_save,file_name_OUTLINE);

    %- Parameters to save results
    parameters.path_save           = path_name_outline_save;
    parameters.path_save_settings  = img.path_names.results;
    parameters.path_name_image     = path_name_image;
    parameters.version             = img.version;
    parameters.flag_type           = 'outline';  

    %- Save outline
    img.save_results(file_name_OUTLINE_full,parameters);
    disp(['Outline-file will be saved with name: ' ,file_name_OUTLINE])
    cd(current_dir)
end

%========================================================================== 
% Process each cell in the image
%==========================================================================

%- Number of cells per image
N_cell = size(img.cell_prop,2);

for i_cell =1:N_cell
 
    %- Pre-detect
    img.spots_predect(i_cell);
    
    %- Calculate quality score only if it will be used for thresholding
    if img.settings.detect.thresh_score > 0
        img.spots_quality_score(i_cell);
        img.spots_quality_score_apply(i_cell,1);
    end
    
    %- Fit
    img.spots_fit_3D(i_cell);
    
end

%- All went good
status_file_ok = 1;

