function varargout = FISH_QUANT_list_folder(varargin)
% FISH_QUANT_list_folder Application M-file for FISH_QUANT_list_folder.fig
%   FISH_QUANT_list_folder, by itself, creates a new FISH_QUANT_list_folder or raises the existing
%   singleton*.
%
%   H = FISH_QUANT_list_folder returns the handle to a new FISH_QUANT_list_folder or the handle to
%   the existing singleton*.
%
%   FISH_QUANT_list_folder('CALLBACK',hObject,eventData,handles,...) calls the local
%   function named CALLBACK in FISH_QUANT_list_folder.M with the given input arguments.
%
%   FISH_QUANT_list_folder('Property','Value',...) creates a new FISH_QUANT_list_folder or raises the
%   existing singleton*.  Starting from the left, property value pairs are
%   applied to the GUI before FISH_QUANT_list_folder_OpeningFunction gets called.  An
%   unrecognized property name or invalid value makes property application
%   stop.  All inputs are passed to FISH_QUANT_list_folder_OpeningFcn via varargin.
%
%   *See GUI Options - GUI allows only one instance to run (singleton).
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Copyright 2000-2006 The MathWorks, Inc.

% Edit the above text to modify the response to help FISH_QUANT_list_folder

% Last Modified by GUIDE v2.5 24-Aug-2004 10:31:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',          mfilename, ...
                   'gui_Singleton',     gui_Singleton, ...
                   'gui_OpeningFcn',    @FISH_QUANT_list_folder_OpeningFcn, ...
                   'gui_OutputFcn',     @FISH_QUANT_list_folder_OutputFcn, ...
                   'gui_LayoutFcn',     [], ...
                   'gui_Callback',      []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FISH_QUANT_list_folder is made visible.
function FISH_QUANT_list_folder_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;


%- Get input parameters
par_main                = varargin{1};
handles.par_microscope  = par_main.par_microscope;
handles.path_names      = par_main.path_names; 

%- Check if directory is empty
initial_dir = varargin{2};
if isempty(initial_dir)
    initial_dir = pwd;
end

% Populate the listbox
load_listbox(initial_dir,handles)

% Return figure handle as first output argument
    
% UIWAIT makes FISH_QUANT_list_folder wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FISH_QUANT_list_folder_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% ------------------------------------------------------------
% Callback for list box - open .fig with guide, otherwise use open
% ------------------------------------------------------------
function listbox1_Callback(hObject, eventdata, handles)

get(handles.figure1,'SelectionType');
if strcmp(get(handles.figure1,'SelectionType'),'open')
    index_selected = get(handles.listbox1,'Value');
    file_list = get(handles.listbox1,'String');
    filename  = file_list{index_selected};
    if  handles.is_dir(handles.sorted_index(index_selected))
        cd (filename)
        load_listbox(pwd,handles)
    else
        [path,name,ext] = fileparts(filename);
        
        switch ext
            case '.txt'
                
                ind_outline = strfind(filename,'outline');
                ind_spots   = strfind(filename,'spots');
                
                if not(isempty(ind_outline)) && isempty(ind_spots)
                    
                    if not(isempty(handles.path_names.img))
                        name_load = fullfile(pwd,filename);
                        disp(['Loaded file: ', name_load])
                        FISH_QUANT_outline('file',name_load, ...
                                        handles.path_names,handles.par_microscope)
                    else
                       warndlg('No folder for images specified. Outlines will not be loaded.','FISH_QUANT_list_folder') 
                    end
                end     
                
                           
                if not(isempty(ind_spots))
                    
                    if not(isempty(handles.path_names.img))
                        
                        file_load.path = pwd;
                        file_load.name = filename;
                        file_load.path_img = handles.path_names.img;
                        
                        
                        disp(['Loaded file: ', file_load.name])
                        disp(['Folder     : ', file_load.path])
                        FISH_QUANT_spots('file',file_load, ...
                                        handles.path_names,handles.par_microscope)
                    else
                        warndlg('No folder for images specified. Outlines will not be loaded.','FISH_QUANT_list_folder') 
                    end
                end     

            case {'.tif','.TIF','.stk','.STK'}    
                
                name_load = fullfile(pwd,filename);
                FISH_QUANT_outline('file_img',name_load, ...
                                        handles.path_names,handles.par_microscope)
        end
    end
end

% ------------------------------------------------------------
% Read the current directory and sort the names
% ------------------------------------------------------------
function load_listbox(dir_path,handles)
cd (dir_path)
dir_struct = dir(dir_path);
[sorted_names,sorted_index] = sortrows({dir_struct.name}');
handles.file_names = sorted_names;
handles.is_dir = [dir_struct.isdir];
handles.sorted_index = sorted_index;
guidata(handles.figure1,handles)
set(handles.listbox1,'String',handles.file_names,...
	'Value',1)
set(handles.text1,'String','Double click to open file / change folder')


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
usewhitebg = 1;
if usewhitebg
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
setappdata(hObject, 'StartPath', pwd);
addpath(pwd);


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
if isappdata(hObject, 'StartPath')
    rmpath(getappdata(hObject, 'StartPath'));
end

