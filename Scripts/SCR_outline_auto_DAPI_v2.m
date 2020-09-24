function SCR_outline_auto_DAPI_v2
%% Determine cellular outlines automatically based on the DAPI image
%  -> cell will be restricted to nucleus
%  -> Script can also read MIP's which will be faster. Unique terms
%  idenfying MIP's, FISH, and DAPI images have to be defined.


%% SOME GENERAL PARAMETERS

%- Specify file-names
ident_MIP      = 'MAX_';     %- Part of the name that specifies the MIP  - will be removed when generating the FQ outlines files
ident_FISH     = 'c2';  %- Unique identifier in name for FISH image
ident_DAPI     = 'c1';  %- Unique identifier in name for DAPI image -> will be used to automatically generate the file-name for FISH images

%- Default settings
par_microscope.pixel_size.xy = 107;
par_microscope.pixel_size.z  = 300;   
par_microscope.RI            = 1.458;   
par_microscope.NA            = 1.4;
par_microscope.Em            = 568;   
par_microscope.Ex            = 568;
par_microscope.type          = 'widefield';  

%- Parameters for detection of nucleus
par_detect.erod_disc_rad = 10;
par_detect.N_pix_min     = 500;


%- Other parameters
flag_exclude_border = 1;  % Exclude all nuclei that are at the border
flag_save_results   = 1;  % Will save an image with the results - name will indicate the segmentation threshold
flag_th_auto        = 1;  % Automated determination of each threshold
th_man              = 5;  % Manual threshold (between 0-100)
N_pix_min           = 500;


%% Specify file-names (DAPI!!!)
[file_name_DAPI,path_name_DAPI]=uigetfile({'*.tif'},'Select DAPI files.','MultiSelect','on');
if ~iscell(file_name_DAPI)
    dum=file_name_DAPI;
    file_name_DAPI={dum};
end


%% LOOP over all files

%- Make folders to save outlines
folder_outline = fullfile(path_name_DAPI,'_OUTLINES');
if ~exist(folder_outline,'dir')
    mkdir(folder_outline);
end

%- Make folders to save outlines
if flag_save_results
    folder_plots = fullfile(path_name_DAPI,'_PLOTS');
    if ~exist(folder_plots,'dir')
        mkdir(folder_plots);
    end
end


%- Get ready
N_files = length(file_name_DAPI);

par_detect.flags.plot   = flag_save_results;
par_detect.flags.dialog = 0;
par_detect.flags.exclude_border = flag_exclude_border;

for i_file =1:N_files
       
    disp(' ')
    
    %- Get file-names
    file_LOOP = file_name_DAPI{i_file};
    disp(file_LOOP)
        
    %- Load image
    image_struct = img_load_stack_v1(fullfile(path_name_DAPI,file_LOOP));
    
    %- DAPI image as MIP
    if image_struct.NZ > 1
        img_DAPI = uint16(max(image_struct.data,[],3));
        flag_load_MIP = 0;
        disp('3D DAPI stack')
    else
        img_DAPI = uint16(image_struct.data);
        flag_load_MIP = 1;
        disp('2D DAPI stack')
    end
    
    %- Detect nuclei
    if flag_th_auto
        th_nuc = graythresh(img_DAPI);
        fprintf('AUTO-THRESHOLD: %g\n', th_nuc)
    else
        th_nuc = th_man;
    end
        
    par_detect.th_DAPI = th_nuc;
    images.DAPI_XY    = img_DAPI;
    [cell_prop, h_fig] = FQ_detect_DAPI_v1(images,par_detect);
    
    %- Generate file-names
    [dum, file_base,ext] = fileparts(file_LOOP);
    
    if flag_load_MIP
        name_DAPI = strrep(file_base, ident_MIP, '');
    else
        name_DAPI = file_base;
    end
    
    name_FISH = strrep(name_DAPI, ident_DAPI, ident_FISH); 
    
    if strcmp(name_FISH,name_DAPI)
        disp('   ')
        disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
        disp('PROBLEM WHEN GENERATING FILE-NAME OF FISH: could not find identifiers for FISH and DAPI!!!!')
    end
    
    file_names.raw      = [name_FISH,ext];   
    file_names.filtered = ''; 
    file_names.DAPI     = [name_DAPI,ext];
    file_names.TS_label = ''; 
    file_names.settings = ''; 
    
    
    %- Save resulting image
    if flag_save_results 
        name_save = [name_FISH,'_AUTO_DETECT.png'];
        saveas(h_fig,fullfile(folder_plots,name_save));
        close(h_fig)
    end
    
    %- Save outline  
    parameters.path_save           = folder_outline;
    parameters.cell_prop           = cell_prop;
    parameters.par_microscope      = par_microscope;
    parameters.path_name_image     = path_name_DAPI;
    parameters.file_names          = file_names;
    parameters.version             = 'v2c';
    parameters.flag_type           = 'outline';  
    
    name_save = [name_FISH,'__',parameters.flag_type,'.txt'];
    
    FQ_save_results_v1(fullfile(folder_outline,name_save),parameters);
    
end