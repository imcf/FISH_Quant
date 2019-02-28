function varargout = FQ_DualColor(varargin)
% FQ_DualColor MATLAB code for FQ_DualColor.fig
%      FQ_DualColor, by itself, creates a new FQ_DualColor or raises the existing
%      singleton*.
%
%      H = FQ_DualColor returns the handle to a new FQ_DualColor or the handle to
%      the existing singleton*.
%
%      FQ_DualColor('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FQ_DualColor.M with the given input arguments.
%
%      FQ_DualColor('Property','Value',...) creates a new FQ_DualColor or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FQ_DualColor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FQ_DualColor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FQ_DualColor

% Last Modified by GUIDE v2.5 09-Mar-2016 10:19:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FQ_DualColor_OpeningFcn, ...
                   'gui_OutputFcn',  @FQ_DualColor_OutputFcn, ...
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


% --- Executes just before FQ_DualColor is made visible.
function FQ_DualColor_OpeningFcn(hObject, eventdata, handles, varargin)


% Choose default command line output for FQ_DualColor
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FQ_DualColor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FQ_DualColor_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

%==========================================================================
% Diverse functions
%==========================================================================


%- Change color of outlines
function button_outlines_change_color_Callback(hObject, eventdata, handles)

parameters.name_str.old = get(handles.text_rename_old,'String');
parameters.name_str.new = get(handles.text_rename_new,'String');

FQ3_outline_replace_color_v2(parameters)


%- Fuse outlines
function button_outlines_fuse_Callback(hObject, eventdata, handles)
name_str.ch1 = get(handles.text_fuse_1,'String');
name_str.ch2 = get(handles.text_fuse_2,'String');

SCR_FQ_outline_fuse_v1(name_str)


%==========================================================================
%- Dual-color distance
%==========================================================================

% ==== Call function to specify files
function button_specify_files_Callback(hObject, eventdata, handles)

%- Define result files of first color
disp('Select FQ result file for first color.')
[file_name_results,folder_ch1]=uigetfile({'*.txt'},'Select FQ result file for first color.','MultiSelect','on');
if ~iscell(file_name_results)
    dum=file_name_results;
    file_name_results={dum};
end
if file_name_results{1} == 0; return; end

handles.par_coloc.file_name_results = file_name_results;
handles.par_coloc.folder_ch1 = folder_ch1;

% - Define folder with results of second color
disp('Define folder with results of second color.')
folder_ch2 = uigetdir(handles.par_coloc.folder_ch1,'Define folder with results of second color.');
if folder_ch2 == 0; return; end

handles.par_coloc.folder_ch2 = folder_ch2;

%-  Define folder with images of first color
disp('Define folder with with images of first color. Press Cancel to not use images.')
folder_img_ch1 = uigetdir(handles.par_coloc.folder_ch1,'Define folder with images of first color.');
%if folder_img_ch1 == 0; return; end

handles.par_coloc.folder_img_ch1 = folder_img_ch1;

%  Define folder with images of second color
if folder_img_ch1 ~= 0
    folder_img_ch2 = uigetdir(handles.par_coloc.folder_img_ch1,'Define folder with images of second color');
else
    folder_img_ch2 = 0;
end
%if folder_img_ch2 == 0; return; end

handles.par_coloc.folder_img_ch2 = folder_img_ch2;

%- Drift correction
handles.par_coloc.drift = [];

set(handles.button_dc_analyze,'enable','on')

% Update handles structure
guidata(hObject, handles);


%==========================================================================
%- Function for dual-color distance
%==========================================================================

function button_dc_analyze_Callback(hObject, eventdata, handles)

par_coloc = handles.par_coloc;

%- Get other parameters
par_coloc.ident_ch1 = get(handles.text_dc_ident_ch1,'String');
par_coloc.ident_ch2 = get(handles.text_dc_ident_ch2,'String');

par_coloc.N_spots_max =str2double(get(handles.text_dc_max_N_spots,'String'));  % Maximum number of spots per color
dist_th = str2double(get(handles.text_dc_max_dist,'String'));  % Maximum allowed distance between spots in two colors

%- Some flags to determine how function works
par_coloc.flags.save_img_spots  = get(handles.checkbox_save_img_spots,'Value');   % Plot results of individual spots
par_coloc.flags.save_img_cells  = get(handles.checkbox_save_img_cell,'Value');   % Plot results of individual spots
par_coloc.flags.save_results    = get(handles.checkbox_save_analysis_details,'Value');   % Plot results of individual spots

par_coloc.flags.drift_calc  = get(handles.checkbox_dc_drift_calc,'Value');   % Calc drift correction
par_coloc.flags.drift_apply = get(handles.checkbox_dc_drift_apply,'Value');

% %- Apply drift correction only if enabled.
if ~par_coloc.flags.drift_apply
    par_coloc.drift = [];
end
    
%- Call routine
[drift, summary_coloc, results_coloc,ch1_all_spots, ch2_all_spots] = FQ3_calc_coloc_v5(par_coloc,dist_th);

%- Save results of drift correction only if not applied at the same time
if par_coloc.flags.drift_calc && ~par_coloc.flags.drift_apply
    par_coloc.drift = drift;
    set(handles.checkbox_dc_drift_apply,'enable','on')
end

%- Save results   
handles.par_coloc = par_coloc;
handles.summary_coloc = summary_coloc;
handles.results_coloc = results_coloc;
handles.ch1_all_spots = ch1_all_spots;
handles.ch2_all_spots = ch2_all_spots;


% Update handles structure
guidata(hObject, handles);

%==========================================================================
% Save results
%==========================================================================

function button_dualcolor_save_results_Callback(hObject, eventdata, handles)

%- Save summary
FQ3_DualColor_save_summary_v1(handles.par_coloc,handles.summary_coloc,handles.results_coloc)

%- Save detailed summary
FQ3_DualColor_save_details_v1(handles.par_coloc,handles.summary_coloc,handles.results_coloc)

%- Save individual summary
FQ3_DualColor_save_indiv_v1(handles.par_coloc,handles.summary_coloc,handles.ch1_all_spots,'ch1')

%- Save individual summary
FQ3_DualColor_save_indiv_v1(handles.par_coloc,handles.summary_coloc,handles.ch2_all_spots,'ch2')



%==========================================================================
% NOT USED
%==========================================================================

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

function text_MIP_nom_slices_Callback(hObject, eventdata, handles)

function text_MIP_nom_slices_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_MIP_central_Callback(hObject, eventdata, handles)

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

function text_IF_ch1_Callback(hObject, eventdata, handles)

function text_IF_ch1_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_IF_ch2_Callback(hObject, eventdata, handles)

function text_IF_ch2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_dc_ident_ch1_Callback(hObject, eventdata, handles)

function text_dc_ident_ch1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_dc_ident_ch2_Callback(hObject, eventdata, handles)

function text_dc_ident_ch2_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_dc_max_dist_Callback(hObject, eventdata, handles)

function text_dc_max_dist_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_dc_drift_calc_Callback(hObject, eventdata, handles)

function popup_projection_Callback(hObject, eventdata, handles)

function popup_projection_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_save_img_spots_Callback(hObject, eventdata, handles)

function checkbox_test_dist_th_Callback(hObject, eventdata, handles)

function text_dc_max_N_spots_Callback(hObject, eventdata, handles)

function text_dc_max_N_spots_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_dc_drift_apply_Callback(hObject, eventdata, handles)

function popup_IF_filename_save_Callback(hObject, eventdata, handles)

function popup_IF_filename_save_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_save_img_cell_Callback(hObject, eventdata, handles)

function checkbox_save_analysis_details_Callback(hObject, eventdata, handles)
