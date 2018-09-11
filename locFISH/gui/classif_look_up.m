function varargout = classif_look_up(varargin)
% CLASSIF_LOOK_UP MATLAB code for classif_look_up.fig
%      CLASSIF_LOOK_UP, by itself, creates a new CLASSIF_LOOK_UP or raises the existing
%      singleton*.
%
%      H = CLASSIF_LOOK_UP returns the handle to a new CLASSIF_LOOK_UP or the handle to
%      the existing singleton*.
%
%      CLASSIF_LOOK_UP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CLASSIF_LOOK_UP.M with the given input arguments.
%
%      CLASSIF_LOOK_UP('Property','Value',...) creates a new CLASSIF_LOOK_UP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before classif_look_up_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to classif_look_up_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help classif_look_up

% Last Modified by GUIDE v2.5 28-Jun-2017 17:46:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @classif_look_up_OpeningFcn, ...
    'gui_OutputFcn',  @classif_look_up_OutputFcn, ...
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


% --- Executes just before classif_look_up is made visible.
function classif_look_up_OpeningFcn(hObject, eventdata, handles, varargin)

handles.ind_image_navigation = [];
handles.output = hObject;
axes(handles.axes1); cla, axis off;
axes(handles.axes2); cla, axis off;

set(handles.Classification,'Enable','off');
set(handles.select_feature,'Enable','off');
set(handles.group_selection,'Enable','off');
set(handles.Previous,'Enable','off');
set(handles.Next,'Enable','off');
set(handles.show_feature,'Enable','off');
set(handles.show_detections,'Enable','off');

%- Define default features
feat_default = define_feat_default;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = classif_look_up_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;


%==========================================================================
% Load data
%==========================================================================
function uiopenfile_ClickedCallback(hObject, eventdata, handles)

%- Load table with localization features
[data_base_name,path_name] = uigetfile('*.csv') ;
if data_base_name == 0; return; end
handles.data_file_name     = fullfile(path_name,data_base_name);
tableFeatures              = readtable(handles.data_file_name , 'Delimiter',';');

if ~isempty(tableFeatures)     
set(handles.Classification,'Enable','on');
set(handles.select_feature,'Enable','on');
end

%- Analyze features
%  Only use entries before 'nRNA', the ones after are not localization features
feature_names       = tableFeatures.Properties.VariableNames;
n_feature           = find(cell2array(cellfun(@(x) strfind('nRNA',x), feature_names,'UniformOutput' ,0)) == 1) - 1;
feature_names_sel   = feature_names(1:n_feature);
tableFeatures_sel   = tableFeatures(:,1:n_feature);
tableInfo           = tableFeatures(:,n_feature+1:end);

%=== Get mRNA density parameters

%- Check if mRNA levels were defined as density (old version)
indexSTRING = strfind(feature_names, 'RNAdensity');

if ~isempty(find(not(cellfun('isempty', indexSTRING))))
    handles.density_sel = unique(tableFeatures.RNAdensity)';
else
    handles.density_sel = unique(tableFeatures.RNAlevel)';
end

set(handles.listbox_mRNA_density, 'Value' , 1);
set(handles.listbox_mRNA_density, 'String' ,handles.density_sel);
set(handles.listbox_mRNA_density, 'Max' ,length(handles.density_sel));

%=== Get pattern levels
pattern_level = unique(tableFeatures.pattern_strength);

%- Remove the non-relevant (NR) or (NA)
ind_NR = cellfun(@(x) strcmp('NR',x),pattern_level);
pattern_level(ind_NR) = [];

handles.pattern_level_sel = pattern_level';
set(handles.listbox_pattern_level, 'Value' ,1);
set(handles.listbox_pattern_level, 'String' ,pattern_level);
set(handles.listbox_pattern_level, 'Max' ,length(pattern_level));

%=== Get pattern levels
handles.pattern = unique(tableFeatures.cell_label);

%=== Save data to be used with other GUIs

%- All features - including file-names, ...
setappdata(0,'tableFeatures_all', tableFeatures);
setappdata(0,'feature_names_all', feature_names);

%- All localization features
setappdata(0,'tableFeatures', tableFeatures_sel);
setappdata(0,'feature_names', feature_names_sel);
setappdata(0,'tableInfo', tableInfo);

%- Selected localization features (by default first)
str_list    = feature_names_sel;
str_default = define_feat_default();
[C,ia,ib]   = intersect(str_list, str_default);
setappdata(0,'ind_feature_selected', ia);
setappdata(0,'features_selected',{feature_names_sel{ia}}) ; 

%- Prepare axis
axes(handles.axes1); cla, axis off;
title('Press Clustering to perform k-means clustering')
axes(handles.axes2); cla, axis off;

guidata(hObject, handles);


%==========================================================================
% Navigate cells
%==========================================================================

% --- Previous
function Previous_Callback(hObject, eventdata, handles)


set(handles.Next,'Enable','off');
set(handles.Previous,'Enable','off');
set(handles.group_selection,'Enable','off');

if isempty(handles.ind_image_navigation);
    warndlg('Select first a class for inspection');
    set(handles.Previous,'Enable','on'); 
    set(handles.Next,'Enable','on'); 
    set(handles.group_selection,'Enable','on');
   
    return; 
end

if  handles.ind_image_navigation  > 1
   
    handles.ind_image_navigation = handles.ind_image_navigation - 1 ;
    
    %- Show features
    if get(handles.show_feature, 'Value'); show_feature_v1(handles); end

    
    show_image_v1(handles);  
end

set(handles.Next,'Enable','on');
set(handles.Previous,'Enable','on');
set(handles.group_selection,'Enable','on');

guidata(hObject, handles);

% ---  Next
function Next_Callback(hObject, eventdata, handles)

set(handles.Next,'Enable','off');
set(handles.Previous,'Enable','off');
set(handles.group_selection,'Enable','off');


if isempty(handles.ind_image_navigation);
    warndlg('Select first a class for inspection');
    set(handles.Next,'Enable','on'); 
    set(handles.Previous,'Enable','on');  
   set(handles.group_selection,'Enable','on');
 
    return; 
end

if  handles.ind_image_navigation  < size(handles.data_feature_subset,1)
    handles.ind_image_navigation = handles.ind_image_navigation + 1 ;
    
    show_image_v1(handles);    
    if get(handles.show_feature, 'Value'); show_feature_v1(handles); end  
end

set(handles.Next,'Enable','on');
set(handles.Previous,'Enable','on');
set(handles.group_selection,'Enable','on');


guidata(hObject, handles);

%==========================================================================
% Actual classification
%==========================================================================

% --- Perform classification
function handles  = Classification_Callback(hObject, eventdata, handles)
disp('Performing clustering .....')

%- Selected mRNA levels
density_index  = get(handles.listbox_mRNA_density,'Value');
density_list   = get(handles.listbox_mRNA_density,'String');
if ischar(density_list); density_list = cellstr(density_list);end 
handles.density_sel    = {density_list{density_index}};

%- Selected pattern strength
pattern_index       = get(handles.listbox_pattern_level,'Value');
pattern_list        = get(handles.listbox_pattern_level,'String');
handles.pattern_sel = {pattern_list{pattern_index}};

%- Perform classification
handles  = classification_v1(handles);
disp(' ..... DONE!')

set(handles.Previous,'Enable','on');
set(handles.Next,'Enable','on');
set(handles.group_selection,'Enable','on');

guidata(hObject, handles);

% --- Select features that will be selected for classification
function select_feature_Callback(hObject, eventdata, handles)
select_feature_v1;
guidata(hObject, handles);



%==========================================================================
% More detailed inspection
%==========================================================================

% --- Executes on button press in show_feature.
function show_feature_Callback(hObject, eventdata, handles)


set(handles.group_selection,'Enable','off');
set(handles.Next,'Enable','off');
set(handles.Previous,'Enable','off');

ind_feature      = get(handles.show_feature, 'Value');
ind_group_empty  =  ~isempty(handles.data_feature_subset);

if ind_feature*ind_group_empty
    show_feature_v1(handles);
end

set(handles.group_selection,'Enable','on');
set(handles.Next,'Enable','on');
set(handles.Previous,'Enable','on');

% --- Select a group for inspection
function group_selection_Callback(hObject, eventdata, handles)

set(handles.group_selection,'Enable','off');
set(handles.Next,'Enable','off');
set(handles.Previous,'Enable','off');

handles.ind_image_navigation  = 1;

%- Select square in confusion matrix
[x, y] = ginput(1);
handles.group = [x y];

ind_pattern            = floor(x - 0.5) + 1;
handles.pattern_image  = handles.pattern{ind_pattern};
handles.classif_image  = handles.ind_row(floor(y - 0.5) + 1);

data_feature_classif = handles.results_classif;
data_feature_subset = data_feature_classif(strcmp(data_feature_classif.cell_label, handles.pattern_image),:);
data_feature_subset = data_feature_subset(data_feature_subset.idx == handles.classif_image,:);

ind_true_family          = handles.ind_row(ind_pattern);

data_true_subset         = data_feature_classif(strcmp(data_feature_classif.cell_label, handles.pattern_image),:);
data_true_subset         = data_true_subset(data_true_subset.idx == ind_true_family,:);

handles.num_image = 1;

set(handles.title_image, 'String', strcat('pattern = ',handles.pattern_image, '---', 'classif = ', num2str(floor(y - 0.5) + 1)))

handles.data_true_subset    = data_true_subset;
handles.data_feature_subset = data_feature_subset;


if ~isempty(handles.data_feature_subset)

show_image_v1(handles);

%- Show features if desired
if get(handles.show_feature, 'Value')
    show_feature_v1(handles);
end


end

set(handles.group_selection,'Enable','on');
set(handles.Next,'Enable','on');
set(handles.Previous,'Enable','on');
set(handles.show_feature,'Enable','on');
set(handles.show_detections,'Enable','on');     



%- Save data
guidata(hObject, handles);

%- Select pattern levels to be analyzed
function show_detections_Callback(hObject, eventdata, handles)
show_image_v1(handles);

%==========================================================================
% NOT USED
%==========================================================================

function listbox_mRNA_density_Callback(hObject, eventdata, handles)

function listbox_pattern_level_Callback(hObject, eventdata, handles)

function feature_list_Callback(hObject, eventdata, handles)

function feature_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function listbox_mRNA_density_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function PCA_Callback(hObject, eventdata, handles)
handles.param_PCA = get(handles.PCA, 'Value');

function ncomp_Callback(hObject, eventdata, handles)

function ncomp_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function tSNE_Callback(hObject, eventdata, handles)

function uitoggletool1_ClickedCallback(hObject, eventdata, handles)

function level_pattern_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function level_pattern_KeyPressFcn(hObject, eventdata, handles)

function listbox_pattern_level_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_show_confusion_separate_Callback(hObject, eventdata, handles)

function show_tSNE_Callback(hObject, eventdata, handles)
