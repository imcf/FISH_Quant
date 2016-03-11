function varargout = FISH_QUANT_batch_filter(varargin)
% FISH_QUANT_BATCH_FILTER MATLAB code for FISH_QUANT_batch_filter.fig
%      FISH_QUANT_BATCH_FILTER, by itself, creates a new FISH_QUANT_BATCH_FILTER or raises the existing
%      singleton*.
%
%      H = FISH_QUANT_BATCH_FILTER returns the handle to a new FISH_QUANT_BATCH_FILTER or the handle to
%      the existing singleton*.
%
%      FISH_QUANT_BATCH_FILTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FISH_QUANT_BATCH_FILTER.M with the given input arguments.
%
%      FISH_QUANT_BATCH_FILTER('Property','Value',...) creates a new FISH_QUANT_BATCH_FILTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FISH_QUANT_batch_filter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FISH_QUANT_batch_filter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FISH_QUANT_batch_filter

% Last Modified by GUIDE v2.5 25-Jun-2013 15:28:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_batch_filter_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_batch_filter_OutputFcn, ...
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


% --- Executes just before FISH_QUANT_batch_filter is made visible.
function FISH_QUANT_batch_filter_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

%- Set font-size to 10
%  For whatever reason are all the fonts on windows are set back to 8 when the .fig is openend
h_font_8 = findobj(handles.h_fishquant_batch_filter,'FontSize',8);
set(h_font_8,'FontSize',10)

%- Get installation directory of FISH-QUANT and initiate 
p = mfilename('fullpath');        
handles.FQ_path = fileparts(p); 
handles         = FISH_QUANT_start_up_v2(handles);

%- Change name of GUI
set(handles.h_fishquant_batch_filter,'Name', ['FISH-QUANT ', handles.version, ': batch filtering']);

%- Get global variables from FQ
global FQ_main_folder par_microscope_FQ settings_filter_FQ

if not(isempty(FQ_main_folder))
    handles.path_name_root    = FQ_main_folder.root;
    handles.path_name_results = FQ_main_folder.results;
    handles.path_name_image   = FQ_main_folder.image;
    handles.path_name_outline = FQ_main_folder.outline;
else
    handles.path_name_image = pwd;
end

if not(isempty(par_microscope_FQ))   
    handles.filter = settings_filter_FQ;
else
    handles.filter.factor_bgd_xy = 5; 
    handles.filter.factor_bgd_z = 5; 
    handles.filter.factor_psf_xy = 1;
    handles.filter.factor_psf_z = 1;
end

%== Filtering
set(handles.text_kernel_factor_bgd_xy,'String',num2str(handles.filter.factor_bgd_xy));
set(handles.text_kernel_factor_bgd_z,'String',num2str(handles.filter.factor_bgd_z));

set(handles.text_kernel_factor_filter_xy,'String',num2str(handles.filter.factor_psf_xy));
set(handles.text_kernel_factor_filter_z,'String',num2str(handles.filter.factor_psf_z));

%- Export figure handle to workspace - will be used in Close All button of main Interface
assignin('base','h_batch_filter',handles.h_fishquant_batch_filter)


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FISH_QUANT_batch_filter wait for user response (see UIRESUME)
% uiwait(handles.h_fishquant_batch_filter);


% --- Outputs from this function are returned to the command line.
function varargout = FISH_QUANT_batch_filter_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% =========================================================================
% Enable & status update
% =========================================================================

%== Enable
function controls_enable(hObject, eventdata, handles)


%- Files added to list for processing
str_list = get(handles.listbox_files,'String');
if not(isempty(str_list))
    handles.status_files = 1;
    set(handles.text_status_files,'String','Files listed')
    set(handles.text_status_files,'ForegroundColor','g')
    
   set(handles.button_files_delete,'Enable','on'); 
   set(handles.button_files_delete_all,'Enable','on'); 
    
else
    handles.status_files = 0;
    set(handles.text_status_files,'String','No files')
    set(handles.text_status_files,'ForegroundColor','r')
    
    set(handles.button_files_delete,'Enable','off');
   set(handles.button_files_delete_all,'Enable','off'); 
end

%- Enable filtering
if handles.status_files
     set(handles.button_filter,'Enable','on');
else
        set(handles.button_filter,'Enable','off'); 
end


% =========================================================================
%  === LIST OF FILES TO BE FILTERED
% =========================================================================

%== Add files
function button_files_add_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with images
current_dir = pwd;
if not(isempty(handles.path_name_image))
   cd(handles.path_name_image)
elseif not(isempty(handles.path_name_root))
   cd(handles.path_name_root) 
end

%- Get file names
[file_name_outline,path_name_list] = uigetfile({'*.tif';'*.TIF';'*.stk';'*.STK';'*.dv';'*.DV'},'Select images that should be filtered','MultiSelect', 'on');

if ~iscell(file_name_outline)
    dum =file_name_outline; 
    file_name_outline = {dum};
end
    
if file_name_outline{1} ~= 0 
    
    str_list_old = get(handles.listbox_files,'String');
    
    if isempty(str_list_old)
        str_list_new = file_name_outline';
    else
        str_list_new = [str_list_old;file_name_outline'];
    end
    
    %- Sometimes there are problems with the list-box value
    if isempty(get(handles.listbox_files,'Value'))
        set(handles.listbox_files,'Value',1);
    end
    
    set(handles.listbox_files,'String',str_list_new);
    handles.path_name_list = path_name_list;
    
    %- Update status
    controls_enable(hObject, eventdata, handles)    
    
    %- Save results
    guidata(hObject, handles); 

end

%- Go back to original image
cd(current_dir);


%== Delete selected files
function button_files_delete_Callback(hObject, eventdata, handles)

str_list = get(handles.listbox_files,'String');

if not(isempty(str_list))

    %- Ask user to confirm choice
    choice = questdlg('Do you really want to remove this file?', 'FISH-QUANT', 'Yes','No','No');

    if strcmp(choice,'Yes')

        %- Extract index of highlighted cell
        ind_sel  = get(handles.listbox_files,'Value');

        %- Delete highlighted cell
        str_list(ind_sel) = [];
        set(handles.listbox_files,'String',str_list)
        set(handles.listbox_files,'Value',1)

        %- Update status
        controls_enable(hObject, eventdata, handles)         
    end
end


%== Delete all files
function button_files_delete_all_Callback(hObject, eventdata, handles)
%- Ask user to confirm choice
choice = questdlg('Do you really want to remove all files?', 'FISH-QUANT', 'Yes','No','No');

if strcmp(choice,'Yes')
    
    set(handles.listbox_files,'String',{})
    set(handles.listbox_files,'Value',1)
    
    %- Update status
    controls_enable(hObject, eventdata, handles)
end


% =========================================================================
%  === FILTER
% =========================================================================

%== Filter all images
function button_filter_Callback(hObject, eventdata, handles)

set(handles.h_fishquant_batch_filter,'Pointer','watch');

%- Get some parameters      
filter.factor_bgd_xy = str2double(get(handles.text_kernel_factor_bgd_xy,'String'));
filter.factor_bgd_z = str2double(get(handles.text_kernel_factor_bgd_z,'String'));
filter.factor_psf_xy = str2double(get(handles.text_kernel_factor_filter_xy,'String'));
filter.factor_psf_z = str2double(get(handles.text_kernel_factor_filter_z,'String'));


kernel_size.bgd_xy = filter.factor_bgd_xy;
kernel_size.bgd_z = filter.factor_bgd_z;

kernel_size.psf_xy = filter.factor_psf_xy;
kernel_size.psf_z = filter.factor_psf_z;

flag.output     = 0;

name_suffix       = get(handles.text_name_suffix,'String');
    
%- Get folder nanme and list of all files
path_name_list = handles.path_name_list;
file_list = get(handles.listbox_files,'String');
N_file = size(file_list,1);

%- Loop over all files
disp('==== BATCH filtering'); 
for i_file = 1:size(file_list,1)
    
   
    disp(' ');
    disp(['- Filtering image ', num2str(i_file), ' of ', num2str(N_file)]);

    %== Get file name and load image
    file_name_load = file_list{i_file};
    image_struct = load_stack_data_v7(fullfile(path_name_list,file_name_load));
    
    img_filt = img_filter_Gauss_v5(image_struct,kernel_size,flag);
    

    %- Save filtered image
    [dum, name_file]    = fileparts(file_name_load); 
    file_name_FILT      = [name_file,name_suffix,'.tif'];
    file_name_FILT_full = fullfile(path_name_list,file_name_FILT);

    %- Make sure file doesn't exit - otherwise planes will be simply added
    if not(exist(file_name_FILT_full,'file'))
        image_save_v2(img_filt,file_name_FILT);
        disp(['  Filtered image will be saved with file-name: ' ,file_name_FILT])
    else
        disp(['  Filtered image will NOT be saved. File already present: ' ,file_name_FILT])
    end
end
set(handles.h_fishquant_batch_filter,'Pointer','arrow');    
    
disp('Batch filtering finished'); 
    

% =========================================================================
%  === NOT USED
% =========================================================================


% --- Executes on selection change in listbox_files.
function listbox_files_Callback(hObject, eventdata, handles)

function listbox_files_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_bgd_xy_Callback(hObject, eventdata, handles)

function text_kernel_factor_bgd_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_filter_xy_Callback(hObject, eventdata, handles)

function text_kernel_factor_filter_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_name_suffix_Callback(hObject, eventdata, handles)

function text_name_suffix_CreateFcn(hObject, eventdata, handles)
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
