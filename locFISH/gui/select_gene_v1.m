function varargout = select_gene_v1(varargin)
% SELECT_FEATURE_V1 MATLAB code for select_feature_v1.fig

% Last Modified by GUIDE v2.5 07-Jun-2017 14:46:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @select_gene_v1_OpeningFcn, ...
                   'gui_OutputFcn',  @select_gene_v1_OutputFcn, ...
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
function select_gene_v1_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

%- Get name of genes 
gene_name           = getappdata(0,'gene_name');
ind_gene_selected   = getappdata(0, 'ind_gene_selected');


set(handles.listbox1, 'String' ,gene_name);
set(handles.listbox1, 'Max' ,length(gene_name));
set(handles.listbox1,'Value',ind_gene_selected);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes select_feature_v1 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Executes on button press in Select.
function Select_Callback(hObject, eventdata, handles)

index_selected         = get(handles.listbox1,'Value');
list                   = get(handles.listbox1,'String');
item_selected          = {list{index_selected}};
gene_selected          = item_selected;

setappdata(0,'ind_gene_selected',index_selected) ; 
setappdata(0,'gene_selected',gene_selected) ; 

close('gcf')


% --- Outputs from this function are returned to the command line.
function varargout = select_gene_v1_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
