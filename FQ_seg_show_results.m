function varargout = FQ_seg_show_results(varargin)
% FQ_seg_show_results MATLAB code for FQ_seg_show_results.fig
%      FQ_seg_show_results, by itself, creates a new FQ_seg_show_results or raises the existing
%      singleton*.
%
%      H = FQ_seg_show_results returns the handle to a new FQ_seg_show_results or the handle to
%      the existing singleton*.
%
%      FQ_seg_show_results('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FQ_seg_show_results.M with the given input arguments.
%
%      FQ_seg_show_results('Property','Value',...) creates a new FQ_seg_show_results or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FQ_seg_show_results_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FQ_seg_show_results_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FQ_seg_show_results

% Last Modified by GUIDE v2.5 05-Feb-2015 15:38:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FQ_seg_show_results_OpeningFcn, ...
                   'gui_OutputFcn',  @FQ_seg_show_results_OutputFcn, ...
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


% --- Executes just before FQ_seg_show_results is made visible.
function FQ_seg_show_results_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FQ_seg_show_results (see VARARGIN)
handles.proj_struct = varargin{1}; 
handles.status_zoom = 0;

% Choose default command line output for FQ_seg_show_results
handles.output = hObject;
plot_images(hObject, eventdata, handles)

global status_plot_first   
status_plot_first = 1;  

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FQ_seg_show_results wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FQ_seg_show_results_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Outputs from this function are returned to the command line.
function plot_images(hObject, eventdata, handles) 

global status_plot_first

%- Index of data-set
ind_dum  = get(handles.slider_ind_data_set,'Value');
N_data   =  length(handles.proj_struct);
ind_data = ceil(ind_dum*(N_data-1))+1;


%- Get contrast values
min1 = get(handles.min_contrast_1, 'Value');
min2 = get(handles.min_contrast_2, 'Value');
max1 = get(handles.max_contrast_1, 'Value');
max2 = get(handles.max_contrast_2, 'Value');
min_image_MIP = min(min(max(handles.proj_struct(ind_data).MIP,[],3)));
max_image_MIP = max(max(max(handles.proj_struct(ind_data).MIP,[],3)));
min_image_proj = min(min(max(handles.proj_struct(ind_data).proj_focus,[],3)));
max_image_proj = max(max(max(handles.proj_struct(ind_data).proj_focus,[],3)));

diff_image_MIP  =   max_image_MIP - min_image_MIP ;
diff_image_proj =   max_image_proj - min_image_proj;

%- Show first image
axes(handles.axes1);
v = axis;
imshow(handles.proj_struct(ind_data).MIP,[min_image_MIP + diff_image_MIP*min1  min_image_MIP + diff_image_MIP*max1]);
ax1 = gca;


%- Show second image
axes(handles.axes2);
imshow(handles.proj_struct(ind_data).proj_focus, [min_image_proj + diff_image_proj*min2  min_image_proj + diff_image_proj*max2]);
ax2 = gca;

linkaxes([ax1,ax2],'xy')


%- Same zoom as before
if not(status_plot_first)
	axis(v);
end

%- Save everything
status_plot_first = 0;



%== Zoom
function button_zoom_Callback(hObject, eventdata, handles)
if handles.status_zoom == 0
    h_zoom = zoom;
    set(h_zoom,'Enable','on');
    handles.status_zoom = 1;
    handles.status_pan  = 0;
    handles.h_zoom      = h_zoom;
else
    set(handles.h_zoom,'Enable','off');    
    handles.status_zoom = 0;
end
guidata(hObject, handles);





function min_contrast_1_Callback(hObject, eventdata, handles)
plot_images(hObject, eventdata, handles) 
 

function min_contrast_1_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function max_contrast_1_Callback(hObject, eventdata, handles)
plot_images(hObject, eventdata, handles) 


function max_contrast_1_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function min_contrast_2_Callback(hObject, eventdata, handles)

function min_contrast_2_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function max_contrast_2_Callback(hObject, eventdata, handles)
plot_images(hObject, eventdata, handles) 


function max_contrast_2_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slider_ind_data_set_Callback(hObject, eventdata, handles)
global status_plot_first   
status_plot_first = 1;  
plot_images(hObject, eventdata, handles) 


function slider_ind_data_set_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
