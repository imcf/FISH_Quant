function [cell_prop, par_microscope, file_names, status_file_ok] = spot_detect_fit_v31(handles,parameters)


%- File-name and path
path_name_list       = parameters.path_name_list;
path_name_image      = parameters.path_name_image;
path_name_outline    = parameters.path_name_outline;
file_name_load       = parameters.file_name_load;

%- Names for filtering
name_filtered        = parameters.name_filtered;

%- Other parameters of the fitting
mode_fit             = parameters.mode_fit;
par_start            = parameters.par_start;
bound                = parameters.bound;
par_microscope       = parameters.par_microscope;
file_name_sett_batch = parameters.file_name_settings;
flag_struct          = parameters.flag_struct;             
detect               = handles.detect;

N_spots_fit_max      = parameters.N_spots_fit_max;


flag_struct.output   = 0;
status_file_ok       = 1;   % Indicates if file was corrected processed (1) or not (0)


%- Create folder to save outlines
path_name_outline_save = fullfile(path_name_outline,'_batch');
if ~exist(path_name_outline_save,'dir'); 
   mkdir(path_name_outline_save)
end


%========================================================================== 
% General parameters
%==========================================================================

%=== Theoretical PSF
pixel_size = handles.par_microscope.pixel_size;

[PSF_theo.xy_nm, PSF_theo.z_nm] = sigma_PSF_BoZhang_v1(par_microscope);
PSF_theo.xy_pix = PSF_theo.xy_nm / par_microscope.pixel_size.xy ;
PSF_theo.z_pix  = PSF_theo.z_nm  / par_microscope.pixel_size.z ;


%========================================================================== 
% Load data
%==========================================================================

%== Determine what type of file we have
[dum, dum, ext] = fileparts(file_name_load);


%-- Load data from outline definition file
if strcmpi(ext,'.txt') 
    [cell_prop, dum, file_names, status_file_ok] = FQ_load_results_WRAPPER_v1(fullfile(path_name_list,file_name_load));    
    
    if status_file_ok
        image_struct = load_stack_data_v7(fullfile(path_name_image,file_names.raw));
        [dum, name_image_base,ext_img] = fileparts(file_names.raw);
    else
        disp('Outline file not OK (empty or wrong format).');
    end

%- Load image files 
elseif strcmpi(ext,'.tif') || strcmpi(ext,'.stk')
    image_struct = load_stack_data_v7(fullfile(path_name_list,file_name_load));
    file_names.raw      = file_name_load; 
    file_names.filtered = [];
    file_names.DAPI     = []; 
    file_names.TS_label = []; 
    [dum, name_image_base,ext] = fileparts(file_name_load);
    
    ext_img = ext;
       
    %- Dimension of entire image
    w = image_struct.w;
    h = image_struct.h;
    cell_prop(1).x      = [1 1 w w];
    cell_prop(1).y      = [1 h h 1];
    
    %- Other parameters
    cell_prop(1).pos_TS = [];
    cell_prop(1).label    = 'EntireImage';
    cell_prop(1).pos_TS   = [];
    cell_prop(1).pos_Nuc  = [];
end


%== Check if image is empty
if isempty(image_struct.data)
    disp(' WARNING: no image file found - maybe folder for images is not defined!');
    status_file_ok = 0;
end


%=== CONTINUE ONLY WHEN VALID FILE IS FOUND
if status_file_ok

    %- Check if same outline should be used for all images
    if handles.status_outline_unique_enable
         cell_prop = deal(handles.cell_prop_loaded );
    end

    %========================================================================== 
    % Filter image
    %==========================================================================

    %- Check if filtered images should be used and are available
    if isfield(handles,'checkbox_use_filtered');
        status_use_filtered = get(handles.checkbox_use_filtered,'Value');
    else
        status_use_filtered = 0;
    end
    
    %- Try to load filtered image
    if status_use_filtered 
        
        %- If file name is not define try default file-name
        if isempty(file_names.filtered)
            
            
            %- If search string is empty then simply add replacement string
            if isempty(name_filtered.string_search)
                file_names.filtered = [name_image_base,name_filtered.string_replace,ext_img];
                flag_good = 1;
            else
                
                modifiedStr = strrep(name_image_base, name_filtered.string_search, name_filtered.string_replace);
                
                if strcmp(modifiedStr,name_image_base)
                    
                    flag_good = 0;
                else
                    flag_good = 1;
                    file_names.filtered = [modifiedStr,ext_img];
                end            
                
            end
                       
            if flag_good
                disp(['No filtered image defined in outline file. Attempt to load image with default name: ' ,file_names.filtered])
                status_file_filt_new = 1;
            else
                disp('Search string not found - default name of filtered image cant be generated!')
                status_file_filt_new = 0;
            end
        else
            status_file_filt_new = 0;
        end
        
        [image_filt_struct, status_file] = load_stack_data_v7(fullfile(path_name_image,file_names.filtered));
        
        %- If filtered file could be used
        if status_file
            image_struct.data_filtered = image_filt_struct.data;
        
        %- If filtered file could not be used
        else
            status_use_filtered = 0;
            disp('+ Filtered image could NOT be loaded (not present)'  ) 
            disp(['Name: ',file_names.filtered ] )
            disp(['Folder: ',path_name_image ] )
        end
    end
    
    %- Filter image    
    if not(status_use_filtered)
        
        fprintf('.. filtering of image ....') 
        
        %- Filtering parameters

        if isfield(handles.filter,'factor_bgd')
            kernel_size.bgd_xy = handles.filter.factor_bgd;
            kernel_size.bgd_z  = handles.filter.factor_bgd;
            
            kernel_size.psf_xy = handles.filter.factor_psf;
            kernel_size.psf_z  = handles.filter.factor_psf;       
        else
            kernel_size.bgd_xy = handles.filter.factor_bgd_xy;
            kernel_size.bgd_z  = handles.filter.factor_bgd_z;
            
            kernel_size.psf_xy = handles.filter.factor_psf_xy;
            kernel_size.psf_z  = handles.filter.factor_psf_z;
          end

        filter.pad        = ceil(3*kernel_size.bgd_xy);

        flag.output     = 0;

        img_filt = img_filter_Gauss_v3(image_struct,kernel_size,flag);
        
        handles.img_plot = max(img_filt,[],3);
        image_struct.data_filtered = img_filt;
        status_file_filt_new       = 1;
        
        fprintf('FINISHED.\n') 
        
    end


    %- Check if filtered images should be saved
    if isfield(handles,'checkbox_save_filtered')
        status_save_filtered = get(handles.checkbox_save_filtered,'Value');
    else
        status_save_filtered = 0;
    end
    
    
    if status_save_filtered && status_file_filt_new

        current_dir = pwd;
        cd(path_name_image)

        %- Save filtered image
        [dum, name_file]    = fileparts(file_names.raw); 
        file_name_FILT      = [name_file,'_filtered_batch.tif'];
        file_name_FILT_full = fullfile(path_name_image,file_name_FILT);

        %- Make sure file doesn't exit - otherwise planes will be simply added
        if not(exist(file_name_FILT_full,'file'))
            image_save_v2(image_struct.data_filtered,file_name_FILT);
            disp(['Filtered image will be saved with file-name: ' ,file_name_FILT])
        else
            disp(['Filtered image will NOT be saved. File already present: ' ,file_name_FILT])
        end
        
        %- Add reference to file-names to allow filtered image to be opened
        file_names.filtered = file_name_FILT;
        
        %- Save new outline definition
        [dum, name_base_outline] = fileparts(file_name_load); 
        
        if isempty(strfind(name_base_outline,'outline'))
            file_name_OUTLINE        = [name_base_outline,'_outline_batch.txt'];
        else
            file_name_OUTLINE        = [name_base_outline,'_batch.txt'];
        end
        
        
        file_name_OUTLINE_full   = fullfile(path_name_outline_save,file_name_OUTLINE);

        %- Assign parameters which should be saved
        struct_save.par_microscope           = par_microscope;
        struct_save.cell_prop                = cell_prop;
        struct_save.version                  = handles.version;
        struct_save.file_names               = file_names;
        struct_save.file_names.settings      = file_name_sett_batch;
        struct_save.file_names.filtered      = file_name_FILT;
        struct_save.path_save                = path_name_outline_save;
        struct_save.path_name_image          = path_name_image;
        struct_save.flag_type                = 'outline';  
         
        %- Save outline
        FQ_save_results_v1(file_name_OUTLINE_full,struct_save);
        disp(['Outline-file will be saved with name: ' ,file_name_OUTLINE])
        cd(current_dir)
    end

    %========================================================================== 
    % Process each cell in the image
    %==========================================================================

    %- Number of cells per image
    N_cell = size(cell_prop,2);


    for i_cell =1:N_cell

        %- Set-up options for pre-detection
        flag_struct.score   = handles.detect.score;
        flag_struct.mode_predetect = handles.detect.mode_predetect;

        options_detect.size_detect = detect.region;
        options_detect.detect_th   = detect.thresh_int;
        options_detect.cell_prop   = cell_prop(i_cell);
        options_detect.pixel_size  = pixel_size;
        options_detect.detect_th_score = detect.thresh_score;
        options_detect.PSF             = PSF_theo;  
        

        if isfield(handles.detect,'flag_region_smaller')
            flag_struct.region_smaller = detect.flag_region_smaller;
        else
            flag_struct.region_smaller = 0;
        end    

        if isfield(handles.detect,'flag_reg_pos_sep')
            flag_struct.reg_pos_sep = detect.flag_reg_pos_sep;
        else
            flag_struct.reg_pos_sep = 0;
        end         
        
        if isfield(handles.detect,'flag_detect_region')
            flag_struct.flag_detect_region = detect.flag_detect_region;
        else
            flag_struct.flag_detect_region = 0;
        end 
        
        %- Pre-detection of spots
        [spots_detected_pos]                               = spots_predetect_v17(image_struct,options_detect,flag_struct);
        [spots_detected dum detect.thresh_score sub_spots] = spots_predetect_analysis_v8(image_struct,[],spots_detected_pos,options_detect,flag_struct);
        N_spots_detect = size(spots_detected,1);
    
        %- Fitting of all pre-detected spots
        flag_struct.output = 0;
        parameters.pixel_size  = pixel_size;
        parameters.PSF_theo    = PSF_theo;
        parameters.par_start   = par_start;
        parameters.flag_struct = flag_struct;
        parameters.mode_fit    = mode_fit;
        parameters.bound       = bound;
        
        
        %- Check if cell has more than the allowed number of spots
        if (N_spots_fit_max < 0)  ||  (N_spots_detect < N_spots_fit_max) 

            %- Call fitting routine 
            spots_fit = spots_fit_batch_3D_Gauss_v7(spots_detected, sub_spots, parameters);

            %- Assigning thresholding parameters
            thresh.all  = ones(size(spots_fit,1),1);
            thresh.in   = ones(size(spots_fit,1),1);

        else
            spots_fit      = zeros(N_spots_detect,16);
            spots_fit(:,:) = NaN;
            
            spots_fit(:,1:2) = (spots_detected(:,1:2) * pixel_size.xy) - pixel_size.xy;
            spots_fit(:,3)   = (spots_detected(:,3)   * pixel_size.z)  - pixel_size.z;
            
            spots_fit(:,13) = ((spots_detected(:,5) - spots_detected(:,4)) / 2)   * pixel_size.xy;
            spots_fit(:,14) = ((spots_detected(:,7) - spots_detected(:,6)) / 2)   * pixel_size.xy;
            spots_fit(:,15) = ((spots_detected(:,9) - spots_detected(:,8)) / 2)   * pixel_size.z;
         
            thresh.all  = ones(N_spots_detect,1);
            thresh.in   = ones(N_spots_detect,1);
                    
             
            
        end

        %- Save fitted spots for this cell
        cell_prop(i_cell).spots_fit      = spots_fit;
        cell_prop(i_cell).spots_detected = spots_detected;
    end
     
else
    cell_prop = [];
    par_microscope = [];
    file_name_image = [];
    file_name_image_filtered = [];
end
