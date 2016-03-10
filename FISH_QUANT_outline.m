function varargout = FISH_QUANT_outline(varargin)
% FISH_QUANT_OUTLINE M-file for FISH_QUANT_outline.fig

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_outline_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_outline_OutputFcn, ...
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


% --- Executes just before FISH_QUANT_outline is made visible.
function FISH_QUANT_outline_OpeningFcn(hObject, eventdata, handles, varargin)

global FQ_outline_open file_ident status_plot_first

%- First time opening outline designer
if isempty(FQ_outline_open) || FQ_outline_open == 0

    FQ_outline_open  = 1;
    status_plot_first = 1;
        
    handles.output = hObject;

    %- Set font-size to 10
    %  For whatever reason are all the fonts on windows are set back to 8 when the .fig is openend
    h_font_8 = findobj(handles.h_fishquant_outline,'FontSize',8);
    set(h_font_8,'FontSize',10)

    %- Get installation directory of FISH-QUANT and initiate 
    p = mfilename('fullpath');        
    handles.FQ_path = fileparts(p); 

    %- Export figure handle to workspace - will be used in Close All button of main Interface
    assignin('base','h_outline',handles.h_fishquant_outline)


    %= Handle that can be used to avoid that plot function is called too
    %frequently
    handles.status_update_only = 0;

    %= Some parameters
    handles.img = FQ_img;

    %- Change name of GUI
    set(handles.h_fishquant_outline,'Name', ['FISH-QUANT ', handles.img.version, ': outline designer']);

    %= Image for DAPI and TS_label
    handles.img_DAPI        = [];
    handles.img_TS_label    = [];

    handles.data_TS_norm   = [];
    handles.data_DAPI_norm   = [];

    handles.img_DAPI_plot   = [];
    handles.img_TS_plot     = [];

    handles.status_TS_label = 0;
    handles.status_DAPI     = 0;

    handles.parameters_TS_detect = [];

    handles.flag_show_cell_label = 1;
    
    %- Use identifiers to get DAPI and TS images automatically
    file_ident.status = 0;    %-1 not specified; 0 dont use; 1 use  -> will be overwritten below for certain calls of GU  
    file_ident.FISH   = '';
    file_ident.DAPI   = '';
    file_ident.TS     = '';

    %= Default parameter for loading of GUI - might be overwritten by later functions
    handles.child         = 0;  % COULD BE REPLACED BY if isequal(get(hObject,'waitstatus'),'waiting')  
    handles.cell_counter  = 1;  % Avoid having cells with same name after deleting one. 
    handles.axis_fig = [];

    %- Parameters for detection of nucleus
    handles.par_nuc_detect.erod_disc_rad = 10;
    handles.par_nuc_detect.N_pix_min     = 500;

    %- Other parameters
    handles.status_draw   = 0;        % Used to avoid multiple calls of draw functions
    handles.v_axis        = [];
    handles.img2_min_show = 0;
    handles.img2_max_show = 0;
    handles.img2_transparency = 0.3;

    handles.cMap2 = bone(256); 
    handles.cMap1 = hot(256); 

    handles.status_zoom = 0;
    handles.h_zoom = rand(1);
    handles.status_pan = 0;
    handles.h_pan = rand(1);

    %- Directories to write data
    handles.path_name_outline = [];
    handles.path_name_root    = [];

    %- Update status of various controls
    set(handles.button_TOP,'String', 'Open image');  
    handles.status_button_finish = 0;

    set(handles.h_fishquant_outline,'WindowStyle','normal')

    %==== Name of loaded outline file
    handles.outline_name_load   = [];
    
    %= Load data if called from other GUI
    if not(isempty(varargin))

        if strcmp( varargin{1},'HandlesMainGui')

            handles.child = 1;        
            handles_MAIN = varargin{2};

            %=== Get image data from GUI
            handles.img           = handles_MAIN.img;

            handles.img_plot      =  handles.img.raw_proj_z;
            handles.img_min       =  min(handles.img.raw(:));
            handles.img_max       =  max(handles.img.raw(:));
            handles.img_diff      =  handles.img_max-handles.img_min;  

            set(handles.text_th_auto_detect, 'String', num2str(handles.img_max ));

            %- Change name of GUI
            handles.cell_counter  = size(handles.img.cell_prop,2) +1;     % Avoid having cells with same name after deleting one. 
                       
            %- Change name of GUI
            set(handles.h_fishquant_outline,'Name', ['FISH-QUANT ', handles.img.version, ': outline designer - ', handles.img.file_names.raw ]);
         
            %- Load DAPI if specified and user wants to
            if not(isempty(handles.img.file_names.DAPI))
               button = questdlg('Load DAPI image as well?','FISH-QUANT outline');       
               if strcmp(button,'Yes')

                    if not(isempty(handles.img.path_names.img))
                       handles.path_name_DAPI = handles.img.path_names.img;
                    elseif not(isempty(handles.img.path_names.root))
                       handles.path_name_DAPI = handles.img.path_names.root;
                    end

                   handles = img_load_DAPI(hObject, eventdata, handles);
               end 
            end

            %- Load TS label if specified and user wants to
            if not(isempty(handles.img.TS_label))
               button = questdlg('Load image with TS label as well?','FISH-QUANT outline');       
               if strcmp(button,'Yes')

                    if not(isempty(handles.img.path_names.img))
                       handles.path_name_TS_label = handles.img.path_names.img;
                    elseif not(isempty(handles.img.path_names.root))
                       handles.path_name_TS_label = handles.img.path_names.root;
                    end

                   handles = img_load_TS_label(hObject, eventdata, handles);
               end 
            end

            %- Check for second stack
            select_second_stack_Callback(hObject, eventdata, handles)
            
            %- Analyze outline
            if not(isempty(handles.img.file_names.raw))
                handles = analyze_outline(hObject, eventdata, handles);
            end

            %- Update status of various controls
            set(handles.button_TOP,'String', 'Finished');  
            handles.status_button_finish = 1;
            set(handles.h_fishquant_outline,'WindowStyle','normal')


        elseif strcmp( varargin{1},'par_main')  

            file_ident.status = -1;
            
            
            handles.img = FQ_img;
            
            par_main                   = varargin{2};
            handles.img.par_microscope = par_main.par_microscope;
            handles.img.path_names     = par_main.path_names;
            

        elseif strcmp( varargin{1},'file')         

            %- Name of file
            name_load                 = varargin{2};
            handles.outline_name_load = name_load;

            fprintf('\n=== FISH-quant outline designer\nAttempting to load file: %s\n\n',name_load);
            
            %- Path names   & parameters
            handles.img = FQ_img;
            handles.img.path_names     = varargin{3};    
            handles.img.par_microscope = varargin{4};

            %- Load outline file
            handles = load_outline_file(name_load,hObject, eventdata, handles); 
            handles = analyze_outline(hObject, eventdata, handles); 


          elseif strcmp( varargin{1},'file_img')         

            file_ident.status = -1;
            
            %- Name of file
            name_full   = varargin{2};
            [img_path,img_name,ext] = fileparts(name_full);

            %- Path names
            handles.img = FQ_img;
            handles.img.path_names     = varargin{3};    
            handles.img.par_microscope = varargin{4};
            
     
           %- Load image results
           handles.img.file_names.raw  = [img_name,ext];     
           handles.img.path_names.img  = img_path;

           handles = img_load_FISH(hObject, eventdata, handles);

        end 
    end

    %- Update handles structure
    guidata(hObject, handles);  

    %- Check which elements should be enabled
    GUI_enable(handles)

    %- UIWAIT makes FISH_QUANT_outline wait for user response (see UIRESUME)
    if not(isempty(varargin))
        if strcmp( varargin{1},'HandlesMainGui')
            uiwait(handles.h_fishquant_outline);
        end
    end
    
    
%- IF GUI IS ALREADY OPEN!!!!    
else
      
    %= Load data if called from other GUI
    if not(isempty(varargin))
    
         if strcmp( varargin{1},'file')         

            %- Name of file
            name_load   = varargin{2};

            handles.outline_name_load = name_load;

            %- Path names
            path_names                      = varargin{3};        
            handles.img.path_names.root     = path_names.root;
            handles.img.path_names.img      = path_names.img;
            handles.img.path_names.outlines = path_names.outlines;
            handles.img.path_names.results  = path_names.results;

            %- Parameters
            handles.par_microscope = varargin{4};

            %- Load outline file
            handles = load_outline_file(name_load,hObject, eventdata, handles); 
            handles = analyze_outline(hObject, eventdata, handles); 
            guidata(hObject, handles);

          elseif strcmp( varargin{1},'file_img')         
  

            %- Name of file
            name_full   = varargin{2};
            [img_path,img_name,ext] = fileparts(name_full);

            %- FQ class
            handles.img                        = FQ_img;
            handles.img.path_names.root        = varargin{3};
            handles.img.par_microscope       = varargin{4};

           %- Load image results
           handles.img.file_names.raw  = [img_name,ext];     
           handles.img.path_names.img = img_path;

           handles = img_load_FISH(hObject, eventdata, handles);
           guidata(hObject, handles);
           
          else
             h_warn = warndlg({'OUTLINE DESIGNER IS ALREADY OPEN'; 'Close it first before processing outlines from main FQ interface .'});
             handles.child = -1 ; 
             pause(2)             
             guidata(hObject, handles);
             if ishandle(h_warn)
                close(h_warn)
             end
          end 
    end
end


%== Check with controls should be enabled
function GUI_enable(handles)

%- Image has to be loaded
if isempty(handles.img.raw)
     set(handles.button_cell_new,'Enable', 'off');    
     set(handles.button_cell_modify,'Enable', 'off');        
     set(handles.button_cell_delete,'Enable', 'off');    
     set(handles.listbox_cell,'Enable', 'off');   
else
     set(handles.button_cell_new,'Enable', 'on');    
     set(handles.button_cell_modify,'Enable', 'on');        
     set(handles.button_cell_delete,'Enable', 'on');    
     set(handles.listbox_cell,'Enable', 'on');     
end

%- DAPI has to be loaded for auto detection of nucleus
if not(isempty(handles.img.raw)) && handles.status_DAPI
      set(handles.button_detect_nucleus,'Enable', 'on');    
else
     set(handles.button_detect_nucleus,'Enable', 'off');     
end


%- Delete/modify only possible if listbox populated
if isempty(get(handles.listbox_cell,'String'))    
     set(handles.button_cell_modify,'Enable', 'off');
     set(handles.button_cell_delete,'Enable', 'off'); 

     set(handles.button_nuc_modify,'Enable', 'off');        
     set(handles.button_nuc_delete,'Enable', 'off');    
     set(handles.button_nuc_new,'Enable', 'off');
     
     set(handles.button_TS_new,'Enable', 'off'); 
     set(handles.button_auto_detect,'Enable', 'off'); 
     
     
else
     set(handles.button_cell_modify,'Enable', 'on');
     set(handles.button_cell_delete,'Enable', 'on');
     
     
     set(handles.button_nuc_modify,'Enable', 'on');        
     set(handles.button_nuc_delete,'Enable', 'on');    
     set(handles.button_nuc_new,'Enable', 'on');      
     
     set(handles.button_TS_new,'Enable', 'on'); 
     set(handles.button_auto_detect,'Enable', 'on'); 
end

%- Delete/modify only possible if listbox populated
if isempty(get(handles.listbox_TS,'String'))    
     set(handles.button_TS_modify,'Enable', 'off');
     set(handles.button_TS_delete,'Enable', 'off'); 
else
     set(handles.button_TS_modify,'Enable', 'on');
     set(handles.button_TS_delete,'Enable', 'on');
end


%- Enable only if image is present
set(handles.menu_save_outline,'Enable', 'on')


%- Enable saving of TS autodetect settings
if isfield(handles.img.settings.TS_detect,'img_det_type')
    set(handles.menu_save_settings_TS_detect,'Enable', 'on');
else
    set(handles.menu_save_settings_TS_detect,'Enable', 'off');
end


%== Parameter that are returned
function varargout = FISH_QUANT_outline_OutputFcn(hObject, eventdata, handles) 


global FQ_outline_open

%- Only if called from main interface
if handles.child == 1
    
    FQ_outline_open = 0;
    
    varargout{1} = handles.img;

    delete(handles.h_fishquant_outline);  
    
elseif handles.child == -1 

    varargout{1} = [];
end


%== Resume GUI when called from other GUI
function button_TOP_Callback(hObject, eventdata, handles)

if handles.status_button_finish
    uiresume(handles.h_fishquant_outline)
else
    handles = button_open_image_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);  
end


% --- Executes when user attempts to close h_fishquant_outline.
function h_fishquant_outline_CloseRequestFcn(hObject, eventdata, handles)

%- Outline will be closed
global FQ_outline_open
FQ_outline_open = 0;

% COULD REPLACE THE CHILD PARAMETER
% if isequal(get(hObject,'waitstatus','waiting')  


if handles.child == 1
    uiresume(handles.h_fishquant_outline)
else
    delete(handles.h_fishquant_outline)
    if isfield(handles,'axes_sep')
        try
            delete(handles.axes_sep)
        catch; 
        
        end
    end
end


%== OPEN IMAGE
function handles = button_open_image_Callback(hObject, eventdata, handles)
handles = menu_load_FISH_Callback(hObject, eventdata, handles);
guidata(hObject, handles); 


%== key press on figure
function h_fishquant_outline_KeyPressFcn(hObject, eventdata, handles)
switch eventdata.Key     
        case {'X','x'}
            button_cell_delete_Callback(hObject, eventdata, handles)
            
        case {'N','n'}
            button_cell_new_Callback(hObject, eventdata, handles)     
end

%== key press on listbox for cells
function listbox_cell_KeyPressFcn(hObject, eventdata, handles)
switch eventdata.Key     
        case {'X','x'}
            button_cell_delete_Callback(hObject, eventdata, handles)
            
        case {'N','n'}
            button_cell_new_Callback(hObject, eventdata, handles)           
end


% =========================================================================
%  OPEN SECOND IMAGE: DAPI or TS label
% =========================================================================


%=== Open FISH image
function handles = menu_load_FISH_Callback(hObject, eventdata, handles)

global status_plot_first

%- Get current directory and go to directory with images
current_dir = pwd;

if not(isempty(handles.img.path_names.img))
   cd(handles.img.path_names.img)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

%- Load image
handles = img_load_FISH(hObject, eventdata, handles);
status_plot_first = 1;
guidata(hObject, handles);

%- Go back to original path
cd(current_dir);


%=== Get file identifier
function get_file_ident

global file_ident

%- Get identifier of DAPI & TS-ident
if file_ident.status == -1;

    %- Load image
    button = questdlg('Do you want to use identifiers to find DAPI / TS-label  images based on FISH file name? If yes, you have to specify unique parts of the file names that set apart the FISH and DAPI image. This has to be done only once.','Load DAPI','Yes','No','No');

    if strcmp(button,'Yes')
        
    
        prompt = {'FISH','DAPI','TxSite'};
        dlg_title = 'Unique identifiers for different images';
        num_lines = 1;
        def = {file_ident.FISH,file_ident.DAPI,file_ident.TS};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        
        if ~isempty(answer)
                          
            file_ident.FISH = answer{1};
            file_ident.DAPI = answer{2};
            file_ident.TS   = answer{3};
            
            file_ident.status = 1;            
        else
            file_ident.status = -1;
            
        end
    else
        file_ident.status = 0;
    end
end


%=== Load DAPI image
function menu_load_DAPI_Callback(hObject, eventdata, handles)

global file_ident

%- Get file-identifier
get_file_ident;

%- Get current directory and go to directory with images
current_dir = pwd;

if not(isempty(handles.img.path_names.img))
   cd(handles.img.path_names.img)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

if file_ident.status == 1 
    name_FISH = handles.img.file_names.raw;
    
    if isempty(name_FISH)
        default_name = [];
        disp('NO FISH IMAGE LOADED!')
    else       
        default_name = strrep(name_FISH, file_ident.FISH, file_ident.DAPI);  
    end    
else
    default_name = [];   
end
    
[file_name_image,path_name_image] = uigetfile({'*.tif';'*.dv';'*.stk';'*.TIF'},'Select file',default_name);

if file_name_image ~= 0

    %- Save results
    handles.img.file_names.DAPI  = file_name_image;
    handles.path_name_DAPI   = path_name_image;
    handles                  = img_load_DAPI(hObject, eventdata, handles);
    guidata(hObject, handles);
    
    %- Check for second stack
    set(handles.checkbox_second_stack,'Value',1);
    select_second_stack_Callback(hObject, eventdata, handles)
    handles = plot_image(handles,handles.axes_image); 
    guidata(hObject, handles); 
end

%- Go back to original image
cd(current_dir);


%=== Load TS_label image
function menu_load_TS_label_Callback(hObject, eventdata, handles)

global file_ident

%- Get file-identifier
get_file_ident;

%- Get current directory and go to directory with images
current_dir = pwd;

if not(isempty(handles.img.path_names.img))
   cd(handles.img.path_names.img)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

if file_ident.status == 1 
    name_FISH = handles.img.file_names.raw;
    
    if isempty(name_FISH)
        default_name = [];
        disp('NO FISH IMAGE LOADED!')
    else       
        default_name = strrep(name_FISH, file_ident.FISH, file_ident.TS);  
    end    
else
    default_name = [];   
end


[file_name_image,path_name_image] = uigetfile({'*.tif';'*.dv';'*.stk';'*.TIF'},'Select file',default_name);

if file_name_image ~= 0

    %- Save results
    handles.img.file_names.TS_label = file_name_image;
    handles.path_name_TS_label  = path_name_image;
    handles = img_load_TS_label(hObject, eventdata, handles);
    
    %- Check for second stack
    select_second_stack_Callback(hObject, eventdata, handles)
    handles = plot_image(handles,handles.axes_image); 
    guidata(hObject, handles); 
end

%- Go back to original image
cd(current_dir);


%== LOAD FISH IMAGE
function handles = img_load_FISH(hObject, eventdata, handles)

global status_plot_first    

%- Load image and plot
handles.img = handles.img.reinit;
status_file = handles.img.load_img([],'raw');

if status_file

    if handles.img.dim.Z == 1
        warndlg('FISH images have to be 3D stacks!','FISH-quant')
        fprintf('\nName of image: %s\n', file_name_image);  
    else
        handles.img_plot      =  max(handles.img.raw,[],3); 
        handles.img_min       =  min(handles.img.raw(:)); 
        handles.img_max       =  max(handles.img.raw(:)); 
        handles.img_diff      =  handles.img_max-handles.img_min;                

        handles.img.cell_prop  = [];
        handles.cell_counter   = 1;

        %= Image for DAPI and TS_label
        handles.img_DAPI        = [];
        handles.img_TS_label    = [];

        handles.data_TS_norm   = [];
        handles.data_DAPI_norm   = [];

        handles.img_DAPI_plot   = [];
        handles.img_TS_plot     = [];

        handles.status_TS_label = 0;
        handles.status_DAPI     = 0;

        handles.cell_counter   = 1; % Reset cell counter
        handles.v_axis         = [];
        status_plot_first = 1;

        guidata(hObject, handles);    

        %- Change name of GUI
        set(handles.h_fishquant_outline,'Name', ['FISH-QUANT ', handles.img.version, ': outline designer - ', handles.img.file_names.raw ]);

        %= Check which elements should be enabled
        GUI_enable(handles)
        set(handles.listbox_cell,'String', []);
        set(handles.listbox_TS,'String', []);
        handles = plot_image(handles,handles.axes_image); 
        guidata(hObject, handles); 
    end
end


%== LOAD DAPI IMAGE
function handles = img_load_DAPI(hObject, eventdata, handles)

set(handles.h_fishquant_outline,'Pointer','watch');
fprintf('DAPI: LOAD IMAGE .... please wait ....')

%- Load image and plot
status_file = handles.img.load_img(fullfile(handles.img.path_names.img,handles.img.file_names.DAPI),'DAPI');

%- Check if file was loaded
if status_file == 0
    warndlg('DAPI file not found. Has to be in image folder','FISH-QUANT')
    fprintf('FILE NOT FOUND.\n')
    disp(['File: ', handles.file_names.DAPI])
    disp(['Path: ', handles.path_name_DAPI])
       
%- Assign data
else
    
    %- Assign data
    handles.img_DAPI_plot =  max(handles.img.DAPI,[],3); 
    handles.img_DAPI_min  =  min(handles.img.DAPI(:)); 
    handles.img_DAPI_max  =  max(handles.img.DAPI(:)); 
    handles.img_DAPI_diff =  handles.img_DAPI_max-handles.img_DAPI_min;                 

    handles.img_DAPI_min_show = handles.img_DAPI_min;
    handles.img_DAPI_max_show = handles.img_DAPI_max;

    %- Calc automated threshold
    th_auto = graythresh(uint16(handles.img_DAPI_plot));
    set(handles.text_th_nucleus,'String',num2str(round(100*th_auto)));

    %- Update
    handles.status_DAPI = 1;
    set(handles.select_second_stack,'Value',1);
    select_second_stack_Callback(hObject, eventdata, handles)
    fprintf('LOADED.\n')
end
set(handles.h_fishquant_outline,'Pointer','arrow');
    
    
%== LOAD TS_label IMAGE
function handles = img_load_TS_label(hObject, eventdata, handles)

set(handles.h_fishquant_outline,'Pointer','watch');

%= Load image and plot
fprintf('TS-label: LOAD IMAGE .... please wait ....')

%- Load image and plot
status_file = handles.img.load_img(fullfile(handles.img.path_names.img,handles.img.file_names.TS_label),'TS_label');

%- Check if file was loaded
if status_file == 0
    warndlg('TS LABEL IMAGE not found. Has to be in image folder','FISH-QUANT')
    fprintf('FILE NOT FOUND.\n')
    disp(['File: ', handles.file_names.TS_label])
    disp(['Path: ', handles.path_name_TS_label])
    
    
else
    
    %- Assign data 
    handles.img_TS_plot      =  max(handles.img.TS_label,[],3); 
    handles.img_TS_min       =  min(handles.img.TS_label(:)); 
    handles.img_TS_max       =  max(handles.img.TS_label(:)); 
    handles.img_TS_diff      =  handles.img_TS_max-handles.img_TS_min;                 

    handles.img_TS_min_show = handles.img_TS_min;
    handles.img_TS_max_show = handles.img_TS_max;

    handles.status_TS_label = 1;
    set(handles.select_second_stack,'Value',2);
    select_second_stack_Callback(hObject, eventdata, handles)
    fprintf('LOADED.\n')
end
set(handles.h_fishquant_outline,'Pointer','arrow');


%== Contrast to show second stack
function menu_2nd_contrast_Callback(hObject, eventdata, handles)
% Function to modify the settings of TS quantification

%- User-dialog
dlgTitle = 'Contrast for second stack';
prompt_avg(1) = {'CONTRAST: MIN'};
prompt_avg(2) = {'CONSTRAST:MAX'};
defaultValue_avg{1} = num2str(handles.img2_min_show);
defaultValue_avg{2} = num2str(handles.img2_max_show);

options.Resize='on';
userValue = inputdlg(prompt_avg,dlgTitle,1,defaultValue_avg,options);

%- Return results if specified
if( ~ isempty(userValue))
    handles.img2_min_show     = str2double(userValue{1});
    handles.img2_max_show     = str2double(userValue{2});
    
    handles = plot_image(handles,handles.axes_image); 
    guidata(hObject, handles); 
end


% =========================================================================
% Detect nucleus
% =========================================================================

%== Detect nucleus
function button_detect_nucleus_Callback(hObject, eventdata, handles)

par_detect = handles.par_nuc_detect;
par_detect.flags.plot   = 1;
par_detect.flags.dialog = 0;
par_detect.th_DAPI = str2double(get(handles.text_th_nucleus,'String'))/100;

if par_detect.th_DAPI > 0 && par_detect.th_DAPI < 1

    %- Restrict to current cell
    status_current_cell = get(handles.checkbox_nuc_auto_in_curr_cell,'Value');    
    if status_current_cell
        status_current_cell = get(handles.listbox_cell,'Value');
        
    end
        
    par_detect.status_current_cell = status_current_cell;
    
    %- Perform Z projection
    if isempty(handles.img.DAPI_proj_z)
        handles.img.project_Z('DAPI','max')
    end
    
    %- Perform segmentation
    handles.img.segment_nuclei(par_detect)   

    %- Plot image and save data
    handles = plot_image(handles,handles.axes_image); 
    guidata(hObject, handles); 
else
    warndlg('Value has to be between 0 and 100.','FISH-QUANT outline')
end


%== Detect nucleus
function button_nuc_delete_Callback(hObject, eventdata, handles)

%- Show plot
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);

%- Ask user to confirm choice
choice = questdlg('Do you really want to delete this nucleus?', 'FISH-QUANT', 'Yes','No','No');

if strcmp(choice,'Yes')
    
    %- Extract index of highlighted cell
    ind_sel  = get(handles.listbox_cell,'Value');
    
    %- Delete nucleus in highlighted cell
    handles.img.cell_prop(ind_sel).pos_Nuc = [];   
    
    %- Show plot
    handles = plot_image(handles,handles.axes_image);
    
    %- Save results
    guidata(hObject, handles);
end


%== New nucleus
function button_nuc_new_Callback(hObject, eventdata, handles)
   
if not(handles.status_draw)

    %- Set status that one object is currently constructed
    handles.status_draw = 1;
    guidata(hObject, handles);

    %- Determine if plot should be done in separate figure
    fig_sep = get(handles.checkbox_sep_window,'Value');
    handles = plot_decide_window(hObject, eventdata, handles);

    %- Draw region
    str = get(handles.pop_up_region, 'String');
    val = get(handles.pop_up_region,'Value');

    param.reg_type = str{val};
    param.h_axes   = gca;
    param.pos      = [];

    reg_result = FQ_draw_region_v1(param);
    position   = reg_result.position;

    %-Analyse region
    Nuc_X = round(position(:,1))';   % Has to be a row vector to agree with read-in from files
    Nuc_Y = round(position(:,2))';


    %- Find cell to which this nucleus belongs       
    ind_cell_Nuc = [];
    cell_prop = handles.img.cell_prop;
    N_cells  = length(cell_prop);
    
    
    for i_cell = 1:N_cells
        cell_X = cell_prop(i_cell).x;
        cell_Y = cell_prop(i_cell).y;   

        in_cell = inpolygon(Nuc_X,Nuc_Y,cell_X,cell_Y);

        if sum(in_cell) == length(Nuc_X)
            ind_cell_Nuc = i_cell; 
        end
    end

        
    %- Assign to cell
    if not(isempty(ind_cell_Nuc))

        %- If nucleus is already defined ask if old one should be deleted
        if not(isempty(handles.img.cell_prop(ind_cell_Nuc).pos_Nuc))         
            choice = questdlg('Nucleus already defined in this cell. Delete old one?','FISH-quant - outline','No','Yes','Yes');         
        else
            choice = 'Yes';        
        end
        
        if strcmp(choice, 'Yes')
            
            %- Save position
            pos_Nuc.x        = Nuc_X;  
            pos_Nuc.y        = Nuc_Y;  
            pos_Nuc.label    = 'Nucleus_manual'; 
            pos_Nuc.reg_type = reg_result.reg_type;  
            pos_Nuc.reg_pos  = reg_result.reg_pos;     

            %- Update information of this cell
            handles.img.cell_prop(ind_cell_Nuc).pos_Nuc = pos_Nuc; 

            if fig_sep
                handles.v_axis = axis(handles.axes_sep);
            end     
        end  
    else
        warndlg('Nucleus could not be assigned to any cell. Must be ENTIRELY within the cell.','FISH-QUANT')
        handles = plot_image(handles,handles.axes_image);  
        guidata(hObject, handles);
    end    
    
    
    %- Save results and show plot       
    handles.status_draw = 0;
    handles = plot_image(handles,handles.axes_image);
    guidata(hObject, handles);


    %- UIWAIT makes FISH_QUANT_outline wait for user response (see UIRESUME)
    %- New call is necessary since impoly breaks first call
    if handles.child;  
        uiwait(handles.h_fishquant_outline);
    end

end



%== Modify nucleus (only for manually defined ones)
function button_nuc_modify_Callback(hObject, eventdata, handles)

%- Extract index and properties of highlighted cell
ind_sel  = get(handles.listbox_cell,'Value');
cell_prop = handles.img.cell_prop(ind_sel);

%- Check if there is a nucleus
if not(isempty(cell_prop.pos_Nuc))

    pos_Nuc = cell_prop.pos_Nuc(1);
    
    if not(handles.status_draw)

        %- Set status that one object is currently constructed
        handles.status_draw = 1;
        guidata(hObject, handles);

        %- Determine if plot should be done in separate figure
        fig_sep = get(handles.checkbox_sep_window,'Value');
        handles = plot_decide_window(hObject, eventdata, handles);

        %- Check if reg-type is defined
        is_reg_type = isfield(pos_Nuc,'reg_type');

        if is_reg_type    

            reg_type  = pos_Nuc.reg_type;
            reg_pos   = pos_Nuc.reg_pos;

            %- Modify region region
            param.reg_type = reg_type;
            param.h_axes   = gca;
            param.pos      = reg_pos;

            reg_result = FQ_draw_region_v1(param);

            position            = reg_result.position;
            pos_Nuc.reg_type  = reg_result.reg_type;
            pos_Nuc.reg_pos   = reg_result.reg_pos;

            pos_Nuc.x = round(position(:,1))';  % v3: Has to be a row vector to agree with read-in from files
            pos_Nuc.y = round(position(:,2))';  % v3: Has to be a row vector to agree with read-in from files

            handles.img.cell_prop(ind_sel).pos_Nuc(1) = pos_Nuc;
            handles.axis_fig     = axis;

            if fig_sep
                handles.v_axis = axis(handles.axes_sep);
            end

            %- Save results
            handles.status_draw = 0;

            handles=plot_image(handles,handles.axes_image);
            guidata(hObject, handles);

            %- UIWAIT makes FISH_QUANT_outline wait for user response (see UIRESUME)
            %- New call is necessary since impoly breaks first call
            if handles.child;
                uiwait(handles.h_fishquant_outline);    
            end
        else
            msgbox('Geometry cannot be modified - only deleted','Outline definition','warn'); 
        end
    end
else
    warndlg('No nucleus defined for this cell.','FISH-QUANT')
end


% =========================================================================
% Load and save
% =========================================================================

%== Save outline
function menu_save_outline_Callback(hObject, eventdata, handles)

%- Get directory with outlines
if  not(isempty(handles.img.path_names.outlines)); 
    path_save = handles.img.path_names.outlines;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

%- Parameters to save results
parameters.path_save           = path_save;
parameters.path_name_image     = handles.img.path_names.img;
parameters.version             = handles.img.version;
parameters.flag_type           = 'outline';

if not(isempty(handles.outline_name_load))
    [file_save,path_save] = uiputfile(handles.outline_name_load,'Save FQ outline');

    if file_save ~= 0
       name_save = fullfile( path_save,file_save);
       handles.outline_name_load = name_save;
       handles.img.save_results(name_save,parameters);
       guidata(hObject, handles);
    end
else
    handles.img.save_results([],parameters);
end


%== Quick-save
function button_quick_save_Callback(hObject, eventdata, handles)

%- Get directory with outlines
if  not(isempty(handles.img.path_names.outlines)); 
    path_save = handles.img.path_names.outlines;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

%- Parameters to save results
parameters.path_save           = path_save;
parameters.path_name_image     = handles.img.path_names.img;
parameters.version             = handles.img.version;
parameters.flag_type           = 'outline';

%- Generate automated name
if isempty(handles.outline_name_load)
    [dum, name_file]      = fileparts(handles.img.file_names.raw);
    name_default          = [name_file,'__',parameters.flag_type,'.txt'];
    name_default_full     = fullfile(path_save,name_default);
    [file_save,path_save] = uiputfile(name_default_full,'Save outline / results of spot detection');
else
    [file_save,path_save] = uiputfile(handles.outline_name_load,'Save outline / results of spot detection');
end

%- Save outline
if file_save ~= 0
    name_save_full = fullfile(path_save,file_save);
    handles.img.save_results(name_save_full,parameters);
    disp(' ')
    disp(['Outline saved as: ', file_save])
    disp(['Folder: ', path_save])
    
end


%== Load outline
function menu_load_outline_Callback(hObject, eventdata, handles)

%- Get directory with outlines
current_dir = pwd;
if  not(isempty(handles.img.path_names.outlines)); 
    path_outline = handles.img.path_names.outlines;
elseif not(isempty(handles.img.path_names.root)); 
    path_outline = handles.img.path_names.root;
else
    path_outline = cd;
end
if exist(path_outline)
    cd(path_outline)
else
    disp('Folder for outlines not present')
end


%- Get outline
[file_name_results,path_name_results] = uigetfile({'*.txt'},'Select file with outline');

if file_name_results ~= 0
    handles = load_outline_file(fullfile(path_name_results,file_name_results),hObject, eventdata, handles); 
    handles = analyze_outline(hObject, eventdata, handles); 
    guidata(hObject, handles);
end

%- Go back to original image
cd(current_dir);


%= Function to load outline file
function handles =  load_outline_file(name_load,hObject, eventdata, handles) 

global status_plot_first
status_plot_first = 1;

%- Get directory with images
if  not(isempty(handles.img.path_names.img)); 
    path_image = handles.img.path_names.img;
elseif not(isempty(handles.img.path_names.root)); 
    path_image = handles.img.path_names.root;
else
    path_image = cd;
end

handles.img.reinit;
handles.img.load_results(name_load,path_image);
       
handles.img_plot      =  handles.img.raw_proj_z;
handles.img_min       =  min(handles.img.raw(:));
handles.img_max       =  max(handles.img.raw(:));
handles.img_diff      =  handles.img_max-handles.img_min; 

%- Set back the values of the listboxes
set(handles.listbox_cell,'Value',1);
set(handles.listbox_TS,'Value',1);

%= Image for DAPI and TS_label
handles.img_DAPI        = [];
handles.img_TS_label    = [];

handles.data_TS_norm   = [];
handles.data_DAPI_norm   = [];

handles.img_DAPI_plot   = [];
handles.img_TS_plot     = [];

handles.status_TS_label = 0;
handles.status_DAPI     = 0;


%- Load DAPI if specified and user wants to
if not(isempty(handles.img.file_names.DAPI))
   button = questdlg('Load DAPI image as well?','FISH-QUANT outline');       
   if strcmp(button,'Yes')
       
        if not(isempty(handles.img.path_names.img))
           handles.path_name_DAPI = handles.img.path_names.img;
        elseif not(isempty(handles.img.path_names.root))
           handles.path_name_DAPI = handles.img.path_names.root;
        end 
       
       handles = img_load_DAPI(hObject, eventdata, handles);
   end 
end

%- Load TS label if specified and user wants to
if not(isempty(handles.img.file_names.TS_label))
   button = questdlg('Load image with TS label as well?','FISH-QUANT outline');       
   if strcmp(button,'Yes')
             
        if not(isempty(handles.img.path_names.img))
           handles.path_name_TS_label = handles.img.path_names.img;
        elseif not(isempty(handles.img.path_names.root))
           handles.path_name_TS_label = handles.img.path_names.root;
        end 
       
       handles = img_load_TS_label(hObject, eventdata, handles);
   end 
end

handles.v_axis        = [];

%- Check for second stack
select_second_stack_Callback(hObject, eventdata, handles)

%- Change name of GUI
set(handles.h_fishquant_outline,'Name', ['FISH-QUANT ', handles.img.version, ': outline designer - ', handles.img.file_names.raw ]);


%== Function to analyze loaded outline 
function handles = analyze_outline(hObject, eventdata, handles)

%- Set back the values of the listboxes
set(handles.listbox_cell,'Value',1);
set(handles.listbox_TS,'Value',1);

%- Populate list with names of cells
cell_prop = handles.img.cell_prop;

if not(isempty(cell_prop))

    N_cell = size(cell_prop,2);
    for i_cell = 1:N_cell
        
        %- Add fields needed for modification
        cell_prop(i_cell).reg_type = 'Polygon';
        
        reg_pos = [];
        reg_pos(:,1)  = cell_prop(i_cell).x;
        reg_pos(:,2)  = cell_prop(i_cell).y;
        
        cell_prop(i_cell).reg_pos = reg_pos;

        
        %- Get string with name of cell
        str_list_cell{i_cell} =  cell_prop(i_cell).label;

        str_list_TS = {};
        
        N_TS = size(cell_prop(i_cell).pos_TS,2);
        for i_TS = 1:N_TS
            
            %- Add fields needed for modification
            cell_prop(i_cell).pos_TS(i_TS).reg_type = 'Polygon';

            reg_pos = [];
            reg_pos(:,1)  = cell_prop(i_cell).pos_TS(i_TS).x;
            reg_pos(:,2)  = cell_prop(i_cell).pos_TS(i_TS).y;

            cell_prop(i_cell).pos_TS(i_TS).reg_pos = reg_pos;

            %- Get name of transcription site
            str_list_TS{i_TS} =  cell_prop(i_cell).pos_TS(i_TS).label;
        end
        cell_prop(i_cell).str_list_TS = str_list_TS;
        cell_prop(i_cell).TS_counter  = N_TS +1;
    end

    set(handles.listbox_cell,'String', str_list_cell);
end

%- Save parameters
handles.img.cell_prop  = cell_prop;
handles.cell_counter   = size(cell_prop,2)+1;

%- Show plot
handles = listbox_cell_Callback(hObject, eventdata, handles);
guidata(hObject, handles);


% =========================================================================
% Functions to manipulate cells
% =========================================================================


%== New cell is entire image
function button_cell_image_Callback(hObject, eventdata, handles)

%- Get current list
str_list = get(handles.listbox_cell,'String');
N_Cell   = size(str_list,1);
ind_cell = N_Cell+1;  

%- Make one cell out of image
handles.img.make_one_cell(ind_cell);

%- Add some more parameters
handles.img.cell_prop(ind_cell).status_filtered = 1;    % Image filterd
handles.img.cell_prop(ind_cell).str_list_TS = [];
handles.img.cell_prop(ind_cell).TS_counter   = 1;  

handles.img.cell_prop(ind_cell).reg_type = 'Rectangle';
handles.img.cell_prop(ind_cell).reg_pos  = [1 1 handles.img.dim.X handles.img.dim.Y];

%- Add entry at the end and update list
str_list{ind_cell} = 'EntireImage';

set(handles.listbox_cell,'String',str_list)
set(handles.listbox_cell,'Value',ind_cell)
listbox_cell_Callback(hObject, eventdata, handles);


%- Save and show results
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);

%- UIWAIT makes FISH_QUANT_outline wait for user response (see UIRESUME)
%- New call is necessary since impoly breaks first call
if handles.child;
    uiwait(handles.h_fishquant_outline);
end


%== New cell
function button_cell_new_Callback(hObject, eventdata, handles)

if not(handles.status_draw)
    
    %- Set status that one object is currently constructed
    handles.status_draw = 1;
    guidata(hObject, handles);

    %- Determine if plot should be done in separate figure
    fig_sep = get(handles.checkbox_sep_window,'Value');
    handles = plot_decide_window(hObject, eventdata, handles);

    %- Get current list
    str_list = get(handles.listbox_cell,'String');
    N_Cell   = size(str_list,1);
    ind_cell = N_Cell+1;

    %- Draw region
    str = get(handles.pop_up_region, 'String');
    val = get(handles.pop_up_region,'Value');

    param.reg_type = str{val};
    param.h_axes   = gca;
    param.pos      = [];

    reg_result = FQ_draw_region_v1(param);

    position = reg_result.position;

    if ~isempty(position)         

        handles.axis_fig  = axis;

        %- Save position
        handles.img.cell_prop(ind_cell).reg_type = reg_result.reg_type;
        handles.img.cell_prop(ind_cell).reg_pos  = reg_result.reg_pos;

        handles.img.cell_prop(ind_cell).x = round(position(:,1))';  % v3: Has to be a row vector to agree with read-in from files
        handles.img.cell_prop(ind_cell).y = round(position(:,2))';  % v3: Has to be a row vector to agree with read-in from files

        handles.img.cell_prop(ind_cell).pos_TS  = [];
        handles.img.cell_prop(ind_cell).pos_Nuc = [];
        handles.img.cell_prop(ind_cell).str_list_TS = [];
        handles.img.cell_prop(ind_cell).TS_counter   = 1;

        %- Add entry at the end and update list
        str_cell = ['Cell_', num2str(handles.cell_counter)];
        str_list{ind_cell} = str_cell;

        set(handles.listbox_cell,'String',str_list)
        set(handles.listbox_cell,'Value',ind_cell)

        handles.img.cell_prop(ind_cell).label = str_cell;
        handles.cell_counter = handles.cell_counter+1;

        if fig_sep
            handles.v_axis = axis(handles.axes_sep);
        end

        %- Update list-box - includes drawing
        listbox_cell_Callback(hObject, eventdata, handles);

        %- Save and show results
        handles.status_draw = 0;
        guidata(hObject, handles);
    end
    %- UIWAIT makes FISH_QUANT_outline wait for user response (see UIRESUME)
    %- New call is necessary since impoly breaks first call
    if handles.child;
        uiwait(handles.h_fishquant_outline);
    end
    
end


%== Modify cell
function button_cell_modify_Callback(hObject, eventdata, handles)

if not(handles.status_draw)
    
    %- Set status that one object is currently constructed
    handles.status_draw = 1;
    guidata(hObject, handles);

    %- Determine if plot should be done in separate figure
    fig_sep = get(handles.checkbox_sep_window,'Value');
    handles = plot_decide_window(hObject, eventdata, handles);

    %- Extract index and properties of highlighted cell
    ind_sel  = get(handles.listbox_cell,'Value');

    cell_prop = handles.img.cell_prop(ind_sel);
    
    %- Check if reg-type is defined
    is_reg_type = isfield(cell_prop,'reg_type');
       
    if is_reg_type    
        
        reg_type  = cell_prop.reg_type;
        reg_pos   = cell_prop.reg_pos;

        %- Modify region region
        param.reg_type = reg_type;
        param.h_axes   = gca;
        param.pos      = reg_pos;

        reg_result = FQ_draw_region_v1(param);

        position            = reg_result.position;
        cell_prop.reg_type  = reg_result.reg_type;
        cell_prop.reg_pos   = reg_result.reg_pos;

        cell_prop.x = round(position(:,1))';  % v3: Has to be a row vector to agree with read-in from files
        cell_prop.y = round(position(:,2))';  % v3: Has to be a row vector to agree with read-in from files

        handles.img.cell_prop(ind_sel) = cell_prop;
        handles.axis_fig     = axis;
        
        if fig_sep
            handles.v_axis = axis(handles.axes_sep);
        end
        
        %- Save results
        handles.status_draw = 0;
        
        handles=plot_image(handles,handles.axes_image);
        guidata(hObject, handles);

        %- UIWAIT makes FISH_QUANT_outline wait for user response (see UIRESUME)
        %- New call is necessary since impoly breaks first call
        if handles.child;
            uiwait(handles.h_fishquant_outline);    
        end
    else
        msgbox('Geometry cannot be modified - only deleted','Outline definition','warn'); 
    end
end


%== Delete cell
function button_cell_delete_Callback(hObject, eventdata, handles)

%- Show plot
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);

%- Ask user to confirm choice
choice = questdlg('Do you really want to delete this cell?', 'FISH-QUANT', 'Yes','No','No');

if strcmp(choice,'Yes')
    
    %- Extract index of highlighted cell
    str_list = get(handles.listbox_cell,'String');
    ind_sel  = get(handles.listbox_cell,'Value');
    
    %- Delete highlighted cell
    str_list(ind_sel) = [];
    
    handles.img.cell_prop(ind_sel) = [];   
    set(handles.listbox_cell,'String',str_list)
    
    %- Make sure that pointer is not outside of defined cells
    N_str = length(str_list);
    if ind_sel > N_str     
        set(handles.listbox_cell,'Value',N_str)
    end
    
    %- Show plot
    listbox_cell_Callback(hObject, eventdata, handles);   
    handles = plot_image(handles,handles.axes_image);
    
    %- Save results
    guidata(hObject, handles);
end


%== Listbox cell
function handles = listbox_cell_Callback(hObject, eventdata, handles)

%-Update list of transcription sites
ind_sel  = get(handles.listbox_cell,'Value');

if not(isempty(handles.img.cell_prop))
    str_list = handles.img.cell_prop(ind_sel).str_list_TS;
    set(handles.listbox_TS,'String',str_list)
    set(handles.listbox_TS,'Value',1)
end

%- Update plot
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);


% =========================================================================
% Functions to automatically detect transcription sites
% =========================================================================

%== Autodetect transcription sites
function button_auto_detect_Callback(hObject, eventdata, handles)

set(handles.h_fishquant_outline,'Pointer','watch'); %= Pointer to watch

%- Get check-box in nucleus
disp('Auto-detection of transcription sites ... please wait .... ')

%- Check with image will be used
str = get(handles.popupmenu_select_img_detect,'String');
val = get(handles.popupmenu_select_img_detect,'Value');
handles.img.settings.TS_detect.img_det_type       = str{val};

handles.img.settings.TS_detect.int_th             = str2double(get(handles.text_th_auto_detect,'String'));
handles.img.settings.TS_detect.th_min_TS_DAPI     = str2double(get(handles.text_th_min_TS_DAPI,'String'));
handles.img.settings.TS_detect.status_only_in_nuc = get(handles.checkbox_TS_only_nucleus,'Value');

%- TS detection
handles.img.TS_detect;

%- Analyse and show results
handles = analyze_outline(hObject, eventdata, handles);
handles = plot_image(handles,handles.axes_image);

fig_sep = get(handles.checkbox_sep_window,'Value');

if fig_sep
    if not(isfield(handles,'axes_sep'))
        figure
        handles.axes_sep = gca;
    end    
    handles = plot_image(handles,handles.axes_sep);
    axis(handles.axis_fig);        
end

%- Update GUI
disp('Auto-detection of transcription sites ... FINISHED .... ')
set(handles.h_fishquant_outline,'Pointer','arrow'); %= Pointer to watch

%- Save detection parameters
GUI_enable(handles)
guidata(hObject, handles); 


%=== Options for quantification
function menu_options_TS_Callback(hObject, eventdata, handles)
handles.img.TS_detect_settings_change;
guidata(hObject, handles);


%=== Save settings for TS detect
function menu_save_settings_TS_detect_Callback(hObject, eventdata, handles)
handles.img.TS_detect_settings_save;
guidata(hObject, handles);



% =========================================================================
% Functions to manipulate TxSites
% =========================================================================

%== New TxSite
function button_TS_new_Callback(hObject, eventdata, handles)

if not(handles.status_draw)
    
    %- Set status that one object is currently constructed
    handles.status_draw = 1;
    guidata(hObject, handles);

    %- Determine if plot should be done in separate figure
    fig_sep = get(handles.checkbox_sep_window,'Value');
    handles = plot_decide_window(hObject, eventdata, handles);

    %---- Draw region
    str = get(handles.pop_up_region, 'String');
    val = get(handles.pop_up_region,'Value');

    param.reg_type = str{val};
    param.h_axes   = gca;
    param.pos      = [];

    reg_result = FQ_draw_region_v1(param);
    position   = reg_result.position;

    %---- Analyse region
    TS_X = round(position(:,1))';   % Has to be a row vector to agree with read-in from files
    TS_Y = round(position(:,2))';
       
    %- Find cell to which this nucleus belongs       
    ind_cell_TS = [];
    cell_prop = handles.img.cell_prop;
    N_cells  = length(cell_prop);
    
    
    for i_cell = 1:N_cells
        cell_X = cell_prop(i_cell).x;
        cell_Y = cell_prop(i_cell).y;   

        in_cell = inpolygon(TS_X,TS_Y,cell_X,cell_Y);

        if sum(in_cell) == length(TS_X)
            ind_cell_TS = i_cell; 
        end
    end
    
    if isempty( ind_cell_TS ) 
        handles.status_draw = 0;

        
        errordlg('Transcription site has to be within the cell.', 'FISH-QUANT')
        handles = plot_image(handles,handles.axes_image);  
        guidata(hObject, handles);
    else
    
        %- Get cell with TS inside 
        str_list_TS   = handles.img.cell_prop(ind_cell_TS).str_list_TS;
        %cell_Y   = handles.img.cell_prop(ind_cell_TS).y;

        pos_TS   = handles.img.cell_prop(ind_cell_TS).pos_TS; 
        N_TS     = size(pos_TS,2);
        ind_TS   = N_TS+1;

        %- Add entry at the end and update list
        str_TS = ['TS_', num2str(handles.img.cell_prop(ind_cell_TS).TS_counter)];
        str_list_TS{ind_TS} = str_TS;
        %set(handles.listbox_TS,'String',str_list)

        %- Save position
        pos_TS(ind_TS).x        = TS_X;  
        pos_TS(ind_TS).y        = TS_Y;  
        pos_TS(ind_TS).label    = str_TS; 
        pos_TS(ind_TS).reg_type = reg_result.reg_type;  
        pos_TS(ind_TS).reg_pos  = reg_result.reg_pos;     

        %- Update information of this cell
        handles.img.cell_prop(ind_cell_TS).pos_TS = pos_TS;
        handles.img.cell_prop(ind_cell_TS).str_list_TS = str_list_TS;        
        handles.img.cell_prop(ind_cell_TS).TS_counter = handles.img.cell_prop(ind_cell_TS).TS_counter+1;   

        if fig_sep
            handles.v_axis = axis(handles.axes_sep);
        end
                
        %- Save results
        handles.status_draw = 0;

        %- Show updated plot
        set(handles.listbox_cell,'Value',ind_cell_TS);
        handles = listbox_cell_Callback(hObject, eventdata, handles);
        set(handles.listbox_TS,'Value',ind_TS);
        handles = plot_image(handles,handles.axes_image);
        guidata(hObject, handles);
    end

    %- UIWAIT makes FISH_QUANT_outline wait for user response (see UIRESUME)
    %- New call is necessary since impoly breaks first call
    
    if handles.child;  
        uiwait(handles.h_fishquant_outline);
    end
end


%== Modify existing TS
function button_TS_modify_Callback(hObject, eventdata, handles)

if not(handles.status_draw)
    
    %- Set status that one object is currently constructed
    handles.status_draw = 1;
    guidata(hObject, handles);
    
    %- Determine if plot should be done in separate figure
    fig_sep = get(handles.checkbox_sep_window,'Value');
    handles = plot_decide_window(hObject, eventdata, handles);

    %- Get current cell and list of TS of this cell
    ind_cell = get(handles.listbox_cell,'Value');
    cell_X   = handles.img.cell_prop(ind_cell).x;
    cell_Y   = handles.img.cell_prop(ind_cell).y;

    %- Extract index of highlighted transcription site
    ind_TS  = get(handles.listbox_TS,'Value');
    pos_TS  = handles.img.cell_prop(ind_cell).pos_TS(ind_TS); 


    %- Extract index and properties of highlighted cell
    reg_type  = handles.img.cell_prop(ind_cell).pos_TS(ind_TS).reg_type;
    reg_pos   = handles.img.cell_prop(ind_cell).pos_TS(ind_TS).reg_pos;

    %- Modify region region
    param.reg_type = reg_type;
    param.h_axes   = gca;
    param.pos      = reg_pos;

    reg_result = FQ_draw_region_v1(param);

    position   = reg_result.position;

    %- Analyse distribution
    TS_X = round(position(:,1))';  % v3: Has to be a row vector to agree with read-in from files
    TS_Y = round(position(:,2))';  % v3: Has to be a row vector to agree with read-in from files

    in_cell = inpolygon(TS_X,TS_Y,cell_X,cell_Y);

    if sum(in_cell) < length(TS_X)    
        handles.status_draw = 0;
        
        
        errordlg('Transcription site has to be within the cell.', 'FISH-QUANT')
        handles = plot_image(handles,handles.axes_image);  
        guidata(hObject, handles);
    else

        %- Save position
        pos_TS = handles.img.cell_prop(ind_cell).pos_TS(ind_TS);    
        pos_TS.x     = TS_X;  
        pos_TS.y     = TS_Y; 
        pos_TS.reg_type = reg_result.reg_type;  
        pos_TS.reg_pos  = reg_result.reg_pos; 
        handles.img.cell_prop(ind_cell).pos_TS(ind_TS) = pos_TS;
        
        if fig_sep
            handles.v_axis = axis(handles.axes_sep);
        end
        
        %- Save results
        handles.status_draw = 0;


        %- Show results
        handles = plot_image(handles,handles.axes_image);
        guidata(hObject, handles);
        set(handles.listbox_TS,'Value',ind_TS);
    end

    %- UIWAIT makes FISH_QUANT_outline wait for user response (see UIRESUME)
    %- New call is necessary since impoly breaks first call
    if handles.child;  
        uiwait(handles.h_fishquant_outline);
    end
end


%== Delete Transcription site
function button_TS_delete_Callback(hObject, eventdata, handles)

%- Show plot
plot_image(handles,handles.axes_image);

%- Ask user to confirm choice
choice = questdlg('Do you really want to delete this TxSite?', 'FISH-QUANT', 'Yes','No','No');

if strcmp(choice,'Yes')
    
    %- Get current cell and list of TS of this cell
    ind_cell = get(handles.listbox_cell,'Value');
    pos_TS   = handles.img.cell_prop(ind_cell).pos_TS;    
    str_list_TS   = handles.img.cell_prop(ind_cell).str_list_TS;
    
    %- Extract index of highlighted cell
    ind_sel  = get(handles.listbox_TS,'Value');
    
    %- Delete highlighted TS 
    str_list_TS(ind_sel) = [];    
    pos_TS(ind_sel) = [];      
   
    %- Save results
    handles.img.cell_prop(ind_cell).pos_TS      = pos_TS; 
    handles.img.cell_prop(ind_cell).str_list_TS = str_list_TS;
    set(handles.listbox_TS,'String',str_list_TS)
    
    
    %- Update GUI and show plot
    set(handles.listbox_TS,'Value',1);
    listbox_TS_Callback(hObject, eventdata, handles) 
    handles = plot_image(handles,handles.axes_image); 
    guidata(hObject, handles);
end


%== Delete ALL Transcription sites
function button_TS_delete_all_Callback(hObject, eventdata, handles)

for i_cell = 1:length(handles.img.cell_prop)
    handles.img.cell_prop(i_cell).pos_TS = {};
     handles.img.cell_prop(i_cell).str_list_TS = {};
end

handles = plot_image(handles,handles.axes_image); 
guidata(hObject, handles);

%== Listbox TS
function listbox_TS_Callback(hObject, eventdata, handles)
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);




% =========================================================================
% Plot
% =========================================================================

%== Decide which plot window to use
function handles = plot_decide_window(hObject, eventdata, handles)

%- Determine if plot should be done in separate figure
fig_sep = get(handles.checkbox_sep_window,'Value');

if fig_sep
    
    %- Has there already been a figure handle?
    if isfield(handles,'axes_sep')
        
        %- Is this figure handle still present?
        
        %  Handles is deletec
        if not(ishandle(handles.axes_sep))
            figure;
            handles.axes_sep = gca;
            handles.axis_fig = [];
            guidata(hObject, handles);  
            
        %  Handles is still there
        else
            axes(handles.axes_sep);            
        end
    
    % New figure handles    
    else
         figure;
         handles.axes_sep = gca;
         handles.axis_fig = [];
         guidata(hObject, handles);
         
    end
    
    handles = plot_image(handles,handles.axes_sep);
    guidata(hObject, handles);
    if not(isempty(handles.v_axis))
        axis(handles.v_axis);
    end
end


%== Plot function
function handles = plot_image(handles,axes_select)

global status_plot_first

%- Displayed images
handles.img_FISH_disp  = [];
handles.img_2nd_disp   = [];

%- Show labels
flag_show_cell_label = handles.flag_show_cell_label;

%- Only image without outlines
status_show_outlines = get(handles.checkbox_show_outlines,'Value');

%- Show FISH
status_show_FISH     = get(handles.checkbox_show_FISH,'Value');

%- Show second stack
status_second = get(handles.checkbox_second_stack,'Value');
if  status_second
   
    str = get(handles.select_second_stack,'String');
    val = get(handles.select_second_stack,'Value');
    img2_type = str{val};
    
    switch img2_type
        case 'DAPI'   
            if handles.status_DAPI
                img2_plot   =  handles.img_DAPI_plot;
                img_2nd_min =  handles.img_DAPI_min;
                img_2nd_max =  handles.img_DAPI_max;
                img_2nd_diff = handles.img_DAPI_diff;

            else
                status_second = 0;
            end
            
            
        case 'TS_label'
            if handles.status_TS_label
                img2_plot   =  handles.img_TS_plot;
                img_2nd_min =  handles.img_TS_min;
                img_2nd_max  = handles.img_TS_max;
                img_2nd_diff = handles.img_TS_diff;

            else
                status_second = 0;
            end
   end
else
    status_second = 0;
end

%- Show one or two images
status_img_one =  not(status_second && status_show_FISH);

%- Get transparency for second iamge
img2_transp = str2double(get(handles.text_2nd_transp,'String'))/100;


%- Select output axis
if isempty(axes_select)
    figure
else
    axes(axes_select)
    v = axis;
    cla    
end

x_min = v(1);
x_max = v(2);
y_min = v(3);
y_max = v(4);

%- FISH: determine the contrast of the image
slider_min = get(handles.slider_contrast_min,'Value');
slider_max = get(handles.slider_contrast_max,'Value');

img_min  = handles.img_min;
img_diff = handles.img_diff;

Im_min = slider_min*img_diff+img_min;
Im_max = slider_max*img_diff+img_min;

if Im_max < Im_min
    Im_max = Im_min+1;
end

%- 2nd stack: determine the contrast of the image
if status_second
    slider_min_2nd = get(handles.slider_contrast_min_2nd,'Value');
    slider_max_2nd = get(handles.slider_contrast_max_2nd,'Value');

    img_min_2nd  = img_2nd_min;
    img_diff_2nd = img_2nd_diff;

    contr_2nd_min = slider_min_2nd*img_diff_2nd+img_min_2nd;
    contr_2nd_max = slider_max_2nd*img_diff_2nd+img_min_2nd;

    if contr_2nd_max < contr_2nd_min
        contr_2nd_max = contr_2nd_min+1;
    end
end

%- Determine which image should be shown
str = get(handles.pop_up_image, 'String');
val = get(handles.pop_up_image,'Value');

%- Set experimental settings based on selection
switch str{val};
    
    case 'Maximum projection' 
        
        %- Show FISH image
        if status_show_FISH
            imshow(handles.img_plot,[Im_min Im_max])
            colormap(hot), axis off
        end
        handles.img_FISH_disp = handles.img_plot;
        
        %- Show second image
        if status_second

            hold on
                if status_img_one
                    imshow(img2_plot,[contr_2nd_min contr_2nd_max])
                    colormap bone, axis off
                else
                   dum1 = uint32(  (img2_plot-contr_2nd_min) * (255 / double(contr_2nd_max-contr_2nd_min) ) );  
                   dum2 = ind2rgb(dum1,handles.cMap2); 
                   h2   = subimage(dum2);
                   set(h2, 'AlphaData', img2_transp)  
                end
            hold off
            
            handles.img_2nd_disp = img2_plot;
        end
     
        title('Maximum projection of loaded image','FontSize',9);
    
    %- Z-stack    
    case 'Z-stack'
        
        ind_plot = str2double(get(handles.text_z_slice,'String'));

        %- Show FISH image
        img_plot =  handles.img.raw(:,:,ind_plot);
        if status_show_FISH
            imshow(img_plot,[Im_min Im_max])
            colormap hot, axis off
        end
        handles.img_FISH_disp = img_plot;
        
        %- Show second image
        if status_second
            
               switch img2_type
                    case 'DAPI'         
                        img2_disp =  handles.img.DAPI(:,:,ind_plot);
            
                    case 'TS_label'
                        img2_disp =  handles.img.TS_label(:,:,ind_plot);
            
               end
            

            hold on
                if status_img_one
                    imshow(img2_disp,[contr_2nd_min contr_2nd_max])
                    colormap bone, axis off
                else
                   dum1 = uint32((img2_disp-contr_2nd_min) * (255/double(contr_2nd_max-contr_2nd_min)));  
                   dum2 = ind2rgb(dum1,handles.cMap2); 
                   h2   = subimage(dum2);
                   set(h2, 'AlphaData', img2_transp)  
                end
            hold off
            
            handles.img_2nd_disp = img2_disp;
        end

        %- Update title
        title(['slice # ' , num2str(ind_plot) , ' of ', num2str(handles.img.dim.Z)],'FontSize',9);
end

%- Plot outline of cell and TS
if status_show_outlines

    hold on
    %if isfield(handles.img,'cell_prop')    
        cell_prop = handles.img.cell_prop;    
        if not(isempty(cell_prop))  
            for i_cell = 1:size(cell_prop,2)
                x = cell_prop(i_cell).x;
                y = cell_prop(i_cell).y;
                plot([x,x(1)],[y,y(1)],'b','Linewidth', 2)  

               % Show cell labels
               if flag_show_cell_label

                    [ geom] = polygeom( x, y ); 
                    x_pos = geom(2); y_pos = geom(3);

                    if x_pos > x_min && x_pos < x_max && y_pos > y_min && y_pos < y_max
                        text(x_pos,y_pos,cell_prop(i_cell).label,'Color','w','FontSize',12, 'Interpreter', 'none','BackgroundColor',[0 0 0],'FontWeight','bold');
                    end
                end     
                
                %- Nucleus
                pos_Nuc   = cell_prop(i_cell).pos_Nuc;   
                if not(isempty(pos_Nuc))  
                    for i_nuc = 1:size(pos_Nuc,2)
                        x = pos_Nuc(i_nuc).x;
                        y = pos_Nuc(i_nuc).y;
                        plot([x,x(1)],[y,y(1)],':b','Linewidth', 2)  
                   end                
                end           

                %- TS
                pos_TS   = cell_prop(i_cell).pos_TS;   
                if not(isempty(pos_TS))  
                    for i_TS = 1:size(pos_TS,2)
                        x = pos_TS(i_TS).x;
                        y = pos_TS(i_TS).y;
                        plot([x,x(1)],[y,y(1)],'b','Linewidth', 2)  
                    end 
                end           
            end

            %- Plot selected cell in different color
            ind_cell = get(handles.listbox_cell,'Value');
            x = cell_prop(ind_cell).x;
            y = cell_prop(ind_cell).y;
            plot([x,x(1)],[y,y(1)],'g','Linewidth', 2)  
            
            %- Nucleus
            pos_Nuc   = cell_prop(ind_cell).pos_Nuc;   
            if not(isempty(pos_Nuc))  
                for i_nuc = 1:size(pos_Nuc,2)
                    x = pos_Nuc(i_nuc).x;
                    y = pos_Nuc(i_nuc).y;
                    plot([x,x(1)],[y,y(1)],':g','Linewidth', 2)  
               end                
            end           
            
            %- TS
            pos_TS   = cell_prop(ind_cell).pos_TS;   
            if not(isempty(pos_TS)) 
                          
                %- Plot selected TS in different color
                ind_sel = get(handles.listbox_TS,'Value');
                x = pos_TS(ind_sel).x;
                y = pos_TS(ind_sel).y;
                plot([x,x(1)],[y,y(1)],'g','Linewidth', 2)             
            end               
        end                
    %end 
    hold off
end

%- Same zoom as before
if not(status_plot_first)
    if axes_select == handles.axes_image
        axis(v);
    end
end

%- Save everything
status_plot_first = 0;

%= Check which elements should be enabled
GUI_enable(handles)

%== Outlines: yes/no
function checkbox_show_outlines_Callback(hObject, eventdata, handles)
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);

%== FISH image: yes/no
function checkbox_show_FISH_Callback(hObject, eventdata, handles)
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);


%== Slider minimum contrast
function slider_contrast_min_Callback(hObject, eventdata, handles)

if ~handles.status_draw
    slider_min = get(handles.slider_contrast_min,'Value');

    img_min  = handles.img_min;
    img_diff = handles.img_diff;

    contr_min = slider_min*img_diff+img_min;
    set(handles.text_contr_min,'String',num2str(round(contr_min)));

    handles = plot_image(handles,handles.axes_image);
    guidata(hObject, handles);
end

%== Slider maximum contrast
function slider_contrast_max_Callback(hObject, eventdata, handles)

if ~handles.status_draw
    slider_min = get(handles.slider_contrast_min,'Value');
    slider_max = get(handles.slider_contrast_max,'Value');

    img_min  = handles.img_min;
    img_diff = handles.img_diff;

    contr_min = slider_min*img_diff+img_min;
    contr_max = slider_max*img_diff+img_min;

    if contr_max < contr_min
        contr_max = contr_min+1;
    end
    set(handles.text_contr_max,'String',num2str(round(contr_max)));

    handles = plot_image(handles,handles.axes_image);
    guidata(hObject, handles);
end

%== Slider for slice
function slider_slice_Callback(hObject, eventdata, handles)
slider_value = get(handles.slider_slice,'Value');

ind_slice = round(slider_value*(handles.img.dim.Z-1)+1);
set(handles.text_z_slice,'String',num2str(ind_slice));

handles = plot_image(handles,handles.axes_image);
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
handles = plot_image(handles,handles.axes_image);
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
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);


%== Selection which image
function pop_up_image_Callback(hObject, eventdata, handles)

str = get(handles.pop_up_image, 'String');
val = get(handles.pop_up_image,'Value');

% Set experimental settings based on selection
switch str{val};
    
    case 'Maximum projection' 
        set(handles.text_z_slice,'String',NaN);
        set(handles.slider_slice,'Value',0);
        
        set(handles.button_slice_decr,'Enable','off');
        set(handles.button_slice_incr,'Enable','off');        
        set(handles.slider_slice,'Enable','off'); 
    
    case 'Z-stack'
        set(handles.text_z_slice,'String',1);
        set(handles.slider_slice,'Value',0);
        
        set(handles.button_slice_decr,'Enable','on');
        set(handles.button_slice_incr,'Enable','on');        
        set(handles.slider_slice,'Enable','on'); 
end


handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles);


%== Selection which image
function checkbox_sep_window_Callback(hObject, eventdata, handles)

status_sep = get(handles.checkbox_sep_window,'Value');
if status_sep == 0
    handles.v_axis = [];
end


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


%== Pan
function button_pan_Callback(hObject, eventdata, handles)
if handles.status_pan == 0
    h_pan = pan;
    set(h_pan,'Enable','on');
    handles.status_pan  = 1;
    handles.status_zoom = 0;
    handles.h_pan      = h_pan;    
else
    set(handles.h_pan,'Enable','off');    
    handles.status_pan = 0;
end
guidata(hObject, handles);


%== Cursor
function button_cursor_Callback(hObject, eventdata, handles)

%- Deactivate zoom
if ishandle(handles.h_zoom)
    set(handles.h_zoom,'Enable','off');  
end

%- Deactivate pan
if ishandle(handles.h_pan)
    set(handles.h_pan,'Enable','off');  
end

%-Datacursormode
dcm_obj = datacursormode;

set(dcm_obj,'SnapToDataVertex','off');
set(dcm_obj,'UpdateFcn',@(x,y)myupdatefcn(x,y,handles))


%=== Function for Data cursor
function txt = myupdatefcn(empt,event_obj,handles)

pos    = get(event_obj,'Position');
target = get(event_obj,'Target');

%- Update cursor accordingly
img_FISH = handles.img_FISH_disp;
img_2nd  = handles.img_2nd_disp;

x_pos = round(pos(1));
y_pos = round(pos(2));

% FISH signal
int_FISH = img_FISH(y_pos,x_pos);

%- DAPI signal
if not(isempty(img_2nd))
    int_2nd = img_2nd(y_pos,x_pos);
else
    int_2nd = '';
end

txt = {['X: ',num2str(x_pos)],...
       ['Y: ',num2str(y_pos)],...
       ['Int (FISH): ',num2str(int_FISH)],...
       ['Int (2nd): ',num2str(int_2nd)]};
     

% =========================================================================
% Second stack
% =========================================================================
   
%=== Figure out if image is present or not 
function select_second_stack_Callback(hObject, eventdata, handles)
   

val = get(handles.select_second_stack,'Value');
str = get(handles.select_second_stack,'String');

switch str{val}
    
    case 'DAPI'
   
        if handles.status_DAPI
            set(handles.checkbox_second_stack,'Enable','on')
            set(handles.checkbox_second_stack,'Value',1)
            status_second = 1;
        else
            set(handles.checkbox_second_stack,'Enable','off')
            set(handles.checkbox_second_stack,'Value',0)
            status_second = 0;
        end
        
        
    case 'TS_label'
        
        if handles.status_TS_label
            set(handles.checkbox_second_stack,'Enable','on')
            set(handles.checkbox_second_stack,'Value',1)
            status_second = 1;
        else
            set(handles.checkbox_second_stack,'Enable','off')
            set(handles.checkbox_second_stack,'Value',0)
            status_second = 0;
        end
        
end

if status_second
    
    %- Update the sliders
    handles.status_update_only = 1;
    slider_contrast_min_2nd_Callback(hObject, eventdata, handles)
    slider_contrast_max_2nd_Callback(hObject, eventdata, handles)
    handles.status_update_only = 0;

    %- Plot image
    handles = plot_image(handles,handles.axes_image);
end

guidata(hObject, handles);


%== Enable/disable display of second stack
function checkbox_second_stack_Callback(hObject, eventdata, handles)
handles = plot_image(handles,handles.axes_image);
guidata(hObject, handles); 


%== Slider for max contrast
function slider_contrast_max_2nd_Callback(hObject, eventdata, handles)
if ~handles.status_draw
    if handles.status_DAPI || handles.status_TS_label
        slider_min = get(handles.slider_contrast_min_2nd,'Value');
        slider_max = get(handles.slider_contrast_max_2nd,'Value');

        str = get(handles.select_second_stack,'String');
        val = get(handles.select_second_stack,'Value');

        switch str{val}
            case 'DAPI'

                    img_min = handles.img_DAPI_min;
                    img_diff = handles.img_DAPI_diff;

            case 'TS_label'
                    img_min = handles.img_TS_min;
                    img_diff = handles.img_TS_diff;
        end

        contr_min = slider_min*img_diff+img_min;
        contr_max = slider_max*img_diff+img_min;

        if contr_max < contr_min
            contr_max = contr_min+1;
        end
        set(handles.text_contr_max_2nd,'String',num2str(round(contr_max)));


        if handles.status_update_only == 0
            handles = plot_image(handles,handles.axes_image);
            guidata(hObject, handles);
        end

    end
end


%== Slider for min contrast
function slider_contrast_min_2nd_Callback(hObject, eventdata, handles)

if ~handles.status_draw
    if handles.status_DAPI || handles.status_TS_label

        slider_min = get(handles.slider_contrast_min_2nd,'Value');

        str = get(handles.select_second_stack,'String');
        val = get(handles.select_second_stack,'Value');

        switch str{val}
            case 'DAPI'
                    img_min = handles.img_DAPI_min;
                    img_diff = handles.img_DAPI_diff;

            case 'TS_label'
                    img_min = handles.img_TS_min;
                    img_diff = handles.img_TS_diff;
        end

        contr_min = slider_min*img_diff+img_min;
        set(handles.text_contr_min_2nd,'String',num2str(round(contr_min)));

        if handles.status_update_only == 0
            handles = plot_image(handles,handles.axes_image);
            guidata(hObject, handles);
        end
    end
end

%== Show cell labels
function menu_show_labels_Callback(hObject, eventdata, handles)


% =========================================================================
% Experimental parameters
% =========================================================================

%== Modify parameters
function menu_change_exp_par_Callback(hObject, eventdata, handles)
par_microscope = handles.par_microscope;

dlgTitle = 'Experimental parameters';

prompt(1) = {'Pixel-size xy [nm]'};
prompt(2) = {'Pixel-size z [nm]'};
prompt(3) = {'Refractive index'};
prompt(4) = {'Numeric aperture NA'};
prompt(5) = {'Emission wavelength'};
prompt(6) = {'Excitation wavelength'};
prompt(7) = {'Microscope'};

defaultValue{1} = num2str(par_microscope.pixel_size.xy);
defaultValue{2} = num2str(par_microscope.pixel_size.z);
defaultValue{3} = num2str(par_microscope.RI);
defaultValue{4} = num2str(par_microscope.NA);
defaultValue{5} = num2str(par_microscope.Em);
defaultValue{6} = num2str(par_microscope.Ex);
defaultValue{7} = num2str(par_microscope.type);

userValue = inputdlg(prompt,dlgTitle,1,defaultValue);

if( ~ isempty(userValue))
    par_microscope.pixel_size.xy = str2double(userValue{1});
    par_microscope.pixel_size.z  = str2double(userValue{2});   
    par_microscope.RI            = str2double(userValue{3});   
    par_microscope.NA            = str2double(userValue{4});
    par_microscope.Em            = str2double(userValue{5});   
    par_microscope.Ex            = str2double(userValue{6});
    par_microscope.type    = userValue{7};   
end


%- Calculate theoretical PSF and show it 
[PSF_theo.xy_nm, PSF_theo.z_nm] = sigma_PSF_BoZhang_v1(par_microscope);
PSF_theo.xy_pix = PSF_theo.xy_nm / par_microscope.pixel_size.xy ;
PSF_theo.z_pix  = PSF_theo.z_nm  / par_microscope.pixel_size.z ;


%- Update handles structure
handles.PSF_theo       = PSF_theo;
handles.par_microscope = par_microscope;
guidata(hObject, handles);


%== Button down
function h_fishquant_outline_ButtonDownFcn(hObject, eventdata, handles)


% =========================================================================
% NOT USED
% =========================================================================

function listbox_TS_CreateFcn(hObject, eventdata, handles)

function listbox_cell_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_parameters_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_contrast_min_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_contrast_max_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_slice_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function pop_up_image_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_region_Callback(hObject, eventdata, handles)

function pop_up_region_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_th_auto_detect_Callback(hObject, eventdata, handles)

function text_th_auto_detect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Untitled_1_Callback(hObject, eventdata, handles)

function Untitled_2_Callback(hObject, eventdata, handles)

function text_th_nucleus_Callback(hObject, eventdata, handles)

function text_th_nucleus_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function select_second_stack_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Untitled_3_Callback(hObject, eventdata, handles)

function Untitled_4_Callback(hObject, eventdata, handles)

function text_2nd_transp_Callback(hObject, eventdata, handles)

function text_2nd_transp_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_TS_only_nucleus_Callback(hObject, eventdata, handles)

function text_th_min_TS_DAPI_Callback(hObject, eventdata, handles)

function text_th_min_TS_DAPI_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popupmenu_select_img_detect_Callback(hObject, eventdata, handles)

function popupmenu_select_img_detect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function slider_contrast_max_2nd_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_contrast_min_2nd_CreateFcn(hObject, eventdata, handles)

if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function checkbox_nuc_auto_in_curr_cell_Callback(hObject, eventdata, handles)
