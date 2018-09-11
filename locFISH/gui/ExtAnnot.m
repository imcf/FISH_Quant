function varargout = ExtAnnot(varargin)
% ExtAnnot MATLAB code for ExtAnnot.fig
%      ExtAnnot, by itself, creates a new ExtAnnot or raises the existing
%      singleton*.
%
%      H = ExtAnnot returns the handle to a new ExtAnnot or the handle to
%      the existing singleton*.
%
%      ExtAnnot('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ExtAnnot.M with the given input arguments.
%
%      ExtAnnot('Property','Value',...) creates a new ExtAnnot or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ExtAnnot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ExtAnnot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ExtAnnot

% Last Modified by GUIDE v2.5 01-Jun-2018 18:23:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ExtAnnot_OpeningFcn, ...
    'gui_OutputFcn',  @ExtAnnot_OutputFcn, ...
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


% --- Executes just before ExtAnnot is made visible.
function ExtAnnot_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ExtAnnot
handles.output = hObject;

handles.ind_cell = 1;
handles.N_cell   = 0;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = ExtAnnot_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
key_press(hObject, eventdata, handles)

% --- Executes on key press with focus on listbox and none of its controls.
function listbox_KeyPressFcn(hObject, eventdata, handles)
key_press(hObject, eventdata, handles)

% --- Executes on key press with focus on previous_cell and none of its controls.
function previous_cell_KeyPressFcn(hObject, eventdata, handles)
key_press(hObject, eventdata, handles)

% --- Executes on key press with focus on next_cell and none of its controls.
function next_cell_KeyPressFcn(hObject, eventdata, handles)
key_press(hObject, eventdata, handles)

% --- Executes on key press with focus on delete_ext and none of its controls.
function delete_ext_KeyPressFcn(hObject, eventdata, handles)
key_press(hObject, eventdata, handles)

% --- Executes on key press with focus on add_extension and none of its controls.
function add_extension_KeyPressFcn(hObject, eventdata, handles)
key_press(hObject, eventdata, handles)

%==========================================================================
%- Keyboard shortcuts
function key_press(hObject, eventdata, handles)

switch eventdata.Key
    
    %- Cell before
    case {'N','n','leftarrow'}
        previous_cell_Callback(hObject, eventdata, handles)
        
        %- Cell after
    case {'M','m','rightarrow'}
        next_cell_Callback(hObject, eventdata, handles)
        
        %- New extension
    case 'return'
        add_extension(hObject, eventdata, handles)
        
        %- Delete last extension
    case {'X','x'}
        delete_ext_Callback(hObject, eventdata, handles)
        
end

%==========================================================================
%= Plot image
function plot_image(hObject, eventdata, handles)
axes(handles.axes1);
mask      = handles.mask ;
imshow(mask,[])
title(handles.cell_name,'interpreter','none')

%==========================================================================
%= Plot extension
function plot_extension(hObject, eventdata, handles)

ind_cell   = handles.ind_cell;
ext_sel    = get(handles.listbox,'Value');
number_ext = get(handles.listbox,'String');

if isempty(number_ext)
    number_ext = 0 ;
else
    number_ext = size(number_ext,1) ;
end

plot_image(hObject, eventdata, handles)

for i=1:number_ext
    hold on
    position_ext      = [] ;
    position_ext(:,1) = handles.cell_library(ind_cell).pos_extension(i).x;
    position_ext(:,2) = handles.cell_library(ind_cell).pos_extension(i).y;
    x_cell            = handles.cell_id_pixel(:,1);
    y_cell            = handles.cell_id_pixel(:,2);
    ind_pixel_inside  = inpolygon(y_cell,x_cell, position_ext(:,1),position_ext(:,2)) ;
    plot(y_cell(ind_pixel_inside),  x_cell(ind_pixel_inside), '.','col','red')
end

ind_ext        = double(ext_sel >= 1);
ind_ext_number = double(number_ext >0);

if ind_ext*ind_ext_number
    
    position_current_ext(:,1) = handles.cell_library(ind_cell).pos_extension(ext_sel).x;
    position_current_ext(:,2) = handles.cell_library(ind_cell).pos_extension(ext_sel).y;
    x_cell                     = handles.cell_id_pixel(:,1);
    y_cell                     = handles.cell_id_pixel(:,2);
    ind_pixel_inside           = inpolygon(y_cell,x_cell, position_current_ext(:,1),position_current_ext(:,2)) ;
    plot(y_cell(ind_pixel_inside),  x_cell(ind_pixel_inside), '.','col','green')
end
hold off


%==========================================================================
%- Add Extension
function add_extension(hObject, eventdata, handles)

ind_cell = handles.ind_cell;
axes(handles.axes1);
%uicontrol(handles.figure1)
drawnow
h_fh          = imfreehand('Closed','true');

if isempty(h_fh); return; end

positions     = getPosition(h_fh);
delete(h_fh)
 
str_list          = get(handles.listbox,'String');
N_ext             = size(str_list,1)*(~isempty(str_list));
string_ext        = ['ext_',num2str(N_ext+1)];
str_list{N_ext+1} = string_ext;

set(handles.listbox,'String',str_list);
set(handles.listbox,'Value',N_ext+1)

handles.cell_library(ind_cell).pos_extension(N_ext +1).x = positions(:,1);
handles.cell_library(ind_cell).pos_extension(N_ext +1).y = positions(:,2);

plot_extension(hObject, eventdata, handles)
guidata(hObject, handles);


%==========================================================================
% --- Save cell library
function save_file_ClickedCallback(hObject, eventdata, handles)
[file,path] = uiputfile(fullfile(handles.pathname,'*.mat'),'Save cell library as');
if file     == 0; return; end

h = msgbox('Saving takes some time ... requires post-processing of extensions. Patience ...','Saving cell library','help');
set(handles.figure1,'Pointer','watch');

%- Further process cell extensions & save results
cell_library_info = handles.cell_library_info;

switch handles.version
    case 'v1'
        cell_library   = extensionsPostproc_v1(handles.cell_library);
        save(fullfile(path,file),'cell_library','cell_library_info')
        
    case 'v2'
        cell_library_v2   = extensionsPostproc_v1(handles.cell_library);
        save(fullfile(path,file),'cell_library_v2','cell_library_info','-v7.3')
end


set(handles.figure1,'Pointer','arrow');
delete(h)

%==========================================================================
% --- Open cell library
function open_file_ClickedCallback(hObject, eventdata, handles)
[filename, pathname]        = uigetfile;
if filename == 0; return; end

set(handles.figure1,'Pointer','watch');
h = msgbox('Loading can take some time. Patience ...','Importing file','help');

loaded_data               = load(fullfile(pathname,filename));

if isfield(loaded_data,'cell_library_v2')
    handles.cell_library      = loaded_data.cell_library_v2;
    handles.version = 'v2';
elseif isfield(loaded_data,'cell_library')
    handles.cell_library      = loaded_data.cell_library;
    handles.version = 'v1';
end

handles.cell_library_info = loaded_data.cell_library_info;
handles.ind_cell          = 1;
handles.pathname          = pathname;
set(handles.listbox,'String','');
set(handles.listbox,'Value',1);

%- Show cell with extensions
handles = analyze_extensions(handles);
plot_image(hObject, eventdata, handles)
plot_extension(hObject, eventdata, handles)

set(handles.figure1,'Pointer','arrow');
guidata(hObject, handles);
delete(h)


%==========================================================================
% --- Button: previous cell
function previous_cell_Callback(hObject, eventdata, handles)
if handles.ind_cell > 1
    handles.ind_cell = handles.ind_cell - 1;
end

handles = analyze_extensions(handles);
plot_extension(hObject, eventdata, handles)
guidata(hObject, handles);


%==========================================================================
% --- Button: next cell
function next_cell_Callback(hObject, eventdata, handles)

if handles.ind_cell < size(handles.cell_library,2);
    handles.ind_cell = handles.ind_cell + 1;
end

handles = analyze_extensions(handles);
plot_extension(hObject, eventdata, handles)
guidata(hObject, handles);


%==========================================================================
% --- Analyze extensions
function handles = analyze_extensions(handles)

ind_cell  = handles.ind_cell;
cell_size = double(max(handles.cell_library(ind_cell).cell_2D));
mask      = poly2mask(double(handles.cell_library(ind_cell).cell_2D(:,1)), double(handles.cell_library(ind_cell).cell_2D(:,2)), cell_size(2), cell_size(1));

[x, y]     = ind2sub(size(mask), find(mask == 1 )) ;

handles.cell_size     = cell_size;
handles.mask          = mask;
handles.cell_id_pixel = [x y] ;

switch handles.version
    case 'v1'
        handles.cell_name     = handles.cell_library(ind_cell).name_img_bgd;
        
    case 'v2'
        handles.cell_name     = handles.cell_library(ind_cell).name_img_BGD;
end

if isfield(handles.cell_library(ind_cell),'pos_extension')
    ext_struct = handles.cell_library(ind_cell).pos_extension;
    N_ext      = size(ext_struct,2) ;
    
    if N_ext == 0
        set(handles.listbox,'String','');
        set(handles.listbox,'Value',0)
    else
        
        str_list = {};        
        for i_ext = 1:N_ext
            str_list{i_ext,1} = strcat('Prot_',num2str(i_ext)) ;
        end
        set(handles.listbox,'String',str_list);
        set(handles.listbox,'Value',1);
    end
end


%==========================================================================
% --- Button: delete extensions
function delete_ext_Callback(hObject, eventdata, handles)
ind_cell      = handles.ind_cell ;
prot_selected = get(handles.listbox,'Value');
if isfield(handles.cell_library(ind_cell),'pos_extension')
    handles.cell_library(ind_cell).pos_extension(prot_selected) = [] ;
    strlist       = get(handles.listbox,'String');
    strlist(prot_selected,:) = [] ;
    set(handles.listbox,'String',strlist)

    new_value_ext = size(handles.cell_library(ind_cell).pos_extension,2) ;
    set(handles.listbox,'Value',new_value_ext)
    guidata(hObject, handles);
    plot_extension(hObject, eventdata, handles)
end


%==========================================================================
% --- Button: add extensions
function add_extension_Callback(hObject, eventdata, handles)
add_extension(hObject, eventdata, handles)


% --- Executes on selection change in listbox.
function listbox_Callback(hObject, eventdata, handles)
plot_extension(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function listbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
