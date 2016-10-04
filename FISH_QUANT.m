function varargout = FISH_QUANT(varargin)
% FISH_QUANT M-file for FISH_QUANT.fig

% Last Modified by GUIDE v2.5 25-May-2016 15:45:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FISH_QUANT is made visible.
function handles = FISH_QUANT_OpeningFcn(hObject, eventdata, handles, varargin)

%- Make sure that already open FQ will not be overwritten
global FQ_open h_fishquant

if isempty(FQ_open) || FQ_open == 0
    
    % == Some housekeeping 
    FQ_open = 1;                       % Indicate that FQ is open
    h_fishquant = handles.h_fishquant; % Figure handle as global
        
    % == Set font-size to 10 (On Windows machines fonts can be set to 8) 
    set(findobj(handles.h_fishquant,'FontSize',8),'FontSize',10)

    % ==  Initialize GUI
    handles     = FQ_init_v1(handles);  
    
    % == Fenerate FQ image object
    handles.img = FQ_img;
 
    % == Load default parameters
    handles.FQ_path     = fileparts(mfilename('fullpath'));
    settings_load       = FQ_load_settings_v1(fullfile(handles.FQ_path,'FISH-QUANT_default_par.txt'),{});
    handles.img.version = settings_load.version;  
    
    if isfield(settings_load, 'par_microscope');
        handles.img.par_microscope = settings_load.par_microscope;
        handles.img.calc_PSF_theo;
    end
       
    
    %== Initialize Bioformats
    [status, ver_bf] = bfCheckJavaPath(1);
    disp(['Bio-Formats ',ver_bf,' will be used.'])
    
    %- Initializes Bio-Formats and its logging level
    try
        bfInitLogging();
    catch 
        disp('FQ-startup: problems with bfInitlogging!')
    end
        
    
    %== Populate GUI
    handles         = FQ_populate_v1(handles);
    popup_filter_type_Callback(hObject, eventdata, handles); % Adjust GUI for default filter
    
    % == Save values
    status_update(hObject, eventdata, handles,{'FISH-QUANT successfully initiated.'})
    handles.output = hObject;
    guidata(hObject, handles);
    
    % == Enable controls
    FQ_enable_controls_v1(handles)
end

% --- Outputs from this function are returned to the command line.
function varargout = FISH_QUANT_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --- Executes during object deletion, before destroying properties.
function h_fishquant_DeleteFcn(hObject, eventdata, handles)


%==========================================================================
%==== Define folder 
%==========================================================================

%== Define folder for root
function menu_folder_root_Callback(hObject, eventdata, handles)
path_usr  = uigetdir(handles.img.path_names.root, 'Choose ROOT directory');

if path_usr
    
    %- Assign roots folder
    handles.img.path_names.root = path_usr;
    
    %- Check if other folders are defined
    if isempty(handles.img.path_names.img)
        handles.img.path_names.img = path_usr;
    end
    
    if isempty(handles.img.path_names.outlines)
        handles.img.path_names.outlines = path_usr;
    end   
    
    if isempty(handles.img.path_names.results)
        handles.img.path_names.results = path_usr;
    end  
    
    %- Save handles
    guidata(hObject, handles);
end


%== Define folder for images
function menu_folder_image_Callback(hObject, eventdata, handles)

if isempty(handles.img.path_names.img) || ~exist(handles.img.path_names.img)
   dir_default =  handles.img.path_names.root;
else
    dir_default = handles.img.path_names.img;
end

path_usr  =  uigetdir(dir_default, 'Choose directory for images');

if path_usr
    handles.img.path_names.img = path_usr;
    guidata(hObject, handles);
end 


%== Define folder for outines
function menu_folder_outline_Callback(hObject, eventdata, handles)
if isempty(handles.img.path_names.outlines) || ~exist(handles.img.path_names.outlines)
   dir_default =  handles.img.path_names.root;
else
    dir_default =  handles.img.path_names.outlines;
end

path_usr  =  uigetdir(dir_default, 'Choose directory for outlines');

if path_usr
    handles.img.path_names.outlines = path_usr;
    guidata(hObject, handles);
end 


%== Define folder for outines
function menu_folder_results_Callback(hObject, eventdata, handles)
if isempty(handles.img.path_names.results) || ~exist(handles.img.path_names.results)
   dir_default =  handles.img.path_names.root;
else
    dir_default =  handles.img.path_names.results;
end

path_usr  =  uigetdir(dir_default, 'Choose directory for results');

if path_usr
    handles.img.path_names.results = path_usr;
    guidata(hObject, handles);
end 


%== Reset folders
function menu_folder_reset_Callback(hObject, eventdata, handles)


button = questdlg('Are you sure?','Reset folders','Yes','No','No');

if strcmp(button,'Yes') 
    handles.img.path_names.root     = [];
    handles.img.path_names.img      = [];
    handles.img.path_names.results  = [];
    handles.img.path_names.outlines = [];
    guidata(hObject, handles);
end

%== Save folders
function menu_folder_save_Callback(hObject, eventdata, handles)

if isempty(handles.img.path_names.root)
    warndlg('No folders specified.', 'FQ-save folders')
else
    FQ_save_folders_v1(handles);
end


%== Load folders
function menu_folder_load_Callback(hObject, eventdata, handles)

if ~isempty(handles.img.path_names.root)
    button = questdlg('Loading folders will overwrite current selection. Continue?','Load folders','Yes','No','No');
else
    button = 'Yes';
end

if strcmp(button,'Yes')    
         
    [file_folder,path_folder] = uigetfile({'*.txt'},'Select files with FQ folders.');
   
    if file_folder ~= 1 
        
        [handles_loaded,flag_file] = FQ_load_folders_v1(fullfile(path_folder,file_folder));

        if flag_file
            handles.img.path_names.root    = handles_loaded.path_name_root;
            handles.img.path_names.results = handles_loaded.path_name_results;
            handles.img.path_names.img     = handles_loaded.path_name_image;
            handles.img.path_names.outlines = handles_loaded.path_name_outline;
            
            disp(' ')
            disp('=== LOADED FOLDERS')
            fprintf('ROOT:    %s\n' , handles.img.path_names.root);
            fprintf('RESULTS: %s\n' , handles.img.path_names.results);
            fprintf('IMAGE:   %s\n' , handles.img.path_names.img);
            fprintf('OUTLINE: %s\n' , handles.img.path_names.outlines);
            
            guidata(hObject, handles);
        end
    end
end

%==========================================================================
%==== Experimental settings
%==========================================================================

%== Modify the experimental settings
function button_define_exp_Callback(hObject, eventdata, handles)

%- Change parameters
handles.img.define_par;

%- Update values
set(handles.text_psf_theo_xy,'String',num2str(round(handles.img.PSF_theo.xy_nm)));
set(handles.text_psf_theo_z, 'String',num2str(round(handles.img.PSF_theo.z_nm)));

%- Calculate size of detection region and show it
handles.detect.region.xy = round(2*handles.img.PSF_theo.xy_pix)+1;       % Size of detection zone in xy 
handles.detect.region.z  = round(2*handles.img.PSF_theo.z_pix)+1;        % Size of detection zone in z 

%- Update handles structure
guidata(hObject, handles);


%==========================================================================
%==== IMAGES: load & save
%==========================================================================

%== Load image and show maximum projection
function handles = button_load_image_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with images
current_dir = pwd;

if not(isempty(handles.img.path_names.img))
   cd(handles.img.path_names.img)
   
elseif not(isempty(handles.img.path_names.root))
    cd(handles.img.path_names.root)
end

%- Load image
if ~isempty(handles.img.raw)
    button = questdlg('Loading new image will delete results of previous analysis. Continue?','Load new image','Yes','No','No');
else
    button = 'Yes';
end

if strcmp(button,'Yes')    
         
    %- Make new FQ object and keep experimental parameters
    handles.img = handles.img.reinit;

    %- Load new image
    status_file = handles.img.load_img([],'raw');

    %- Continue if ok
    if status_file

        %- Load image, make MIP along Z
        handles.img.project_Z('raw','max');

        %- Check image is 3D        
        if handles.img.dim.Z == 1  && handles.img.status_3D
            warndlg('FISH images have to be 3D stacks!','FISH-quant')
            handles.img = FQ_img;
        else        
            
            %- Assign raw image as filtered image
            handles.img.filt        = handles.img.raw;
            handles.img.filt_proj_z = handles.img.raw_proj_z;

            handles.status_image      = 1;
            handles.status_filtered   = 0;
            
            %- Save path as root if no root is define 
            if isempty(handles.img.path_names.root)
                handles.img.path_names.root =  handles.img.path_names.img;
            end

            %- Prepare GUI
            handles = FQ_populate_v1(handles);
            popup_filter_type_Callback(hObject, eventdata, handles); % Adjust GUI for default filter
 

            %- Save handles
            guidata(hObject, handles);

            %- Plot results and enable controls
            status_update(hObject, eventdata, handles,{'Image loaded.'})
            set(handles.pop_up_image_select,'Value',1);     % Save selection to raw image
 
            FQ_enable_controls_v1(handles)
            plot_image(handles,handles.axes_image);
        end
    end
end

%- Go back to original image
cd(current_dir);


%== Menu: load image
function menu_load_image_Callback(hObject, eventdata, handles)
handles = button_load_image_Callback(hObject, eventdata, handles);
guidata(hObject, handles);


%=== Menu: load filtered image
function menu_load_image_filt_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with images
current_dir = pwd;

if not(isempty(handles.img.path_names.img))
   cd(handles.img.path_names.img)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

%- Load filtered image
status_file = handles.img.load_img([],'filt');

if status_file
    
    %- Assigng image
    handles.img.project_Z('filt','max');
    handles.status_filtered   = 1;
    guidata(hObject, handles);

    %- Plot results and enable controls
    status_update(hObject, eventdata, handles,{'Filtered image loaded.'})
    set(handles.pop_up_image_select,'Value',2);     % Save selection to filtered image

    plot_image(handles,handles.axes_image);
    
    plot_image(handles,handles.axes_image);
    FQ_enable_controls_v1(handles)
end

cd(current_dir)


%== Menu: save filtered image
function menu_save_filtered_img_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with images
current_dir = pwd;

if    not(isempty(handles.img.path_names.img))
   cd(handles.img.path_names.img)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

%- Save image
handles.img.save_img([],'filt');
guidata(hObject, handles);

%- Go back to original directory
cd(current_dir)


%==========================================================================
%==== SETTINGS: load & save
%==========================================================================

%== Menu: save settings  
function menu_save_settings_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with results/settings
current_dir = cd;

if     not(isempty(handles.img.path_names.results)); path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root));    path_save = handles.img.path_names.root;
else                                            path_save = cd; 
end

cd(path_save)

%- Save settings
handles.img.save_settings([]);
guidata(hObject, handles);

%- Go back to original directory
cd(current_dir) 


%== Menu: load settings  
function menu_load_settings_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with results/settings
current_dir = cd;

if      not(isempty(handles.img.path_names.results)); path_save = handles.img.path_names.results;
elseif  not(isempty(handles.img.path_names.root));    path_save = handles.img.path_names.root;
else                                                  path_save = cd;
end

cd(path_save)

%- Get settings
[file_name_settings,path_name_settings] = uigetfile({'*.txt'},'Select file with settings');

if file_name_settings ~= 0
    
    handles.img.load_settings(fullfile(path_name_settings,file_name_settings));
    handles = FQ_populate_v1(handles);  
    
    %- Set filter
    switch handles.img.settings.filter.method
        case '3D_2xGauss'
            set(handles.popup_filter_type,'Value',2);
            
        case '3D_LoG'
            set(handles.popup_filter_type,'Value',1);
    end
            
    popup_filter_type_Callback(hObject, eventdata, handles); % Adjust GUI for default filter
    
    %- Save data
    guidata(hObject, handles);
end

%- Go back to original directory
cd(current_dir) 



%== Function to load settings and assign thresholds
function handles = load_settings(file_name_full, handles)

%- Set all threshold locks to zero - the ones which are locked will be
% changed to one 
handles.img.settings.thresh.sigmaxy.lock   = 0;
handles.img.settings.thresh.sigmaz.lock    = 0;
handles.img.settings.thresh.amp.lock       = 0;
handles.img.settings.thresh.bgd.lock       = 0;
handles.img.settings.thresh.pos_z.lock     = 0;
handles.img.settings.thresh.int_raw.lock   = 0;
handles.img.settings.thresh.int_filt.lock  = 0;
handles.detect.flag_detect_region = 0;

handles.img.load_settings(fullfile(path_name_settings,file_name_settings));
%handles = FQ_load_settings_prev_v1(file_name_full,handles);

%- Update some of the parameters
handles = FQ_populate_v1(handles);
popup_filter_type_Callback(hObject, eventdata, handles); % Adjust GUI for default filter
 

%- Update the ones that had a locked threshold
names_all = fieldnames(handles.img.settings.thresh);
    
N_names   = size(names_all,1);

for i_name = 1:N_names
    par_name   = char(names_all{i_name});
    par_fields = getfield(handles.img.settings.thresh,par_name);
    locked     = par_fields.lock;

    if locked
                     
            switch par_name
                
                case 'sigmaxy'
                    handles.img.settings.thresh.sigmaxy.min_hist = par_fields.min_hist;                 
                    handles.img.settings.thresh.sigmaxy.max_hist = par_fields.max_hist;   
                
                case 'sigmaz'
                    handles.img.settings.thresh.sigmaz.min_hist = par_fields.min_hist;                 
                    handles.img.settings.thresh.sigmaz.max_hist = par_fields.max_hist;   
                
                case 'amp'
                    handles.img.settings.thresh.amp.min_hist = par_fields.min_hist;                 
                    handles.img.settings.thresh.amp.max_hist = par_fields.max_hist;                  
                    
                case 'bgd'
                    handles.img.settings.thresh.bgd.min_hist = par_fields.min_hist;                 
                    handles.img.settings.thresh.bgd.max_hist = par_fields.max_hist; 
                    
                case 'pos_z'
                    handles.img.settings.thresh.pos_z.min_hist = par_fields.min_hist;                 
                    handles.img.settings.thresh.pos_z.max_hist = par_fields.max_hist;    
                    
                case 'int_raw'
                    handles.img.settings.thresh.int_raw.min_hist = par_fields.min_hist;                 
                    handles.img.settings.thresh.int_raw.max_hist = par_fields.max_hist; 
                    
                case 'int_filt'
                    handles.img.settings.thresh.int_filt.min_hist = par_fields.min_hist;                 
                    handles.img.settings.thresh.int_filt.max_hist = par_fields.max_hist;     
                 
                otherwise
                    warndlg('Thresholding parameter not defined.','load_settings');
            end
    end
end
       
 

%==========================================================================
%==== OUTLINES & RESULTS: load & save
%==========================================================================


%== Menu: save outline of cell and TS
function menu_save_outline_Callback(hObject, eventdata, handles)

%- Get directory with outlines
if  not(isempty(handles.img.path_names.outlines)); 
    path_save = handles.img.path_names.outlines;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

%- Get directory with results
if  not(isempty(handles.img.path_names.results)); 
    path_save_settings = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save_settings = handles.img.path_names.root;
else
    path_save_settings = cd;
end


%- Parameters to save results
parameters.path_save           = path_save;
parameters.path_save_settings  = path_save_settings;
parameters.path_name_image     = handles.img.path_names.img;
parameters.version             = handles.img.version;
parameters.flag_type           = 'outline';  

handles.img.save_results([],parameters);


%== Menu: save results of spot detection   
function file_name_results = save_spots(hObject, handles, flag_th_only)

%- Get current directory and go to directory with outlines
current_dir = cd;

if     not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- Save settings if not already saved
if isempty(handles.img.file_names.settings)
    handles.img.save_settings([]);
end

%- Save results
if handles.img.file_names.settings ~= 0
    
    %- Parameters to save results
    parameters.path_save           = path_save;
    parameters.path_name_image     = handles.img.path_names.img;
    parameters.version             = handles.img.version;
    parameters.flag_type           = 'spots'; 
    parameters.flag_th_only        = flag_th_only;
    
    [file_name_results, path_save] = handles.img.save_results([],parameters);
else
    file_name_results = [];
end

%- Go back to original directory
cd(current_dir)    


%== Menu: save results of spot detection   
function menu_save_spots_Callback(hObject, eventdata, handles)
handles.file_names.results = save_spots(hObject, handles, 0);
guidata(hObject, handles); 


%== Menu: save results of spot detection [only thresholded]
function menu_save_spots_th_Callback(hObject, eventdata, handles)
handles.file_names.results = save_spots(hObject, handles, 1);
guidata(hObject, handles); 


%= Menu to load detected spots
function handles = load_result_files(hObject, eventdata, handles)

%- Get file name
[file_name_results,path_name_results] = uigetfile({'*.txt'},'Select file');

if file_name_results ~= 0
        
    %- Find path with images
    if     not(isempty(handles.img.path_names.img))
        path_img = handles.img.path_names.img;
    elseif not(isempty(handles.img.path_names.root))
        path_img = handles.img.path_names.root; 
    else
        handles.img.path_names.root = path_name_results;
        path_img                    = path_name_results;     
    end
    
    %- Generate new FQ object
    handles.img = handles.img.reinit;
    status_open = handles.img.load_results(fullfile(path_name_results,file_name_results),path_img);       
    set(handles.checkbox_plot_outline,'Value',1);
    
    if ~status_open.outline
        warndlg('OUTLINE could not be opened!','FISH-quant')
        fprintf('=== FILE COULD NOT BE OPENED\n');
        fprintf('File  : %s\n', file_name_results)
        fprintf('Folder: %s\n', path_name_results)
        return
    end
    
    
    if ~status_open.img
        warndlg('Image could not be opened!','FISH-quant')
        fprintf('=== FILE COULD NOT BE OPENED\n');
        fprintf('File  : %s\n', handles.img.file_names.raw)
        fprintf('Folder: %s\n', path_img)
        return
    else
        
        %- Check if image is 2D
        if handles.img.dim.Z == 1  && handles.img.status_3D
                warndlg('FISH images have to be 3D stacks!','FISH-quant')
                img = FQ_img;
                fprintf('\nName of image: %s\n', img.file_names.raw);   
        else
  
            %- Set status of raw image
            handles.status_image    = 1;
            
            %- Assign raw image as filtered image
            handles.img.filt        = handles.img.raw;
            handles.img.filt_proj_z = handles.img.raw_proj_z;
            
            %- Load filtered image if specified 
            if not(isempty(handles.img.file_names.filtered))

                status_file = handles.img.load_img(fullfile(path_img,handles.img.file_names.filtered),'filt');

                if status_file
                    handles.img.project_Z('filt','max');
                    handles.status_filtered   = 1;  
                end
             end

            %- Load settings if specified in file
            handles.img.settings.thresh.sigmaxy.lock   = 0;
            handles.img.settings.thresh.sigmaz.lock    = 0;
            handles.img.settings.thresh.amp.lock       = 0;
            handles.img.settings.thresh.bgd.lock       = 0;
            handles.img.settings.thresh.pos_z.lock     = 0;
            handles.img.settings.thresh.int_raw.lock   = 0;
            handles.img.settings.thresh.int_filt.lock  = 0;
            handles.detect.flag_detect_region = 0;
          
            handles = FQ_populate_v1(handles); 
            popup_filter_type_Callback(hObject, eventdata, handles); % Adjust GUI for default filter

            set(handles.text_psf_theo_xy,'String',num2str(round(handles.img.PSF_theo.xy_nm)));
            set(handles.text_psf_theo_z, 'String',num2str(round(handles.img.PSF_theo.z_nm)));

            %- Analyze detected regions
            handles = analyze_cellprop(hObject, eventdata, handles);    
            status_update(hObject, eventdata, handles,{'Results of spot detection loaded.'}) 

            %- Save everything
            guidata(hObject, handles); 

        end
    end
end


%== Menu: load outline of cell and position of transcription site
function menu_load_outline_Callback(hObject, eventdata, handles)

%- Change to outline or root directory if specified
current_dir = pwd;

if      not(isempty(handles.img.path_names.outlines))
   cd(handles.img.path_names.outlines)    
elseif  not(isempty(handles.img.path_names.root))   
    cd(handles.img.path_names.root)
end

handles = load_result_files(hObject, eventdata, handles);
guidata(hObject, handles);
status_update(hObject, eventdata, handles,{'Outline loaded.'})

%- Go back to original folder
cd(current_dir)


%= Menu to load detected spots
function menu_load_detected_spots_Callback(hObject, eventdata, handles)

current_dir = pwd;

if not(isempty(handles.img.path_names.results))
   cd(handles.img.path_names.results)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

handles = load_result_files(hObject, eventdata, handles);
guidata(hObject, handles);
status_update(hObject, eventdata, handles,{'Results loaded.'})

%- Go back to original folder
cd(current_dir)


%== Menu: load outline from other channel
function menu_load_outline_other_Callback(hObject, eventdata, handles)

%- Change to outline or root directory if specified
current_dir = pwd;

if      not(isempty(handles.img.path_names.outlines))
   cd(handles.img.path_names.outlines)    
elseif  not(isempty(handles.img.path_names.root))   
    cd(handles.img.path_names.root)
end
    
%- Generate new FQ object
status_open = handles.img.load_existing_outline([]);       

if status_open.outline
    handles = analyze_cellprop(hObject, eventdata, handles); 
    set(handles.checkbox_plot_outline,'Value',1);
    status_update(hObject, eventdata, handles,{'Results loaded.'})
    guidata(hObject, handles);
    
end
%- Go back to original folder
cd(current_dir)



%==========================================================================
%==== Define outlines
%==========================================================================

%== Button: determine outline of cell and position of transcription site
function button_outline_define_Callback(hObject, eventdata, handles)
handles.img = FISH_QUANT_outline('HandlesMainGui',handles);

%- Can be returned empty if outline designer is already open
if ~isempty(handles.img)
    set(handles.checkbox_plot_outline,'Value',1);
    handles = analyze_cellprop(hObject, eventdata, handles); 
    guidata(hObject, handles);
end


%==========================================================================
%==== Functions to analyze results files
%==========================================================================


%= Function to analyze detected regions
function handles = analyze_cellprop(hObject, eventdata, handles)

cell_prop = handles.img.cell_prop;
dim_sub_z = 2*handles.img.settings.detect.reg_size.z+1;

%- Parallel computing - open MATLAB session for parallel computation 
%flag_struct.parallel = get(handles.checkbox_parallel_computing, 'Value');

%- Populate pop-up menu with labels of cells
N_cell = size(cell_prop,2);

if N_cell > 0

    %- Call pop-up function to show results and bring values into GUI
    for i = 1:N_cell
        str_menu{i,1} = cell_prop(i).label;

        cell_prop(i).status_filtered = 0;    % Image filterd
        cell_prop(i).status_image    = 1;    % Image loaded
        cell_prop(i).status_detect   = 0;    % Spots detected
        cell_prop(i).status_fit      = 0;    % Spots fit with 3D Gaussian
        cell_prop(i).status_avg      = 0;    % Spots averaged
        cell_prop(i).status_avg_rad  = 0;    % Averaged spots were fit
        cell_prop(i).status_avg_con  = 0;    % Averaged spots were used for reconstruction
        cell_prop(i).spots_proj      = 0;    % Averaged spots were fit        
        
        %- Assign thresholding parameters
        if not(isempty(cell_prop(i).spots_fit))
            cell_prop(i).status_fit        = 1;
            cell_prop(i).FIT_Result        = [];            
            
            %- Extract sub-spots for fitting
            img_mask        = []; 
            flags.output    = 0;
        
            %= Options 
            [sub_spots, sub_spots_filt] = FQ_spots_predetect_mosaic_v1(handles.img,img_mask,i,flags);                      
                                  
            %- Calculate projections for plot with montage function
            spots_proj = [];
            for k=1:size(cell_prop(i).spots_fit,1)
                
                %- MIP in xy
                MIP_xy = max(sub_spots{k},[],3);
                spots_proj.xy(:,:,1,k) = MIP_xy;
                
                %- MIP in XZ
                MIP_xz = squeeze(max(sub_spots{k},[],1))';
                dim_MIP_z = size(MIP_xz,1); 
            
                %- Add zeros if not enough planes (for incomplete spots)
                if     dim_MIP_z < dim_sub_z
                   MIP_xz(dim_MIP_z+1:dim_sub_z,:) = 0;
                elseif dim_MIP_z > dim_sub_z
                    errordlg('Cropping dimension for spots do not agree. This happens when the settings file was not saved at the same time as the spot detection results.')
                    return
                end
                spots_proj.xz(:,:,1,k) = MIP_xz;
            end
            
            %- Save results
            cell_prop(i).spots_proj     = spots_proj;
            cell_prop(i).status_detect  = 1;            
            cell_prop(i).sub_spots      = sub_spots;
            cell_prop(i).sub_spots_filt = sub_spots_filt;            
        end         
    end  
else
    str_menu = {' '};
end

%- Save and analyze results
set(handles.pop_up_outline_sel_cell,'String',str_menu);
set(handles.pop_up_outline_sel_cell,'Value',1);

handles.img.cell_prop = cell_prop;

handles = pop_up_outline_sel_cell_Callback(hObject, eventdata, handles);        

%- Enable outline selection
FQ_enable_controls_v1(handles)

%- Save everything
guidata(hObject, handles); 
status_update(hObject, eventdata, handles,{'Spot data analyzed.'})        


%= Function to analyze detected regions
function str_menu = cells_get_names(cell_prop)


%- Populate pop-up menu with labels of cells
N_cell = size(cell_prop,2);

if N_cell > 0

    %- Call pop-up function to show results and bring values into GUI
    for i = 1:N_cell
        str_menu{i,1} = cell_prop(i).label;
    end  
else
    str_menu = {' '};
end


%== Used defined outline of cell and populate everything
function handles = pop_up_outline_sel_cell_Callback(hObject, eventdata, handles)

val       = get(handles.pop_up_outline_sel_cell,'Value');
cell_prop = handles.img.cell_prop;

%- If results of spot detection were saved as well
if not(isempty(cell_prop))
    if not(isempty(cell_prop(val).spots_fit))     
        handles.img.cell_prop(val).status_fit = 1;
        handles = fit_analyze(hObject,eventdata, handles);    
        FQ_enable_controls_v1(handles)    
    else
        cla(handles.axes_histogram_th,'reset');
        cla(handles.axes_histogram_all,'reset');
        cla(handles.axes_proj_xy,'reset');
        cla(handles.axes_proj_xz,'reset');
        cla(handles.axes_resid_xy,'reset');

        set(handles.axes_histogram_th,'Visible','off');
        set(handles.axes_histogram_all,'Visible','off');
        set(handles.axes_proj_xy,'Visible','off');
        set(handles.axes_proj_xz,'Visible','off');
        set(handles.axes_resid_xy,'Visible','off');   
    end
    
else
    cla(handles.axes_histogram_th,'reset');
    cla(handles.axes_histogram_all,'reset');
    cla(handles.axes_proj_xy,'reset');
    cla(handles.axes_proj_xz,'reset');
    cla(handles.axes_resid_xy,'reset');

    set(handles.axes_histogram_th,'Visible','off');
    set(handles.axes_histogram_all,'Visible','off');
    set(handles.axes_proj_xy,'Visible','off');
    set(handles.axes_proj_xz,'Visible','off');
    set(handles.axes_resid_xy,'Visible','off');   
end

%- Save results 
guidata(hObject, handles);

%- Update controls and plot
plot_image(handles,handles.axes_image);
FQ_enable_controls_v1(handles)



%==========================================================================
%==== Filter
%==========================================================================


%=== Pop-up to select filter
function popup_filter_type_Callback(hObject, eventdata, handles)

str = get(handles.popup_filter_type,'Value');
val = get(handles.popup_filter_type,'String');

switch val{str}
    
    case '3D_LoG'
        handles.img.settings.filter.method = val{str};
        
        set(handles.text_kernel_factor_bgd_xy,'String',num2str(handles.img.settings.filter.LoG_H));
        set(handles.text_kernel_factor_filter_xy,'String',num2str(handles.img.settings.filter.LoG_sigma));
        
        set(handles.text_kernel_factor_bgd_z,'Visible','off');
        set(handles.text_kernel_factor_filter_z,'Visible','off');        
        
        set(handles.text6,'String','Size');
        set(handles.text7,'String','Standard deviation (sigma)');
        
        
    case '3D_2xGauss'
        handles.img.settings.filter.method = val{str};
        
        set(handles.text_kernel_factor_bgd_xy,'String',num2str(handles.img.settings.filter.kernel_size.bgd_xy));
        set(handles.text_kernel_factor_bgd_z,'String',num2str(handles.img.settings.filter.kernel_size.bgd_z));
        set(handles.text_kernel_factor_filter_xy,'String',num2str(handles.img.settings.filter.kernel_size.psf_xy));
        set(handles.text_kernel_factor_filter_z,'String',num2str(handles.img.settings.filter.kernel_size.psf_z));
          
        set(handles.text6,'String','Kernel BGD [pixel]: XY, Z');
        set(handles.text7,'String','Kernel SNR [pixel]: XY, Z'); 
        
        set(handles.text_kernel_factor_bgd_z,'Visible','on');
        set(handles.text_kernel_factor_filter_z,'Visible','on');

        
    otherwise
        warndlg('INCORRECT SELECTION',mfilename)
        
end
        

%=== Filter image for pre-detection
function button_filter_Callback(hObject, eventdata, handles)

%= Indicate that filtering takes place
set(handles.h_fishquant,'Pointer','watch');
status_update(hObject, eventdata, handles,{'Filtering: more information in command window .... in progress ....'})


%== Get input for filtering and call function
val = get(handles.popup_filter_type,'Value');
str = get(handles.popup_filter_type,'String');
filter_type  =str{val};

%- Save settings of filter
handles.img.settings.filter.method = filter_type;

switch filter_type
    
    case '3D_LoG'
        handles.img.settings.filter.LoG_H = str2double(get(handles.text_kernel_factor_bgd_xy,'String'));
        handles.img.settings.filter.LoG_sigma = str2double(get(handles.text_kernel_factor_filter_xy,'String'));  
        
    case '3D_2xGauss'
        handles.img.settings.filter.kernel_size.bgd_xy = str2double(get(handles.text_kernel_factor_bgd_xy,'String'));
        handles.img.settings.filter.kernel_size.bgd_z  = str2double(get(handles.text_kernel_factor_bgd_z,'String'));
        handles.img.settings.filter.kernel_size.psf_xy = str2double(get(handles.text_kernel_factor_filter_xy,'String'));
        handles.img.settings.filter.kernel_size.psf_z  = str2double(get(handles.text_kernel_factor_filter_z,'String'));
end
 

%= Apply filter
flag.output = 1;
handles.img.filter(flag);
handles.img.project_Z('filt','max');
handles.status_filtered    = 1;
set(handles.pop_up_image_select,'Value',2);
guidata(hObject, handles);



%- Enable corresponding options in GUI
FQ_enable_controls_v1(handles)

%- Show filtered image (maximum projection)
axes(handles.axes_image);
h_plot = imshow(handles.img.filt_proj_z,[]);
set(h_plot, 'ButtonDownFcn', @axes_image_ButtonDownFcn)
title('Maximum projection of filtered image (Gaussian)','FontSize',8); 
colormap(hot)
status_update(hObject, eventdata, handles,{'Filtering: FINISHED!'})
set(handles.h_fishquant,'Pointer','arrow');


%==========================================================================
%==== Detection + Fit
%==========================================================================


%=== Pre-detection
function button_predetect_Callback(hObject, eventdata, handles)
set(handles.h_fishquant,'Pointer','watch');
status_update(hObject, eventdata, handles,{'Pre-detection in progress ..... start up of GUI might take some time ... '})

try
    handles.img = FISH_QUANT_predetect('HandlesMainGui',handles);
  
catch err
    errordlg('Error occured during pre-detection. See user-manual & command window for detailed error message.', 'FISH-QUANT: pre-dection')
    disp(err) 
end
    
%- Get names of cells (in case outline was defined during pre-detection)
str_menu = cells_get_names(handles.img.cell_prop);
set(handles.pop_up_outline_sel_cell,'String',str_menu);

%- Update GUI and enable controls
FQ_enable_controls_v1(handles)
status_update(hObject, eventdata, handles,{'Pre-detection: FINISHED'})
set(handles.h_fishquant,'Pointer','arrow');

%- Save results 
guidata(hObject, handles);


%=== Determine how many spots should be fitted
function butto_restrict_N_spots_fit_Callback(hObject, eventdata, handles)


dlgTitle = 'Maximum number of spots per cell to be fit:';
prompt(1) = {'-1 = always fit; 0 = never fit; '};
defaultValue{1} = num2str(handles.img.settings.fit.N_spots_fit_max);
numlines=[1 75];

userValue = inputdlg(prompt,dlgTitle,numlines,defaultValue);

if( ~ isempty(userValue))
    handles.img.settings.fit.N_spots_fit_max = str2double(userValue{1});
    
    %- Save results
    guidata(hObject, handles);
end


%=== Fit with 3D Gaussian
function button_fit_3d_Callback(hObject, eventdata, handles)

%- Prepare GUI
set(handles.h_fishquant,'Pointer','watch');
status_update(hObject, eventdata, handles,{'Fitting: STARTED ... '})

%- Some parameters
%handles.img.settings.fit.flags.parallel = get(handles.checkbox_parallel_computing, 'Value');

%- Used to compensate for spots that were close the edge 
dim_sub_xy = 2*handles.img.settings.detect.reg_size.xy+1;
dim_sub_z  = 2*handles.img.settings.detect.reg_size.z+1;


%== Loop over cells
tic
for ind_cell = 1:length(handles.img.cell_prop);
    
    % = Fit spots
    handles.img.spots_fit_3D(ind_cell);
    
    % = Get projections of residuals
    FIT_Result = handles.img.cell_prop(ind_cell).FIT_Result;
    spots_proj = handles.img.cell_prop(ind_cell).spots_proj; 
    N_spots    = size(handles.img.cell_prop(ind_cell).spots_fit,1);
    
    if not(isempty(FIT_Result))
        spots_proj.res_xy = zeros(size(spots_proj.xy));
    end

    for k=1:N_spots
        if not(isempty(FIT_Result))
            MIP_xy = max(FIT_Result{k}.im_residual,[],3);   
            [dim_MIP_1,dim_MIP_2] = size(MIP_xy);
            MIP_xy = padarray(MIP_xy,[dim_sub_xy-dim_MIP_1 dim_sub_xy-dim_MIP_2],'post'); 
            spots_proj.res_xy(:,:,1,k) = MIP_xy;
            
        %- Loaded results have sub-spots but not fits and residuals
        elseif not(isempty(spots_proj))
            spots_proj.res_xy(:,:,1,k) =  0;        
        else
            spots_proj = [];
            spots_proj.res_xy(:,:,1,k) =  0;
            spots_proj.xy(:,:,1,k)     =  0;
            spots_proj.xz(:,:,1,k)     =  0;
        end
    end
    
    handles.img.cell_prop(ind_cell).spots_proj = spots_proj; 
    
end
    
toc

%- Set all locks back to 0
handles.img.settings.thresh.sigmaxy.lock   = 0;
handles.img.settings.thresh.sigmaz.lock    = 0;
handles.img.settings.thresh.amp.lock       = 0;
handles.img.settings.thresh.bgd.lock       = 0;
handles.img.settings.thresh.pos_z.lock     = 0;
handles.img.settings.thresh.int_raw.lock   = 0;
handles.img.settings.thresh.int_filt.lock  = 0;

%- Analyze results
handles = fit_analyze(hObject,eventdata, handles);

%- Save results
guidata(hObject, handles);
status_update(hObject, eventdata, handles,{'Fitting: ... FINISHED! '})
set(handles.h_fishquant,'Pointer','arrow');


%=== Restrict fitting parameters
function button_fit_restrict_Callback(hObject, eventdata, handles)

cell_prop = handles.img.cell_prop;
N_cell = length(cell_prop);

summary_fit_all = [];

for i_reg = 1:N_cell
    summary_fit_loop = cell_prop(i_reg).spots_fit;
    summary_fit_all = [summary_fit_all;summary_fit_loop];
end

parameters.summary_fit_all  = summary_fit_all;
parameters.fit_limits = handles.img.settings.fit.limits; 
parameters.col_par    = handles.img.col_par;

[handles.img.settings.fit.limits]  = FISH_QUANT_restrict_par(parameters);
guidata(hObject, handles);


%=== Function to analyze the results of the fit
function handles = fit_analyze(hObject,eventdata, handles)

%- Also important when selecting other cell and threshold were already
%  selected.

col_par = handles.img.col_par;

%- Extracted fitted spots for this cell
ind_cell        = get(handles.pop_up_outline_sel_cell,'Value');
spots_fit       = handles.img.cell_prop(ind_cell).spots_fit;
spots_detected  = handles.img.cell_prop(ind_cell).spots_detected;
thresh          = handles.img.cell_prop(ind_cell).thresh; 
th_sett         = handles.img.settings.thresh;

% - Clear the plot axes
cla(handles.axes_image,'reset');
cla(handles.axes_histogram_th,'reset');
cla(handles.axes_histogram_all,'reset');
cla(handles.axes_proj_xy,'reset');
cla(handles.axes_proj_xz,'reset');
cla(handles.axes_resid_xy,'reset');    

%- Get averaged values for PSF
if not(isempty(spots_fit))
    PSF_exp.sigmax_all = mean(spots_fit(:,col_par.sigmax));
    PSF_exp.sigmax_th  = mean(spots_fit(:,col_par.sigmax));
    PSF_exp.sigmax_avg = mean(spots_fit(:,col_par.sigmax));
    
    PSF_exp.sigmax_all_std = std(spots_fit(:,col_par.sigmax));
    PSF_exp.sigmax_th_std  = std(spots_fit(:,col_par.sigmax));
    PSF_exp.sigmax_avg_std = std(spots_fit(:,col_par.sigmax));

    PSF_exp.sigmay_all = mean(spots_fit(:,col_par.sigmay));
    PSF_exp.sigmay_th  = mean(spots_fit(:,col_par.sigmay));
    PSF_exp.sigmay_avg = mean(spots_fit(:,col_par.sigmay));
    
    PSF_exp.sigmay_all_std = std(spots_fit(:,col_par.sigmay));
    PSF_exp.sigmay_th_std  = std(spots_fit(:,col_par.sigmay));
    PSF_exp.sigmay_avg_std = std(spots_fit(:,col_par.sigmay));
    
    PSF_exp.sigmaz_all = mean(spots_fit(:,col_par.sigmaz));
    PSF_exp.sigmaz_th  = mean(spots_fit(:,col_par.sigmaz));
    PSF_exp.sigmaz_avg = mean(spots_fit(:,col_par.sigmaz));
    
    PSF_exp.sigmaz_all_std = std(spots_fit(:,col_par.sigmaz));
    PSF_exp.sigmaz_th_std  = std(spots_fit(:,col_par.sigmaz));
    PSF_exp.sigmaz_avg_std = std(spots_fit(:,col_par.sigmaz));

    PSF_exp.amp_all    = mean(spots_fit(:,col_par.amp));
    PSF_exp.amp_th     = mean(spots_fit(:,col_par.amp));
    PSF_exp.amp_avg    = mean(spots_fit(:,col_par.amp));
    
    PSF_exp.amp_all_std  = std(spots_fit(:,col_par.amp));
    PSF_exp.amp_th_std   = std(spots_fit(:,col_par.amp));
    PSF_exp.amp_avg_std  = std(spots_fit(:,col_par.amp));    

    PSF_exp.bgd_all    = mean(spots_fit(:,col_par.bgd));
    PSF_exp.bgd_th     = mean(spots_fit(:,col_par.bgd));
    PSF_exp.bgd_avg    = mean(spots_fit(:,col_par.bgd));

    PSF_exp.bgd_all_std    = std(spots_fit(:,col_par.bgd));
    PSF_exp.bgd_th_std     = std(spots_fit(:,col_par.bgd));
    PSF_exp.bgd_avg_std    = std(spots_fit(:,col_par.bgd));
    
    set(handles.text_psf_fit_sigmaX,'String', num2str(PSF_exp.sigmax_all,'%.0f'));
    set(handles.text_psf_fit_sigmaY,'String', num2str(PSF_exp.sigmay_all,'%.0f'));
    set(handles.text_psf_fit_sigmaZ,'String', num2str(PSF_exp.sigmaz_all,'%.0f'));
    set(handles.text_psf_fit_amp,'String',    num2str(PSF_exp.amp_all,'%.0f'));
    set(handles.text_psf_fit_bgd,'String',    num2str(PSF_exp.bgd_all,'%.0f'));
    set(handles.pop_up_select_psf,'Value',1);
    
    %- Set-up structure for thresholding
    thresh.sigmaxy.in       = thresh.in;
    if th_sett.sigmaxy.lock == 0
        thresh.sigmaxy.min_th = min(spots_fit(:,col_par.sigmax));               
        thresh.sigmaxy.max_th = max(spots_fit(:,col_par.sigmax)); 
    else
        thresh.sigmaxy.min_th = th_sett.sigmaxy.min_th;               
        thresh.sigmaxy.max_th = th_sett.sigmaxy.max_th; 
    end

    thresh.sigmaz.in       = thresh.in;  
    if th_sett.sigmaz.lock == 0
        thresh.sigmaz.min_th = min(spots_fit(:,col_par.sigmaz));               
        thresh.sigmaz.max_th = max(spots_fit(:,col_par.sigmaz)); 
    else
        thresh.sigmaz.min_th = th_sett.sigmaz.min_th;               
        thresh.sigmaz.max_th = th_sett.sigmaz.max_th; 
    end

    thresh.amp.in       = thresh.in;             
    if th_sett.amp.lock == 0
        thresh.amp.min_th = min(spots_fit(:,col_par.amp));               
        thresh.amp.max_th = max(spots_fit(:,col_par.amp)); 
    else
        thresh.amp.min_th = th_sett.amp.min_th;               
        thresh.amp.max_th = th_sett.amp.max_th; 
    end

    thresh.bgd.in       = thresh.in;           
    if th_sett.bgd.lock == 0
        thresh.bgd.min_th = min(spots_fit(:,col_par.bgd));               
        thresh.bgd.max_th = max(spots_fit(:,col_par.bgd)); 
    else
        thresh.bgd.min_th = th_sett.bgd.min_th;               
        thresh.bgd.max_th = th_sett.bgd.max_th; 
    end 
     
    thresh.int_raw.in       = thresh.in;           
    if th_sett.int_raw.lock == 0
        thresh.int_raw.min_th = min(spots_detected(:,col_par.int_raw));               
        thresh.int_raw.max_th = max(spots_detected(:,col_par.int_raw)); 
    else
        thresh.int_raw.min_th = th_sett.int_raw.min_th;               
        thresh.int_raw.max_th = th_sett.int_raw.max_th; 
    end   
    
    thresh.int_filt.in  = thresh.in;           
    if th_sett.int_filt.lock == 0
        thresh.int_filt.min_th = min(spots_detected(:,col_par.int_filt));               
        thresh.int_filt.max_th = max(spots_detected(:,col_par.int_filt)); 
    else
        thresh.int_filt.min_th = th_sett.int_filt.min_th;               
        thresh.int_filt.max_th = th_sett.int_filt.max_th; 
    end 

    thresh.pos_z.in  = thresh.in;           
    if th_sett.pos_z.lock == 0
        thresh.pos_z.min_th = min(spots_fit(:,col_par.pos_z));               
        thresh.pos_z.max_th = max(spots_fit(:,col_par.pos_z)); 
    else
        thresh.pos_z.min_th = th_sett.pos_z.min_th;               
        thresh.pos_z.max_th = th_sett.pos_z.max_th; 
    end
    
    %- Save results
    handles.img.cell_prop(ind_cell).thresh = thresh;
    handles.img.PSF_exp                    = PSF_exp;

    %- Call functions to illustrate the fits
    handles = pop_up_threshold_Callback(hObject, eventdata, handles);
    %handles = button_threshold_Callback(hObject, eventdata, handles);

    %- Save results
    guidata(hObject, handles);

else
    status_update(hObject, eventdata, handles,{'Fitting: ... no spots for fitting! '})    
end

%- Update GUI and enable controls
FQ_enable_controls_v1(handles)
    
    
%==========================================================================
%==== THRESHOLD SPOTS
%==========================================================================


%=== Select thresholding parameter
function handles = pop_up_threshold_Callback(hObject, eventdata, handles)

%- Extracted fitted spots for this cell
ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
spots_fit = handles.img.cell_prop(ind_cell).spots_fit;
th_sett   = handles.img.settings.thresh;

%- Executes only if there are results
if not(isempty(spots_fit))
    
    thresh = handles.img.cell_prop(ind_cell).thresh;
    
    str = get(handles.pop_up_threshold,'String');
    val = get(handles.pop_up_threshold,'Value');
    popup_parameter = str{val};
  
    %-Check which parameters
    switch (popup_parameter)
        
        case 'Sigma - XY'
           field_name = 'sigmaxy';
           
        case 'Sigma - Z'
            field_name = 'sigmaz';
            
        case 'Amplitude'
            field_name = 'amp';          
            
        case 'Background'
            field_name = 'bgd';
            
        case 'Pos (Z)'
            field_name = 'pos_z';          
            
        case 'Pixel-intensity (Raw)'
            field_name = 'int_raw';
            
        case 'Pixel-intensity (Filtered)'
            field_name = 'int_filt';       
            
    end
    
    thresh_sel  = thresh.(field_name);
    th_sett_sel = th_sett.(field_name);         

    %- Enable lock if specififed
    set(handles.checkbox_th_lock,'Value',th_sett_sel.lock);

    %== Set sliders and text box according to selection   
    
    %-  Locked - based on saved values
    if th_sett_sel.lock == 1; 
        
        %- Assign global values to this particular cell
        thresh_sel.min_th = th_sett_sel.min_th;
        thresh_sel.max_th = th_sett_sel.max_th;
        
        %- Update slider values
        value_min = (thresh_sel.min_th-thresh_sel.min)/thresh_sel.diff;
        if value_min < 0; value_min = 0; end    % Might be necessary if slider was at the left end
        if value_min > 1; value_min = 1; end    % Might be necessary if slider was at the right end
        
        value_max = (thresh_sel.max_th-thresh_sel.min)/thresh_sel.diff;
        if value_max < 0; value_max = 0; end   % Might be necessary if slider was at the left end  
        if value_max > 1; value_max = 1; end   % Might be necessary if slider was at the right end        
        
        %- Slider for lower limit and corresponding text box
        set(handles.slider_th_min,'Value',value_min)
        set(handles.text_th_min,'String', num2str(thresh_sel.min_th));     
     
        %- Slider for upper limit and corresponding text box
        set(handles.slider_th_max,'Value',value_max)
        set(handles.text_th_max,'String', num2str(thresh_sel.max_th));
    
    %- Not locked - not thresholding
    else                    
        
        %- Slider for lower limit and corresponding text box
        set(handles.slider_th_min,'Value',0)
        set(handles.text_th_min,'String', num2str(thresh_sel.min));     
     
        %- Slider for upper limit and corresponding text box
        set(handles.slider_th_max,'Value',1)
        set(handles.text_th_max,'String', num2str(thresh_sel.max));
    end
 
    %== For slider functions calls and call of threshold function
    handles.img.cell_prop(ind_cell).thresh.diff = thresh_sel.diff;  %- Save 'diff' for histogram plotting later
    handles.img.cell_prop(ind_cell).thresh.min  = thresh_sel.min;   %- Save 'diff' for histogram plotting later
    handles.img.cell_prop(ind_cell).thresh.max  = thresh_sel.max;   %- Save 'diff' for histogram plotting later
    
    %- Save handles-structure
    handles = button_threshold_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);  

end


%=== Threshold data based on selection
function handles = button_threshold_Callback(hObject, eventdata, handles)

%- Extracted fitted spots for this cell
ind_cell        = get(handles.pop_up_outline_sel_cell,'Value');
spots_fit       = handles.img.cell_prop(ind_cell).spots_fit;
spots_detected  = handles.img.cell_prop(ind_cell).spots_detected;

PSF_exp    = handles.img.PSF_exp;
col_par    = handles.img.col_par;
th_sett    = handles.img.settings.thresh;

%- Execute only if there are results
if not(isempty(spots_fit))
    
    thresh     = handles.img.cell_prop(ind_cell).thresh;
    
    %- Locked threshold?
    th_lock  = get(handles.checkbox_th_lock, 'Value');
    
    %- Selected thresholds
    min_th = floor(str2double(get(handles.text_th_min,'String')));        % floor and ceil necessary for extreme slider position to select all points.
    max_th = ceil(str2double(get(handles.text_th_max,'String')));      
    
    %- Save for plotting of the histograms
    thresh.min_th =  min_th;    
    thresh.max_th =  max_th;
    
    % =====================================================================   
    % Assign thresholding parameters
    % ===================================================================== 
    
    str = get(handles.pop_up_threshold,'String');
    val = get(handles.pop_up_threshold,'Value');
    popup_parameter = str{val};     
    
    switch (popup_parameter)
        
        case 'Sigma - XY'                       
            th_sett.sigmaxy.lock   = th_lock;
            th_sett.sigmaxy.min_th = min_th;
            th_sett.sigmaxy.max_th = max_th;
            
            values_for_th      = spots_fit(:,col_par.sigmax);
            name_field         = 'sigmaxy';
            
        case 'Sigma - Z'            
            th_sett.sigmaz.lock   = th_lock;
            th_sett.sigmaz.min_th = min_th;
            th_sett.sigmaz.max_th = max_th;  
            
            values_for_th     = spots_fit(:,col_par.sigmaz);
            name_field        = 'sigmaz';

        case 'Amplitude'            
            th_sett.amp.lock   = th_lock;
            th_sett.amp.min_th = min_th;
            th_sett.amp.max_th = max_th;  
            
            values_for_th  = spots_fit(:,col_par.amp);
            name_field          = 'amp';

        case 'Background'            
            th_sett.bgd.lock = th_lock;
            th_sett.bgd.min_th = min_th;
            th_sett.bgd.max_th = max_th;  
            
            values_for_th  = spots_fit(:,col_par.bgd);
            name_field          = 'bgd';
             
       case 'Pos (Z)'            
            th_sett.pos_z.lock = th_lock;
            th_sett.pos_z.min_th = min_th;
            th_sett.pos_z.max_th = max_th;   
            
            values_for_th      = spots_fit(:,col_par.pos_z);
            name_field          = 'pos_z';

             
       case 'Pixel-intensity (Raw)'            
            th_sett.int_raw.lock = th_lock;
            th_sett.int_raw.min_th = min_th;
            th_sett.int_raw.max_th = max_th;  
            
            values_for_th      = spots_detected(:,col_par.int_raw);
            name_field          = 'int_raw';
     
        case 'Pixel-intensity (Filtered)'            
            th_sett.int_filt.lock   = th_lock;
            th_sett.int_filt.min_th = min_th;
            th_sett.int_filt.max_th = max_th;  
            
            values_for_th       = spots_detected(:,col_par.int_filt);
            name_field          = 'int_filt';
                
    end
    
    %- Apply threshold for currently selected parameter
    thresh.in_sel           = ((values_for_th >= min_th) & ...
                                  (values_for_th <= max_th)) | ...
                                  isnan(values_for_th);
    thresh.(name_field).in  = thresh.in_sel;
    
    
    % =====================================================================   
    % Exclude spots that are too close
    % =====================================================================  
    data    = spots_fit(:,1:3);
    N_spots = size(data,1);
    
    r_min = str2double(get(handles.text_min_dist_spots,'String'));
    
    if r_min > 0
    
        %- Mask with relative distance and matrix with radius
        dum        = [];
        dum(1,:,:) = data';
        data_3D_1  = repmat(dum,[N_spots 1 1]);
        data_3D_2  = repmat(data,[1 1 N_spots]);

        d_coord = data_3D_1-data_3D_2;

        r = sqrt(squeeze(d_coord(:,1,:).^2 + d_coord(:,2,:).^2 + d_coord(:,3,:).^2)); 

        %- Determine spots that are too close
        mask_close          = zeros(size(r));
        mask_close(r<r_min) = 1;
        mask_close_inv      = not(mask_close);

        %- Mask with intensity ratios
        data_int     = spots_detected(:,col_par.int_raw);
        mask_int_3D1 = repmat(data_int,1,N_spots);
        mask_int_3D2 = repmat(data_int',N_spots,1);

        mask_int_ratio = mask_int_3D2 ./ mask_int_3D1;

        %- Find close spots and remove the ones with the dimmest pixel
        m_diag = logical(diag(1*(1:N_spots)));

        mask_close_spots = mask_int_ratio;
        mask_close_spots(mask_close_inv) = 10;
        mask_close_spots(m_diag)         = 10;  %- Set diagonal to 10;

        %- Find ratios of spot that are < 1 
        [row,col] = find(mask_close_spots < 1);
        ind_spots_too_close1 = unique(col);

        %- Find ratios of spot that are == 1 
        [row,col] = find(mask_close_spots == 1);
        ind_spots_too_close2 = unique(col(2:end));

        ind_spots_too_close = union(ind_spots_too_close1,ind_spots_too_close2);
    else
        ind_spots_too_close = [];
    end

    % =====================================================================   
    % APPLY THRESHOLD
    % =====================================================================   
    
    %- Thresholding under consideration of locked ones
    %  Can be written in boolean algebra: Implication Z = x?y = ?x?y = not(x) or y
    %  http://en.wikipedia.org/wiki/Boolean_algebra_%28logic%29#Basic_operations
    %  x = [0,1] ... unlocked [0] and locked [1]
    %  y = [0,1] ... index is thresholded [0] or not [1]
    %  Number is always considered (z=1) unless paramter is locked (x=1) and number is thresholded (y=0)
    %          y
    %       |0   1
    %     ----------
    %   x 0 |1   1
    %     1 |0   1

    %- Save old thresholding
    thresh.logic_out_man  = (thresh.in == -1);

    %==== New thresholding only with locked values
    thresh.logic_in  = (not(th_sett.sigmaxy.lock) | thresh.sigmaxy.in == 1) & ...
                       (not(th_sett.sigmaz.lock)  | thresh.sigmaz.in == 1) & ...
                       (not(th_sett.amp.lock)     | thresh.amp.in == 1) & ...
                       (not(th_sett.bgd.lock)     | thresh.bgd.in == 1) & ...
                       (not(th_sett.pos_z.lock)   | thresh.pos_z.in == 1)& ...
                       (not(th_sett.int_raw.lock) | thresh.int_raw.in == 1)& ...
                       (not(th_sett.int_filt.lock)| thresh.int_filt.in == 1); 

    thresh.logic_in(ind_spots_too_close)  = 0;   % Spots that are too close                

    %- Finalize thresholding    
    thresh.in(thresh.logic_in == 1) = 1;
    thresh.in(thresh.logic_in == 0) = 0;
    thresh.in(thresh.logic_out_man) = -1;

    thresh.out = (thresh.in == 0) | (thresh.in == -1);

%     %=== Chech which spots are in the nucleus
%     if not(isempty(handles.img.cell_prop(ind_cell).pos_Nuc))
% 
%         %=== Look at spots after thresholding to get overall spot
%         %counts in the nucleus
%         
%         x_Nuc = handles.img.cell_prop(ind_cell).pos_Nuc.x * handles.img.par_microscope.pixel_size.xy;
%         y_Nuc = handles.img.cell_prop(ind_cell).pos_Nuc.y * handles.img.par_microscope.pixel_size.xy;
% 
%         %=== Look at all spots       
%         spots_y = data(:,1);
%         spots_x = data(:,2);
% 
%         %- Find spots which are in nucleus
%         in_Nuc = inpolygon(spots_x,spots_y,x_Nuc,y_Nuc); % Points defined in Positions inside the polygon
% 
%     else
%         in_Nuc = zeros(size(data,1),1);
%     end
    
    %=== Spots which are in considering the current selection even if it is not locked
    thresh.in_display = thresh.in_sel  & thresh.logic_in & ~(thresh.in == -1); 
    
    handles.img.cell_prop(ind_cell).thresh  = thresh;
    %handles.img.cell_prop(ind_cell).in_Nuc  = in_Nuc;
    handles.img.settings.thresh   = th_sett;
    handles.thresh.Spots_min_dist = r_min;
    
    %=== Update experimental PSF settings    
    PSF_exp.sigmax_th  = nanmean(spots_fit(thresh.in_display,col_par.sigmax));
    PSF_exp.sigmay_th  = nanmean(spots_fit(thresh.in_display,col_par.sigmay));
    PSF_exp.sigmaz_th  = nanmean(spots_fit(thresh.in_display,col_par.sigmaz));
    PSF_exp.amp_th     = nanmean(spots_fit(thresh.in_display,col_par.amp));
    PSF_exp.bgd_th     = nanmean(spots_fit(thresh.in_display,col_par.bgd));

    PSF_exp.sigmax_th_std  = nanstd(spots_fit(thresh.in_display,col_par.sigmay));
    PSF_exp.sigmay_th_std  = nanstd(spots_fit(thresh.in_display,col_par.sigmay));
    PSF_exp.sigmaz_th_std  = nanstd(spots_fit(thresh.in_display,col_par.sigmaz));
    PSF_exp.amp_th_std     = nanstd(spots_fit(thresh.in_display,col_par.amp));
    PSF_exp.bgd_th_std     = nanstd(spots_fit(thresh.in_display,col_par.bgd));

    set(handles.text_psf_fit_sigmaX,'String', num2str(PSF_exp.sigmax_th,'%.0f'));
    set(handles.text_psf_fit_sigmaY,'String', num2str(PSF_exp.sigmay_th,'%.0f'));
    set(handles.text_psf_fit_sigmaZ,'String', num2str(PSF_exp.sigmaz_th,'%.0f'));
    set(handles.text_psf_fit_amp,'String',    num2str(PSF_exp.amp_th,'%.0f'));
    set(handles.text_psf_fit_bgd,'String',    num2str(PSF_exp.bgd_th,'%.0f'));

    set(handles.pop_up_select_psf,'Value',2);

    handles.img.PSF_exp = PSF_exp;

    %=== Save data
    guidata(hObject, handles); 
    
    %== Make spots fits available as global variable
    global spots_fit_th
    spots_fit_th = [];
    spots_fit_th = spots_fit(thresh.in == 1,:); 
    
    
    %=== VARIOUS PLOTS

    %- Clear the plot axes
    cla(handles.axes_image,'reset');
    cla(handles.axes_histogram_th,'reset');
    cla(handles.axes_histogram_all,'reset');
    cla(handles.axes_proj_xy,'reset');
    cla(handles.axes_proj_xz,'reset');
    cla(handles.axes_resid_xy,'reset');

    %- Plot histogram
    handles = plot_hist_all(handles,handles.axes_histogram_all,values_for_th);

    %- Plot thresholded histogram
    handles = plot_hist_th(handles,handles.axes_histogram_th,values_for_th);

    %- Plot spot-projection in xy
    plot_proj_xy(handles,handles.axes_proj_xy)

    %- Plot spot-projection in xy
    plot_proj_xz(handles,handles.axes_proj_xz)

    %- Plot residual-projection in xy
    plot_resid_xy(handles,handles.axes_resid_xy)

    %- Plot image and position of selected and rejected spots
    plot_image(handles,handles.axes_image);

    %- Set selections for plot accordingly
    set(handles.pop_up_image_spots,'Value',3);
     
end
    

%==== Button to unlock all thresholds
function button_th_unlock_all_Callback(hObject, eventdata, handles)

%- Reset locks and apply thresholding
handles.img.th_lock_reset;
handles = pop_up_threshold_Callback(hObject, eventdata, handles);
%handles = button_threshold_Callback(hObject, eventdata, handles);

guidata(hObject, handles);


%=== Check-box for locking parameters
function checkbox_th_lock_Callback(hObject, eventdata, handles) 
handles = button_threshold_Callback(hObject, eventdata, handles);
guidata(hObject, handles);


%=== Slider for minimum values of threshold
function slider_th_min_Callback(hObject, eventdata, handles)
sliderValue = get(handles.slider_th_min,'Value');

ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;

%- Determine value at current slider position
value_thresh = sliderValue*thresh.diff+thresh.min;

%- Change text box and line in histogram
set(handles.text_th_min,'String', value_thresh);

axes(handles.axes_histogram_all);
delete(handles.h_hist_min);
v = axis;
hold on, 
handles.h_hist_min = plot([value_thresh value_thresh] , [0 1e5],'r');
hold off
axis(v);

axes(handles.axes_histogram_th);
delete(handles.h_hist_th_min);
v = axis;
hold on, 
handles.h_hist_th_min = plot([value_thresh value_thresh] , [0 1e5],'r');
hold off
axis(v);

guidata(hObject, handles);      % Update handles structure


%== Slider for maximum values of threshold
function slider_th_max_Callback(hObject, eventdata, handles)

sliderValue = get(handles.slider_th_max,'Value');
ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;

%- Determine value at current slider position
value_thresh = sliderValue*thresh.diff+thresh.min;

%- Change text box and line in histogram
set(handles.text_th_max,'String', value_thresh);

axes(handles.axes_histogram_all);
if isobject(handles.h_hist_max); delete(handles.h_hist_max); end
v = axis;
hold on
handles.h_hist_max = plot([value_thresh value_thresh] , [0 1e5],'r');
hold off
axis(v);

axes(handles.axes_histogram_th);
if isobject(handles.h_hist_th_max); delete(handles.h_hist_th_max); end
v = axis;
hold on
handles.h_hist_th_max = plot([value_thresh value_thresh] , [0 1e5],'r');
hold off
axis(v);

guidata(hObject, handles);      % Update handles structure


%=== Edit values of slider selection: minimum 
function text_th_min_Callback(hObject, eventdata, handles)
value_edit = str2double(get(handles.text_th_min,'String'));

ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;

%- Set new slider value only if value is within range
if value_edit > thresh.min  && value_edit < thresh.max
    slider_new = (value_edit-thresh.min)/thresh.diff;
    set(handles.slider_th_min,'Value',slider_new);   

else
    set(handles.text_th_min,'String',num2str(value_edit))    
end


%=== Edit values of slider selection: maximum 
function text_th_max_Callback(hObject, eventdata, handles)
value_edit = str2double(get(handles.text_th_max,'String'));

ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;

%- Set new slider value only if value is within range
if value_edit > thresh.min  && value_edit < thresh.max
    slider_new = (value_edit-thresh.min)/thresh.diff;
    set(handles.slider_th_max,'Value',slider_new);
    slider_th_max_Callback(hObject, eventdata, handles)
else
    set(handles.text_th_max,'String',num2str(value_edit))     
end


%==========================================================================
%==== AVERAGE SPOTS
%==========================================================================

%=== Define settings for spot averaging
function menu_settings_avg_Callback(hObject, eventdata, handles)

status_change = handles.img.define_par_avg;

% If settings changed for the first time
if status_change && ~handles.status_avg_settings
    
    handles.status_avg_settings = 1;
    
    %- Save handles, enable controls
    guidata(hObject, handles);
    FQ_enable_controls_v1(handles)
end
    
    
%=== Average spots: from current cell 
function menu_avg_calc_Callback(hObject, eventdata, handles)

%- Average spots from one cell
ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
handles.img.avg_spots(ind_cell,[]);
handles.img.avg_spots_plot;
handles.status_avg_calc     = 1;  % Average calculated

%- Save handles, enable controls
guidata(hObject, handles);
FQ_enable_controls_v1(handles)
   

%=== Average spots: from all cell    
function menu_avg_calc_all_Callback(hObject, eventdata, handles)

%- Average spots from ALL cells
handles.img.avg_spots([],[]);
handles.img.avg_spots_plot;
handles.status_avg_calc     = 1;  % Average calculated

%- Save handles, enable controls
guidata(hObject, handles);
FQ_enable_controls_v1(handles)


%==== Fit averaged spots
function handles = menu_avg_fit_Callback(hObject, eventdata, handles)

%- Get some parameters
parameters_fit.flags.ns     = 0;  % Fit over-sampled (which will be identical to normal-sampling if no over-sampling has been specified)
parameters_fit.flags.output = 1;

%- Image should be cropped to the size of the detection region
parameters_fit.flags.crop  = 1;
parameters_fit.par_crop.xy = handles.img.settings.detect.reg_size.xy; 
parameters_fit.par_crop.z  = handles.img.settings.detect.reg_size.z; 

%- Average image
handles.img.avg_spot_fit(parameters_fit)

%- Update experimental PSF settings
PSF_exp.sigmax_avg = handles.img.spot_avg_fit_par.sigma_xy;
PSF_exp.sigmay_avg = handles.img.spot_avg_fit_par.sigma_xy;
PSF_exp.sigmaz_avg = handles.img.spot_avg_fit_par.sigma_z;
PSF_exp.amp_avg    = handles.img.spot_avg_fit_par.amp;
PSF_exp.bgd_avg    = handles.img.spot_avg_fit_par.bgd;

set(handles.text_psf_fit_sigmaX,'String', num2str(PSF_exp.sigmax_avg,'%.0f'));
set(handles.text_psf_fit_sigmaY,'String', num2str(PSF_exp.sigmay_avg,'%.0f'));
set(handles.text_psf_fit_sigmaZ,'String', num2str(PSF_exp.sigmaz_avg,'%.0f'));
set(handles.text_psf_fit_amp,'String',    num2str(PSF_exp.amp_avg,'%.0f'));
set(handles.text_psf_fit_bgd,'String',    num2str(PSF_exp.bgd_avg,'%.0f'));

set(handles.pop_up_select_psf,'Value',3);

%- Save values
%handles.img.spot_avg_os_fit = PSF_fit_os;
handles.status_avg_fit     = 1;
handles.img.PSF_exp        = PSF_exp;
guidata(hObject, handles);     


%=== Menu: save averaged spot with normal sampling as tiff
function menu_avg_save_ns_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with images
current_dir = pwd;

if    not(isempty(handles.img.path_names.results))
   cd(handles.img.path_names.results)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

%- Save image
handles.img.save_img('','avg_ns')

%- Go back to original directory
cd(current_dir)


%=== Menu: save averaged spot with over-sampling spot as tiff
function menu_avg_save_os_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with images
current_dir = pwd;

if    not(isempty(handles.img.path_names.results))
   cd(handles.img.path_names.results)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

%- Save image
handles.img.save_img('','avg_os')

%- Go back to original directory
cd(current_dir)




%==========================================================================
%==== VISUALIZATION
%==========================================================================

%==========================================================================
%==== Functions for the different plots

%=== Image with position of detected spots
function plot_image(handles,axes_select)


col_par = handles.img.col_par;

flag_outline  = get(handles.checkbox_plot_outline, 'Value');
pixel_size    = handles.img.par_microscope.pixel_size;
ind_cell      = get(handles.pop_up_outline_sel_cell,'Value');

%- Might be called with no cell properties defined
if isempty(handles.img.cell_prop)
    spots_fit = {}; thresh = []; cell_prop = {};
else
    spots_fit  = handles.img.cell_prop(ind_cell).spots_fit;
    thresh     = handles.img.cell_prop(ind_cell).thresh;
    cell_prop  = handles.img.cell_prop; 
end

%- Select image-data to plot
str       = get(handles.pop_up_image_select,'String');
val       = get(handles.pop_up_image_select,'Value');
sel_image = str{val};

switch (sel_image)    
    case 'Raw image'  
        img_plot = handles.img.raw_proj_z;
        
    case 'Filtered image'  
        img_plot = handles.img.filt_proj_z;
        
    case 'No image'
        img_plot = [];
end

%- Select spots to plot
str       = get(handles.pop_up_image_spots,'String');
val       = get(handles.pop_up_image_spots,'Value');
sel_spots = str{val};

flag_spots = 0;

switch sel_spots      
    case 'Detected spots',       flag_spots = 1;
    case 'Thresholded spots',    flag_spots = 2;
end
            
%- 1. Plot image
if isempty(axes_select)

    if flag_spots || flag_outline
        figure
        imshow(img_plot,[]);
    else
        imtool(uint16(img_plot),[]);  % imtool does not work with 32bit
    end
else
    axes(axes_select);   
    h = imshow(img_plot,[]);
    set(h, 'ButtonDownFcn', @axes_image_ButtonDownFcn)
   
end

title('Maximum projection of loaded image','FontSize',9);
colormap(hot), axis off


%- If no image is shown
if isempty(img_plot)
    h_fig = figure(45);
    clf
    set(h_fig,'color','w')
    set(gca,'YDir','rev')
    axis equal
    axis off

end


%- 2. Plot-spots
if flag_spots
          
    if not(isempty(spots_fit))
        
        %- Select spots which will be shown
        if     flag_spots == 1    %- Detected spots
            ind_plot_in      = logical(thresh.all);
            ind_plot_out     = not(thresh.all);
            ind_plot_out_man = not(thresh.all);
            
        elseif flag_spots == 2   %- Thresholded spots
            ind_plot_in      = logical(thresh.in_display);
            ind_plot_out     = not(thresh.in_display);
            ind_plot_out_man = thresh.in == -1 ;    % Manually removed in spot inspector
        end
        
        %- Plot spots        
        %  Add one pixel since image starts at one and detected spots at pixel
        global h_out h_out_man h_in
        if ~ isempty(img_plot)        
            hold on
                h_out     = plot((spots_fit(ind_plot_out,col_par.pos_x)/pixel_size.xy + 1),     (spots_fit(ind_plot_out,col_par.pos_y)/pixel_size.xy +1)    ,'ob','MarkerSize',10);
                h_out_man = plot((spots_fit(ind_plot_out_man,col_par.pos_x)/pixel_size.xy + 1), (spots_fit(ind_plot_out_man,col_par.pos_y)/pixel_size.xy +1),'om','MarkerSize',10);
                h_in      = plot((spots_fit(ind_plot_in,col_par.pos_x)/pixel_size.xy  + 1) ,    (spots_fit(ind_plot_in,col_par.pos_y)/pixel_size.xy +1)     ,'og','MarkerSize',10);
            hold off
        else
            hold on
                h_out     = plot((spots_fit(ind_plot_out,col_par.pos_x)/pixel_size.xy + 1),     (spots_fit(ind_plot_out,col_par.pos_y)/pixel_size.xy +1)    ,'.b');
                h_out_man = plot((spots_fit(ind_plot_out_man,col_par.pos_x)/pixel_size.xy + 1), (spots_fit(ind_plot_out_man,col_par.pos_y)/pixel_size.xy +1),'.m');
                h_in      = plot((spots_fit(ind_plot_in,col_par.pos_x)/pixel_size.xy  + 1) ,    (spots_fit(ind_plot_in,col_par.pos_y)/pixel_size.xy +1)     ,'.g');
            hold off
        end
   
        title(['Spots Detected ', num2str(length(ind_plot_in ))],'FontSize',9); 
        colormap(hot)
        freezeColors(gca)
        
        
        if sum(ind_plot_in) && sum(ind_plot_out) && sum(ind_plot_out_man) 
            legend('Rejected Spots','Rejected Spots [man]','Selected Spots');  
        elseif sum(ind_plot_in) && sum(ind_plot_out) && not(sum(ind_plot_out_man))   
            legend('Rejected Spots','Selected Spots');  
        elseif not(sum(ind_plot_in)) && sum(ind_plot_out) && not(sum(ind_plot_out_man))   
            legend('Rejected Spots'); 
         elseif not(sum(ind_plot_in)) && not(sum(ind_plot_out)) && (sum(ind_plot_out_man))   
            legend('Rejected Spots [man]');    
        elseif sum(ind_plot_in) && not(sum(ind_plot_out)) && not(sum(ind_plot_out_man)) 
            legend('Selected Spots');
        end 
    end   
end

%- 3. Plot outline if specified
if flag_outline
    
    %- Plot outline of cell and TS
    hold on
    %if isfield(handles.img,'cell_prop')    
           
        if not(isempty(cell_prop))  
            for i_cell = 1:size(cell_prop,2)
                x = cell_prop(i_cell).x;
                y = cell_prop(i_cell).y;
                plot([x,x(1)],[y,y(1)],'b','Linewidth', 2)  
                            
                %- Nucleus
                pos_Nuc   = cell_prop(i_cell).pos_Nuc;   
                if not(isempty(pos_Nuc))  
                    for i_nuc = 1:size(pos_Nuc,2)
                        x = pos_Nuc(i_nuc).x;
                        y = pos_Nuc(i_nuc).y;
                        plot([x,x(1)],[y,y(1)],':b','Linewidth', 2)  
                   end                
                end                    
                
                %- TS
                pos_TS   = cell_prop(i_cell).pos_TS;   
                if not(isempty(pos_TS))  
                    for i_TS = 1:size(pos_TS,2)
                        x = pos_TS(i_TS).x;
                        y = pos_TS(i_TS).y;
                        plot([x,x(1)],[y,y(1)],'b','Linewidth', 2)  

                    end                
                end            
  
            end

            %- Plot selected cell in different color
            ind_cell = get(handles.pop_up_outline_sel_cell,'Value');
            x = cell_prop(ind_cell).x;
            y = cell_prop(ind_cell).y;
            plot([x,x(1)],[y,y(1)],'y','Linewidth', 2)  

            %- Nucleus
            pos_Nuc   = cell_prop(ind_cell).pos_Nuc;   
            if not(isempty(pos_Nuc))  
                for i_nuc = 1:size(pos_Nuc,2)
                    x = pos_Nuc(i_nuc).x;
                    y = pos_Nuc(i_nuc).y;
                    plot([x,x(1)],[y,y(1)],':y','Linewidth', 2)  
               end                
            end           
            
            %- TS
            pos_TS   = cell_prop(ind_cell).pos_TS;   
            if not(isempty(pos_TS))  
                for i = 1:size(pos_TS,2)
                    x = pos_TS(i).x;
                    y = pos_TS(i).y;
                    plot([x,x(1)],[y,y(1)],'g','Linewidth', 2)  
            
                end                
            end            
        end        
    %end
    hold off
    
end
    

%=== Plot-histogram of all values
function handles = plot_hist_all(handles,axes_select,values_for_th)

ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;

if isempty(axes_select)
    figure
    hist(values_for_th,25); 
    v = axis;
    hold on
         plot([thresh.min_th thresh.min_th] , [0 1e5],'r');
         plot([thresh.max_th thresh.max_th] , [0 1e5],'r');
    hold off
    axis(v);
    colormap jet; 
    
% Handles for min and max line are returned for slider callback function    
else
    axes(axes_select); 
    hist(values_for_th,25); 
    h = findobj(axes_select);
    v = axis;
    hold on
         handles.h_hist_min = plot([thresh.min_th thresh.min_th] , [0 1e5],'r');
         handles.h_hist_max = plot([thresh.max_th thresh.max_th] , [0 1e5],'r');
    hold off
    axis(v);
    colormap jet;
    freezeColors;
    set(h,'ButtonDownFcn',@axes_histogram_all_ButtonDownFcn);   % Button-down function has to be set again
end
 
title(strcat('Total # of spots: ',sprintf('%d' ,length(thresh.in) )),'FontSize',9);    
    

%=== Plot-histogram of thresholded parameters
function handles = plot_hist_th(handles,axes_select,values_for_th)

ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;

if isempty(axes_select)
    figure
    hist(values_for_th(handles.thresh.in_display),25); 
    v = axis;
    hold on
         plot([thresh.min_th thresh.min_th] , [0 1e5],'r');
         plot([thresh.max_th thresh.max_th] , [0 1e5],'r');
    hold off
    axis(v);
    colormap jet; 
    
% Handles for min and max line are returned for slider callback function    
else
    axes(axes_select); 
    hist(values_for_th(thresh.in_display),25); 
    h = findobj(axes_select);
    v = axis;
    hold on
         handles.h_hist_th_min = plot([thresh.min_th thresh.min_th] , [0 1e5],'r');
         handles.h_hist_th_max = plot([thresh.max_th thresh.max_th] , [0 1e5],'r');
    hold off
    axis(v);
    colormap jet;
    freezeColors;
    set(h,'ButtonDownFcn',@axes_histogram_th_ButtonDownFcn);   % Button-down function has to be set again
end
    
title(strcat('Selected # of spots:',sprintf(' %d' ,sum(thresh.in_display) )),'FontSize',9);     


%=== Projection in xy
function plot_proj_xy(handles,axes_select)

ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;
spots_proj = handles.img.cell_prop(ind_cell).spots_proj;

%- Show mosaic only if there are fewer than 1000 spots
if length(thresh.in == 1) < 1000

    %- Plot only if data is present
    if sum(spots_proj.xy(:))
        if isempty(axes_select)
            figure
            montage(spots_proj.xy(:,:,:,thresh.in == 1),'DisplayRange', []);    
            set(gcf,'Position', [300   300   500   400])       
            set(gca,'Units','normalized')
            set(gca,'Position', [0.1   0.1   0.8   0.8])
            colormap(jet);
        else
            axes(axes_select);
            h = montage(spots_proj.xy(:,:,:,thresh.in_display),'DisplayRange', []);
            set(h,'ButtonDownFcn',@axes_proj_xy_ButtonDownFcn);   % Button-down function has to be set again
            colormap(jet);
            freezeColors;
        end
        title('Max-projection XY','FontSize',9)  
    else
       set(handles.axes_proj_xy,'Visible','off');     
    end
end  

%=== Projection in xz
function plot_proj_xz(handles,axes_select)

ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;
spots_proj = handles.img.cell_prop(ind_cell).spots_proj;

%- Show mosaic only if there are fewer than 1000 spots
if length(thresh.in == 1) < 1000

    %- Plot only if data is present
    if sum(spots_proj.xz(:))  
        if isempty(axes_select)
            figure
            montage(spots_proj.xz(:,:,:,thresh.in == 1),'DisplayRange', []);    
            set(gcf,'Position', [300   300   500   400])       
            set(gca,'Units','normalized')
            set(gca,'Position', [0.1   0.1   0.8   0.8])
            colormap(jet);
        else
            axes(axes_select);
            h = montage(spots_proj.xz(:,:,:,thresh.in_display),'DisplayRange', []);
            set(h,'ButtonDownFcn',@axes_proj_xz_ButtonDownFcn);   % Button-down function has to be set again
            colormap(jet);
            freezeColors;
        end
        title('Max-projection XZ','FontSize',9) 
    else
       set(handles.axes_proj_xz,'Visible','off');     
    end
end

%=== Residuals in xy
function plot_resid_xy(handles,axes_select)

ind_cell   = get(handles.pop_up_outline_sel_cell,'Value');
thresh     = handles.img.cell_prop(ind_cell).thresh;
spots_proj = handles.img.cell_prop(ind_cell).spots_proj;

%- Show mosaic only if there are fewer than 1000 spots
if length(thresh.in == 1) < 1000
    
    %- Plot only if data is present
    if isfield(spots_proj,'res_xy')
        if sum(spots_proj.res_xy(:))     
            if isempty(axes_select)
                figure
                montage(spots_proj.res_xy(:,:,:,thresh.in == 1),'DisplayRange', []);    
                set(gcf,'Position', [300   300   500   400])       
                set(gca,'Units','normalized')
                set(gca,'Position', [0.1   0.1   0.8   0.8])
                colormap(jet);    
            else
                axes(axes_select);
                h_xy = montage(spots_proj.res_xy(:,:,:,thresh.in_display),'DisplayRange', []);
                set(h_xy,'ButtonDownFcn',@axes_resid_xy_ButtonDownFcn);   % Button-down function has to be set again
                colormap(jet);
                freezeColors;
            end
            title('RESID: Max-proj XY','FontSize',9)
        else
            set(handles.axes_resid_xy,'Visible','off');       
        end    
    else
       set(handles.axes_resid_xy,'Visible','off');     
    end
end



%==========================================================================
%===  Functions for double clicks on plots 


%=== 2D plot
function axes_image_ButtonDownFcn(hObject, eventdata, handles)
sel_type = get(gcf,'selectiontype');    % Normal for single click, Open for double click
   
if strcmp(sel_type,'open')
    handles = guidata(hObject);        % Appears that handles are not always input parameter for function call
    plot_image(handles,[]);
end


%=== Projections in xy
function axes_proj_xy_ButtonDownFcn(hObject, eventdata, handles)
sel_type = get(gcf,'selectiontype');    % Normal for single click, Open for double click
    
if strcmp(sel_type,'open')
    handles = guidata(hObject);        % Appears that handles are not always input parameter for function call
    plot_proj_xy(handles,[]);
end


%=== Projections in xy
function axes_proj_xz_ButtonDownFcn(hObject, eventdata, handles)
sel_type = get(gcf,'selectiontype');    % Normal for single click, Open for double click
    
if strcmp(sel_type,'open')
    handles = guidata(hObject);        % Appears that handles are not always input parameter for function call
    plot_proj_xz(handles,[]);
end


%=== Residuals
function axes_resid_xy_ButtonDownFcn(hObject, eventdata, handles)
sel_type = get(gcf,'selectiontype');    % Normal for single click, Open for double click
    
if strcmp(sel_type,'open')
    handles = guidata(hObject);        % Appears that handles are not always input parameter for function call
    plot_resid_xy(handles,[]);
end


%=== Histogram
function axes_histogram_all_ButtonDownFcn(hObject, eventdata, handles)
sel_type = get(gcf,'selectiontype');    % Normal for single click, Open for double click
    
if strcmp(sel_type,'open')
    handles = guidata(hObject);        % Appears that handles are not always input parameter for function call
    plot_hist_all(handles,[]);
end


%=== Thresholded histogram
function axes_histogram_th_ButtonDownFcn(hObject, eventdata, handles)
sel_type = get(gcf,'selectiontype');    % Normal for single click, Open for double click
    
if strcmp(sel_type,'open')
    handles = guidata(hObject);        % Appears that handles are not always input parameter for function call
    plot_hist_th(handles,[]);
end


%==========================================================================
%===  Various calls of the plot functions


%==== Plot function within GUI
function button_plot_image_Callback(hObject, eventdata, handles)
plot_image(handles,handles.axes_image);


%=== Show figures in Matlab
function button_visualize_matlab_Callback(hObject, eventdata, handles)

global image_struct    

%== Select visualization open
vis_sel_str = get(handles.popup_vis_sel,'String');
vis_sel_val = get(handles.popup_vis_sel,'Value');
    
switch vis_sel_str{vis_sel_val}

    case 'Spot inspector'        
       FISH_QUANT_spots('HandlesMainGui',handles);  


    case 'ImageJ'        

        MIJ_start(hObject, eventdata, handles)
        
        %- Get path of image
        if not(isempty(handles.img.path_names.img))
           path_image = handles.img.path_names.img;
        elseif not(isempty(handles.img.path_names.root))
           path_image = handles.img.path_names.root; 
        end

        % Generate temporary result file
        file_name_temp                      = fullfile(path_image,'FQ_results_tmp.txt');
        parameters.cell_prop                = handles.img.cell_prop;
        parameters.par_microscope           = handles.par_microscope;
        parameters.path_names_image         = path_image;
        parameters.file_names.raw           = handles.img.file_names;
        parameters.path_save                = path_image;
        parameters.flag_type                = 'spots';
        
        FQ_save_results_v1(file_name_temp,parameters);                

        %- Call macro
        ij.IJ.runMacroFile(handles.imagej_macro_name,file_name_temp);                   
end


%== Change settings for rendering
function menu_settings_rendering_Callback(hObject, eventdata, handles)
handles.settings_rendering = FQ_change_setting_VTK_v1(handles.settings_rendering);
status_update(hObject, eventdata, handles,{'  ';'## Settings for RENDERING are modified'});         
guidata(hObject, handles);


%=== Menu: averaged spot
function Menu_averaged_spot_Callback(hObject, eventdata, handles)
if exist('Miji')
    set(handles.menu_spot_avg_imagej,'Enable', 'off')
end


%=== Menu: show averaged spot with normal sampling in ImageJ
function menu_spot_avg_imagej_ns_Callback(hObject, eventdata, handles)
MIJ_start(hObject, eventdata, handles)
ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
MIJ.createImage('Matlab: PSF with normal sampling', uint32(handles.img.spot_avg),1);    


%=== Menu: show averaged spot with over-sampling in ImageJ
function menu_spot_avg_imagej_os_Callback(hObject, eventdata, handles)
MIJ_start(hObject, eventdata, handles)
ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
MIJ.createImage('Matlab: over-sampled PSF', uint32(handles.img.spot_avg_os),1);    


%=== Menu: show radial averaged curve in ImageJ
function menu_spot_avg_imagej_radial_Callback(hObject, eventdata, handles)
MIJ_start(hObject, eventdata, handles)
ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
MIJ.createImage('Matlab: radial PSF', uint32(handles.img.cell_prop(ind_cell).psf_radial_bin_os),1);    


%= Function to start MIJ
function MIJ_start(hObject, eventdata, handles)
if isfield(handles,'flag_MIJ')
    if handles.flag_MIJ == 0
       Miji;                          % Start MIJ/ImageJ by running the Matlab command: MIJ.start("imagej-path")
       handles.flag_MIJ = 1;       
    end
else
   Miji;                          % Start MIJ/ImageJ by running the Matlab command: MIJ.start("imagej-path")
   handles.flag_MIJ = 1;
end
guidata(hObject, handles);


%= Function to start MIJ
function menu_restart_imagej_Callback(hObject, eventdata, handles)
if handles.flag_MIJ == 1
    MIJ.exit;
    MIJ_start(hObject, eventdata, handles);
else
    MIJ_start(hObject, eventdata, handles);  
end


%==========================================================================
%==== Tools
%==========================================================================

%== Cell segmentation
function menu_segmentation_Callback(hObject, eventdata, handles)
if ~isempty(handles.img.path_names.root)
    cd(handles.img.path_names.root)
end
FQ_seg;

%== Batch filtering 
function menu_batch_filter_Callback(hObject, eventdata, handles)
global FQ_main_folder par_microscope_FQ settings_filter_FQ
FQ_main_folder.root    =  handles.img.path_names.root;
FQ_main_folder.results =  handles.img.path_names.results;
FQ_main_folder.image   =  handles.img.path_names.img;
FQ_main_folder.outline =  handles.img.path_names.outlines;

par_microscope_FQ  = handles.par_microscope;
settings_filter_FQ = handles.filter;

FISH_QUANT_batch_filter


%== Outline editor
function menu_outline_Callback(hObject, eventdata, handles)
par_main.path_names     = handles.img.path_names;
par_main.par_microscope = handles.img.par_microscope;
FISH_QUANT_outline('par_main',par_main);


%== Batch mode
function menu_batch_Callback(hObject, eventdata, handles)

global FQ_main_folder
FQ_main_folder.root    =  handles.img.path_names.root;
FQ_main_folder.results =  handles.img.path_names.results;
FQ_main_folder.image   =  handles.img.path_names.img;
FQ_main_folder.outline =  handles.img.path_names.outlines;

FISH_QUANT_batch


%== Spot inspector
function menu_spot_inspector_Callback(hObject, eventdata, handles)

par_main.par_microscope = handles.img.par_microscope;
par_main.path_names     = handles.img.path_names;
drawnow
FISH_QUANT_spots('par_main',par_main);


%== Transcription site quantification
function menu_TxSite_quant_Callback(hObject, eventdata, handles)
FISH_QUANT_TxSite('HandlesMainGui',handles);


%== List directory
function menu_list_directory_Callback(hObject, eventdata, handles)
par_main.par_microscope = handles.img.par_microscope;
par_main.path_names     = handles.img.path_names;

%- Get current directory and go to directory with images
if not(isempty(handles.img.path_names.root))
   path_name = handles.img.path_names.img;
elseif not(isempty(handles.img.path_names.outlines))
   path_name = handles.img.path_names.outlines;
else
   path_name = pwd; 
end

FISH_QUANT_list_folder(par_main,path_name);


%== Create outlines in second color
function menu_outlines_2nd_Callback(hObject, eventdata, handles)
FQ_OutlineSecond;


%== Batch processing - folders
function menu_batch_folders_Callback(hObject, eventdata, handles)
%FISH_QUANT_batch_folder


%==========================================================================
%==== Various Features
%==========================================================================

%== Parallel computing
function checkbox_parallel_computing_Callback(hObject, eventdata, handles)

flag_parallel = get(handles.checkbox_parallel_computing,'Value');

if exist('gcp','file')

    %- Parallel computing - open MATLAB session for parallel computation 
    if flag_parallel == 1    
        
        p = gcp('nocreate'); % If no pool, do not create new one.

        if isempty(p)
            
            %- Update status
            set(handles.h_fishquant,'Pointer','watch');
            status_text = {' ';'== STARTING matlabpool for parallel computing ... please wait ... '};
            status_update(hObject, eventdata, handles,status_text);

            parpool;

            %- Update status
            status_text = {' ';'    ... STARTED'};
            status_update(hObject, eventdata, handles,status_text);        
            set(handles.h_fishquant,'Pointer','arrow');
        end

    %- Parallel computing - close MATLAB session for parallel computation     
    else
        
        p = gcp('nocreate'); % If no pool, do not create new one.
        
        if ~isempty(p)
            
            %- Update status
            set(handles.h_fishquant,'Pointer','watch');
            status_text = {' ';'== STOPPING matlabpool for parallel computing ... please wait ... '};
            status_update(hObject, eventdata, handles,status_text);

            delete(p)

            %- Update status
            status_text = {' ';'    ... STOPPED'};
            status_update(hObject, eventdata, handles,status_text);
            set(handles.h_fishquant,'Pointer','arrow');
        end
    end
    
else
    warndlg('Parallel toolbox not available','FISH_QUANT')
    set(handles.checkbox_parallel_computing,'Value',0);
end

%== Change fit mode
function checkbox_fit_fixed_width_Callback(hObject, eventdata, handles)
val_check = get(handles.checkbox_fit_fixed_width,'Value');
handles.flag_fit = val_check;
guidata(hObject, handles);


%== Close all windows except GUI
function menu_close_windows_Callback(hObject, eventdata, handles)


%- Find all figure handles and delete the one of the GUI
fh    =  findall(0,'Type','Figure');
fh(fh == handles.h_fishquant) = [];

if evalin('base', 'exist(''h_batch'',''var'')');
    h_batch = evalin('base', 'h_batch');
    fh(fh == h_batch) = [];
end

if evalin('base', 'exist(''h_outline'',''var'')');
    h_outline = evalin('base', 'h_outline');
    fh(fh == h_outline) = [];
end

if evalin('base', 'exist(''h_spots'',''var'')');
    h_spots = evalin('base', 'h_spots');
    fh(fh == h_spots) = [];
end

if evalin('base', 'exist(''h_predetect'',''var'')');
    h_spots = evalin('base', 'h_predetect');
    fh(fh == h_spots) = [];
end

if evalin('base', 'exist(''h_TxSite'',''var'')');
    h_spots = evalin('base', 'h_TxSite');
    fh(fh == h_spots) = [];
end

if evalin('base', 'exist(''h_batch_filter'',''var'')');
    h_spots = evalin('base', 'h_batch_filter');
    fh(fh == h_spots) = [];
end


%== Reset GUI to starting values
function menu_GUI_reset_Callback(hObject, eventdata, handles)
button = questdlg('Are you sure that you want to reset the GUI?','RESET GUI','Yes','No','No');

global FQ_open
if strcmp(button,'Yes')    
    FQ_open = 0;
    FISH_QUANT_OpeningFcn(hObject, eventdata, handles);    
end


%=== Pop-up to select which estimates should be shown
function pop_up_select_psf_Callback(hObject, eventdata, handles)

PSF_exp = handles.img.PSF_exp;      
    
%- Thresholding parameter
str = get(handles.pop_up_select_psf,'String');
val = get(handles.pop_up_select_psf,'Value');
popup_parameter = str{val};


switch (popup_parameter)
    
    case 'All spots'           

        set(handles.text_psf_fit_sigmaX,'String', num2str(PSF_exp.sigmax_all,'%.0f'));
        set(handles.text_psf_fit_sigmaY,'String', num2str(PSF_exp.sigmay_all,'%.0f'));
        set(handles.text_psf_fit_sigmaZ,'String', num2str(PSF_exp.sigmaz_all,'%.0f'));
        set(handles.text_psf_fit_amp,'String',    num2str(PSF_exp.amp_all,'%.0f'));
        set(handles.text_psf_fit_bgd,'String',    num2str(PSF_exp.bgd_all,'%.0f'));

        disp(' ')
        disp('FIT TO 3D GAUSSIAN: avg of ALL spots ')
        disp(['Sigma (xy): ', num2str(round(PSF_exp.sigmax_all)), ' +/- ', num2str(round(PSF_exp.sigmax_all_std))])
        disp(['Sigma (z) : ', num2str(round(PSF_exp.sigmaz_all)), ' +/- ', num2str(round(PSF_exp.sigmaz_all_std))])
        disp(['Amplitude : ', num2str(round(PSF_exp.amp_all)), ' +/- ', num2str(round(PSF_exp.amp_all_std))])
        disp(['BGD       : ', num2str(round(PSF_exp.bgd_all)), ' +/- ', num2str(round(PSF_exp.bgd_all_std))])
        disp(' ')

        
    case 'Thresholded'
                
        set(handles.text_psf_fit_sigmaX,'String', num2str(PSF_exp.sigmax_th,'%.0f'));
        set(handles.text_psf_fit_sigmaY,'String', num2str(PSF_exp.sigmay_th,'%.0f'));
        set(handles.text_psf_fit_sigmaZ,'String', num2str(PSF_exp.sigmaz_th,'%.0f'));
        set(handles.text_psf_fit_amp,'String',    num2str(PSF_exp.amp_th,'%.0f'));
        set(handles.text_psf_fit_bgd,'String',    num2str(PSF_exp.bgd_th,'%.0f'));  

        disp(' ')
        disp('FIT TO 3D GAUSSIAN: avg of ALL spots ')
        disp(['Sigma (xy): ', num2str(round(PSF_exp.sigmax_th)), ' +/- ', num2str(round(PSF_exp.sigmax_th_std))])
        disp(['Sigma (z) : ', num2str(round(PSF_exp.sigmaz_th)), ' +/- ', num2str(round(PSF_exp.sigmaz_th_std))])
        disp(['Amplitude : ', num2str(round(PSF_exp.amp_th)), ' +/- ', num2str(round(PSF_exp.amp_th_std))])
        disp(['BGD       : ', num2str(round(PSF_exp.bgd_th)), ' +/- ', num2str(round(PSF_exp.bgd_th_std))])
        disp(' ')

                
    case 'Averaged spot'
        
        set(handles.text_psf_fit_sigmaX,'String', num2str(PSF_exp.sigmax_avg,'%.0f'));
        set(handles.text_psf_fit_sigmaY,'String', num2str(PSF_exp.sigmay_avg,'%.0f'));
        set(handles.text_psf_fit_sigmaZ,'String', num2str(PSF_exp.sigmaz_avg,'%.0f'));
        set(handles.text_psf_fit_amp,'String',    num2str(PSF_exp.amp_avg,'%.0f'));
        set(handles.text_psf_fit_bgd,'String',    num2str(PSF_exp.bgd_avg,'%.0f'));   
     
end


%=== Manually change PSF-X
function text_psf_fit_sigmaX_Callback(hObject, eventdata, handles)
handles.par_fit.sigma_XY_fixed = str2double(get(handles.text_psf_fit_sigmaX,'String'));
set(handles.text_psf_fit_sigmaY,'String',handles.par_fit.sigma_XY_fixed);
guidata(hObject, handles);

set(handles.pop_up_select_psf,'Value',4);
FQ_enable_controls_v1(handles)


%=== Manually change PSF-Y
function text_psf_fit_sigmaY_Callback(hObject, eventdata, handles)
handles.par_fit.sigma_XY_fixed = str2double(get(handles.text_psf_fit_sigmaY,'String'));
set(handles.text_psf_fit_sigmaX,'String',handles.par_fit.sigma_XY_fixed);
guidata(hObject, handles);

set(handles.pop_up_select_psf,'Value',4);
FQ_enable_controls_v1(handles)


%=== Manually change PSF-Z
function text_psf_fit_sigmaZ_Callback(hObject, eventdata, handles)
handles.par_fit.sigma_Z_fixed = str2double(get(handles.text_psf_fit_sigmaZ,'String'));
guidata(hObject, handles);

set(handles.pop_up_select_psf,'Value',4);
FQ_enable_controls_v1(handles)


%== Update status
function status_update(hObject, eventdata, handles,status_text)
status_old = get(handles.list_box_status,'String');
status_new = [status_old;status_text];
set(handles.list_box_status,'String',status_new)
set(handles.list_box_status,'ListboxTop',round(size(status_new,1)))
drawnow
guidata(hObject, handles); 


%== Close GUI
function h_fishquant_CloseRequestFcn(hObject, eventdata, handles)
button = questdlg('Are you sure that you want to close the GUI?','CLOSE GUI','Yes','No','No');

if strcmp(button,'Yes')    
   delete(hObject);   
   clear global image_struct FQ_open

end


%== CellC - cell counter
function menu_cellC_Callback(hObject, eventdata, handles)
cellc


%==========================================================================
%==== MENU
%==========================================================================

%== MENU
function menu_loadSave_Callback(hObject, eventdata, handles)
if isfield(handles,'pos_cell')
    set(handles.menu_save_outline,'Enable','on')
end

%- Export spots
if not(isempty(handles.img.cell_prop))
    ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
    spots_fit = handles.img.cell_prop(ind_cell).spots_fit;
    if not(isempty(spots_fit))
        set(handles.menu_save_spots,'Enable','on')
        set(handles.menu_save_spots_th,'Enable','on')
        
    else
        set(handles.menu_save_spots,'Enable','off')   
        set(handles.menu_save_spots_th,'Enable','off')   
        
    end
else
    set(handles.menu_save_spots,'Enable','off')
    set(handles.menu_save_spots_th,'Enable','off')
end

%== Display help file
function menu_help_show_help_file_Callback(hObject, eventdata, handles)
dir_FQ = fileparts(which(mfilename));
file_name_pdf = 'FISH_QUANT_v3.pdf'; 

%- Replacement for development version
dir_doc = strrep(dir_FQ,'GUI','Documentation');

%- This is for the compiled version
if strcmp(dir_doc,dir_FQ);
    dir_doc = fullfile(dir_FQ,'Documentation');
end
open(fullfile(dir_doc,file_name_pdf))


%== Menu about FISH-quant
function menu_about_Callback(hObject, eventdata, handles)
dir_FQ = fileparts(which(mfilename));

if exist(fullfile(dir_FQ,'FQ_version.txt'))
    
    %- Open file
    fid  =  fopen(fullfile(dir_FQ,'FQ_version.txt'),'r');

    if fid == -1; return; end

    dum      = fgetl(fid);
    str_date = fgetl(fid);
    str_time = fgetl(fid);
    fclose(fid);
    
    msgbox({'Compilation information          ' ['Date ',str_date] ['Time ',str_time]},'FISH-quant           ','help');
    
end
    
%== Change between 2D and 3D detection
function menu_sett_2D_Callback(hObject, eventdata, handles)

%- Get current status
if handles.img.status_3D 
    text_status = '3D';
else
    text_status = '2D';
end

% Construct a questdlg with three options
choice = questdlg('Should the analysis be performed in 2D or 3D?', 'FISH-quant','2D', '3D',text_status);

switch choice
    case '2D'
        handles.img.status_3D = 0;
        handles.img.settings.detect.flags.region_smaller = 1;
        display('FISH-quant - analysis will be performed in 2D');
            
    case '3D'
        handles.img.status_3D = 1;
        display('FISH-quant - analysis will be performed in 3D');
end
guidata(hObject, handles); 


% ===== CREATE FUNCTIONS and CALL BACKS with no additional code
function menu_spot_avg_imagej_Callback(hObject, eventdata, handles)
    
function text_psf_theo_xy_Callback(hObject, eventdata, handles)

function text_psf_theo_z_Callback(hObject, eventdata, handles)

function pop_up_exp_default_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_psf_theo_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%    set(hObject,'BackgroundColor','white');
end

function text_psf_theo_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
 %   set(hObject,'BackgroundColor','white');
end

function text_TS_size_xy_Callback(hObject, eventdata, handles)

function text_TS_size_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_TS_size_z_Callback(hObject, eventdata, handles)

function text_TS_size_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_detect_quality_Callback(hObject, eventdata, handles)

function pop_up_detect_quality_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detect_region_xy_Callback(hObject, eventdata, handles)

function text_detect_region_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detect_region_z_Callback(hObject, eventdata, handles)

function text_detect_region_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_bgd_xy_Callback(hObject, eventdata, handles)

function text_kernel_bgd_xy_CreateFcn(hObject, eventdata, handles)
 if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_bgd_xy_Callback(hObject, eventdata, handles)

function text_kernel_factor_bgd_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_filter_xy_Callback(hObject, eventdata, handles)

function text_kernel_filter_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_filter_xy_Callback(hObject, eventdata, handles)

function text_kernel_factor_filter_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_th_min_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_th_max_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function slider_th_min_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_th_max_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function checkbox_th_lock_max_Callback(hObject, eventdata, handles)

function pop_up_imagej_style_Callback(hObject, eventdata, handles)

function pop_up_imagej_style_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_imagej_1st_Callback(hObject, eventdata, handles)

function pop_up_imagej_1st_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_imagej_2nd_Callback(hObject, eventdata, handles)

function pop_up_imagej_2nd_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function button_save_Callback(hObject, eventdata, handles)

function pop_up_save_Callback(hObject, eventdata, handles)

function pop_up_save_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function menu_help_Callback(hObject, eventdata, handles)

function menu_load_Callback(hObject, eventdata, handles)

function menu_save_Callback(hObject, eventdata, handles)

function edit15_Callback(hObject, eventdata, handles)

function text_psf_fit_sigmaX_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_psf_fit_sigmaY_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_psf_fit_sigmaZ_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_psf_fit_bgd_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function menu_test_settings_Callback(hObject, eventdata, handles)

function test_settings_load_image_Callback(hObject, eventdata, handles)

function test_settings_load_outline_Callback(hObject, eventdata, handles)

function test_settings_run_Callback(hObject, eventdata, handles)

function edit20_Callback(hObject, eventdata, handles)

function edit20_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detection_threshold_Callback(hObject, eventdata, handles)

function text_detection_threshold_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_image_select_Callback(hObject, eventdata, handles)

function pop_up_image_select_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_th_min_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_image_spots_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_th_low_Callback(hObject, eventdata, handles)

function text_psf_fit_amp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_avg_size_xy_Callback(hObject, eventdata, handles)

function text_avg_size_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_avg_size_z_Callback(hObject, eventdata, handles)

function text_avg_size_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_fact_os_xy_Callback(hObject, eventdata, handles)

function text_fact_os_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_fact_os_z_Callback(hObject, eventdata, handles)

function text_fact_os_z_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_select_psf_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Menu_export_handles_Callback(hObject, eventdata, handles)

function pop_up_outline_sel_cell_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_plot_outline_Callback(hObject, eventdata, handles)

function pop_up_image_spots_Callback(hObject, eventdata, handles)

function button_outline_clear_Callback(hObject, eventdata, handles)

function menu_tools_Callback(hObject, eventdata, handles)

function list_box_status_Callback(hObject, eventdata, handles)

function list_box_status_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_proc_all_cells_Callback(hObject, eventdata, handles)

function menu_TS_Callback(hObject, eventdata, handles)

function pushbutton30_Callback(hObject, eventdata, handles)

function popup_vis_sel_Callback(hObject, eventdata, handles)

function popup_vis_sel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Untitled_1_Callback(hObject, eventdata, handles)

function menu_spot_avg_save_Callback(hObject, eventdata, handles)

function Untitled_3_Callback(hObject, eventdata, handles)

function text_min_dist_spots_Callback(hObject, eventdata, handles)

function text_min_dist_spots_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_bgd_z_Callback(hObject, eventdata, handles)

function text_kernel_factor_bgd_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_filter_z_Callback(hObject, eventdata, handles)

function text_kernel_factor_filter_z_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_filter_type_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
