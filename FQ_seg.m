function varargout = FQ_seg(varargin)
% FQ_seg MATLAB code for FQ_seg.fig
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FQ_seg

% Last Modified by GUIDE v2.5 10-Oct-2016 11:03:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FQ_seg_OpeningFcn, ...
                   'gui_OutputFcn',  @FQ_seg_OutputFcn, ...
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

% --- Executes just before FQ_seg is made visible.
function FQ_seg_OpeningFcn(hObject, eventdata, handles, varargin)


%- Get installation directory of FISH-QUANT and initiate 
p               = mfilename('fullpath');        
handles.FQ_path = fileparts(p);
handles.status_par_def  = 0;
handles.status_par2_def = 0;

handles.status_img           = 0;
handles.status_img_outline   = 0;
handles.status_store_results = 0;

%- Load default settings
settings_load  = FQ_load_settings_v1(fullfile(handles.FQ_path,'FISH-QUANT_default_par.txt'),{});

if isfield(settings_load,  'par_microscope');
    handles.par_microscope    = settings_load.par_microscope;
    handles.par_microscope_c2 = settings_load.par_microscope;
end
    
%== Initialize Bioformats
[status, ver_bf] = bfCheckJavaPath(1);
disp(['Bio-Formats ',ver_bf,' will be used.'])

% Choose default command line output for FQ_seg
handles.output = hObject;

% Update handles structure
enable_controls(hObject, eventdata, handles); 
guidata(hObject, handles);

% UIWAIT makes FQ_seg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FQ_seg_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


%==========================================================================
% Diverse functions for general control of the GUI
%==========================================================================

%=== Enable controls
function enable_controls(hObject, eventdata, handles) 


%---------- PROJECTION

%- Only one focus measurement can be enabled
status_z_proj = get(handles.check_project_local,'Value');

if status_z_proj
    
    %- Local projection
    set(handles.popup_proj_local_operator,'enable','on')
    set(handles.txt_proj_local_window,'enable','on')
    set(handles.popup_proj_local_method,'enable','on')
    set(handles.txt_proj_local_N_slices,'enable','on')
    
    %- Standard projection
    set(handles.popup_proj_standard_method,'enable','off')
    
else
    
    %- Local projection
    set(handles.popup_proj_local_operator,'enable','off')
    set(handles.txt_proj_local_window,'enable','off')
    set(handles.popup_proj_local_method,'enable','off')
    set(handles.txt_proj_local_N_slices,'enable','off')
    
    %- Standard projection
    set(handles.popup_proj_standard_method,'enable','on')
    
end

%- Loaded images
if handles.status_img
    set(handles.button_project,'enable','on')
else
    set(handles.button_project,'enable','off')
end


%- Stored results for inspection
if handles.status_store_results
    set(handles.show_result,'enable','on')
else
    set(handles.show_result,'enable','off')
end    



%---------- FQ outlines from CP

%- First parameters are defined
if handles.status_par_def
    set(handles.button_define_exp,'ForegroundColor','k');
else
    set(handles.button_define_exp,'ForegroundColor','r');
end
    

%- What's going on with the second color
check_2nd = get(handles.check_outline_2nd_color,'Value');

if ~check_2nd
    status_2nd = 1;
    set(handles.button_parameters_2nd,'ForegroundColor','k');
else
    if handles.status_par2_def 
        status_2nd = 1;
        set(handles.button_parameters_2nd,'ForegroundColor','k');
    else
        status_2nd = 0;
        set(handles.button_parameters_2nd,'ForegroundColor','r');
    end
end

%- What's going on with first channel
status_1st = 0;
status_make_1st = ~get(handles.check_outline_not_1st,'Value');

if  (~check_2nd && handles.status_par_def)      || ...         % Only 1st one and parameters are define
    (check_2nd && status_make_1st && handles.status_par_def)   % First and second color are made & parameters of first one are defined
    status_1st = 1;
end
    
    
%- Stored results for inspection
%  (i) Parameters have to be defined, 
%  (ii) status of 2nd color clarfied, 
%  (iii) images have to be defined
if status_1st && status_2nd && handles.status_img_outline
    set(handles.button_create_FQ_outlines,'enable','on')
else
    set(handles.button_create_FQ_outlines,'enable','off')
end    


%- Save handles
guidata(hObject, handles);

%== Enable/disable standard projection
function check_project_standard_Callback(hObject, eventdata, handles)

%- Only one focus measurement can be enabled
status_proj = get(handles.check_project_standard,'Value');

if status_proj
    set(handles.check_project_local,'Value',0);
else
    set(handles.check_project_local,'Value',1);
end

% Update handles structure
enable_controls(hObject, eventdata, handles); 
guidata(hObject, handles);

%== Enable/disable local projection
function check_project_local_Callback(hObject, eventdata, handles)

%- Only one focus measurement can be enabled
status_proj = get(handles.check_project_local,'Value');

if status_proj
    set(handles.check_project_standard,'Value',0);
else
    set(handles.check_project_standard,'Value',1);
end

% Update handles structure
enable_controls(hObject, eventdata, handles); 
guidata(hObject, handles);

%== Enable/disable controls for saving projections
function check_save_projections_Callback(hObject, eventdata, handles)

%- Only one focus measurement can be enabled
status_check = get(handles.check_save_projections,'Value');

if status_check
    set(handles.check_save_name_prefix,'Enable','on');
    set(handles.check_save_folder_same,'Enable','on');
    set(handles.check_save_folder_sub,'Enable','on');
    set(handles.check_save_folder_replace,'Enable','on');    
else
    set(handles.check_save_name_prefix,'Enable','off');
    set(handles.check_save_folder_same,'Enable','off');
    set(handles.check_save_folder_sub,'Enable','off');
    set(handles.check_save_folder_replace,'Enable','off');    
end
guidata(hObject, handles);


%== Checkbox for folders for saving
function check_save_folder_same_Callback(hObject, eventdata, handles)
status_check = get(handles.check_save_folder_same,'Value');
if status_check
    set(handles.check_save_folder_sub,'Value',0);
    set(handles.check_save_folder_replace,'Value',0);
       
    set(handles.check_save_name_prefix,'Value',1);
else
    set(handles.check_save_name_prefix,'Value',0);
    set(handles.check_save_folder_sub,'Value',1);
end


function check_save_folder_sub_Callback(hObject, eventdata, handles)
status_check = get(handles.check_save_folder_sub,'Value');
if status_check
    set(handles.check_save_folder_same,'Value',0);
end


function check_save_folder_replace_Callback(hObject, eventdata, handles)

status_check = get(handles.check_save_folder_replace,'Value');
if status_check
    set(handles.check_save_folder_same,'Value',0);     
end


%== Checkbox for folders for saving of outlines
function check_save_folder_outline_same_Callback(hObject, eventdata, handles)
status_check = get(handles.check_save_folder_outline_same,'Value');
if status_check
    set(handles.check_save_folder_outline_sub,'Value',0);
    set(handles.check_save_folder_outline_replace,'Value',0);
end

function check_save_folder_outline_sub_Callback(hObject, eventdata, handles)
status_check = get(handles.check_save_folder_outline_sub,'Value');
if status_check
    set(handles.check_save_folder_outline_same,'Value',0);
    set(handles.check_save_folder_outline_replace,'Value',0);
end

function check_save_folder_outline_replace_Callback(hObject, eventdata, handles)
status_check = get(handles.check_save_folder_outline_replace,'Value');
if status_check
    set(handles.check_save_folder_outline_sub,'Value',0);
    set(handles.check_save_folder_outline_same,'Value',0);
end


%== Checkbox to save 2nd color
function check_outline_2nd_color_Callback(hObject, eventdata, handles)
status_check = get(handles.check_outline_2nd_color,'Value');
if status_check
    set(handles.text_outline_img_FISH_2nd,'Enable','on');
    set(handles.check_outline_not_1st,'Enable','on');
    set(handles.button_parameters_2nd,'Enable','on');
else
    set(handles.text_outline_img_FISH_2nd,'Enable','off');
    set(handles.check_outline_not_1st,'Enable','off');
    set(handles.button_parameters_2nd,'Enable','off');

end
enable_controls(hObject, eventdata, handles)


%== Checkbox to save 1st color
function check_outline_not_1st_Callback(hObject, eventdata, handles)
status_check = get(handles.check_outline_not_1st,'Value');
if status_check
    set(handles.button_define_exp,'Enable','off');
else
    set(handles.button_define_exp,'Enable','on');
end

%==========================================================================
% Perform projection
%==========================================================================


% === Define images
function button_define_images_Callback(hObject, eventdata, handles)

%== Define images
[file_name_all,path_name] = uigetfile({'*.tif';'*.TIF';'*.STK';'*.stk'},'Select images','MultiSelect','on');

if ~iscell(file_name_all)
    dum=file_name_all;
    file_name_all={dum};
end

%- Progress if images are specified
if file_name_all{1} ~=0

    handles.files_proc.input_type = 'file';
    handles.files_proc.file_name_all = file_name_all;
    handles.files_proc.path_name     = path_name;
    
    %== Update handles structure
    handles.status_img = 1;
    enable_controls(hObject, eventdata, handles); 
    guidata(hObject, handles);
end


% === Define folder
function button_define_folder_Callback(hObject, eventdata, handles)

folder_name = uigetdir;

if folder_name ~= 0
    
    %== Get directory
    handles.files_proc.input_type = 'dir';
    handles.files_proc.path_scan = folder_name;
    
    %== Update handles structure
    handles.status_img = 1;
    enable_controls(hObject, eventdata, handles); 
    guidata(hObject, handles);
    
end


% === Perform projection
function button_project_Callback(hObject, eventdata, handles)

%-- Get parameter for slice-based focus measurement
sel_value  = get(handles.popup_slice_select_operator, 'Value');
sel_string = get(handles.popup_slice_select_operator,'String');
param.slice_select.operator = sel_string{sel_value};

param.slice_select.n_slices   = str2num(get(handles.txt_slice_select_number, 'String'));

%-- Projection type
status_proj_local = get(handles.check_project_local,'Value');

%- Get parameters for local focus projection 
if status_proj_local
    param.project.type = 'local';
    
    sel_value = get(handles.popup_proj_local_operator, 'Value');
    sel_string = get(handles.popup_proj_local_operator, 'String');    
    param.project.operator     = sel_string{sel_value};
    
    param.project.windows_size = str2num(get(handles.txt_proj_local_window, 'String'));

    sel_value = get(handles.popup_proj_local_method, 'Value');
    sel_string = get(handles.popup_proj_local_method, 'String');    
    param.project.method     = sel_string{sel_value};
 
    param.project.N_slice = str2num(get(handles.txt_proj_local_N_slices, 'String'));
    
%- Get parameter for standard projection    
else
    param.project.type = 'standard';
    
    sel_value  = get(handles.popup_proj_standard_method, 'Value');
    sel_string = get(handles.popup_proj_standard_method, 'String');
    param.project.method  = sel_string{sel_value};
end


%- Flags
param.flags.save  = get(handles.check_save_projections,'Value');
param.flags.show  = get(handles.check_show_results,'Value');
param.flags.store = get(handles.check_store_results,'Value');

if param.flags.save
    param.save.flag_prefix = get(handles.check_save_name_prefix,'Value');
    param.save.prefix      = get(handles.txt_save_name_prefix,'String'); 
    param.save.flag_folder   = ''; % Create but don't assign a value --> will be populated only if a choice will be made
    save_opt_specified       = 0;  % Check if at least one optino has been specified
    
    %- Same folder
    if get(handles.check_save_folder_same,'Value')
        save_opt_specified = 1;
        param.save.flag_folder = 'same';
    end
    
    %- Replace parts of the folder name
    if get(handles.check_save_folder_replace,'Value')
        save_opt_specified = 1;
        param.save.flag_folder   = 'replace';
        param.save.string_orig   = get(handles.txt_folder_replace_orig,'String');
        param.save.string_new    = get(handles.txt_folder_replace_new,'String');
    end
    
    %- Create subfolder
    if get(handles.check_save_folder_sub,'Value')
        save_opt_specified          = 1;
        param.save.stats_folder_sub = 1;
        param.save.name_sub         = get(handles.txt_save_folder_sub,'String');    
        
    else
        param.save.stats_folder_sub = 0;
    end
    
    %- Continue only if a folder has been specified
    if save_opt_specified == 0
        warndlg('No folder to save results has been specified. Specify before processing.','Z Projection')
        return
    end
    
end

%- Check if some files should be ignored
handles.files_proc.flag_ignore = get(handles.check_proj_ingnore_file,'Value');

if handles.files_proc.flag_ignore

    %- Split in individual strings
    handles.files_proc.name_ignore = strsplit(get(handles.txt_proj_ingnore_file,'String'),';');
end

%- Other parameters
handles.files_proc.img_ext = get(handles.txt_folder_img_extension,'String');
handles.files_proc.flag_folder_rec = get(handles.checkbox_folder_recursive,'Value');  %- Recursive check of folder or not

%- Call function to perform z-projection
proj_struct = FQ3_proj_z_v1(handles.files_proc,param);

if param.flags.store
    handles.status_store_results = 1;
    handles.proj_struct = proj_struct;
else
    handles.status_store_results = 0;
    handles.proj_struct = [];
end

%== Update handles structure
enable_controls(hObject, eventdata, handles); 
guidata(hObject, handles);


% === Show results of projection
function show_result_Callback(hObject, eventdata, handles)
 FQ_seg_show_results(handles.proj_struct )
 

% ==========================================================================
% ===== FQ outlines FROM  FROM CELL PROFILER RESULTS 
% ==========================================================================

%== Modify the experimental settings
function button_define_exp_Callback(hObject, eventdata, handles)
handles.par_microscope = define_par(handles.par_microscope);
handles.status_par_def = 1;
enable_controls(hObject, eventdata, handles); 
guidata(hObject, handles);


%== Modify the experimental settings
function button_parameters_2nd_Callback(hObject, eventdata, handles)
handles.par_microscope_c2 = define_par(handles.par_microscope_c2);
handles.status_par2_def = 1;
enable_controls(hObject, eventdata, handles); 
guidata(hObject, handles);


%== Modify the experimental settings
function par_microscope = define_par(par_microscope)

dlgTitle = 'Experimental parameters';

prompt(1) = {'Pixel-size xy [nm]'};
prompt(2) = {'Pixel-size z [nm]'};
prompt(3) = {'Refractive index'};
prompt(4) = {'Numeric aperture NA'};
prompt(5) = {'Excitation wavelength'};
prompt(6) = {'Emission wavelength'};
prompt(7) = {'Microscope'};

defaultValue{1} = num2str(par_microscope.pixel_size.xy);
defaultValue{2} = num2str(par_microscope.pixel_size.z);
defaultValue{3} = num2str(par_microscope.RI);
defaultValue{4} = num2str(par_microscope.NA);
defaultValue{5} = num2str(par_microscope.Ex);
defaultValue{6} = num2str(par_microscope.Em);
defaultValue{7} = num2str(par_microscope.type);

userValue = inputdlg(prompt,dlgTitle,1,defaultValue);

if( ~ isempty(userValue))
    par_microscope.pixel_size.xy = str2double(userValue{1});
    par_microscope.pixel_size.z  = str2double(userValue{2});   
    par_microscope.RI            = str2double(userValue{3});   
    par_microscope.NA            = str2double(userValue{4});
    par_microscope.Ex            = str2double(userValue{5});
    par_microscope.Em            = str2double(userValue{6});   
    par_microscope.type    = userValue{7};   
end


% --- Executes on button press in button_define_images_proj.
function button_define_images_proj_Callback(hObject, eventdata, handles)
%== Define images
[file_name_all,path_name] = uigetfile({'*.tif';'*.TIF';'*.STK';'*.stk'},'Select images','MultiSelect','on');

if ~iscell(file_name_all)
    dum=file_name_all;
    file_name_all={dum};
end

%- Progress if images are specified
if file_name_all{1} ~=0

    handles.files_outline_proc.input_type = 'file';
    handles.files_outline_proc.file_name_all = file_name_all;
    handles.files_outline_proc.path_name     = path_name;
    
    %== Update handles structure
    handles.status_img_outline = 1;
    enable_controls(hObject, eventdata, handles); 
    guidata(hObject, handles);
end


% --- Executes on button press in button_define_folder_proj.
function button_define_folder_proj_Callback(hObject, eventdata, handles)
folder_name = uigetdir;

if folder_name ~= 0
    
    %== Get directory
    handles.files_outline_proc.input_type = 'dir';
    handles.files_outline_proc.path_scan = folder_name;
    
    %== Update handles structure
    handles.status_img_outline = 1;
    enable_controls(hObject, eventdata, handles); 
    guidata(hObject, handles);
    
end


%== Create FQ outlines
function button_create_FQ_outlines_Callback(hObject, eventdata, handles)

%- Identifiers for actual images
names_struct.suffix.DAPI = get(handles.text_outline_img_dapi,'String');    %- Identifier for DAPI images
names_struct.suffix.FISH = get(handles.text_outline_img_FISH,'String');    %- Identifier for FISH images

%- Identifiers for masks
names_struct.suffix.nuc  = get(handles.text_outline_seg_nuc,'String');     %- Suffix of CellProfiler for nucleus
names_struct.suffix.cell = get(handles.text_outline_seg_cell,'String');    %- Suffix of CellProfiler for cells

%- Extension of original images
parameters.ext_orig = get(handles.text_CP_ext_orig,'String');

%-  Where to save results
if get(handles.check_save_folder_outline_replace,'Value');
    parameters.save.flag_folder = 'replace';
    parameters.save.string_orig   = get(handles.txt_folder_outline_replace_orig,'String');
    parameters.save.string_new    = get(handles.txt_folder_outline_replace_new,'String');
end

if get(handles.check_save_folder_outline_sub,'Value');
    parameters.save.flag_folder = 'sub';
    parameters.save.name_sub    = get(handles.txt_save_folder_outline_sub,'String');
end

if get(handles.check_save_folder_outline_same,'Value');
    parameters.save.flag_folder = 'same';
end


%- Part of file-name that should be removed
names_struct.name_remove = get(handles.txt_name_remove,'String');   %- Suffix of CellProfiler for cells

%- Outline files in second color
parameters.save_2nd.status = get(handles.check_outline_2nd_color,'Value');

if parameters.save_2nd.status
    parameters.save_2nd.suffix            = get(handles.text_outline_img_FISH_2nd,'String');
    parameters.save_2nd.status_not_1st    = get(handles.check_outline_not_1st,'Value');
    parameters.save_2nd.par_microscope_c2 = handles.par_microscope_c2;
end

%- Folders will be search recursively or not
handles.files_outline_proc.flag_folder_rec = get(handles.checkbox_folder_proj_recursive,'Value');

%- Parameters to save
parameters.names_struct   = names_struct;
parameters.par_microscope = handles.par_microscope;
parameters.files_proc = handles.files_outline_proc;

WRAPPER_cell_label_to_FQ_v1(parameters)


% =========================================================================
% =====   FQ outlines FROM  CELL COGNITION RESULTS 
% =========================================================================

%- Define experimental parameters
function button_define_exp_cell_cog_Callback(hObject, eventdata, handles)
handles.par_microscope = define_par(handles.par_microscope);
handles.status_par_def = 1;
enable_controls(hObject, eventdata, handles); 
guidata(hObject, handles);


% --- Executes on button press in button_define_folder_proj_cell_cog.
function button_define_folder_proj_cell_cog_Callback(hObject, eventdata, handles)

path_plate = uipickfiles;

%- Make cell array
if ~iscell(path_plate)
   dum = path_plate;
   clear path_plate
   path_plate{1} = dum;
end

%- Test if value is zero (for cancel)
if path_plate{1} ~= 0
    
    %== Get directory
    handles.path_plate = path_plate;
    
    %== Update handles structure
    guidata(hObject, handles);
end


% --- Executes on button press in button_create_FQ_outlines_cell_cog.
function button_create_FQ_outlines_cell_cog_Callback(hObject, eventdata, handles)

%== Assign parameters

parameter.DAPI_identifier              = get(handles.DAPI_image_identifier_cell_cog, 'String');
parameter.cell_identifier              = get(handles.Segmentation_image_identifier_cell_cog, 'String');
parameter.FISH_identifier              = get(handles.FISH_image_identifier_cellcog, 'String');

parameter.method_nucleus               = get(handles.Nucleus_seg_method, 'String');
parameter.method_cell                  = get(handles.Cell_seg_method, 'String');
parameter.path_plate                   = handles.path_plate;
parameter.outline_folder_name          = get(handles.Outline_folder_cell_cog, 'String');
parameter.extension                    = get(handles.Image_extension, 'String'); 
parameter.par_microscope               = handles.par_microscope;

%== Call function
cell_cognition_outline_v1(parameter)



% ==========================================================================
% NOT USED
% ==========================================================================

function text_rename_old_Callback(hObject, eventdata, handles)

function text_rename_old_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_rename_new_Callback(hObject, eventdata, handles)

function text_rename_new_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_fuse_1_Callback(hObject, eventdata, handles)

function text_fuse_1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_fuse_2_Callback(hObject, eventdata, handles)

function text_fuse_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_slice_select_number_Callback(hObject, eventdata, handles)

function txt_slice_select_number_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_outline_img_dapi_Callback(hObject, eventdata, handles)
    
function text_outline_img_dapi_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_outline_img_FISH_Callback(hObject, eventdata, handles)

function text_outline_img_FISH_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_outline_seg_nuc_Callback(hObject, eventdata, handles)

function text_outline_seg_nuc_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_outline_seg_cell_Callback(hObject, eventdata, handles)

function text_outline_seg_cell_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_slice_select_operator_Callback(hObject, eventdata, handles)

function popup_slice_select_operator_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_proj_standard_method_Callback(hObject, eventdata, handles)

function popup_proj_standard_method_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_proj_local_operator_Callback(hObject, eventdata, handles)

function popup_proj_local_operator_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_proj_local_window_Callback(hObject, eventdata, handles)

function txt_proj_local_window_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu3_Callback(hObject, eventdata, handles)

function popupmenu3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function size_filter_Callback(hObject, eventdata, handles)

function size_filter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function save_image_Callback(hObject, eventdata, handles)

function Untitled_1_Callback(hObject, eventdata, handles)

function Untitled_2_Callback(hObject, eventdata, handles)

function Untitled_3_Callback(hObject, eventdata, handles)

function filter_Callback(hObject, eventdata, handles)

function median_Callback(hObject, eventdata, handles)

function checkbox9_Callback(hObject, eventdata, handles)

function NIT_Callback(hObject, eventdata, handles)

function NIT_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_proj_local_method_Callback(hObject, eventdata, handles)

function popup_proj_local_method_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_proj_local_N_slices_Callback(hObject, eventdata, handles)

function txt_proj_local_N_slices_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_folder_recursive_Callback(hObject, eventdata, handles)

function check_show_results_Callback(hObject, eventdata, handles)

function txt_folder_img_extension_Callback(hObject, eventdata, handles)

function txt_folder_img_extension_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function check_store_results_Callback(hObject, eventdata, handles)

function check_save_name_prefix_Callback(hObject, eventdata, handles)

function txt_save_name_prefix_Callback(hObject, eventdata, handles)

function txt_save_name_prefix_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_save_folder_sub_Callback(hObject, eventdata, handles)

function txt_save_folder_sub_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_folder_replace_orig_Callback(hObject, eventdata, handles)

function txt_folder_replace_orig_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_folder_replace_new_Callback(hObject, eventdata, handles)

function txt_folder_replace_new_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_save_folder_outline_sub_Callback(hObject, eventdata, handles)

function txt_save_folder_outline_sub_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_folder_outline_replace_orig_Callback(hObject, eventdata, handles)

function txt_folder_outline_replace_orig_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_folder_outline_replace_new_Callback(hObject, eventdata, handles)

function txt_folder_outline_replace_new_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_outline_img_FISH_2nd_Callback(hObject, eventdata, handles)

function text_outline_img_FISH_2nd_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_name_remove_Callback(hObject, eventdata, handles)

function txt_name_remove_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_folder_proj_recursive_Callback(hObject, eventdata, handles)

function txt_proj_ingnore_file_Callback(hObject, eventdata, handles)

function txt_proj_ingnore_file_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function check_proj_ingnore_file_Callback(hObject, eventdata, handles)



function Outline_folder_cell_cog_Callback(hObject, eventdata, handles)

function Outline_folder_cell_cog_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function DAPI_image_identifier_cell_cog_Callback(hObject, eventdata, handles)


function DAPI_image_identifier_cell_cog_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Segmentation_image_identifier_cell_cog_Callback(hObject, eventdata, handles)

function Segmentation_image_identifier_cell_cog_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function Nucleus_seg_method_Callback(hObject, eventdata, handles)

function Nucleus_seg_method_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Cell_seg_method_Callback(hObject, eventdata, handles)

function Cell_seg_method_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Image_extension_Callback(hObject, eventdata, handles)

function Image_extension_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_CP_different_ext_Callback(hObject, eventdata, handles)

function text_CP_ext_orig_Callback(hObject, eventdata, handles)

function text_CP_ext_orig_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FISH_image_identifier_cellcog_Callback(hObject, eventdata, handles)
% hObject    handle to FISH_image_identifier_cellcog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FISH_image_identifier_cellcog as text
%        str2double(get(hObject,'String')) returns contents of FISH_image_identifier_cellcog as a double


% --- Executes during object creation, after setting all properties.
function FISH_image_identifier_cellcog_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FISH_image_identifier_cellcog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
