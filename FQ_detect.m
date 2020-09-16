function varargout = FQ_detect(varargin)
% FQ_DETECT MATLAB code for FQ_detect.fig
%      FQ_DETECT, by itself, creates a new FQ_DETECT or raises the existing
%      singleton*.
%
%      H = FQ_DETECT returns the handle to a new FQ_DETECT or the handle to
%      the existing singleton*.
%
%      FQ_DETECT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FQ_DETECT.M with the given input arguments.
%
%      FQ_DETECT('Property','Value',...) creates a new FQ_DETECT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FQ_detect_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FQ_detect_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FQ_detect

% Last Modified by GUIDE v2.5 22-Jun-2017 14:40:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FQ_detect_OpeningFcn, ...
                   'gui_OutputFcn',  @FQ_detect_OutputFcn, ...
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


% --- Executes just before FQ_detect is made visible.
function FQ_detect_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

%- Initiate FQ object and save
img = FQ_img;
setappdata(0,'img',img)

%- Flag for how to determine where images are stored
handles.flags.path_img = 'HCS_Montpellier';
handles.version_GMM    = 'v0';

%- Launch parallel pool if not already launched
poolobj = gcp('nocreate');

if isempty(poolobj)
    disp('Starting parallel pool ... will take a few seconds')
    poolobj = parpool;
end
    
if ~isempty(poolobj)
    N_worker = poolobj.NumWorkers;
else
    N_worker = 1;
end

set(handles.text_N_cells,'String',num2str(N_worker));

%- Populate filter
popup_filter_type_Callback(hObject, eventdata, handles)

%- Update handles structure
guidata(hObject, handles);

function varargout = FQ_detect_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;


%% ====== MISC FUNCTIONS===================================================

%=== Pop-up to select filter
function button_define_path_img_Callback(hObject, eventdata, handles)
disp('Specify folder containing the images')
path_img = uigetdir();
if path_img ~= 0
    handles.flags.path_img = 'Specified';
    handles.path_img = path_img;
    
    %- Update handles structure
    guidata(hObject, handles);
end

%=== Pop-up to select filter
function popup_filter_type_Callback(hObject, eventdata, handles)

str = get(handles.popup_filter_type,'Value');
val = get(handles.popup_filter_type,'String');

img = getappdata(0,'img');

switch val{str}
    
    case '3D_LoG'
                
        set(handles.text_kernel_factor_bgd_xy,'String',num2str(img.settings.filter.LoG_H));
        set(handles.text_kernel_factor_filter_xy,'String',num2str(img.settings.filter.LoG_sigma));
        
        set(handles.text_kernel_factor_bgd_z,'Visible','off');
        set(handles.text_kernel_factor_filter_z,'Visible','off');        
        
        set(handles.text_filt_1,'String','Size');
        set(handles.text_filt_2,'String','Standard deviation (sigma)');
        
        
    case '3D_2xGauss'
                
        set(handles.text_kernel_factor_bgd_xy,'String',num2str(img.settings.filter.kernel_size.bgd_xy));
        set(handles.text_kernel_factor_bgd_z,'String',num2str(img.settings.filter.kernel_size.bgd_z));
        set(handles.text_kernel_factor_filter_xy,'String',num2str(img.settings.filter.kernel_size.psf_xy));
        set(handles.text_kernel_factor_filter_z,'String',num2str(img.settings.filter.kernel_size.psf_z));
          
        set(handles.text_filt_1,'String','Kernel BGD [pixel]: XY, Z');
        set(handles.text_filt_2,'String','Kernel SNR [pixel]: XY, Z'); 
        
        set(handles.text_kernel_factor_bgd_z,'Visible','on');
        set(handles.text_kernel_factor_filter_z,'Visible','on');

        
    otherwise
        warndlg('INCORRECT SELECTION',mfilename)
        
end
     

%=== Pop-up to open outline
function button_open_outline_Callback(hObject, eventdata, handles)

%- Get file name
[file_name_outline,path_name_outline] = uigetfile({'*.txt'},'Select file');

if file_name_outline ~= 0
        
    %- Replacements for HCS with Montpellier
    switch handles.flags.path_img
        
        case 'HCS_Montpellier'
            path_img = strrep(path_name_outline,'Analysis','Acquisition');
            path_img = strrep(path_img,['FQ_outlines',filesep],'');
           
        case 'Specified'
            path_img = handles.path_img;
    end
    
    %-Get FQ object, reinit, load data
    img = getappdata(0,'img');    
    img.reinit;
    
    disp('Loading  outline and image ....')
    status = img.load_results(fullfile(path_name_outline,file_name_outline),path_img); 

    %- Check if outline file was found
    if status.outline == 0
        disp('No outline file found!')
        disp(fullfile(path_name_outline,file_name_outline))
        return
    end
    
    %- Check if outline file was found
    if status.img == 0
        disp('Image could not be opened!')
        disp(path_img)
        return
    end
    
    img.path_names.outlines = path_name_outline;
    img.file_names.outlines = file_name_outline;
    setappdata(0,'img',img)
    
    %- Analyse image
    disp('Analyzing outline and filtering images cropped around cells ....')
    analyse_outline(handles)
    
    %- Populate outline
    listbox_cells_Callback(hObject, eventdata, handles)
    disp('finished')

end
    

%==== Function to analyze the saved outlines, crop cells and filter them
function analyse_outline(handles)

img = getappdata(0,'img');  

N_cells      = numel(img.cell_prop);
N_cells_proc = str2double(get(handles.text_N_cells,'String'));
N_proc       = min([N_cells N_cells_proc]);

%- Allocate space 
img_crop = {};
img_crop{N_proc} = [];

img_filtered_2D = img_crop;
img_filtered_3D = img_crop;
str_menu = img_crop;
pixel_cell_2D_list = img_crop;

%- Prepare filter
str = get(handles.popup_filter_type,'String');
val = get(handles.popup_filter_type,'Value');
filter_type = str{val};

img = getappdata(0,'img');
img.settings.filter.method = filter_type;

switch filter_type
    
    case '3D_LoG'
        img.settings.filter.LoG_H = str2double(get(handles.text_kernel_factor_bgd_xy,'String'));
        img.settings.filter.LoG_sigma = str2double(get(handles.text_kernel_factor_filter_xy,'String'));  
        filt_log = fspecialCP3D('3D LoG, Raj', img.settings.filter.LoG_H, img.settings.filter.LoG_sigma);
        
    case '3D_2xGauss'
        img.settings.filter.kernel_size.bgd_xy = str2double(get(handles.text_kernel_factor_bgd_xy,'String'));
        img.settings.filter.kernel_size.bgd_z  = str2double(get(handles.text_kernel_factor_bgd_z,'String'));
        img.settings.filter.kernel_size.psf_xy = str2double(get(handles.text_kernel_factor_filter_xy,'String'));
        img.settings.filter.kernel_size.psf_z  = str2double(get(handles.text_kernel_factor_filter_z,'String'));
        kernel_size = img.settings.filter.kernel_size;
        flag_Gauss.output = 0;
end

setappdata(0,'img',img);

%- Loop over all cells to crop
cell_prop = img.cell_prop;
dim       = img.dim;

for iC = 1:N_proc
   
    %- Get name for list
    str_menu{iC,1} = cell_prop(iC).label;
    
    %- Get position of cell
    min_x = min(cell_prop(iC).x)-20;
    max_x = max(cell_prop(iC).x)+20;
    
    min_y = min(cell_prop(iC).y)-20;
    max_y = max(cell_prop(iC).y)+20;
    
    if min_x<1;          min_x = 1;       end
    if max_x>dim.X;  max_x=dim.X; end

    if min_y<1;          min_y = 1;       end
    if max_y>dim.Y;  max_y=dim.Y; end
    
    img_crop{iC} = img.raw(min_y:max_y,min_x:max_x,:);
    
    crop_dim(iC).min_x = min_x;
    crop_dim(iC).min_y = min_y;
    
    
end

%- Loop over all cells to filter
    
switch filter_type

    case '3D_LoG'
        parfor iC = 1:N_proc
            img_filtered_3D{iC} = abs(imfilter(double(img_crop{iC}), filt_log,'symmetric') *(-1)); 
            img_2D              = max(img_filtered_3D{iC},[],3);
            img_filtered_2D{iC} = img_2D;
            
            %- Make pixel-lists for 2D
            x_loop = cell_prop(iC).x - crop_dim(iC).min_x;
            y_loop = cell_prop(iC).y - crop_dim(iC).min_y;
            
            mask_cell_2D             = poly2mask(x_loop, y_loop, size(img_2D,1), size(img_filtered_2D{iC},2));
            pixel_cell_2D_list{iC} = img_2D(mask_cell_2D);
           
            
        end
        
    case '3D_2xGauss'
        parfor iC = 1:N_proc
            img_filtered_3D{iC} = img_filter_Gauss_v5(img_crop{iC},kernel_size,flag_Gauss);
            img_2D              = max(img_filtered_3D{iC},[],3);
            img_filtered_2D{iC} = img_2D;
            
            %- Make pixel-lists for 2D
            x_loop = cell_prop(iC).x - crop_dim(iC).min_x;
            y_loop = cell_prop(iC).y - crop_dim(iC).min_y;
            
            mask_cell_2D             = poly2mask(x_loop, y_loop, size(img_2D,1), size(img_filtered_2D{iC},2));
            pixel_cell_2D_list{iC} =  img_2D(mask_cell_2D);
        end
end
    

%- Calc Otsu for all images and determine median value as a recommended threshold
for iC = 1:N_proc
    pixel_list_cell = pixel_cell_2D_list{iC};
    
    thresh_1 = multithresh(pixel_list_cell,1);
    thresh_2 = multithresh(pixel_list_cell,2);
    median_list = median(pixel_list_cell);
    
    if thresh_1     > 10*median_list   %- Happens if bright structures are present
        thresh_auto.all(iC) = thresh_2(1);
    elseif thresh_1 < 2*median_list    % Happens when background shows dim patches
        thresh_auto.all(iC) = thresh_2(2);
    else
        thresh_auto.all(iC) = thresh_1;
    end
             
end

thresh_auto.median = round(median(thresh_auto.all));
set(handles.txt_threshold,'String',num2str(thresh_auto.median));


%- Save data
setappdata(0,'crop_dim',crop_dim); 
setappdata(0,'crop_dim',crop_dim); 
setappdata(0,'img_filtered_2D',img_filtered_2D); 
setappdata(0,'pixel_cell_2D_list',pixel_cell_2D_list); 
setappdata(0,'img_filtered_3D',img_filtered_3D); 


%- Update list box
set(handles.listbox_cells,'String',str_menu);
set(handles.listbox_cells,'Value',1);


%===== Apply pre-detection
function button_detect_Callback(hObject, eventdata, handles)

%- Get data
crop_dim = getappdata(0,'crop_dim'); 
img      = getappdata(0,'img'); 
crop_dim = getappdata(0,'crop_dim'); 
ind_cell = get(handles.listbox_cells,'Value');

%- Determine detection method
str = get(handles.popupmenu_predetect_mode,'String');
val = get(handles.popupmenu_predetect_mode,'Value');
detection_method = str{val};

thresh_int = str2double(get(handles.txt_threshold,'String'));
img.settings.detect.thresh_int = thresh_int;


%- Determine dimensionality
str = get(handles.popup_dim,'String');
val = get(handles.popup_dim,'Value');
detect_dim = str{val};

switch detect_dim

    case '2D'
        img_proc = getappdata(0,'img_filtered_2D'); 
        
    case '3D'
        img_proc = getappdata(0,'img_filtered_3D'); 
        
end

img_proc = img_proc{ind_cell};

%- Perform detection
switch detection_method

    case 'Local maximum'
        img.settings.detect.method = 'nonMaxSupr';
        reg_size.xy = str2double(get(handles.text_detect_region_xy,'String'));
        reg_size.z  = str2double(get(handles.text_detect_region_z,'String'));
        
        img.settings.detect.flags.reg_pos_sep = 1;
        img.settings.detect.reg_size.xy_sep   = reg_size.xy;
        img.settings.detect.reg_size.z_sep    = reg_size.z;
        
        switch detect_dim
             case '3D'
                rad_detect = [reg_size.xy reg_size.xy reg_size.z];  
            case '2D'
                rad_detect = [reg_size.xy reg_size.xy];
        end
        
         pos_pre_detect = nonMaxSupr(double(img_proc), rad_detect,thresh_int);
        
    case 'Connected components'
        img.settings.detect.method = 'connectcomp';
        
        %- Connected components
        par_ccc.conn        = 26;   % Connectivity in 3D
        par_ccc.thresholds  = thresh_int;
        [dum, dum, CC]      = multithreshstack_v4(img_proc,par_ccc);
        
        %- Get centroid of each identified region
        CC_best = CC{1};
        S = regionprops(CC_best,'Centroid');
        N_spots = CC_best.NumObjects;

        centroid_linear  = [S.Centroid]';
        
        %- Check if detection is 2D or 3D
        switch detect_dim

                case '3D'
                    centroid_matrix      = round(reshape(centroid_linear,3,N_spots))';
                case '2D'
                    centroid_matrix      = round(reshape(centroid_linear,2,N_spots))';
                    centroid_matrix(:,3) = 1;
        end
            
        pos_pre_detect = []; 
        pos_pre_detect(:,1) = centroid_matrix(:,2);
        pos_pre_detect(:,2) = centroid_matrix(:,1);
        pos_pre_detect(:,3) = centroid_matrix(:,3);
        
        
end

%- Make sure spots are in cell
cell_poly(:,2) = img.cell_prop(ind_cell).x - crop_dim(ind_cell).min_x;
cell_poly(:,1) = img.cell_prop(ind_cell).y - crop_dim(ind_cell).min_y;

if ~isempty(pos_pre_detect)
    ind_good = inpoly(pos_pre_detect(:,1:2),cell_poly);
    pos_pre_detect = pos_pre_detect(ind_good,:);
end
N_detect = size(pos_pre_detect,1);

set(handles.txt_N_detect,'String',num2str(N_detect));

%- Save settings
setappdata(0,'img',img);

if isfield(handles,'h_spots') && ~isempty(isgraphics(handles.h_spots))
    delete(handles.h_spots)
end

%- Plot detections
axes(handles.axes1);  
hold on
handles.h_spots = plot(pos_pre_detect(:,2),pos_pre_detect(:,1),'or');
hold off

% Update handles structure
guidata(hObject, handles);


%===== Plot image
function listbox_cells_Callback(hObject, eventdata, handles)

img     = getappdata(0,'img'); 
N_cells = numel(img.cell_prop);

%- return if there are no cells
if N_cells == 0
    return
end


%- Get current contrast
ind_cell = get(handles.listbox_cells,'Value');
if ind_cell > N_cells
    set(handles.listbox_cells,'Value',N_cells)
    return
end
    
%- Get current contrast
contr = get(handles.axes1,'CLim');

% Check if contrast value were already set
if contr(2) == 1
    contr = [];
end

%- Prepare plot
clear handles.h_spots
axes(handles.axes1);   
crop_dim = getappdata(0,'crop_dim'); 
img_mip = getappdata(0,'img_filtered_2D'); 
pixel_list = getappdata(0,'pixel_cell_2D_list'); 

%- Get position of cell
x = img.cell_prop(ind_cell).x - crop_dim(ind_cell).min_x;
y = img.cell_prop(ind_cell).y - crop_dim(ind_cell).min_y;

%- Show cell with outline
imshow(img_mip{ind_cell},contr);
hold on          

    plot([x,x(1)],[y,y(1)],'y','Linewidth', 2) 
hold off  
%button_contrast_Callback(hObject, eventdata, handles)

%- Perform detection
button_detect_Callback(hObject, eventdata, handles)


%=== Enable/disable plotting the spots
function check_box_show_spots_Callback(hObject, eventdata, handles)

if isfield(handles,'h_spots') && ~isempty(isgraphics(handles.h_spots))

    if get(handles.check_box_show_spots,'Value')
        set(handles.h_spots,'Visible','on')
    else
        set(handles.h_spots,'Visible','off')
    end

end
    

%=== Open window to change contrast
function button_contrast_Callback(hObject, eventdata, handles)
imcontrast(handles.axes1);


%==== Save settings
function button_save_settings_Callback(hObject, eventdata, handles)

%- Get data
img = getappdata(0,'img');

%- Get pixel-size
img.par_microscope.pixel_size.xy = str2double(get(handles.txt_pixel_xy,'String'));
img.par_microscope.pixel_size.z  = str2double(get(handles.txt_pixel_z,'String'));

%- Get file-names for settings
switch handles.flags.path_img

    case 'HCS_Montpellier'
        str_folder = ['FQ_results__Script_',handles.version_GMM,'__',datestr(date,'yymmdd')];
        path_settings = strrep(img.path_names.outlines,'FQ_outlines',str_folder);

    case 'Specified'
        
        %- Create string for new folder
        str_folder = ['FQ_results__',datestr(date,'yymmdd')];
        
        %- Create folder in parental directory
        %  Not elegant but didn't find another way .... 
        current_dir = pwd;
        cd(fullfile(img.path_names.outlines,'..'))
        parent_dir = pwd;
        path_settings = fullfile(parent_dir,str_folder);
        cd(current_dir)
end    
    
%- Create folder if necessary
if ~exist(path_settings); mkdir(path_settings); end  
file_name_full = fullfile(path_settings,'_FQ_settings_MATURE.txt');

%- Save settings
[file_save, path_save] = save_settings(img,file_name_full);
disp(' === SETTINGS saved')
disp(file_save)
disp(path_save)


%% ====== NOT USED ========================================================

function text_kernel_factor_bgd_xy_Callback(hObject, eventdata, handles)

function text_kernel_factor_bgd_xy_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_filter_xy_Callback(hObject, eventdata, handles)

function text_kernel_factor_filter_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_filter_type_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_bgd_z_Callback(hObject, eventdata, handles)

function text_kernel_factor_bgd_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_kernel_factor_filter_z_Callback(hObject, eventdata, handles)

function text_kernel_factor_filter_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu_predetect_mode_Callback(hObject, eventdata, handles)

function popupmenu_predetect_mode_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detect_region_xy_Callback(hObject, eventdata, handles)

function text_detect_region_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_detect_region_z_Callback(hObject, eventdata, handles)

function text_detect_region_z_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function listbox_cells_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_N_cells_Callback(hObject, eventdata, handles)

function text_N_cells_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_auto_threshold_Callback(hObject, eventdata, handles)

function popup_auto_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_pixel_xy_Callback(hObject, eventdata, handles)

function txt_pixel_xy_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_pixel_z_Callback(hObject, eventdata, handles)

function txt_pixel_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_dim_Callback(hObject, eventdata, handles)

function popup_dim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_dim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_threshold_Callback(hObject, eventdata, handles)

function txt_threshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function txt_N_detect_Callback(hObject, eventdata, handles)

function txt_N_detect_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
