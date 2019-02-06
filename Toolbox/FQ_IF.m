function varargout = FQ_IF(varargin)
% FQ_IF MATLAB code for FQ_IF.fig
%      FQ_IF, by itself, creates a new FQ_IF or raises the existing
%      singleton*.
%
%      H = FQ_IF returns the handle to a new FQ_IF or the handle to
%      the existing singleton*.
%
%      FQ_IF('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FQ_IF.M with the given input arguments.
%
%      FQ_IF('Property','Value',...) creates a new FQ_IF or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FQ_IF_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FQ_IF_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FQ_IF

% Last Modified by GUIDE v2.5 09-Sep-2015 14:32:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FQ_IF_OpeningFcn, ...
                   'gui_OutputFcn',  @FQ_IF_OutputFcn, ...
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


% --- Executes just before FQ_IF is made visible.
function FQ_IF_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for FQ_IF
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FQ_IF wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FQ_IF_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



%==========================================================================
%- Analyse IF images
%==========================================================================

% ==== Call function to specify files
function button_IF_files_Callback(hObject, eventdata, handles)

%- Get files with results - multi-select is possible
disp('Specify FQ results files!')
[results_list,folder_results] = uigetfile({'*.txt'},'Select FQ results files','MultiSelect', 'on');
if ~iscell(results_list)
    dum =results_list; 
    results_list = {dum};
end
if results_list{1} == 0; return; end

%- Define folder where images can be found
disp('Specify folder with IF images!')
folder_image = uigetdir([],'Define folder with IF images');
if folder_image == 0; return; end


%- Update handles structure
handles.par_IF.folder_image = folder_image;
handles.par_IF.results_list   = results_list;
handles.par_IF.folder_results = folder_results;
guidata(hObject, handles);

set(handles.button_analyze_IF,'enable','on')


% ==== Call function to specify files
function button_analyze_IF_Callback(hObject, eventdata, handles)

%- Get projection type
sel_str = get(handles.popup_projection,'String');
sel_int = get(handles.popup_projection,'Value');
handles.par_IF.proj_type = sel_str{sel_int};

%- Which file-name to save
sel_str = get(handles.popup_IF_filename_save,'String');
sel_int = get(handles.popup_IF_filename_save,'Value');
handles.par_IF.filename_save = sel_str{sel_int};

%- Parameters
handles.par_IF.name_str.ch1 = get(handles.text_IF_ch1,'String');
handles.par_IF.name_str.ch2 = get(handles.text_IF_ch2,'String');

handles.par_IF.flags.output   = 0;   % For each cell: plot outline file and images corresponding to different parts of the cell
handles.par_IF.file_name_save = ['__FQ_Quant_IF_Proj-', handles.par_IF.proj_type , '_', datestr(now,'yymmdd'),'.txt'];  % Name to save the results

%- Analyze
FQ3_analyze_int_region_v1(handles.par_IF);



%==========================================================================
%  == NOT USED
%==========================================================================


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

function popupmenu1_Callback(hObject, eventdata, handles)

function popupmenu1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_projection_Callback(hObject, eventdata, handles)

function popup_projection_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_IF_filename_save_Callback(hObject, eventdata, handles)

function popup_IF_filename_save_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
