function varargout = FQ_OutlineSecond(varargin)
% FQ_OUTLINESECOND MATLAB code for FQ_OutlineSecond.fig
%      FQ_OUTLINESECOND, by itself, creates a new FQ_OUTLINESECOND or raises the existing
%      singleton*.
%
%      H = FQ_OUTLINESECOND returns the handle to a new FQ_OUTLINESECOND or the handle to
%      the existing singleton*.
%
%      FQ_OUTLINESECOND('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FQ_OUTLINESECOND.M with the given input arguments.
%
%      FQ_OUTLINESECOND('Property','Value',...) creates a new FQ_OUTLINESECOND or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FQ_OutlineSecond_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FQ_OutlineSecond_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FQ_OutlineSecond

% Last Modified by GUIDE v2.5 09-Mar-2016 10:21:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FQ_OutlineSecond_OpeningFcn, ...
                   'gui_OutputFcn',  @FQ_OutlineSecond_OutputFcn, ...
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


% --- Executes just before FQ_OutlineSecond is made visible.
function FQ_OutlineSecond_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FQ_OutlineSecond (see VARARGIN)

% Choose default command line output for FQ_OutlineSecond
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FQ_OutlineSecond wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FQ_OutlineSecond_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button_outlines_change_color.
function button_outlines_change_color_Callback(hObject, eventdata, handles)

parameters.name_str.old = get(handles.text_rename_old,'String');
parameters.name_str.new = get(handles.text_rename_new,'String');

FQ3_outline_replace_color_v2(parameters)

function text_rename_old_Callback(hObject, eventdata, handles)
% hObject    handle to text_rename_old (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_rename_old as text
%        str2double(get(hObject,'String')) returns contents of text_rename_old as a double


% --- Executes during object creation, after setting all properties.
function text_rename_old_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_rename_old (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function text_rename_new_Callback(hObject, eventdata, handles)
% hObject    handle to text_rename_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of text_rename_new as text
%        str2double(get(hObject,'String')) returns contents of text_rename_new as a double


% --- Executes during object creation, after setting all properties.
function text_rename_new_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_rename_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
