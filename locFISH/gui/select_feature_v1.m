function varargout = select_feature_v1(varargin)
% SELECT_FEATURE_V1 MATLAB code for select_feature_v1.fig
%      SELECT_FEATURE_V1, by itself, creates a new SELECT_FEATURE_V1 or raises the existing
%      singleton*.
%
%      H = SELECT_FEATURE_V1 returns the handle to a new SELECT_FEATURE_V1 or the handle to
%      the existing singleton*.
%
%      SELECT_FEATURE_V1('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELECT_FEATURE_V1.M with the given input arguments.
%
%      SELECT_FEATURE_V1('Property','Value',...) creates a new SELECT_FEATURE_V1 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before select_feature_v1_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to select_feature_v1_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help select_feature_v1

% Last Modified by GUIDE v2.5 22-May-2018 15:06:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @select_feature_v1_OpeningFcn, ...
                   'gui_OutputFcn',  @select_feature_v1_OutputFcn, ...
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


% --- Executes just before select_feature_v1 is made visible.
function select_feature_v1_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for select_feature_v1
handles.output = hObject;

%- Get default features
handles.feat_default = define_feat_default;

%- Get name of localization features
feature_names       = getappdata(0,'feature_names');
ind_feature_selected = getappdata(0, 'ind_feature_selected');

set(handles.listbox1, 'String',feature_names);
set(handles.listbox1, 'Max' ,length(feature_names));

set(handles.listbox1,'Value',ind_feature_selected);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes select_feature_v1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Executes on button press in button_select_default.
function button_select_default_Callback(hObject, eventdata, handles)
str_list    = get(handles.listbox1,'String');
str_default = handles.feat_default;
[C,ia,ib]   = intersect(str_list, str_default);
set(handles.listbox1,'Value',ia);

%- Update handles structure
guidata(hObject, handles);


% --- Executes on button press in Select.
function Select_Callback(hObject, eventdata, handles)
index_selected         = get(handles.listbox1,'Value');
list                   = get(handles.listbox1,'String');
features_selected      = {list{index_selected}};

setappdata(0,'ind_feature_selected',index_selected) ; 
setappdata(0,'features_selected',features_selected) ; 

close('gcf')


% --- Outputs from this function are returned to the command line.
function varargout = select_feature_v1_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



