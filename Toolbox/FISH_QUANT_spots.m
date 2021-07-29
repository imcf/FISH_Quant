function varargout = FISH_QUANT_spots(varargin)
% FISH_QUANT_SPOTS MATLAB code for FISH_QUANT_spots.fig
%      FISH_QUANT_SPOTS, by itself, creates a new FISH_QUANT_SPOTS or raises the existing
%      singleton*.
%
%      H = FISH_QUANT_SPOTS returns the handle to a new FISH_QUANT_SPOTS or the handle to
%      the existing singleton*.
%
%      FISH_QUANT_SPOTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FISH_QUANT_SPOTS.M with the given input arguments.
%
%      FISH_QUANT_SPOTS('Property','Value',...) creates a new FISH_QUANT_SPOTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FISH_QUANT_spots_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FISH_QUANT_spots_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FISH_QUANT_spots

% Last Modified by GUIDE v2.5 03-May-2016 11:04:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_spots_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_spots_OutputFcn, ...
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


% --- Executes just before FISH_QUANT_spots is made visible.
function FISH_QUANT_spots_OpeningFcn(hObject, eventdata, handles, varargin)


%- Set font-size to 10
%  Fonts on windows are set back to 8 when the .fig is openend
h_font_8 = findobj(handles.h_fishquant_spots,'FontSize',8);
set(h_font_8,'FontSize',10)

%- Get installation directory of FISH-QUANT and initiate 
p = mfilename('fullpath');        
handles.FQ_path = fileparts(p); 
handles.img.col_par = FQ_define_col_results_v1; %- Columns of results file    

%= Some parameters
handles.status_data_cursor = 0;
handles.status_zoom = 0;
handles.status_cursor = 0;
handles.h_zoom = rand(1);
handles.status_pan = 0;
handles.status_plot_first = 1;  % Indicate if plot command was never used
handles.h_pan = rand(1);

handles.marker_size_spot = 10;
handles.marker_extend_z  = 3;

handles.h_spots_in  = [];
handles.h_spots_out  = [];
handles.h_spots_out_man = [];

%= Load data if called from other GUI

%- Some controls are different when spot inspector is called from main
%interface or as stand-alone GUI
handles.status_child = 0;
set(handles.checkbox_remove_man,'Enable','on')

%==== Path-name
handles.path_name_root          = [];
handles.path_name_image         = [];
handles.path_name_outline       = [];
handles.path_name_results       = [];
handles.path_name_settings      = [];
    
%= Some other parameters
handles.ident_caller = [];    

%- Check if called from another GUI
if not(isempty(varargin))
    
    if strcmp( varargin{1},'HandlesMainGui')
    
        %- Specific controls 
        handles.status_child = 1;
        set(handles.checkbox_remove_man,'Enable','off')

        %- Read data from Main GUI
        handles_MAIN = varargin{2};       
        handles.img  = handles_MAIN.img;
    
        %- Change name of GUI
        set(handles.h_fishquant_spots,'Name', ['FISH-QUANT ', handles.img.version, ': spot inspector']);
        
        %- Other parameters        
        handles.marker_extend_z = handles.img.settings.detect.reg_size.z;

        %- Analyze results
        handles = analyze_image(hObject, eventdata, handles);

        %- Analyze detected regions
        handles = analyze_cellprop(hObject, eventdata, handles);    

        %- Check if cell was selected
        if isfield(handles_MAIN,'ind_cell_sel')
            set(handles.pop_up_cell_select,'Value',handles_MAIN.ind_cell_sel);
        end
       
        
        %- Set selector of plot-type accordingly 
        handles.ident_caller = varargin{1};   

         if      strcmp( varargin{1},'HandlesMainGui') 
            set(handles.pop_up_view,'Value',1);

         elseif  strcmp( varargin{1},'MS2Q_2D')    
            set(handles.pop_up_view,'Value',2);  
         end         

        %- Save everything
        guidata(hObject, handles); 
        handles = plot_image(hObject, eventdata, handles);
        
        
    elseif strcmp( varargin{1},'par_main')         
        
        par_main                  = varargin{2};
        handles.img               = FQ_img;
        handles.img.path_names    = par_main.path_names; 
     
    elseif strcmp( varargin{1},'file')         
        
        %- Name of file
        file_load   = varargin{2};
        handles.file_load = file_load;
        
        %- FQ_img object, path_names, and par_microscope
        handles.img            = FQ_img;
        handles.img.path_names = varargin{3};      
        handles.par_microscope = varargin{4};
        
        %- Load outline file
        handles = load_results_file(file_load,hObject, eventdata, handles);
        
    end
end

%- Export figure handle to workspace - will be used in Close All button of
% main Interface
assignin('base','h_spots',handles.h_fishquant_spots)

%- Matlab stuff
handles.output = hObject;
guidata(hObject, handles);
%uiresume(handles.h_fishquant_spots)

% --- Outputs from this function are returned to the command line.
function varargout = FISH_QUANT_spots_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes when user attempts to close h_fishquant_spots.
function h_fishquant_spots_CloseRequestFcn(hObject, eventdata, handles)
if handles.status_child 
    %uiresume(handles.h_fishquant_outline)
else    
    delete(handles.h_fishquant_spots)
end




% =========================================================================
% TOOLBAR
% =========================================================================

%=== LOAD OUTLINES
function tool_load_ClickedCallback(hObject, eventdata, handles)

%- Go to directory with results
current_dir = pwd;

if not(isempty(handles.img.path_names.results))
   cd(handles.img.path_names.results)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

%- Get directory with images
if  not(isempty(handles.img.path_names.img))
    path_image = handles.img.path_names.img;
elseif not(isempty(handles.img.path_names.root))
    path_image = handles.img.path_names.root;
else
    path_image = cd;
end

%- Ge results
[file_name_results,path_name_results] = uigetfile({'*.txt'},'Select file with results of spot detection');

if file_name_results ~= 0
    file_load.path = path_name_results;
    file_load.name = file_name_results;
    file_load.path_img = path_image;
    handles = load_results_file(file_load,hObject, eventdata, handles);
    guidata(hObject, handles); 
end

%- Go back to original directory
cd(current_dir)

%=== SAVE OUTLINES
function tool_save_ClickedCallback(hObject, eventdata, handles)

%- Get current directory and go to directory with outlines
current_dir = cd;

if     not(isempty(handles.img.path_names.results))
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root))
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)


%- Parameters to save results
parameters.path_save           = path_save;
parameters.path_save_settings  = path_save;
parameters.path_name_image     = handles.img.path_names.img;
parameters.version             = handles.img.version;
parameters.flag_type           = 'spots';  

handles.img.save_results([],parameters);
guidata(hObject, handles);

%- Go back to original directory
cd(current_dir)


%=== Options
function tool_options_ClickedCallback(hObject, eventdata, handles)
dlgTitle = 'Different parameters for visualization';

prompt(1) = {'Size for circles to show spots'};
prompt(2) = {'[Z-stack] show spots for +/- frames'};

defaultValue{1} = num2str(handles.marker_size_spot);
defaultValue{2} = num2str(handles.marker_extend_z);

userValue = inputdlg(prompt,dlgTitle,1,defaultValue);

if( ~ isempty(userValue))
    handles.marker_size_spot = str2double(userValue{1}); 
    handles.marker_extend_z = str2double(userValue{2});     
end

guidata(hObject, handles);


%=== Data cursor
function tool_cursor_ClickedCallback(hObject, eventdata, handles)

%- Delete region inspector if present
if isfield(handles,'h_impixregion')   
    if ishandle(handles.h_impixregion)
        delete(handles.h_impixregion)
    end
end

%- Datacursormode
dcm_obj = datacursormode;
drawnow;

set(dcm_obj,'SnapToDataVertex','off');
set(dcm_obj,'DisplayStyle','window');
set(dcm_obj,'UpdateFcn',@(x,y)myupdatefcn(x,y,hObject,handles))



% =========================================================================
% Load and save
% =========================================================================


%== Menu: save results of spot detection
function menu_save_spots_Callback(hObject, eventdata, handles)


%- Get current directory and go to directory with outlines
current_dir = cd;

if     not(isempty(handles.img.path_names.results))
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)) 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)


%- Parameters to save results
parameters.path_save           = path_save;
parameters.path_save_settings  = path_save;
parameters.path_name_image     = handles.img.path_names.img;
parameters.version             = handles.img.version;
parameters.flag_type           = 'spots';  

handles.img.save_results([],parameters);
guidata(hObject, handles);

%- Go back to original directory
cd(current_dir)


%=== Menu: load results of spot detection
function menu_load_spots_Callback(hObject, eventdata, handles)

%- Go to directory with results
current_dir = pwd;

if not(isempty(handles.img.path_names.results))
   cd(handles.img.path_names.results)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

%- Get directory with images
if  not(isempty(handles.img.path_names.img))
    path_image = handles.img.path_names.img;
elseif not(isempty(handles.img.path_names.root))
    path_image = handles.img.path_names.root;
else
    path_image = cd;
end

%- Ge results
[file_name_results,path_name_results] = uigetfile({'*.txt'},'Select file with results of spot detection');

if file_name_results ~= 0
    file_load.path = path_name_results;
    file_load.name = file_name_results;
    file_load.path_img = path_image;
    handles = load_results_file(file_load,hObject, eventdata, handles);
    guidata(hObject, handles); 
end

%- Go back to original directory
cd(current_dir)


%=== Load results of spot detection
function handles = load_results_file(file_load,hObject, eventdata, handles)

%- Reset GUI
FISH_QUANT_spots_OpeningFcn(hObject, eventdata, handles); 

%- Load results
status_file = handles.img.load_results(fullfile(file_load.path,file_load.name),file_load.path_img);    

if ~status_file.img
    warndlg('Image could not be opened!','FISH-quant')
    fprintf('=== FILE COULD NOT BE OPENED\n');
    disp('Often this is caused because folders for results or images are badly defined.')
    fprintf('\nResults [name]: %s\n',file_load.name)
    fprintf('Results [path]: %s\n\n',file_load.path)
    fprintf('Image [path]: %s\n\n',file_load.path_img)

elseif ~status_file.outline
    warndlg('Outline could not be opened!','FISH-quant')
    fprintf('=== FILE COULD NOT BE OPENED\n');
    disp('Often this is caused because folders for results or images are badly defined.')
    fprintf('\nResults [name]: %s\n',file_load.name)
    
else

    %- Load settings files
    if not(isempty(handles.img.file_names.settings))
        handles.img.load_settings(fullfile(handles.img.path_names.results,handles.img.file_names.settings));                
    end    
    %[cell_prop.FIT_Result] = deal([]);

        %- Load filtered image if specified 
        if not(isempty(handles.img.file_names.filtered))
            handles.img.load_img(fullfile(file_load.path_img,handles.img.file_names.filtered),'filt'); 
        end    

        %- Analyze results
        handles = analyze_image(hObject, eventdata, handles);

        %- Analyze detected regions
        handles = analyze_cellprop(hObject, eventdata, handles);    

        %- Save everything
        handles = plot_image(hObject, eventdata, handles);
        guidata(hObject, handles); 
end


%= Function to analyze detected regions
function handles = analyze_image(hObject, eventdata, handles)

%- Change name of GUI
if not(isempty(handles.img.file_names.raw))
    set(handles.h_fishquant_spots,'Name', ['FQ ', handles.img.version, ': spot inspector - ', handles.img.file_names.raw ]);
else
    set(handles.h_fishquant_spots,'Name', ['FQ ', handles.img.version, ': spot inspector']);
end

%- Slider values for contrast: RAW
handles.slider_contr_min_img  = 0;
handles.slider_contr_max_img  = 1;  

%- Slider values for contrast: FILTERED
handles.slider_contr_min_img_filt  = 0;
handles.slider_contr_max_img_filt  = 1;

%- Analyze image
handles.img_plot =  handles.img.raw_proj_z;
handles.img_min  =  min(handles.img.raw(:)); 
handles.img_max  =  max(handles.img.raw(:)); 
handles.img_diff =  handles.img_max-handles.img_min; 

set(handles.text_contr_min,'String',num2str(round(handles.img_min)));
set(handles.text_contr_max,'String',num2str(round(handles.img_max)));

%- Analyze filtered image
handles.img_filt_plot =  handles.img.filt_proj_z;
handles.img_filt_min  =  min(handles.img.filt(:)); 
handles.img_filt_max  =  max(handles.img.filt(:)); 
handles.img_filt_diff =  handles.img_filt_max-handles.img_filt_min; 

%- Image is plotted for the first time
handles.status_plot_first = 1;

%- Save everything
guidata(hObject, handles); 


%= Function to analyze detected regions
function handles = analyze_cellprop(hObject, eventdata, handles)

cell_prop = handles.img.cell_prop;

%- Populate pop-up menu with labels of cells
N_cell = size(cell_prop,2);

[dim.Y, dim.X, dim.Z] = size(handles.img.raw);

if N_cell > 0

    %- Call pop-up function to show results and bring values into GUI
    for i = 1:N_cell
        str_menu{i,1} = cell_prop(i).label;
     
        %- Calculate projections for plot with montage function
        spots_proj_GUI = [];
        
        
        %- Check if Fit_result is define
        if ~isfield(cell_prop(i),'FIT_Result')
            cell_prop(i).FIT_Result = {};
        end
        
        %- Check if FIT_results contains something
        if  isempty(cell_prop(i).FIT_Result)
        
            
            for k=1:size(cell_prop(i).spots_detected,1)

                if any(isnan(cell_prop(i).spots_detected(:,4))) 
                    continue
                end
                
                spots_detected = cell_prop(i).spots_detected;

                y_min = spots_detected(k,4);
                y_max = spots_detected(k,5);
                x_min = spots_detected(k,6);
                x_max = spots_detected(k,7);         
                z_min = spots_detected(k,8);
                z_max = spots_detected(k,9);

                img_sub = handles.img.raw(y_min:y_max,x_min:x_max,z_min:z_max);            

                spots_proj_GUI(k).xy = max(img_sub,[],3);
                spots_proj_GUI(k).xz = squeeze(max(img_sub,[],1))';
                spots_proj_GUI(k).yz = squeeze(max(img_sub,[],2))'; 
                
                spots_proj_GUI(k).xy_fit = [];
                spots_proj_GUI(k).xz_fit = [];
                spots_proj_GUI(k).yz_fit = []'; 
                
            end
            
        else
            for k=1:length(cell_prop(i).FIT_Result)
                spot_image = cell_prop(i).sub_spots{k};
                spot_fit   = cell_prop(i).FIT_Result{k}.img_fit;
                
                spots_proj_GUI(k).xy = max(spot_image,[],3);
                spots_proj_GUI(k).xz = squeeze(max(spot_image,[],1))';
                spots_proj_GUI(k).yz = squeeze(max(spot_image,[],2))'; 
                
                spots_proj_GUI(k).xy_fit = max(spot_fit,[],3);
                spots_proj_GUI(k).xz_fit = squeeze(max(spot_fit,[],1))';
                spots_proj_GUI(k).yz_fit = squeeze(max(spot_fit,[],2))';  
                
            end
            
        end            
            
        %- Save results
        cell_prop(i).spots_proj_GUI  = spots_proj_GUI;
    end  
else
    str_menu = {' '};
end

%- Save and analyze results
set(handles.pop_up_cell_select,'String',str_menu);
set(handles.pop_up_cell_select,'Value',1);

handles.img.cell_prop  = cell_prop;

%- Save everything
guidata(hObject, handles); 


% =========================================================================
% Different functions
% =========================================================================

%=== Manually remove one data-point
function checkbox_remove_man_Callback(hObject, eventdata, handles)
datacursormode off

ind_spot = str2double(get(handles.text_spot_id,'String'));

if not(isnan(ind_spot))

    %- Which cell
    ind_cell   = get(handles.pop_up_cell_select,'Value');
    
    check_box = get(handles.checkbox_remove_man,'Value');
        
    if check_box == 1
        handles.img.cell_prop(ind_cell).thresh.in(ind_spot) = -1;
     else
        handles.img.cell_prop(ind_cell).thresh.in(ind_spot) = 1;
    end
       
    %- Uncheck check-box and start datacursormode again
    set(handles.checkbox_remove_man,'Value',0);
    
    %- Save everything and plot
    handles = plot_image(hObject, eventdata, handles);
    guidata(hObject, handles); 
end


%=== Options
function menu_options_Callback(hObject, eventdata, handles)

dlgTitle = 'Different parameters for visualization';

prompt(1) = {'Size for circles to show spots'};
prompt(2) = {'[Z-stack] show spots for +/- frames'};

defaultValue{1} = num2str(handles.marker_size_spot);
defaultValue{2} = num2str(handles.marker_extend_z);

userValue = inputdlg(prompt,dlgTitle,1,defaultValue);

if( ~ isempty(userValue))
    handles.marker_size_spot = str2double(userValue{1}); 
    handles.marker_extend_z = str2double(userValue{2});     
end

guidata(hObject, handles);
 

%=== Close window
function button_close_window_Callback(hObject, eventdata, handles)
button = questdlg('Are you sure that you want to close the GUI?','Close GUI','Yes','No','No');

if strcmp(button,'Yes')    
    delete(handles.h_fishquant_spots)   
end


% =========================================================================
% Plot
% =========================================================================

%=== Plot image
function handles = plot_image(hObject, eventdata, handles)

%datacursormode off

col_par    = handles.img.col_par;
pixel_size = handles.img.par_microscope.pixel_size;

%= Flag to determine if cell labels are shown
flag_show_cell_label = get(handles.checkbox_show_cell_label,'Value');

%= Flag to indicate if all outlines are shown
flag_show_all_cells = get(handles.checkbox_show_all_cells,'Value');

%= Flag to determine if spots are shown
flag_show_spots = get(handles.checkbox_show_spots,'Value');

%= Flag to determine which spots to plot
flag_good_only = get(handles.checkbox_good_only,'Value');
flag_bad_only  = get(handles.checkbox_bad_only,'Value');

%= Flag to determine if spot ID is shown or not
flag_spot_ID = get(handles.checkbox_show_spot_ID,'Value');

%== Select output axis
axes(handles.axes_main)
v = axis;

x_min = v(1);
x_max = v(2);
y_min = v(3);
y_max = v(4);
    

%== Determine which view: MIP or 3D stack
str = get(handles.pop_up_view, 'String');
val = get(handles.pop_up_view,'Value');

switch str{val}
    case 'Maximum projection' 
        status_z_stack = 0;
        set(handles.text_z_slice,'String','');
    
    case '3D-Stack'        
        status_z_stack = 1;
        ind_slice = str2double(get(handles.text_z_slice,'String'));
        
        z_min = ind_slice - handles.marker_extend_z;
        z_max = ind_slice + handles.marker_extend_z;

        if z_min < 1; z_min = 1;end
        if z_max > handles.img.dim.Z; z_max = handles.img.dim.Z; end
end

%== Select which image
str_img = get(handles.pop_up_img_sel,'String');
val_img = get(handles.pop_up_img_sel,'Value');

switch str_img{val_img}
    
    case 'Raw image'
        img_min  = handles.img_min;
        img_diff = handles.img_diff;        
        
        if status_z_stack == 0
            img_plot = handles.img_plot;
        else
            img_plot = handles.img.raw(:,:,ind_slice);
        end
        
    case 'Filtered image'  
        img_min  = handles.img_filt_min;
        img_diff = handles.img_filt_diff;
        
        
        if status_z_stack == 0
            img_plot = handles.img_filt_plot;
        else
            img_plot = handles.img.filt(:,:,ind_slice); 
        end
end
handles.img_plot_GUI = img_plot;

%== Determine the contrast of the image

%- Minimum
slider_min = get(handles.slider_contrast_min,'Value');
contr_min  = slider_min*img_diff+img_min;

%- Maximum
slider_max = get(handles.slider_contrast_max,'Value');
contr_max = slider_max*img_diff+img_min;
if contr_max < contr_min
    contr_max = contr_min+1;
end

set(handles.text_contr_min,'String',num2str(round(contr_min)));
set(handles.text_contr_max,'String',num2str(round(contr_max)));

%== Save slider values
switch str_img{val_img}
    
     case 'Raw image'         
            handles.slider_contr_min_img  = slider_min;
            handles.slider_contr_max_img  = slider_max;  
     case 'Filtered image'      
            handles.slider_contr_min_img_filt  = slider_min;
            handles.slider_contr_max_img_filt  = slider_max;
end

%== Show image
handles.h_img = imshow(img_plot,[contr_min contr_max]);
axis off

%==== Which cell?
ind_cell      = get(handles.pop_up_cell_select,'Value');

%- SPOTS: continue only if spots are defined
cell_prop       = handles.img.cell_prop; 
spots_fit       = handles.img.cell_prop(ind_cell).spots_fit;
spots_detected  = handles.img.cell_prop(ind_cell).spots_detected;
thresh          = handles.img.cell_prop(ind_cell).thresh;


%- Show spots
if not(isempty(spots_fit))

    %- Select spots which will be shown
    ind_plot_in      = thresh.in == 1;
    ind_plot_out     = thresh.in == 0;
    ind_plot_out_man = thresh.in == -1 ;

    ind_all      = 1:length(thresh.in);  

    %- Plot spots
    if status_z_stack == 1 
        ind_spots_range = spots_detected(:,3) >= z_min & spots_detected(:,3) <= z_max; 
    else
        ind_spots_range = true(size(ind_plot_in));
    end

    %- Get the relative indices - separate plots for the spots but in
    %  the selection we refer back to the complete lists of spots
    handles.ind_rel_in      = ind_all(ind_spots_range & ind_plot_in);
    handles.ind_rel_out     = ind_all(ind_spots_range & ind_plot_out);
    handles.ind_rel_out_man = ind_all(ind_spots_range & ind_plot_out_man); 

    %- Plot only good spots
    if flag_good_only
        ind_plot_out = 0;
        ind_plot_out_man = 0;
    end
    
    %- Plot only good spots
    if flag_bad_only
        ind_plot_in = 0;
    end
    

    %=== Plot spots if any are in range & if selected to be shown      
    if flag_show_spots
        
        hold on  
        
        %- Rejected spots (auto)
        if sum(ind_spots_range & ind_plot_out)

            if flag_spot_ID

                ind_plot_all = find(ind_spots_range & ind_plot_out);
                N_plot = length(ind_plot_all);

                for i_text = 1: N_plot

                    ind_text = ind_plot_all(i_text);
                    x_pos    = spots_fit(ind_text,col_par.pos_x)/pixel_size.xy + 2;
                    y_pos    = spots_fit(ind_text,col_par.pos_y)/pixel_size.xy;
                    if x_pos > x_min && x_pos < x_max && y_pos > y_min && y_pos < y_max    
                        text(x_pos,y_pos,num2str(ind_text),'Color','b')      
                    end
                end
            end

           handles.h_spots_out = plot((spots_fit(ind_spots_range & ind_plot_out,col_par.pos_x)/pixel_size.xy + 1), (spots_fit(ind_spots_range & ind_plot_out,col_par.pos_y)/pixel_size.xy + 1),'or','MarkerSize',handles.marker_size_spot);

        else
            handles.h_spots_out = 0;
        end

        %- Rejected spots (manual)
        if sum(ind_spots_range & ind_plot_out_man)

            if flag_spot_ID

                ind_plot_all = find(ind_spots_range & ind_plot_out_man);
                N_plot = length(ind_plot_all);

                for i_text = 1: N_plot

                    ind_text = ind_plot_all(i_text);
                    x_pos    = spots_fit(ind_text,col_par.pos_x)/pixel_size.xy + 2;
                    y_pos    = spots_fit(ind_text,col_par.pos_y)/pixel_size.xy;

                    if x_pos > x_min && x_pos < x_max && y_pos > y_min && y_pos < y_max
                        text(x_pos,y_pos,num2str(ind_text),'Color','m')      
                    end
                end
            end

           handles.h_spots_out_man = plot((spots_fit(ind_spots_range & ind_plot_out_man,col_par.pos_x)/pixel_size.xy + 1), (spots_fit(ind_spots_range & ind_plot_out_man,col_par.pos_y)/pixel_size.xy + 1),'om','MarkerSize',handles.marker_size_spot);

        else
            handles.h_spots_out_man = 0;
        end


        %- Good spots
        if sum(ind_spots_range & ind_plot_in)

            if flag_spot_ID

                ind_plot_all = find(ind_spots_range & ind_plot_in);
                N_plot = length(ind_plot_all);
                for i_text = 1: N_plot

                    ind_text = ind_plot_all(i_text);
                    x_pos    = spots_fit(ind_text,col_par.pos_x)/pixel_size.xy + 2;
                    y_pos    = spots_fit(ind_text,col_par.pos_y)/pixel_size.xy;

                    if x_pos > x_min && x_pos < x_max && y_pos > y_min && y_pos < y_max
                        text(x_pos,y_pos,num2str(ind_text),'Color','g')      
                    end
                end
            end

            handles.h_spots_in  = plot((spots_fit(ind_spots_range & ind_plot_in,col_par.pos_x)/pixel_size.xy + 1), (spots_fit(ind_spots_range & ind_plot_in,col_par.pos_y)/pixel_size.xy + 1),'og','MarkerSize',handles.marker_size_spot);


        else
            handles.h_spots_in = 0;
        end

        hold off  

        if     sum(ind_spots_range & ind_plot_in) && sum(ind_spots_range & ind_plot_out) && sum(ind_spots_range & ind_plot_out_man)
            legend('Rejected Spots','Rejected Spots [man]','Selected Spots');  

        elseif sum(ind_spots_range & ind_plot_in) && sum(ind_spots_range & ind_plot_out) 
            legend('Rejected Spots','Selected Spots');      

        elseif sum(ind_spots_range & ind_plot_in) && sum(ind_spots_range & ind_plot_out_man)
            legend('Rejected Spots [man]','Selected Spots');   

        elseif sum(ind_spots_range & ind_plot_out) && sum(ind_spots_range & ind_plot_out_man)
            legend('Rejected Spots [auto]','Rejected Spots [man]');     

        elseif sum(ind_spots_range & ind_plot_in) 
            legend('Selected Spots');      

        elseif sum(ind_spots_range & ind_plot_out)
            legend('Rejected Spots');   

        elseif sum(ind_spots_range & ind_plot_out_man)
            legend('Rejected Spots [man]');        
        end 
    
    end
    
%- Check if there are detected spots    
elseif ~isempty(spots_detected) && flag_show_spots
    
    ind_good =   logical(spots_detected(:,14));
    ind_bad  = ~ spots_detected(:,14);
    
    hold on
        plot(spots_detected(ind_good,2),spots_detected(ind_good,1),'og','MarkerSize',handles.marker_size_spot);
        plot(spots_detected(ind_bad,2),spots_detected(ind_bad,1),'or','MarkerSize',handles.marker_size_spot);
    hold off
    
end

%- Same zoom as before
if not(handles.status_plot_first)
    axis(v);
end

%- Show cell label
if flag_show_cell_label || flag_show_all_cells
    hold on        
    if not(isempty(cell_prop))  

        for i_cell = 1:size(cell_prop,2)

            x = cell_prop(i_cell).x;
            y = cell_prop(i_cell).y;

            if flag_show_all_cells
                plot([x,x(1)],[y,y(1)],'b','Linewidth', 2)

                if isfield(handles.img.cell_prop(ind_cell),'cluster_prop')
                    for i_c = 1: length(cell_prop(i_cell).cluster_prop);

                        y_sub = cell_prop(i_cell).cluster_prop(i_c).y;
                        x_sub = cell_prop(i_cell).cluster_prop(i_c).x;                    

                        plot(x_sub,y_sub,'.m','MarkerSize',3)
                    end    
                end


                 if isfield(handles.img.cell_prop(ind_cell),'aggregate_prop')
                    for i_a = 1: length(cell_prop(i_cell).aggregate_prop);

                        y_sub = cell_prop(i_cell).aggregate_prop(i_a).y;
                        x_sub = cell_prop(i_cell).aggregate_prop(i_a).x;                    

                        plot(x_sub,y_sub,'.c','MarkerSize',3)
                    end    
                end                   

            end


            if flag_show_cell_label

                [ geom] = polygeom( x, y ); 

                x_pos = geom(2);
                y_pos = geom(3);


                if x_pos > x_min && x_pos < x_max && y_pos > y_min && y_pos < y_max
                    text(x_pos,y_pos,cell_prop(i_cell).label,'Color','w','FontSize',12, 'Interpreter', 'none','BackgroundColor',[0 0 0],'FontWeight','bold');
                end
            end
        end
    end
end


%- Plot outline of cell and TS
hold on 
if not(isempty(cell_prop))  
    for i_cell = ind_cell:ind_cell %1:size(cell_prop,2)

        %- Cells
        x = cell_prop(i_cell).x;
        y = cell_prop(i_cell).y;
        plot([x,x(1)],[y,y(1)],'y','Linewidth', 2)               

        %- Nucleus
        pos_Nuc   = cell_prop(i_cell).pos_Nuc;   
        if not(isempty(pos_Nuc))  
            for i_nuc = 1:size(pos_Nuc,2)
                x = pos_Nuc(i_nuc).x;
                y = pos_Nuc(i_nuc).y;
                plot([x,x(1)],[y,y(1)],':y','Linewidth', 2)  
           end                
        end           

        %- TS
        pos_TS   = cell_prop(i_cell).pos_TS;   
        if not(isempty(pos_TS))  
            for i_TS = 1:size(pos_TS,2)
                x = pos_TS(i_TS).x;
                y = pos_TS(i_TS).y;
                plot([x,x(1)],[y,y(1)],'g','Linewidth', 2)  

            end                
        end  
    end   
end   
hold off


%- Show clusters
if isfield(handles.img.cell_prop(ind_cell),'cluster_prop')
    if ~isempty(handles.img.cell_prop(ind_cell).cluster_prop)
        
        for i_c = 1: length(handles.img.cell_prop(ind_cell).cluster_prop);
        
            x_sub = handles.img.cell_prop(ind_cell).cluster_prop(i_c).x;
            y_sub = handles.img.cell_prop(ind_cell).cluster_prop(i_c).y;
            
            hold on
                plot(x_sub,y_sub,'.m','MarkerSize',3)
            hold off
            
        end
            
    end
end



%- Show aggregates
if isfield(handles.img.cell_prop(ind_cell),'aggregate_prop')
    if ~isempty(handles.img.cell_prop(ind_cell).aggregate_prop)
        
  
        for i_a = 1: length(handles.img.cell_prop(ind_cell).aggregate_prop);
        
            x_sub = handles.img.cell_prop(ind_cell).aggregate_prop(i_a).x;
            y_sub = handles.img.cell_prop(ind_cell).aggregate_prop(i_a).y;
            
            hold on
                plot(x_sub,y_sub,'.c','MarkerSize',3)
            hold off
            
        end
            
    end
end
    

%- Same zoom as before
if not(handles.status_plot_first)
    axis(v);
end

%- Save everything
handles.status_plot_first = 0;
handles.h_fig_plot = gcf;
handles.h_gca_plot = gca;
guidata(hObject, handles); 


%- Update button down function
set(handles.h_img, 'ButtonDownFcn', @axes_main_ButtonDownFcn)
if not(isempty(spots_fit)) && flag_show_spots
    if handles.h_spots_in ~= 0;      set(handles.h_spots_in, 'ButtonDownFcn', @axes_main_ButtonDownFcn); end
    if handles.h_spots_out ~= 0 ;    set(handles.h_spots_out, 'ButtonDownFcn', @axes_main_ButtonDownFcn); end
    if handles.h_spots_out_man ~= 0; set(handles.h_spots_out_man, 'ButtonDownFcn', @axes_main_ButtonDownFcn); end
end


%== Slider: contrast minimum
function slider_contrast_min_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%== Slider: contrast maximum
function slider_contrast_max_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles); 


%== Slider to select z-plane
function slider_slice_Callback(hObject, eventdata, handles)
N_slice      = handles.img.dim.Z;
slider_value = get(handles.slider_slice,'Value');

ind_slice = round(slider_value*(N_slice-1)+1);
set(handles.text_z_slice,'String',num2str(ind_slice));

handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles); 


%== Up one slice
function button_slice_incr_Callback(hObject, eventdata, handles)
N_slice = handles.img.dim.Z;

%- Get next value for slice
ind_slice = str2double(get(handles.text_z_slice,'String'))+1;
if ind_slice > N_slice;ind_slice = N_slice;end
set(handles.text_z_slice,'String',ind_slice);

%-Update slider
slider_value = (ind_slice-1)/(N_slice-1);
set(handles.slider_slice,'Value',slider_value);

%- Save and plot image
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%== Down one slice
function button_slice_decr_Callback(hObject, eventdata, handles)
N_slice = handles.img.dim.Z;

%- Get next value for slice
ind_slice = str2double(get(handles.text_z_slice,'String'))-1;
if ind_slice <1;ind_slice = 1;end
set(handles.text_z_slice,'String',ind_slice);

%-Update slider
slider_value = (ind_slice-1)/(N_slice-1);
set(handles.slider_slice,'Value',slider_value);

%- Save and plot image
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%== Select different way to plot image
function pop_up_view_Callback(hObject, eventdata, handles)

str = get(handles.pop_up_view, 'String');
val = get(handles.pop_up_view,'Value');

% Set experimental settings based on selection
switch str{val};
    
    case 'Maximum projection' 
        set(handles.text_z_slice,'String',NaN);
        set(handles.slider_slice,'Value',0);
        
        set(handles.button_slice_decr,'Enable','off');
        set(handles.button_slice_incr,'Enable','off');        
        set(handles.slider_slice,'Enable','off'); 
    
    case '3D-Stack'
        set(handles.text_z_slice,'String',1);
        set(handles.slider_slice,'Value',0);
        
        set(handles.button_slice_decr,'Enable','on');
        set(handles.button_slice_incr,'Enable','on');        
        set(handles.slider_slice,'Enable','on'); 
end

handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles); 


%== Select raw vs. filtered image
function pop_up_img_sel_Callback(hObject, eventdata, handles)

%== Select which image
str_img = get(handles.pop_up_img_sel,'String');
val_img = get(handles.pop_up_img_sel,'Value');

switch str_img{val_img}    
    case 'Raw image'
        set(handles.slider_contrast_min,'Value',handles.slider_contr_min_img);
        set(handles.slider_contrast_max,'Value',handles.slider_contr_max_img);
        
    case 'Filtered image'
        set(handles.slider_contrast_min,'Value',handles.slider_contr_min_img_filt);
        set(handles.slider_contrast_max,'Value',handles.slider_contr_max_img_filt);
end

%- Plot
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%=== Image region
function button_image_region_Callback(hObject, eventdata, handles)%impixelregion(handles.axes_main)
if not(isfield(handles,'h_impixregion'))
    handles.h_impixregion = impixelregion(handles.axes_main);
else 
    if not(ishandle(handles.h_impixregion))
        handles.h_impixregion = impixelregion(handles.axes_main);
    end
end
guidata(hObject, handles);


%=== Data cursor
function button_image_data_cursor_Callback(hObject, eventdata, handles)

%- Delete region inspector if present
if isfield(handles,'h_impixregion')   
    if ishandle(handles.h_impixregion)
        delete(handles.h_impixregion)
    end
end

% %- Deactivate zoom
% if ishandle(handles.h_zoom)
%     set(handles.h_zoom,'Enable','off');  
% end
% 
% %- Deactivate pan
% if ishandle(handles.h_pan)
%     set(handles.h_pan,'Enable','off');  
% end

%- Datacursormode
dcm_obj = datacursormode;
drawnow;

set(dcm_obj,'SnapToDataVertex','off');
set(dcm_obj,'DisplayStyle','window');
set(dcm_obj,'UpdateFcn',@(x,y)myupdatefcn(x,y,hObject,handles))
          

%=== Function for Data cursor
function txt = myupdatefcn(empty,event_obj,hObject,handles)

%- Continue only if calling axes is the main axes in the GUI
hAxesParent  = get(get(event_obj,'Target'),'Parent');
if hAxesParent  ==   handles.axes_main
    col_par = handles.img.col_par;

    pos    = get(event_obj,'Position');
    target = get(event_obj,'Target');
    index  = get(event_obj,'DataIndex');

    %- Plot subregions of image
    if  any(target == handles.h_spots_in) || any(target == handles.h_spots_out)  || any(target == handles.h_spots_out_man)
       ind_cell   = get(handles.pop_up_cell_select,'Value');
       spots_fit  = handles.img.cell_prop(ind_cell).spots_fit;
       thresh     = handles.img.cell_prop(ind_cell).thresh;

       pixel_size    = handles.img.par_microscope.pixel_size;

       %- Get index of target and link back to original spot number   
       if         target == handles.h_spots_in
            spot_ind = handles.ind_rel_in(index);   
       elseif     target == handles.h_spots_out
            spot_ind = handles.ind_rel_out(index); 
       elseif     target == handles.h_spots_out_man
            spot_ind = handles.ind_rel_out_man(index);           
       end

       img_xy = handles.img.cell_prop(ind_cell).spots_proj_GUI(spot_ind).xy;
       img_xz = handles.img.cell_prop(ind_cell).spots_proj_GUI(spot_ind).xz;
       img_yz = handles.img.cell_prop(ind_cell).spots_proj_GUI(spot_ind).yz;

       fit_xy = handles.img.cell_prop(ind_cell).spots_proj_GUI(spot_ind).xy_fit;
       fit_xz = handles.img.cell_prop(ind_cell).spots_proj_GUI(spot_ind).xz_fit;
       fit_yz = handles.img.cell_prop(ind_cell).spots_proj_GUI(spot_ind).yz_fit;

       spot_pos.x = spots_fit(spot_ind,col_par.pos_x_sub);
       spot_pos.y = spots_fit(spot_ind,col_par.pos_y_sub);
       spot_pos.z = spots_fit(spot_ind,col_par.pos_z_sub);

       %- Plot the sub-images
       slider_min = handles.slider_contr_min_img;
       Im_min  = slider_min*handles.img_diff+handles.img_min;

       slider_max = handles.slider_contr_max_img;
       Im_max = slider_max*handles.img_diff+handles.img_min;

       handles.spots.img_xy = img_xy;
       handles.spots.Im_min = Im_min;
       handles.spots.Im_max = Im_max;

       %-XY
       pixel.x = pixel_size.xy;   pixel.y = pixel_size.xy;
       spot_plots.x = spot_pos.x; spot_plots.y = spot_pos.y;
       FQ_plot_spots_axes_v1(handles.axes_zoom_xy,img_xy,pixel,spot_plots,'Data - XY')
       
       
       %-XZ
       spot_plots.x = spot_pos.x; spot_plots.y = spot_pos.z;
       pixel.x = pixel_size.xy;   pixel.y = pixel_size.z;               
       FQ_plot_spots_axes_v1(handles.axes_zoom_xz,img_xz,pixel,spot_plots,'Data - XZ')

       %-YZ
       spot_plots.y = spot_pos.y; spot_plots.y = spot_pos.z;
       pixel.x = pixel_size.xy;   pixel.y = pixel_size.z;
       FQ_plot_spots_axes_v1(handles.axes_zoom_yz,img_yz,pixel,spot_plots,'Data - YZ')


       %- Plot fit
       if not(isempty(fit_xy))

           %-XY
           pixel.x = pixel_size.xy;   pixel.y = pixel_size.xy;
           spot_plots.x = spot_pos.x; spot_plots.y = spot_pos.y;
           FQ_plot_spots_axes_v1(handles.axes_fit_xy,fit_xy,pixel,spot_plots,'Fit - XY')

           %-XZ
           spot_plots.x = spot_pos.x; spot_plots.y = spot_pos.z;
           pixel.x = pixel_size.xy;   pixel.y = pixel_size.z;               
           FQ_plot_spots_axes_v1(handles.axes_fit_xz,fit_xz,pixel,spot_plots,'Fit - XZ')

           %-YZ
           spot_plots.y = spot_pos.y; spot_plots.y = spot_pos.z;
           pixel.x = pixel_size.xy;   pixel.y = pixel_size.z;
           FQ_plot_spots_axes_v1(handles.axes_fit_yz,fit_yz,pixel,spot_plots,'Fit - YZ')
        else

            cla(handles.axes_fit_xy)
            cla(handles.axes_fit_xz)
            cla(handles.axes_fit_yz)
       end
              
       %- Update information about spot
       set(handles.text_spot_id,'String',round(spot_ind));
       set(handles.text_sigmaxy,'String',round(spots_fit(spot_ind,col_par.sigmax)));
       set(handles.text_sigmaz,'String',round(spots_fit(spot_ind,col_par.sigmaz)));
       set(handles.text_amp,'String',round(spots_fit(spot_ind,col_par.amp)));
       set(handles.text_bgd,'String',round(spots_fit(spot_ind,col_par.bgd)));

       %- Set selector for manual removal
       if thresh.in(spot_ind) == -1
           set(handles.checkbox_remove_man,'Value',1);
       else
           set(handles.checkbox_remove_man,'Value',0);
       end

    else

        cla(handles.axes_zoom_xy)
        cla(handles.axes_zoom_xz)
        cla(handles.axes_zoom_yz)

        cla(handles.axes_fit_xy)
        cla(handles.axes_fit_xz)
        cla(handles.axes_fit_yz)

        set(handles.text_spot_id,'String','');
        set(handles.text_sigmaxy,'String','');
        set(handles.text_sigmaz,'String','');
        set(handles.text_amp,'String','');
        set(handles.text_bgd,'String','');

        set(handles.checkbox_remove_man,'Value',0);
    end

  
    %- Update cursor accordingly
    img_plot = handles.img_plot_GUI;
    x_pos = round(pos(1));
    y_pos = round(pos(2));

    if     target == handles.h_spots_in
        txt = {['Good spot: ',num2str(spot_ind)], ...
               ['X-Y: ',num2str(x_pos),'-',num2str(y_pos)],...
               ['Int: ',num2str(img_plot(y_pos,x_pos))]};

    elseif target == handles.h_spots_out
        txt = {['Bad spot [auto]: ',num2str(spot_ind)], ...
               ['X-Y: ',num2str(x_pos),'-',num2str(y_pos)],...
               ['Int: ',num2str(img_plot(y_pos,x_pos))]}; 
    elseif target == handles.h_spots_out_man
        txt = {['Bad spot [man]: ',num2str(spot_ind)], ...
               ['X-Y: ',num2str(x_pos),'-',num2str(y_pos)],...
               ['Int: ',num2str(img_plot(y_pos,x_pos))]}; 
    else
        txt = {['X-Y: ',num2str(x_pos),'-',num2str(y_pos)],...
               ['Int: ',num2str(img_plot(y_pos,x_pos))]};
    end

else
	txt = '';
end
    


%=== Function for Cell selector
function FQ_plot_spots_axes(h_ax,img,pixel,spot_pos)
imshow(img,[ ],'XData',[0 (size(img,2)-1)*pixel.x],'YData',[0 (size(img,1)-1)*pixel.y],'Parent', h_ax)  


%=== Function for Cell selector
function pop_up_cell_select_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%== ZOOM button
function button_zoom_in_Callback(hObject, eventdata, handles)
if handles.status_zoom == 0
    datacursormode off
    h_zoom = zoom;
    set(h_zoom,'Enable','on');
    handles.status_zoom   = 1;
    handles.status_pan    = 0;
    handles.status_cursor = 0;
    
    handles.h_zoom      = h_zoom;
else
    set(handles.h_zoom,'Enable','off');    
    handles.status_zoom = 0;
end
guidata(hObject, handles);


%== PAN button
function menu_pan_Callback(hObject, eventdata, handles)
if handles.status_pan == 0
    h_pan = pan;
    set(h_pan,'Enable','on');
    handles.h_pan      = h_pan; 
    
    handles.status_pan    = 1;
    handles.status_zoom   = 0;
    handles.status_cursor = 0;
       
else
    set(handles.h_pan,'Enable','off');    
    handles.status_pan = 0;
end
guidata(hObject, handles);


%== Show only good spots
function checkbox_good_only_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%== Show only bad spots
function checkbox_bad_only_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles)


%== Show spot index
function checkbox_show_spot_ID_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%== Show spots
function checkbox_show_spots_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%== Show cell label
function checkbox_show_cell_label_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);


%== Show all cells
function checkbox_show_all_cells_Callback(hObject, eventdata, handles)
handles = plot_image(hObject, eventdata, handles);
guidata(hObject, handles);

% =========================================================================
% Not used
% =========================================================================

function axes_main_ButtonDownFcn(hObject, eventdata, handles)

function slider_contrast_max_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_contrast_min_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_slice_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function pop_up_view_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Untitled_1_Callback(hObject, eventdata, handles)

function pushbutton1_Callback(hObject, eventdata, handles)

function pop_up_img_sel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_cell_select_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function zoom_in_ClickedCallback(hObject, eventdata, handles)
h = zoom;

function mycallback_zoom_in(obj,event_obj)
h = zoom;

function h_fishquant_spots_ButtonDownFcn(hObject, eventdata, handles)

function uipanel2_ButtonDownFcn(hObject, eventdata, handles)




          
