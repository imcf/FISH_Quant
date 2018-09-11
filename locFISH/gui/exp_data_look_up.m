function varargout = exp_data_look_up(varargin)
% EXP_DATA_LOOK_UP MATLAB code for exp_data_look_up.fig
%      EXP_DATA_LOOK_UP, by itself, creates a new EXP_DATA_LOOK_UP or raises the existing
%      singleton*.
%
%      H = EXP_DATA_LOOK_UP returns the handle to a new EXP_DATA_LOOK_UP or the handle to
%      the existing singleton*.
%
%      EXP_DATA_LOOK_UP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EXP_DATA_LOOK_UP.M with the given input arguments.
%
%      EXP_DATA_LOOK_UP('Property','Value',...) creates a new EXP_DATA_LOOK_UP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before exp_data_look_up_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to exp_data_look_up_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help exp_data_look_up

% Last Modified by GUIDE v2.5 12-Jul-2017 13:18:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @exp_data_look_up_OpeningFcn, ...
                   'gui_OutputFcn',  @exp_data_look_up_OutputFcn, ...
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


% --- Executes just before exp_data_look_up is made visible.
function exp_data_look_up_OpeningFcn(hObject, eventdata, handles, varargin)

%- Default parameters for deep-zoom image
handles.par_deepzoom.nX = 50000;
handles.par_deepzoom.nY = 50000;
handles.par_deepzoom.pad = 200;
handles.par_deepzoom.scale_img = 1.5;
handles.par_deepzoom.N_save_tmp = 500;
handles.par_deepzoom.N_cells_proc = -1;
handles.ind_point = [] ; 

set(handles.select_gene,'Enable','off');
set(handles.select_feature,'Enable','off');
set(handles.classification,'Enable','off');
set(handles.gene_plot,'Enable','off');
set(handles.tSNE,'Enable','off');
set(handles.classif_plot,'Enable','off');
set(handles.select_cell,'Enable','off');
set(handles.show_detection,'Enable','off');
set(handles.show_features,'Enable','off');

% Choose default command line output for exp_data_look_up
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = exp_data_look_up_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --------------------------------------------------------------------
function load_results_ClickedCallback(hObject, eventdata, handles)
[file_name, path_name] = uigetfile('*.csv');
if file_name == 0; return; end

handles.loc_features_name = fullfile(path_name,file_name );
handles.loc_features      =  readtable(handles.loc_features_name); %- Load the table with the loc features

table_feat       = handles.loc_features;
feature_names     = table_feat.Properties.VariableNames ; 
feature_names     = feature_names(1:length(feature_names) - 8); %- Get the name of the loc features
feature_selected  = feature_names ;  %- At first, all features are considered selected

%- All features 
setappdata(0,'feature_names', feature_names); %- all feature name
handles.feature_selected = feature_selected ; 

%- Selected localization features (by default)
str_list    = feature_selected;
str_default = define_feat_default();
[C,ia,ib]   = intersect(str_list, str_default);
setappdata(0,'ind_feature_selected', ia); 
setappdata(0,'features_selected',{feature_selected{ia}}) ; %- feature selected ( here, same as feature_name)

%- Gene name
gene_name     = unique(handles.loc_features.gene_name);
gene_selected = gene_name; %- Name of all genes

%- All genes 
setappdata(0,'gene_name', gene_name);%- all gene name
setappdata(0,'ind_gene_selected', 1:1:length(gene_selected));
setappdata(0,'gene_selected',transpose(gene_selected)) ; %- gene selected ( here, same as gene_name)

handles.gene_selected = transpose(gene_selected) ; 
handles = create_subset_table_v1(handles);

%- Set the number of classes to the number of genes
set(handles.Kclass,'String',num2str(length(gene_selected)));

%- Other structures
handles.data_tSNE            = []; 
handles.data_tSNE_classif    = []; 
handles.data_classif_results = []; %- When loading new table, clear table of previous tSNE proj and classif results

button_handler_v1(handles)

msgbox('Data loaded. Now please select the genes that you want to classify, the number of classes, and perform clustering.');

guidata(hObject, handles);


% --- Executes on button press in tSNE.
function tSNE_Callback(hObject, eventdata, handles)

handles.features_selected = getappdata(0,'features_selected'); %- all feature name ;
handles                   = create_subset_table_v1(handles);

handles.data_tSNE        = tSNE_proj_v1(handles,2); % Perform the tSNE projection to display the cells
handles                  = plot_tSNE(handles);
button_handler_v1(handles)

guidata(hObject, handles);


% --- Executes on button press in select_gene.
function select_gene_Callback(hObject, eventdata, handles)
select_gene_v1;  %- Select the genes to put in the analysis

handles.data_tSNE            = []; 
handles.data_tSNE_classif    = []; 
handles.data_classif_results = []; %- When changing the genes, clear table of previous tSNE proj and classif results

guidata(hObject, handles);


% --- Executes on button press in select_cell.
function select_cell_Callback(hObject, eventdata, handles)
[x, y]        = ginput(1);
handles.group = [x y];  %- Get the coordinate where user clicked

dist_points = distmat(handles.group, handles.data_tSNE);
[min_d handles.ind_point] = min(dist_points);  %- Find the closest cell to the click

show_cell_v2(handles); %- Load and display image of the corresponding cell
button_handler_v1(handles);
guidata(hObject, handles);


% --- Executes on button press in show_detection.
function show_detection_Callback(hObject, eventdata, handles)
show_cell_v2(handles); %- Display the cell and the detection of mRNA


% --- Executes on button press in classification.
function classification_Callback(hObject, eventdata, handles)
handles.features_selected = getappdata(0,'features_selected'); %- all feature name ;
handles                   = create_subset_table_v1(handles);

if isempty(handles.data_tSNE)   
    handles.data_tSNE        = tSNE_proj_v1(handles,2); % Perform the tSNE projection to display the cells
end

handles = classif_exp_v1(handles); %- Perform classification of the cells
classif_plot_v1(handles); %- Plot the classif results
button_handler_v1(handles)

guidata(hObject, handles);


% --- Executes on button press in classification.
function Kclass_Callback(hObject, eventdata, handles)
handles.data_classif_results = []; 
guidata(hObject, handles);


% --- Executes on button press in classification.
function n_tSNE_Callback(hObject, eventdata, handles)
handles.data_tSNE_classif    = [];  %- When changing the number of tSNE components, clear table of previous tSNE proj and classif results
handles.data_classif_results = []; 
guidata(hObject, handles);


% --- Executes on button press in select_feature.
function select_feature_Callback(hObject, eventdata, handles)
select_feature_v1;
handles.data_tSNE            = []; 
handles.data_tSNE_classif    = []; 
handles.data_classif_results = [] ; %- When changing the features, clear table of previous tSNE proj and classif results
button_handler_v1(handles);

guidata(hObject, handles);


% --- Executes on button press in classif_plot.
function classif_plot_Callback(hObject, eventdata, handles)
classif_plot_v1(handles); %- Plot the classification results


% --- Executes on button press in gene_plot.
function gene_plot_Callback(hObject, eventdata, handles)
plot_tSNE(handles);%- Plot the tSNE proj results


% --- Executes on button press in classif_tSNE.
function classif_tSNE_Callback(hObject, eventdata, handles)
handles.data_tSNE_classif    = []; 
button_handler_v1(handles);
guidata(hObject, handles);


% --- Executes on button press in number_classes.
function number_classes_Callback(hObject, eventdata, handles)
handles = Number_classes_v1(handles);  %- Perform classif for # number of classes and compute a score for each
guidata(hObject, handles);


% --- Executes on button press in show_features.
function show_features_Callback(hObject, eventdata, handles)
show_feature_exp_v1(handles) %- Show features value of the currently displayed cell in the total distribution. 


% --- Change options for creating of high-resolution image
function options_large_image_Callback(hObject, eventdata, handles)

%- Define input dialog
dlgTitle = 'Parameter for high-res img';

prompt(1) = {'Image-size in X [pix - max is 65K]'};
prompt(2) = {'Image-size in X [pix - max is 65K]'};
prompt(3) = {'Down-scaling factor for cells'};
prompt(4) = {'Padding around image [pix]'};
prompt(5) = {'Save tmp image after N cells (-1 to not save)'};
prompt(6) = {'Number of randomly selected cells (-1 for all)'};

defaultValue{1} = num2str(handles.par_deepzoom.nX);
defaultValue{2} = num2str(handles.par_deepzoom.nY);
defaultValue{3} = num2str(handles.par_deepzoom.scale_img);
defaultValue{4} = num2str(handles.par_deepzoom.pad);
defaultValue{5} = num2str(handles.par_deepzoom.N_save_tmp);
defaultValue{6} = num2str(handles.par_deepzoom.N_cells_proc);

userValue = inputdlg(prompt,dlgTitle,1,defaultValue);

if( ~ isempty(userValue))
    handles.par_deepzoom.nX = str2double(userValue{1});
    handles.par_deepzoom.nY  = str2double(userValue{2});   
    handles.par_deepzoom.scale_img = str2double(userValue{3});   
    handles.par_deepzoom.pad       = str2double(userValue{4});
    handles.par_deepzoom.N_save_tmp  = str2double(userValue{5});
    handles.par_deepzoom.N_cells_proc   = str2double(userValue{6});
    guidata(hObject, handles);
end

% --------------------------------------------------------------------
% Create large image with classification results for deepzoom
function create_large_image_Callback(hObject, eventdata, handles)

disp('CREATING LARGE ZOOMABLE IMAGE .... this will take some time.')
set(gcf,'pointer','watch')

%- Create folder to save high res images
path_save = fullfile(fileparts(handles.loc_features_name),'dzi_tsne');
if ~exist(path_save); mkdir(path_save); end

%- Requires two variables
%       data_tSNE ... 2D coordinates of each cell
%       loc_features_gene_selected ... results of each cell
loc_features = handles.loc_features_gene_selected;
data_tSNE    = handles.data_tSNE;

%- Get general parameters of deep-zoom image
nX = handles.par_deepzoom.nX;
nY = handles.par_deepzoom.nY;
scale_img = handles.par_deepzoom.scale_img;
pad = handles.par_deepzoom.pad; % Padding to avoid that cells touch the border
N_save_tmp    = handles.par_deepzoom.N_save_tmp;
N_cells_proc  = handles.par_deepzoom.N_cells_proc;

%- Create empty image matrix
img_mask = uint8(255*ones(nY, nX));

%- Make tSNE coordinates positive
data_tSNE(:,1) = data_tSNE(:,1) + abs(min(data_tSNE(:,1)));
data_tSNE(:,2) = data_tSNE(:,2) + abs(min(data_tSNE(:,2)));

%- Invert y-coordinates to match deepzoom image to t-SNE from GUI
tsne_y_max     = max(data_tSNE(:,2));
data_tSNE(:,2) = abs(data_tSNE(:,2)-tsne_y_max-1);

%- Analyze tSNE space to get scaling factor
dX_tSNE = max(data_tSNE(:,1)) - min(data_tSNE(:,1));
dY_tSNE = max(data_tSNE(:,2)) - min(data_tSNE(:,2));

scale_X = floor((nX-2*pad)/dX_tSNE);
scale_Y = floor((nY-2*pad)/dY_tSNE);

%- FQ object
FQ_obj = FQ_img;

%- Loop over all cells
if N_cells_proc <0
    N_cells = size(loc_features,1); 
    ind_open = (1:N_cells);
else
    N_cells = N_cells_proc;
    ind_open = randperm(N_cells);
end

%- Initiate progress bar
progressbar               % Initialize/reset
progressbar(0)            % Initialize/reset
progressbar('Create large image for DeepZoom')      % Initialize/reset and label the bar

%- Resukts that are alrady open
file_open = '';

%- Loop over cells
for iLoop = 1:N_cells
    

progressbar(iLoop/N_cells)
    
    %- Get actual index of cell
    iCell = ind_open(iLoop);
    
    %- Open outline
    cell_selected = loc_features(iCell,:);
    file_loop     = cell_selected.results_GMM{1};
    
    if ~strcmp(file_loop,file_open)   
        FQ_obj.reinit();
        status_load = FQ_obj.load_results(file_loop,[],0);
        file_open = file_loop;
    end
   
    %- If file cannot be opened, skip to next iteration
    if ~status_load.outline
        disp('Cannot open outline')
        disp(cell_selected.results_GMM{1})
        continue; 
    end
    
    %- Get which cell to display in the detection results structure
    cell_selected_name = cell_selected.cell_name{1};
    ind_cell_outline = find(cell2array(cellfun(@(x) strfind(x,strcat(cell_selected_name,'_')), {FQ_obj.cell_prop.label},'UniformOutput',false))); 
    
    %- Only continue if only one cell from outline file could be matched
    if isempty(ind_cell_outline); continue; end
    if length(ind_cell_outline) > 1; continue; end
    
    %- Get cell properties of cell        
    cell_prop = FQ_obj.cell_prop(ind_cell_outline);   
    pix_xy = FQ_obj.par_microscope.pixel_size.xy;
    
    %- Rescale
    cell_x = round(cell_prop.x/scale_img);
    cell_y = round(cell_prop.y/scale_img);
    
    nuc_x = round(cell_prop.pos_Nuc.x/scale_img);
    nuc_y = round(cell_prop.pos_Nuc.y/scale_img);
    
    spot_x = round(( (cell_prop.spots_fit(:,2)./ pix_xy) + 2) / scale_img);
    spot_y = round(( (cell_prop.spots_fit(:,1)./ pix_xy) + 2) / scale_img);
    
    %- This can bug sometimes - ignore cell if it does
    try
        min_x  = min(cell_x);
        min_y  = min(cell_y);
    catch
       continue 
    end

    %=== Create small image of the cell - will be added to deepzoom image
    disk_1     = strel('disk',1);
    disk_2     = strel('disk',2);
    
    %- Brings coords to 0
    cell_x = cell_x - min_x;  
    cell_y = cell_y - min_y;
    
    nuc_x = nuc_x - min_x;  
    nuc_y = nuc_y - min_y;
    
    spot_x = uint16(spot_x - min_x);  
    spot_y = uint16(spot_y - min_y);
    
    %- Border of cell
    mask_cell = poly2mask(cell_y, cell_x, max(cell_x), max(cell_y));    
    img_cell  = mask_cell - imerode(mask_cell, disk_2);
    
    %- Border of nucleus
    mask_nuc = poly2mask(nuc_y, nuc_x, max(cell_x), max(cell_y));    
    mask_nuc_border = mask_nuc - imerode(mask_nuc, disk_1);
    img_cell(logical(mask_nuc_border)) = 1;
    
    %== mRNA spots
    
    %- make sure that coordinates are not outside of image
    spot_x(spot_x==0) = 1;
    spot_y(spot_y==0) = 1;
    
    spot_x(spot_x>size(mask_cell,1)) = size(mask_cell,1);
    spot_y(spot_y>size(mask_cell,2)) = size(mask_cell,2);
    
    %- Add mRNA spots to image
    img_spots = zeros(size(img_cell));
    linearInd_spots = sub2ind(size(img_spots), spot_x, spot_y);    
    img_spots(linearInd_spots) = 1;   
    img_spots = imdilate(img_spots,disk_1);
    
    img_cell(logical(img_spots)) = 1;
    
    %- Add border around cell
    img_cell(:,1) = 1;img_cell(:,end) = 1;
    img_cell(1,:) = 1;img_cell(end,:) = 1;
    
    %- Invert image
    img_cell = ~logical(img_cell);
    img_cell = uint8(255*img_cell);
    
    %==== Get cell label 
    hfigtxt = figure; set(hfigtxt,'color','w'); set(hfigtxt,'visible','off'); axis off

    %- Generate figure with text
    text(0,0,cell_selected.gene_name(1), 'col', 'black', 'FontSize',18, 'Interpreter', 'none')
    im = print(hfigtxt,'-RGBImage','-r0');
    close(hfigtxt);

    %- Convert figure to video frame and then image matrix
    VideoFrame         = im2frame(im);
    img_text_RGB       = frame2im(VideoFrame);
    img_text_8bit      = rgb2gray(img_text_RGB);
    img_text_8bit_crop = uint8(255*((RemoveWhiteSpace(img_text_8bit))));
    
    pad_x              = size(img_text_8bit_crop,2)+2 - size(img_cell,2);
    img_cell           = [img_cell  255.*ones(size(img_cell,1),pad_x)];
    
    
    
    img_cell(3:size(img_text_8bit_crop,1)+2,3:size(img_text_8bit_crop,2)+2) = img_text_8bit_crop;
   
    %==== Add to deepzoom image
    
    %- Get coordinates of t-SNE
    x_pos = round(data_tSNE(iCell,1)*scale_X) + pad;
    y_pos = round(data_tSNE(iCell,2)*scale_Y) - pad;
    
    %- Get coordinates where image should be placed
    [img_cell_NY, img_cell_NX] = size(img_cell);
    
    y_add_min = floor(y_pos - img_cell_NY/2);
    y_add_max = floor(y_pos + img_cell_NY/2-1);
    
    x_add_min = floor(x_pos - img_cell_NX/2);
    x_add_max = floor(x_pos + img_cell_NX/2-1);
    
    %- Add image of cell in large image - continue if bugs
    try
        img_mask(y_add_min:y_add_max,x_add_min:x_add_max) = uint8(img_cell);  
    catch
       disp('Could not place this cell!')
       continue
    end
    
    %- save intermediate image for inspection
    if (N_save_tmp > 0) && rem(iLoop,N_save_tmp) == 0
        name_save = fullfile(path_save,'tsne_highres_temp.tif');
        imwrite(uint8(img_mask),name_save)
    end
end

progressbar(1) % Close progressbar

%close (h_fig)
disp('Finished')

%- Convert to RBG
%Im = ind2rgb(X,map);

% = Save deep-zoom image
name_save = fullfile(path_save,'tsne_highres.tif');
imwrite(uint8(img_mask),name_save)

set(gcf,'Pointer','arrow')


function button_handler_v1(handles)

if ~isempty(handles.loc_features_gene_selected_feature_selected)
    set(handles.select_gene,'Enable','on');
    set(handles.select_feature,'Enable','on');
    set(handles.classification,'Enable','on');
    set(handles.tSNE,'Enable','on');
else
    set(handles.select_gene,'Enable','off');
    set(handles.select_feature,'Enable','off');
    set(handles.classification,'Enable','off');
    set(handles.tSNE,'Enable','off');
end

if ~isempty(handles.data_tSNE)
    set(handles.gene_plot,'Enable','on');
    set(handles.select_cell,'Enable','on');
else
    set(handles.gene_plot,'Enable','off');
    set(handles.select_cell,'Enable','off');
    set(handles.show_detection,'Enable','off');
    set(handles.show_features,'Enable','off');
end


if ~isempty(handles.data_classif_results)
    set(handles.classif_plot,'Enable','on');
else
    set(handles.classif_plot,'Enable','off');
end


if ~isempty(handles.data_classif_results)
    set(handles.classif_plot,'Enable','on');
else
    set(handles.classif_plot,'Enable','off');
end

if ~isempty(handles.ind_point)
    
    set(handles.show_detection,'Enable','on');
    set(handles.show_features,'Enable','on');
    
end

%==========================================================================
%  NOT USED
%==========================================================================

function nRNA_lim_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function nRNA_lim_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function n_tSNE_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Kclass_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in color_gene.
function color_gene_Callback(hObject, eventdata, handles)

% --- Executes on button press in colored_classif.
function colored_classif_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function adv_options_Callback(hObject, eventdata, handles)
