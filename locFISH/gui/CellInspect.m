function varargout = CellInspect(varargin)
% CellInspect MATLAB code for CellInspect.fig
%      CellInspect, by itself, creates a new CellInspect or raises the existing
%      singleton*.
%
%      H = CellInspect returns the handle to a new CellInspect or the handle to
%      the existing singleton*.
%
%      CellInspect('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CellInspect.M with the given input arguments.
%
%      CellInspect('Property','Value',...) creates a new CellInspect or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CellInspect_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CellInspect_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CellInspect

% Last Modified by GUIDE v2.5 20-Apr-2018 11:13:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CellInspect_OpeningFcn, ...
                   'gui_OutputFcn',  @CellInspect_OutputFcn, ...
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


% --- Executes just before CellInspect is made visible.
function CellInspect_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = CellInspect_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in previous.
function previous_Callback(hObject, eventdata, handles)
handles.ind_cell = max(1,handles.ind_cell -1 ); 
cell_display(handles); 
guidata(hObject, handles);

% --- Executes on button press in next.
function next_Callback(hObject, eventdata, handles)
handles.ind_cell = min(length(handles.cell_library),handles.ind_cell + 1); 
cell_display(handles); 
guidata(hObject, handles);

% --- Executes on button press in reject.
function reject_Callback(hObject, eventdata, handles)
handles.accept_cell(handles.ind_cell) = 0; 
handles.ind_cell = min(length(handles.cell_library),handles.ind_cell + 1); 
cell_display(handles); 
guidata(hObject, handles);

% --- Executes on button press in accept.
function accept_Callback(hObject, eventdata, handles)
handles.accept_cell(handles.ind_cell) = 1; 
handles.ind_cell = min(length(handles.cell_library),handles.ind_cell + 1); 
cell_display(handles); 
guidata(hObject, handles);

%- Display current cell
function cell_display(handles)

%- Plot current cell
cell_struct = handles.cell_library(handles.ind_cell) ; 

alpha_cell = str2double(get(handles.alpha_cell,'string'));
alpha_nucleus = str2double(get(handles.alpha_nucleus,'string'));

axes(handles.axes1);
trisurf(cell_struct.K_cell, ...
    cell_struct.pos_cell_pix(:,1) * handles.cell_library_info.pixel_size_xy,  ...
    cell_struct.pos_cell_pix(:,2) * handles.cell_library_info.pixel_size_xy, ...
    cell_struct.pos_cell_pix(:,3) * handles.cell_library_info.pixel_size_z , ...
    'FaceColor','yellow','FaceAlpha',alpha_cell)
hold on
trisurf(cell_struct.K_nuc, cell_struct.pos_nuc_pix(:,1) * handles.cell_library_info.pixel_size_xy, ...
    cell_struct.pos_nuc_pix(:,2) * handles.cell_library_info.pixel_size_xy, ...
    cell_struct.pos_nuc_pix(:,3) * handles.cell_library_info.pixel_size_z, ...
    'FaceColor','blue','FaceAlpha',alpha_nucleus)
axis equal
hold off
title(cell_struct.name_img_BGD, 'Interpreter', 'none')

%- Update text
set(handles.cell_status,'String', strcat('cell_status : ', num2str(handles.accept_cell(handles.ind_cell))))
if handles.accept_cell(handles.ind_cell)
    set(handles.cell_status,'ForeGroundColor','g');
else
    set(handles.cell_status,'ForeGroundColor','r');
end

% --------------------------------------------------------------------
function menu_open_ClickedCallback(hObject, eventdata, handles)

[cell_library_name, cell_library_path] = uigetfile;
if cell_library_name==0; return; end

set(handles.figure1,'Pointer','watch');
h = msgbox('Loading can take some time. Patience ...','Importing file','help');

%- Load library and save to handles structure
load(fullfile(cell_library_path,cell_library_name))

handles.cell_library_path = cell_library_path ; 
handles.cell_library = cell_library_v2; 
handles.cell_library_info = cell_library_info; 

%- Display first cell
handles.ind_cell    = 1; 
handles.accept_cell  = ones(length(cell_library_v2),1); 
cell_display(handles); 
guidata(hObject, handles);

set(handles.figure1,'Pointer','arrow');
delete(h)

% --------------------------------------------------------------------
function menu_save_ClickedCallback(hObject, eventdata, handles)
%- Get inspected cell library
cell_library_v2 = handles.cell_library(logical(handles.accept_cell));

%- Get file-name to save it
name_save = fullfile(handles.cell_library_path,'cell_library_inspected.mat');
[FileName,PathName] = uiputfile('*.mat','Save inspected cell-library',name_save);
if FileName == 0; return; end
name_save = fullfile(PathName,FileName);

%- Save library and info
cell_library_info = handles.cell_library_info;
save(name_save, 'cell_library_v2', 'cell_library_info'); 


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)

switch eventdata.Key
  case 'rightarrow'
    next_Callback(hObject, eventdata, handles)
  case 'leftarrow'
    previous_Callback(hObject, eventdata, handles)
  case 'f'  
    reject_Callback(hObject, eventdata, handles)
  case 'g'  
   accept_Callback(hObject, eventdata, handles) 
end


%==========================================================================
% --- NOT USED

% --------------------------------------------------------------------
function Menu_Callback(hObject, eventdata, handles)

function cell_status_Callback(hObject, eventdata, handles)

function cell_status_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function accept_cell_Callback(hObject, eventdata, handles)

function figure1_CreateFcn(hObject, eventdata, handles)

function alpha_cell_Callback(hObject, eventdata, handles)


function alpha_cell_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function alpha_nucleus_Callback(hObject, eventdata, handles)

function alpha_nucleus_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
