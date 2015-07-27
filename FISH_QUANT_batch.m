function varargout = FISH_QUANT_batch(varargin)
% FISH_QUANT_BATCH M-file for FISH_QUANT_batch.fig

% Last Modified by GUIDE v2.5 05-Mar-2015 18:01:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_batch_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_batch_OutputFcn, ...
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


% --- Executes just before FISH_QUANT_batch is made visible.
function FISH_QUANT_batch_OpeningFcn(hObject, eventdata, handles, varargin)

%- Only initiate if not already open
if not(isfield(handles,'img'))

    %- Set font-size to 10
    %  On windows are set back to 8 when the .fig is openend
    h_font_8 = findobj(handles.h_gui_batch,'FontSize',8);
    set(h_font_8,'FontSize',10)

    
    %- Get installation directory of FISH-QUANT and initiate 
%     p = mfilename('fullpath');        
%     handles.FQ_path = fileparts(p); 

    % == Fenerate FQ image object
    handles.img = FQ_img;
     
    %- Get folders from main interface
    menu_folder_FQ_main_Callback(hObject, eventdata, handles)
    
    
    %- Parameters to save results
    handles.file_summary   = [];
    handles.cell_summary   = {};
    handles.cell_counter   = 1;
    
    handles.TS_summary     = {};
    handles.TS_counter     = 1;

    handles.spots_fit_all  = [];
    handles.spots_range    = [];

    %- Status flags
    handles.status_avg_settings = 0;  % AVG spots: settings defined
    handles.status_avg_calc     = 1;  % AVG spots: calculated
    handles.status_started = 1;
    handles.status_setting = 0;
    handles.status_files   = 0;
    handles.status_fit     = 0;
    handles.status_AMP              = 0;
    handles.status_AMP_PROC         = 0;
    handles.status_settings_TS      = 0;
    handles.status_QUANT            = 0;
    handles.status_settings_TS_proc = 0;
    handles.status_PSF_PROC         = 0;
    handles.status_TS_simple_only   = 0;
    handles.status_outline_unique_loaded = 0;
    handles.status_outline_unique_enable = 0;
    handles.status_settings_TS_detect    = 0;
        
    %- Other parameters
    handles.par_microscope = [];
    handles.PSF            = [];
    handles.flag_fit       = 0;
 
    
    %=== Options for autosave
    handles.i_file_proc_mature = 1;
    
    %=== Options for TxSite quantification
    handles.i_file_proc        = 1; % Index where the processing starts (used when autosaved data is loaded).
    handles.i_cell_proc        = 1;
    handles.i_TS_proc          = 1;

    handles.status_auto_detect = 0;

    handles.mRNA_prop     = [];
    handles.PSF_shift     = [];
    handles.PSF_path_name = [];
    handles.PSF_file_name = [];
    handles.BGD_path_name = [];
    handles.BGD_file_name = [];
    handles.bgd_value     = [];    
    handles.AMP_path_name = [];
    handles.AMP_file_name = [];    
    handles.fact_os       = [];  

    
   % handles.settings_TS_detect = [];

    %- File-names
    handles.file_name_settings_new = [];
    handles.file_name_settings     = [];
    handles.file_name_settings_TS  = [];

    %- Default file-names
    handles.file_name_suffix_spots  = ['_spots_', datestr(date,'yymmdd'), '.txt'];
    handles.file_name_summary       = ['__FQ_batch_summary_MATURE_', datestr(date,'yymmdd'), '.txt'];
    handles.file_name_summary_TS    = ['__FQ_batch_summary_NASCENT_', datestr(date,'yymmdd'), '.txt'];
    handles.file_name_summary_ALL   = ['__FQ_batch_summary_ALL_', datestr(date,'yymmdd'), '.txt'];

    handles.file_name_settings_save         = ['_FQ_batch_settings_MATURE_', datestr(date,'yymmdd'), '.txt'];
    handles.file_name_settings_nascent_save = ['_FQ_batch_settings_NASCENT_', datestr(date,'yymmdd'), '.txt'];

    %- Settings for saving
    %handles.settings_save.N_ident = 4;  
    handles.settings_save.file_id_start = 4;
    handles.settings_save.file_id_end   = 0;

    %- Names for filtering
    handles.name_filtered.string_search  = '';
    handles.name_filtered.string_replace = '_filtered_batch';

    %- Change name of GUI
    set(handles.h_gui_batch,'Name', ['FISH-QUANT ', handles.img.version, ': batch mode']);

    %=== Plot rendering
    handles.h_VTK = [];
    handles.settings_rendering.factor_BGD = 1;
    handles.settings_rendering.factor_int = 1;
    handles.settings_rendering.flag_crop  = 1;
    handles.settings_rendering.opacity    = 0.5;

%     %=== Get ImageJ directories
%     FQ_path       = handles.FQ_path;
%     ij_macro_name = handles.ij_macro_name;                              
%     handles.imagej_macro_name = fullfile(FQ_path,'java',ij_macro_name);

    %- Export figure handle to workspace - will be used in Close All button of
    % main Interface
    assignin('base','h_batch',handles.h_gui_batch)

    %- Update everything and save
    controls_enable(hObject, eventdata, handles)
end

%- Save
handles.output = hObject;
guidata(hObject, handles);


% =========================================================================
% Enable & status update
% =========================================================================

%== Enable
function controls_enable(hObject, eventdata, handles)

str_list = get(handles.listbox_files,'String');

if not(isempty(str_list))
    handles.status_files = 1;
else
	handles.status_files = 0;
end

%==== Mature mNRA detection

%- Settings for mature mRNA define
if handles.status_setting
    set(handles.text_status_settings,'String','Settings defined')
    set(handles.text_status_settings,'ForegroundColor','g')
else
    set(handles.text_status_settings,'String','NOT defined')
    set(handles.text_status_settings,'ForegroundColor','r') 
end


%==== Controls to add, delete files
if handles.status_fit
   
   set(handles.button_files_delete,'Enable','off');
   set(handles.button_files_delete_all,'Enable','off'); 
   set(handles.button_files_add,'Enable','off');
   set(handles.text_status_files,'String','Select New analysis from menu to analyse different files.')
   set(handles.text_status_files,'ForegroundColor','b')
   
else
    
   set(handles.button_files_add,'Enable','on');
   
    
    if not(isempty(str_list))
        set(handles.text_status_files,'String','Files listed')
        set(handles.text_status_files,'ForegroundColor','g')

       set(handles.button_files_delete,'Enable','on'); 
       set(handles.button_files_delete_all,'Enable','on'); 

    else
        set(handles.text_status_files,'String','No files')
        set(handles.text_status_files,'ForegroundColor','r')

       set(handles.button_files_delete,'Enable','off');
       set(handles.button_files_delete_all,'Enable','off'); 
    end
end


%- Files to process and settings defined
if handles.status_setting && handles.status_files 
   set(handles.button_process,'Enable','on');    
   set(handles.button_fit_restrict,'Enable','on'); 
   
   set(handles.button_process,'Enable','on'); 
else
   set(handles.button_process,'Enable','off'); 
   set(handles.button_fit_restrict,'Enable','off'); 
   
   set(handles.button_process,'Enable','off'); 
end


%- Mature mRNA is processed
if handles.status_avg_settings
   set(handles.menu_avg_calc,'Enable','on');     
else
   set(handles.menu_avg_calc,'Enable','off'); 
end

%=== Spots are averaged
set(handles.menu_avg_fit ,'Enable','off')
set(handles.menu_avg_save_ns ,'Enable','off')
set(handles.menu_avg_save_os ,'Enable','off')
set(handles.menu_imagej_ns ,'Enable','off')
set(handles.menu_imagej_os ,'Enable','off')


if handles.status_avg_calc 
    set(handles.menu_avg_fit ,'Enable','on')
    set(handles.menu_avg_save_ns ,'Enable','on')
    set(handles.menu_avg_save_os ,'Enable','on')
    set(handles.menu_imagej_ns ,'Enable','on')   
    set(handles.menu_imagej_os ,'Enable','on')
end


% ==== After fit is done - thresholding and saving
if handles.status_fit

    %- Enable thresholding
    set(handles.button_threshold,'Enable','on')
    set(handles.pop_up_threshold,'Enable','on')
    set(handles.slider_th_min,'Enable','on')
    set(handles.slider_th_max,'Enable','on')
    set(handles.text_th_min,'Enable','on')
    set(handles.text_th_max,'Enable','on')
    set(handles.checkbox_th_lock,'Enable','on')
    set(handles.button_th_unlock_all,'Enable','on')
    set(handles.text_min_dist_spots,'Enable','on') 
    
    %- Other controls
    set(handles.button_show_detected_spots,'Enable','on')
  
else

    %- Enable thresholding
    set(handles.button_threshold,'Enable','off')
    set(handles.pop_up_threshold,'Enable','off')
    set(handles.slider_th_min,'Enable','off')
    set(handles.slider_th_max,'Enable','off')
    set(handles.text_th_min,'Enable','off')
    set(handles.text_th_max,'Enable','off')
    set(handles.checkbox_th_lock,'Enable','off')
    set(handles.button_th_unlock_all,'Enable','off')
    set(handles.text_min_dist_spots,'Enable','off') 
    
    %- Other controls
    set(handles.button_show_detected_spots,'Enable','off')

end


% === Enable unique outline processing
if handles.status_outline_unique_loaded
    set(handles.menu_load_outline_enable ,'Enable','on') 
else
    set(handles.menu_load_outline_enable ,'Enable','off')
end


%== AUTODETECT TxSite
if not(isempty(str_list)) && handles.status_settings_TS_detect  && handles.status_setting
    set(handles.button_TS_detect,'Enable','on');  
else
    set(handles.button_TS_detect,'Enable','off');  
end


% ======= TxSite quantification
if handles.status_settings_TS 
    set(handles.text_status_PSF,'String','Settings defined')
    set(handles.text_status_PSF,'ForegroundColor','g')
else
    set(handles.text_status_PSF,'String','Settings NOT defined')
    set(handles.text_status_PSF,'ForegroundColor','r')
end

%- Only simple quantifications
if handles.status_TS_simple_only

    if handles.status_setting && handles.status_settings_TS 
       set(handles.button_process_TxSite,'Enable','on');     
    else
       set(handles.button_process_TxSite,'Enable','off'); 
    end
    
        
else

    % === TxSite quantification: analyze PSF
    if handles.status_setting && handles.status_settings_TS 
       set(handles.button_analyze_TxSite,'Enable','on');     
    else
       set(handles.button_analyze_TxSite,'Enable','off'); 
    end


    % === Settigns for TS and mature are defined  
    if handles.status_setting && handles.status_settings_TS 
        set(handles.button_PSF_amp,'Enable','on');
    else
        set(handles.button_PSF_amp,'Enable','off'); 

    end

    %== Amplitudes are define
    if handles.status_AMP
        set(handles.text_AMP,'String','AMPs defined')
        set(handles.text_AMP,'ForegroundColor','g')    
    else
        set(handles.text_AMP,'String','AMPs NOT defined')
        set(handles.text_AMP,'ForegroundColor','r')       
    end

    %== PSF is processed
    if  handles.status_PSF_PROC
        set(handles.text_PSF_analyze,'String','Settings analyzed')
        set(handles.text_PSF_analyze,'ForegroundColor','g')
    else
        set(handles.text_PSF_analyze,'String','Settings NOT analyzed')
        set(handles.text_PSF_analyze,'ForegroundColor','r')
    end


    %== Analyze TxSite
    if handles.status_PSF_PROC && not(isempty(str_list))
        set(handles.button_process_TxSite,'Enable','on');  
    else
        set(handles.button_process_TxSite,'Enable','off');  
    end
end



%== Save results of mature mRNA detection
if isempty(handles.cell_summary)
    set(handles.menu_save_mature,'Enable','off'); 
    set(handles.menu_save_results_image_only_th,'Enable','off'); 
    set(handles.menu_save_results_image,'Enable','off'); 
    set(handles.menu_save_summary_thresolded_spots,'Enable','off'); 
    set(handles.menu_save_summary_spots,'Enable','off'); 
else
    set(handles.menu_save_mature,'Enable','on'); 
    set(handles.menu_save_results_image_only_th,'Enable','on'); 
    set(handles.menu_save_results_image,'Enable','on'); 
    set(handles.menu_save_summary_thresolded_spots,'Enable','on'); 
    set(handles.menu_save_summary_spots,'Enable','on');  
end    
    
    
%== Restrict size
if not(isempty(handles.TS_summary)) && not(handles.status_TS_simple_only)
    set(handles.button_TS_restrict_size,'Enable','on');   
else
    set(handles.button_TS_restrict_size,'Enable','off');      
end

%== Save results of nascent mRNA quantification
if isempty(handles.TS_summary)
    set(handles.menu_save_nascent,'Enable','off');  
    set(handles.button_TS_restrict_size,'Enable','off');  
    
else
    set(handles.menu_save_nascent,'Enable','on');  
    set(handles.button_TS_restrict_size,'Enable','on');      
end


%== Save results of TS quantification and mature mRNA detection
if not(isempty(handles.TS_summary)) && not(isempty(handles.cell_summary))
    set(handles.menu_save_nascent_mature,'Enable','on');  
else
    set(handles.menu_save_nascent_mature,'Enable','off');  
end    


%== Update status
function status_update(hObject, eventdata, handles,status_text)
status_old = get(handles.listbox_status,'String');
status_new = [status_old;status_text];
set(handles.listbox_status,'String',status_new)
set(handles.listbox_status,'ListboxTop',round(size(status_new,1)))
drawnow
guidata(hObject, handles); 


%== New analysis
function menu_new_analysis_Callback(hObject, eventdata, handles)

%- Ask user to confirm choice
choice = questdlg('Will delete results of current analysis. Contintue?', 'FISH-QUANT', 'Yes','No','No');

if strcmp(choice,'Yes')
    
    set(handles.listbox_files,'String',{})
    set(handles.listbox_files,'Value',1)
    
    reset(handles.axes_histogram_th);
    cla(handles.axes_histogram_th);
    
    reset(handles.axes_histogram_all);
    cla(handles.axes_histogram_all);
    
    
    %=== Options for autosave
    
    
    handles.i_file_proc_mature = 1;
    handles.i_file_proc        = 1; % Index where the processing starts (used when autosaved data is loaded).
    handles.i_cell_proc        = 1;
    handles.i_TS_proc          = 1;
    
    
    %- Parameters to save results
    handles.img.reinit;
    
    handles.file_summary   = [];
    handles.cell_summary   = {};
    handles.cell_counter   = 1;
    
    handles.TS_summary     = {};
    handles.TS_counter     = 1;

    handles.spots_fit_all  = [];
    handles.img.thresh_all     = [];
    handles.spots_range    = [];

    %- Status flags
    handles.status_started = 1;
    handles.status_setting = 0;
    handles.status_files   = 0;
    handles.status_fit     = 0;
    handles.status_AMP              = 0;
    handles.status_AMP_PROC         = 0;
    handles.status_settings_TS      = 0;
    handles.status_QUANT            = 0;
    handles.status_settings_TS_proc = 0;
    handles.status_PSF_PROC         = 0;
    handles.status_TS_simple_only   = 0;
    handles.status_outline_unique_loaded = 0;
    handles.status_outline_unique_enable = 0;
    handles.status_settings_TS_detect    = 0;
    
    %- Set all threshold locks to zero - the ones which are locked will be changed to one 
    handles.img.thresh_all.sigmaxy.lock  = 0;
    handles.img.thresh_all.sigmaz.lock   = 0;
    handles.img.thresh_all.amp.lock      = 0;
    handles.img.thresh_all.bgd.lock      = 0;
    handles.img.thresh_all.pos_z.lock    = 0;
    handles.img.thresh_all.int_raw.lock  = 0;
    handles.img.thresh_all.int_filt.lock = 0;

    %- Update status
    controls_enable(hObject, eventdata, handles)
    status_update(hObject, eventdata, handles,{' ';'## Analysis results cleared.'});    
end
   


%==========================================================================
%==== Define folders 
%==========================================================================

%== Define folder for root
function menu_folder_root_Callback(hObject, eventdata, handles)
path_usr  = uigetdir(handles.img.path_names.root, 'Choose ROOT directory');

if path_usr
    handles.img.path_names.root = path_usr;
    guidata(hObject, handles);
end


%== Define folder for images
function menu_folder_image_Callback(hObject, eventdata, handles)
if isempty(handles.img.path_names.img)
   dir_default =  handles.img.path_names.root;
else
    dir_default =  handles.img.path_names.img;
end

path_usr  =  uigetdir(dir_default, 'Choose directory for images');

if path_usr
    handles.img.path_names.img = path_usr;
    guidata(hObject, handles);
end 

 
%== Define folder for outines
function menu_folder_outline_Callback(hObject, eventdata, handles)
if isempty(handles.img.path_names.outlines)
   dir_default =  handles.img.path_names.root;
else
    dir_default =  handles.img.path_names.outlines;
end

path_usr  =  uigetdir(dir_default, 'Choose directory for outlines');

if path_usr
    handles.img.path_names.outlines = path_usr;
    guidata(hObject, handles);
end 


%== Define folder for outines
function menu_folder_results_Callback(hObject, eventdata, handles)
if isempty(handles.img.path_names.results)
   dir_default =  handles.img.path_names.root;
else
    dir_default =  handles.img.path_names.results;
end

path_usr  =  uigetdir(dir_default, 'Choose directory for results');

if path_usr
    handles.img.path_names.results = path_usr;
    guidata(hObject, handles);
end 


%== Reset folders
function menu_folder_reset_Callback(hObject, eventdata, handles)

button = questdlg('Are you sure?','Reset folders','Yes','No','No');

if strcmp(button,'Yes') 
    handles.img.path_names.root    = [];
    handles.img.path_names.results = [];
    handles.img.path_names.img   = [];
    handles.img.path_names.outlines = [];
    guidata(hObject, handles);
end


%== Use folders from main interface
function menu_folder_FQ_main_Callback(hObject, eventdata, handles)

global FQ_main_folder
handles.img.path_names.root    = FQ_main_folder.root;
handles.img.path_names.results = FQ_main_folder.results;
handles.img.path_names.img   = FQ_main_folder.image;
handles.img.path_names.outlines = FQ_main_folder.outline;


%- Change path of results if not defined
if isempty(handles.img.path_names.results)
    handles.img.path_names.results   = handles.img.path_names.root;
end

%- Change path of image if not defined
if isempty(handles.img.path_names.img)
    handles.img.path_names.img   = handles.img.path_names.root;
end

%- Change path of root if not defined
if isempty(handles.img.path_names.root)
    handles.img.path_names.root   = handles.img.path_names.root;
end

%- Change path of root if not defined
if isempty(handles.img.path_names.outlines)
    handles.img.path_names.outlines   = handles.img.path_names.root;
end

guidata(hObject, handles);



% =========================================================================
% FILES
% =========================================================================


%== Load settings
function load_settings_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with results/settings
current_dir = cd;

if    not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif  not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- Get settings
[file_name_settings,path_name_settings] = uigetfile({'*.txt'},'Select file with settings');

if file_name_settings ~= 0  
    name_settings.path = path_name_settings;
    name_settings.name = file_name_settings;
    handles = load_settings(hObject, eventdata, handles,name_settings);
    guidata(hObject, handles);
end

%- Go back to original folder
cd(current_dir)


%= FUNCTION that loads the settings
function handles = load_settings(hObject, eventdata, handles,name_settings)

    
%- Set all threshold locks to zero - the ones which are locked will be changed to one 
handles.img.settings.thresh.sigmaxy.lock   = 0;
handles.img.settings.thresh.sigmaz.lock    = 0;
handles.img.settings.thresh.amp.lock       = 0;
handles.img.settings.thresh.bgd.lock       = 0;
handles.img.settings.thresh.pos_z.lock     = 0;
handles.img.settings.thresh.int_raw.lock   = 0;
handles.img.settings.thresh.int_filt.lock  = 0; 

handles.detect.flag_detect_region = 0;

%- Load settings
handles.file_name_settings = name_settings.name;
handles.path_name_settings = name_settings.path;    

handles.img.load_settings(fullfile(name_settings.path,name_settings.name));

 
%- Check if there are limits
if not(isfield(handles.img.settings,'fit_limits'))
   handles.img.settings.fit_limits.sigma_xy_min = 0;
   handles.img.settings.fit_limits.sigma_xy_max = 1000;

   handles.img.settings.fit_limits.sigma_z_min = 0;
   handles.img.settings.fit_limits.sigma_z_max = 2000;
end

%- Check if the minimum distance is defined
if isfield(handles.img.settings ,'thresh') && isfield(handles.img.settings.thresh,'Spots_min_dist')
	set(handles.text_min_dist_spots,'String',num2str(handles.img.settings.thresh.Spots_min_dist))
else
    set(handles.text_min_dist_spots,'String',num2str(handles.img.par_microscope.pixel_size.z))
end


%- Save region for fit in separate variable --> otherwise complications
% occur when fitting averaged spot!    
handles.fit.region = handles.img.settings.detect.reg_size;

%- Update the ones that had a locked threshold
names_all = fieldnames(handles.img.settings.thresh);

N_names   = size(names_all,1);

for i_name = 1:N_names
    par_name   = char(names_all{i_name});
    par_fields = getfield(handles.img.settings.thresh,par_name);

    if isfield(par_name, 'lock')
    locked     = par_fields.lock;

        if locked    

                switch par_name

                    case 'sigmaxy'
                        handles.img.settings.thresh.sigmaxy.min_th = par_fields.min_th;                 
                        handles.img.settings.thresh.sigmaxy.max_th = par_fields.max_th;   

                    case 'sigmaz'
                         handles.img.settings.thresh.sigmaz.min_th = par_fields.min_th;                 
                        handles.img.settings.thresh.sigmaz.max_th = par_fields.max_th;   

                    case 'amp'
                        handles.img.settings.thresh.amp.min_th = par_fields.min_th;                 
                        handles.img.settings.thresh.amp.max_th = par_fields.max_th;                  

                    case 'bgd'
                        handles.img.settings.thresh.bgd.min_th = par_fields.min_th;                 
                        handles.img.settings.thresh.bgd.max_th = par_fields.max_th;                              

                    case 'pos_z'
                        handles.img.settings.thresh.bgd.min_th = par_fields.min_th;                 
                        handles.img.settings.thresh.bgd.max_th = par_fields.max_th;  

                    case 'int_raw'
                        handles.img.settings.thresh.int_raw.min_th = par_fields.min_th;                 
                        handles.img.settings.thresh.int_raw.max_th = par_fields.max_th; 

                    case 'int_filt'
                        handles.img.settings.thresh.int_filt.min_th = par_fields.min_th;                 
                        handles.img.settings.thresh.int_filt.max_th = par_fields.max_th; 

                    otherwise
                        warndlg('Thresholding parameter not defined.','load_settings');
                end
        end
    end
end

%- Update status
handles.status_setting = 1;    
status_update(hObject, eventdata, handles,{'  ';'## Settings loaded'});     

%- Save results
controls_enable(hObject, eventdata, handles)


%== Add files
function button_files_add_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with images
current_dir = pwd;
if not(isempty(handles.img.path_names.outlines))
   cd(handles.img.path_names.outlines)
elseif not(isempty(handles.img.path_names.img))
   cd(handles.img.path_names.img)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end

%- Get file names
[file_name_outline,path_name_list] = uigetfile({'*.txt';'*.tif';'*.stk'},'Select files with outline definition or image files','MultiSelect', 'on');

if ~iscell(file_name_outline)
    dum =file_name_outline; 
    file_name_outline = {dum};
end
    
if file_name_outline{1} ~= 0 
    
    str_list_old = get(handles.listbox_files,'String');
    
    if isempty(str_list_old)
        str_list_new = file_name_outline';
    else
        str_list_new = [str_list_old;file_name_outline'];
    end
    
    %- Sometimes there are problems with the list-box value
    if isempty(get(handles.listbox_files,'Value'))
        set(handles.listbox_files,'Value',1);
    end
    
    set(handles.listbox_files,'String',str_list_new);
    handles.path_name_list = path_name_list;
    
    %- Update status
    controls_enable(hObject, eventdata, handles)    
    status_text = { ' ';'## Outline definition files specified'; [num2str(size(str_list_new,1)) ' files will be processed']};
    status_update(hObject, eventdata, handles,status_text);  
    
    %- Save results
    guidata(hObject, handles); 

end

%- Go back to original image
cd(current_dir);


%== Delete selected files
function button_files_delete_Callback(hObject, eventdata, handles)

str_list = get(handles.listbox_files,'String');

if not(isempty(str_list))

    %- Ask user to confirm choice
    choice = questdlg('Do you really want to remove selected file(s)?', 'FISH-QUANT', 'Yes','No','No');

    if strcmp(choice,'Yes')

        %- Extract index of highlighted cell
        ind_sel  = get(handles.listbox_files,'Value');

        %- Delete highlighted cell
        str_list(ind_sel) = [];
        set(handles.listbox_files,'String',str_list)
        set(handles.listbox_files,'Value',1)

        %- Update status
        controls_enable(hObject, eventdata, handles)        
        status_text = {' ';'## File removed'; [num2str(size(str_list,1)) ' files will be processed']};
        status_update(hObject, eventdata, handles,status_text);  
    end
end


%== Delete all files
function button_files_delete_all_Callback(hObject, eventdata, handles)
%- Ask user to confirm choice
choice = questdlg('Do you really want to remove all files?', 'FISH-QUANT', 'Yes','No','No');

if strcmp(choice,'Yes')
    
    set(handles.listbox_files,'String',{})
    set(handles.listbox_files,'Value',1)
    
    %- Update status
    controls_enable(hObject, eventdata, handles)
    status_update(hObject, eventdata, handles,{' ';'## All files removed'});    
end


%== Load files with results
function menu_load_results_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with images
current_dir = pwd;
if not(isempty(handles.img.path_names.results))
   cd(handles.img.path_names.results)
elseif not(isempty(handles.img.path_names.img))
   cd(handles.img.path_names.img)
elseif not(isempty(handles.img.path_names.root))
   cd(handles.img.path_names.root) 
end


%- Ask user to confirm choice
choice = questdlg('Will delete results of current analysis. Contintue?', 'FISH-QUANT', 'Yes','No','No');

if strcmp(choice,'Yes')
    
    set(handles.listbox_files,'String',{})
    set(handles.listbox_files,'Value',1)
    
    %- Update status
    controls_enable(hObject, eventdata, handles)
    status_update(hObject, eventdata, handles,{' ';'## All files removed'});    

    %- Get files with results
    [file_name_results,path_name_results] = uigetfile({'*.txt'},'Select file with results of spot detection','MultiSelect', 'on');

    if ~iscell(file_name_results)
        dum =file_name_results; 
        file_name_results = {dum};
    end

    if file_name_results{1} ~= 0 


        ind_cell = 1;
        file_name_list = {};

        for i_F = 1:length(file_name_results)
             
            %- Load image
            status_open = handles.img.load_results(fullfile(path_name_results,file_name_results{i_F}),[]); 

            %- Assign parameters
             if status_open.outline

               file_summary(i_F).file_name_list      = file_name_results{i_F};
               file_summary(i_F).file_names          = handles.img.file_names;
               file_summary(i_F).file_names.results  = file_name_results{i_F};
               file_summary(i_F).par_microscope      = handles.img.par_microscope;
               file_summary(i_F).flag_file_ok        = 1;
               file_summary(i_F).status_file_ok      = 1;      
               file_name_list{i_F,1} = file_name_results{i_F};

               %=== Check how many cells in image
               cell_prop = handles.img.cell_prop;             
               N_cell = length(cell_prop);

               %- No cells
               if N_cell == 0

                    file_summary(i_F).cells.start = [];    
                    file_summary(i_F).cells.end   = [];

               %- Loop over cells
               else
                   file_summary(i_F).cells.start = ind_cell;

                   for i_C = 1:length(cell_prop)

                       cell_summary(ind_cell,1).name_list                = file_name_results{i_F};
                       cell_summary(ind_cell,1).name_image               = handles.img.file_names.raw;
                       cell_summary(ind_cell,1).file_name_image_filtered = handles.img.file_names.filtered;
                       cell_summary(ind_cell,1).label                    = cell_prop(i_C).label;
                       cell_summary(ind_cell,1).x                        = cell_prop(i_C).x; 
                       cell_summary(ind_cell,1).y                        = cell_prop(i_C).y;  
                       cell_summary(ind_cell,1).pos_TS                   = cell_prop(i_C).pos_TS;  
                       cell_summary(ind_cell,1).pos_Nuc                  = cell_prop(i_C).pos_Nuc; 
                       cell_summary(ind_cell,1).spots_fit                = cell_prop(i_C).spots_fit;
                       cell_summary(ind_cell,1).spots_detected           = cell_prop(i_C).spots_detected;

                       if not(isempty(cell_summary(ind_cell,1).spots_fit))
                           cell_summary(ind_cell,1).thresh.in = cell_prop(i_C).thresh.in;
                           N_total                            = size(cell_prop(i_C).spots_fit,1);  
                           cell_summary(ind_cell,1).N_total   = N_total;
                       else
                           cell_summary(ind_cell,1).thresh.in = []; 
                           cell_summary(ind_cell,1).N_total   = 0;
                       end

                       %-Get area of cell and nucleus
                        area_cell = polyarea(cell_prop(i_C).x,cell_prop(i_C).y);

                        if ~isempty(cell_prop(i_C).pos_Nuc)
                            area_nuc = polyarea(cell_prop(i_C).pos_Nuc.x,cell_prop(i_C).pos_Nuc.y);
                        else
                            area_nuc = 0;
                        end

                        cell_summary(ind_cell,1).area_cell = area_cell;
                        cell_summary(ind_cell,1).area_nuc  = area_nuc;

                        %- Update counter
                       ind_cell = ind_cell+1;

                   end
                   file_summary(i_F).cells.end      = ind_cell-1;  
               end       
             end
        end

        %- Update string list for files
        str_list_old = get(handles.listbox_files,'String');

        if isempty(str_list_old)
            str_list_new = file_name_list;
        else
            str_list_new = [str_list_old;file_name_list];
        end
        set(handles.listbox_files,'String',str_list_new); 

        %- Set all threshold locks to zero - the ones which are locked will be changed to one 
        handles.img.settings.thresh.sigmaxy.lock  = 0;
        handles.img.settings.thresh.sigmaz.lock   = 0;
        handles.img.settings.thresh.amp.lock      = 0;
        handles.img.settings.thresh.bgd.lock      = 0;
        handles.img.settings.thresh.pos_z.lock    = 0;
        handles.img.settings.thresh.int_raw.lock  = 0;
        handles.img.settings.thresh.int_filt.lock = 0;

        %- Update settings
        name_settings.path = handles.img.path_names.results;
        name_settings.name = handles.img.file_names.settings;
        handles = load_settings(hObject, eventdata, handles,name_settings);
        
        %- Assign results
        handles.cell_summary      = cell_summary;
        handles.path_name_list    = path_name_results;

        %- Change path of results if not defined
        if isempty(handles.img.path_names.results)
            handles.img.path_names.results   = path_name_results;
        end

        %- Change path of image if not defined
        if isempty(handles.img.path_names.img)
            handles.img.path_names.img   = path_name_results;
        end

        %- Change path of root if not defined
        if isempty(handles.img.path_names.root)
            handles.img.path_names.root   = path_name_results;
        end

        %- Change path of root if not defined
        if isempty(handles.img.path_names.outlines)
            handles.img.path_names.outlines   = path_name_results;
        end

        handles.file_summary      = file_summary;

        %- Update status
        status_text = {' ';'== Result files read in.';[num2str(ind_cell-1) ' can be averaged']};
        handles.status_fit = 1;
        status_update(hObject, eventdata, handles,status_text);
        controls_enable(hObject, eventdata, handles)

        %- Analyse results
        handles = results_summarize(hObject, eventdata, handles);

        if not(isempty(handles.spots_fit_all))
            handles = results_analyse(hObject, eventdata, handles);
            handles = pop_up_threshold_Callback(hObject, eventdata, handles);         
        else
            status_text = {' ';'NO SPOTS DETECTED'};
            status_update(hObject, eventdata, handles,status_text); 
        end
    end 
end


%- Save results
guidata(hObject, handles); 

%- Go back to original folder
cd(current_dir);
 

% =========================================================================
% Batch process
% =========================================================================

%== Load file with detection threshold settings
function menu_settings_detect_thresh_Callback(hObject, eventdata, handles)
[file_name_settings,path_name_settings] = uigetfile({'*.txt'},'Specify files with pre-detection settings for files','MultiSelect', 'on');

if file_name_settings ~= 0
    fid = fopen(fullfile(path_name_settings,file_name_settings));

    %- Read-in header line and determine number of columns
    header_line = fgetl(fid);
    num_cols    = 1 + sum(header_line == sprintf('\t'));

    %- Read in data
    str_read_in = ['%s',repmat('%f', 1, num_cols-1)];
    thresh_struct = textscan(fid, str_read_in,'HeaderLines',0,'delimiter','\t','CollectOutput',0);
    fclose(fid);

    %- Assign values
    detect_file.name = thresh_struct{1};
    
    if num_cols == 2 
        detect_file.th_detect = thresh_struct{2};
    end
    
    if num_cols > 2 
        detect_file.th_detect = thresh_struct{2};
        detect_file.th_score  = thresh_struct{3};
    end
   
    handles.detect_file = detect_file;
    guidata(hObject, handles);
end


%== Process all files
function button_process_Callback(hObject, eventdata, handles)

%- Update status
status_text = {' ';'== Processing files - check command window for details'};
status_update(hObject, eventdata, handles,status_text);

%- Some flags and status definitions
handles.img.settings.fit.flags.parallel = get(handles.checkbox_parallel_computing,'Value');
status_save_auto = get(handles.checkbox_auto_save_mature,'Value');

parameters.flags.filtered_use  = get(handles.checkbox_use_filtered,'Value');
parameters.flags.filtered_save = get(handles.checkbox_save_filtered,'Value');

%- Same outline for all images
parameters.flags.outline_unique_enable = handles.status_outline_unique_enable;
if parameters.flags.outline_unique_enable
    parameters.cell_prop_loaded = handles.cell_prop_loaded;
end

%- Path to images
if     not(isempty(handles.img.path_names.img))
    parameters.path_name_image = handles.img.path_names.img;
else 
    parameters.path_name_image = handles.path_name_list;
end

%- Path to save outlines images
if     not(isempty(handles.img.path_names.outlines))
    parameters.path_name_outline    = handles.img.path_names.outlines;
elseif not(isempty(handles.img.path_names.img))
    parameters.path_name_outline    = handles.img.path_names.img;
else
    parameters.path_name_outline = handles.path_name_list;
end

%- Path to files in list
parameters.path_name_list     = handles.path_name_list;

%- Structure with information about filtered file names
parameters.name_filtered       = handles.name_filtered;

%- Some options that might not be defined in older versions
if isfield(handles.img.settings.fit,'N_spots_fit_max')
    handles.img.settings.fit.N_spots_fit_max = -1;
end

%- List with files to be processed
file_list = get(handles.listbox_files,'String');
N_file = size(file_list,1);

%- Other parameters
cell_counter = handles.cell_counter;
cell_summary = handles.cell_summary;
file_summary = handles.file_summary;

%- Autosave or CTRL-C: check if you want to continue analysis or restart
if handles.i_file_proc_mature ~= 1
   choice = questdlg('Continue mature mRNA analysis where it got interrupted?','Batch-processing','Yes','No','Yes'); 
   
   if strcmp(choice,'No')
       handles.i_file_proc_mature = 1;
       handles.cell_counter   = 1;
       handles.file_summary   = [];
       handles.cell_summary   = {};  
   end    
end


%=== LOOP OVER ALL FILES and ALL CELLS
for i_file = handles.i_file_proc_mature:N_file
    
    %- Make new FQ object and reinitiate
    handles.img = handles.img.reinit;    
    handles.img

    %- Get first outline
    file_name_outline = file_list{i_file};
       
    disp(' ');
    disp(['=== Processing file ', num2str(i_file), ' of ', num2str(N_file)]);
        
    %- Update status
    status_text = {['- Processing file ', num2str(i_file), ' of ', num2str(N_file)]};
    status_update(hObject, eventdata, handles,status_text);        
    
    %- Check if separate detection settings are specified
    parameters.detect  = handles.detect;
    
    if isfield(handles,'detect_file')
        if isfield(handles.detect_file,'name')
            
            [dum name_loop] = fileparts(file_name_outline);
            ind_file = find(strcmpi(name_loop,handles.detect_file.name));  %- Old version
    
            if not(isempty(ind_file))
                if isfield(handles.detect_file,'th_detect')
                    handles.img.settings.detect.thresh_int = handles.detect_file.th_detect(ind_file);
                    disp(['- Individual detection threshold: ', num2str(handles.detect.thresh_int)])
                end

                if isfield(handles.detect_file,'th_score')
                    handles.img.settings.detect.thresh_score = handles.detect_file.th_score(ind_file);
                end
                
            else
                disp(['No threshold found for file: ', file_name_outline])
            end
        end
    end

    
    %- Process files  
    parameters.file_name_load = file_name_outline;         
    status_file_ok            = handles.img.proc_mature_all(parameters);           
   
    %- Save results
    file_summary(i_file).file_name_list   = file_list{i_file};
    file_summary(i_file).file_names       = handles.img.file_names;
    file_summary(i_file).par_microscope   = handles.img.par_microscope;
    file_summary(i_file).status_file_ok   = status_file_ok;
    
    %- Summarize results and loop over all processed cells for this file
    N_cell =  size(handles.img.cell_prop,2);

    if N_cell == 0
        
        file_summary(i_file).cells.start = [];
        file_summary(i_file).cells.end   = [];        
        
    else
        file_summary(i_file).cells.start = cell_counter;
   
        for i_cell = 1:N_cell

            N_total                                               = size(handles.img.cell_prop(i_cell).spots_fit,1);        
            cell_summary(cell_counter,1).name_list                = file_list{i_file};
            cell_summary(cell_counter,1).name_image               = handles.img.file_names.raw;
            cell_summary(cell_counter,1).file_name_image_filtered = handles.img.file_names.filtered;
            cell_summary(cell_counter,1).cell                     = handles.img.cell_prop(i_cell).label;
            cell_summary(cell_counter,1).N_total                  = N_total;
            cell_summary(cell_counter,1).spots_fit                = handles.img.cell_prop(i_cell).spots_fit;
            cell_summary(cell_counter,1).spots_detected           = handles.img.cell_prop(i_cell).spots_detected;
            cell_summary(cell_counter,1).thresh.in                = ones(size(handles.img.cell_prop(i_cell).spots_fit,1),1);

            cell_summary(cell_counter,1).label                    = handles.img.cell_prop(i_cell).label; 
            cell_summary(cell_counter,1).x                        = handles.img.cell_prop(i_cell).x; 
            cell_summary(cell_counter,1).y                        = handles.img.cell_prop(i_cell).y;  
            cell_summary(cell_counter,1).pos_TS                   = handles.img.cell_prop(i_cell).pos_TS; 
            cell_summary(cell_counter,1).pos_Nuc                  = handles.img.cell_prop(i_cell).pos_Nuc;   
            
            %-Get area of cell and nucleus
            area_cell = polyarea(handles.img.cell_prop(i_cell).x,handles.img.cell_prop(i_cell).y);
            
            if ~isempty(handles.img.cell_prop(i_cell).pos_Nuc)
                area_nuc = polyarea(handles.img.cell_prop(i_cell).pos_Nuc.x,handles.img.cell_prop(i_cell).pos_Nuc.y);
            else
                area_nuc = 0;
            end

            cell_summary(cell_counter,1).area_cell = area_cell;
            cell_summary(cell_counter,1).area_nuc  = area_nuc;
            
            %- Update cell counter
            cell_counter = cell_counter +1;
            
            %- Update status
            status_text = ['Spots: [total] ', num2str(N_total)];
            status_update(hObject, eventdata, handles,status_text);   
        end
    
        file_summary(i_file).cells.end = cell_counter-1;
    end
   
   handles.cell_summary       = cell_summary;
   handles.file_summary       = file_summary;
   handles.cell_counter       = cell_counter;
   handles.i_file_proc_mature = i_file+1;
   
   %- Auto-save
   if status_save_auto 
        file_name      = ['_FQ_analysis_AUTOSAVE_', datestr(date,'yymmdd'), '.mat'];
        file_name_full = fullfile(path_save_results,file_name);       
        FQ_batch_save_handles_v3(file_name_full,handles);
   end   
    
end

handles.cell_summary = cell_summary; 
handles.file_summary = file_summary;

%- Reset counter for auto-save
handles.i_file_proc_mature = 1;
handles.cell_counter       = 1;

%- Analyze and save results
handles.status_fit = 1;
handles = results_summarize(hObject, eventdata, handles);

if not(isempty(handles.spots_fit_all))
    handles = results_analyse(hObject, eventdata, handles);
    handles = pop_up_threshold_Callback(hObject, eventdata, handles);
    guidata(hObject, handles); 
else
    status_text = {' ';'NO SPOTS DETECTED'};
    status_update(hObject, eventdata, handles,status_text); 
end

%- Auto-save
if status_save_auto 
    file_name      = ['_FQ_analysis_AUTOSAVE_', datestr(date,'yymmdd'), '.mat'];
    file_name_full = fullfile(path_save_results,file_name);       
    FQ_batch_save_handles_v3(file_name_full,handles);
end  


%== Summarize results for quick illustration
function handles = results_summarize(hObject, eventdata, handles)

%-- Extract relevant parameters of all cells
cell_summary = handles.cell_summary;
thresh_all   = handles.img.settings.thresh;

spots_fit_all      = [];
spots_detected_all = [];
thresh_all.in      = [];

spots_range = {};

for i_cell = 1:size(cell_summary,1)
    
    %- Save start index of cell
    spots_range(i_cell).start = size(spots_fit_all,1)+1;
    
    %- Extract parameters for each cells
    spots_fit_loop      = cell_summary(i_cell,1).spots_fit;
    spots_detected_loop = cell_summary(i_cell,1).spots_detected;  
    thresh_in_loop      = cell_summary(i_cell,1).thresh.in;
    
    %- Save in long list
    spots_fit_all      = vertcat(spots_fit_all,spots_fit_loop);
    spots_detected_all = vertcat(spots_detected_all,spots_detected_loop);
    thresh_all.in      = vertcat(thresh_all.in,thresh_in_loop);
    
    %- Save end index of cell
    spots_range(i_cell).end = size(spots_fit_all,1);    
     
end

%- Calculate averaged value for PSF
col_par = handles.img.col_par;

if not(isempty(spots_fit_all))
    PSF.avg_OF.avg_sigmaxy = round(mean(spots_fit_all(:,col_par.sigmax)));
    PSF.avg_OF.avg_sigmaz  = round(mean(spots_fit_all(:,col_par.sigmaz)));
    PSF.avg_OF.avg_bgd     = round(mean(spots_fit_all(:,col_par.bgd)));
    PSF.avg_OF.avg_amp     = round(mean(spots_fit_all(:,col_par.amp)));

    PSF.avgED.avg_sigmaxy = PSF.avg_OF.avg_sigmaxy;
    PSF.avgED.avg_sigmaz  = PSF.avg_OF.avg_sigmaz;
    PSF.avgED.avg_bgd     = PSF.avg_OF.avg_bgd;
    PSF.avgED.avg_amp     = PSF.avg_OF.avg_amp;
else
    PSF.avg_OF.avg_sigmaxy = [];
    PSF.avg_OF.avg_sigmaz  = [];
    PSF.avg_OF.avg_bgd     = [];
    PSF.avg_OF.avg_amp     = [];

    PSF.avgED.avg_sigmaxy = [];
    PSF.avgED.avg_sigmaz  = [];
    PSF.avgED.avg_bgd     = [];
    PSF.avgED.avg_amp     = [];
end
    
set(handles.text_psf_fit_sigmaX,'String',num2str(PSF.avg_OF.avg_sigmaxy))
set(handles.text_psf_fit_sigmaZ,'String',num2str(PSF.avg_OF.avg_sigmaz))
set(handles.text_psf_bgd,'String',num2str(PSF.avg_OF.avg_bgd))
set(handles.text_psf_amp,'String',num2str(PSF.avg_OF.avg_amp))

controls_enable(hObject, eventdata, handles)


%- Save all results
handles.PSF = PSF;
handles.spots_fit_all      = spots_fit_all;
handles.spots_detected_all = spots_detected_all;
handles.spots_range        = spots_range;
handles.img.settings.thresh         = thresh_all;
guidata(hObject, handles); 


%== Analyze results of batch processing for further thresholding
function handles = results_analyse(hObject, eventdata, handles)

spots_fit_all      = handles.spots_fit_all;
spots_detected_all = handles.spots_detected_all;
thresh_all    = handles.img.settings.thresh;
col_par       = handles.img.col_par;

%- Set-up structure for thresholding
%thresh_all.sigmaxy.values   = spots_fit_all(:,col_par.sigmax);
thresh_all.sigmaxy.min      = min(spots_fit_all(:,col_par.sigmax));
thresh_all.sigmaxy.max      = max(spots_fit_all(:,col_par.sigmax));
thresh_all.sigmaxy.diff     = max(spots_fit_all(:,col_par.sigmax)) - min(spots_fit_all(:,col_par.sigmax));             
thresh_all.sigmaxy.in       = thresh_all.in;
if thresh_all.sigmaxy.lock == 0
    thresh_all.sigmaxy.min_th = min(spots_fit_all(:,col_par.sigmax));               
    thresh_all.sigmaxy.max_th = max(spots_fit_all(:,col_par.sigmax)); 
end

%thresh_all.sigmaz.values   = spots_fit_all(:,col_par.sigmaz );
thresh_all.sigmaz.min      = min(spots_fit_all(:,col_par.sigmaz ));
thresh_all.sigmaz.max      = max(spots_fit_all(:,col_par.sigmaz ));
thresh_all.sigmaz.diff     = max(spots_fit_all(:,col_par.sigmaz )) - min(spots_fit_all(:,col_par.sigmaz ));             
thresh_all.sigmaz.in       = thresh_all.in; 
if thresh_all.sigmaz.lock == 0
    thresh_all.sigmaz.min_th = min(spots_fit_all(:,col_par.sigmaz ));               
    thresh_all.sigmaz.max_th = max(spots_fit_all(:,col_par.sigmaz )); 
end

%thresh_all.amp.values   = spots_fit_all(:,col_par.amp);
thresh_all.amp.min      = min(spots_fit_all(:,col_par.amp));
thresh_all.amp.max      = max(spots_fit_all(:,col_par.amp));
thresh_all.amp.diff     = max(spots_fit_all(:,col_par.amp)) - min(spots_fit_all(:,col_par.amp));             
thresh_all.amp.in       = thresh_all.in;           
if thresh_all.amp.lock == 0
    thresh_all.amp.min_th = min(spots_fit_all(:,col_par.amp));               
    thresh_all.amp.max_th = max(spots_fit_all(:,col_par.amp)); 
end

%thresh_all.bgd.values = spots_fit_all(:,col_par.bgd );
thresh_all.bgd.min      = min(spots_fit_all(:,col_par.bgd ));
thresh_all.bgd.max      = max(spots_fit_all(:,col_par.bgd ));
thresh_all.bgd.diff     = max(spots_fit_all(:,col_par.bgd )) - min(spots_fit_all(:,col_par.bgd ));             
thresh_all.bgd.in       = thresh_all.in;            
if thresh_all.bgd.lock == 0
    thresh_all.bgd.min_th = min(spots_fit_all(:,col_par.bgd ));               
    thresh_all.bgd.max_th = max(spots_fit_all(:,col_par.bgd )); 
end

%thresh_all.pos_z.values = spots_fit_all(:,col_par.pos_z );
thresh_all.pos_z.min      = min(spots_fit_all(:,col_par.pos_z ));
thresh_all.pos_z.max      = max(spots_fit_all(:,col_par.pos_z ));
thresh_all.pos_z.diff     = max(spots_fit_all(:,col_par.pos_z )) - min(spots_fit_all(:,col_par.pos_z ));             
thresh_all.pos_z.in       = thresh_all.in;            
if thresh_all.pos_z.lock == 0
    thresh_all.pos_z.min_th = min(spots_fit_all(:,col_par.pos_z ));               
    thresh_all.pos_z.max_th = max(spots_fit_all(:,col_par.pos_z )); 
end

%thresh_all.int_raw.values   = spots_detected_all(:,col_par.int_raw );
thresh_all.int_raw.min      = min(spots_detected_all(:,col_par.int_raw ));
thresh_all.int_raw.max      = max(spots_detected_all(:,col_par.int_raw ));
thresh_all.int_raw.diff     = max(spots_detected_all(:,col_par.int_raw )) - min(spots_detected_all(:,col_par.int_raw ));             
thresh_all.int_raw.in       = thresh_all.in;            
if thresh_all.int_raw.lock == 0
    thresh_all.int_raw.min_th = min(spots_detected_all(:,col_par.int_raw ));               
    thresh_all.int_raw.max_th = max(spots_detected_all(:,col_par.int_raw )); 
end

%thresh_all.int_filt.values   = spots_detected_all(:,col_par.int_filt );
thresh_all.int_filt.min      = min(spots_detected_all(:,col_par.int_filt ));
thresh_all.int_filt.max      = max(spots_detected_all(:,col_par.int_filt ));
thresh_all.int_filt.diff     = max(spots_detected_all(:,col_par.int_filt )) - min(spots_detected_all(:,col_par.int_filt ));             
thresh_all.int_filt.in       = thresh_all.in;            
if thresh_all.int_filt.lock == 0
    thresh_all.int_filt.min_th = min(spots_detected_all(:,col_par.int_filt ));               
    thresh_all.int_filt.max_th = max(spots_detected_all(:,col_par.int_filt )); 
end

%- Save all results
handles.img.settings.thresh = thresh_all;


%== Restrict range
function button_fit_restrict_Callback(hObject, eventdata, handles)

parameters.summary_fit_all  = handles.spots_fit_all;
parameters.fit_limits       = handles.fit_limits; 
parameters.col_par          = handles.col_par;

[handles.fit_limits]  = FISH_QUANT_restrict_par(parameters);
guidata(hObject, handles);


%== Settings for filtering
function menu_sett_filter_Callback(hObject, eventdata, handles)

  
%- User-dialog
dlgTitle = 'SETTINGS to use existing filtered images ';
prompt_avg(1) = {'Part of file-name to replace (empty to add replacement string)'};
prompt_avg(2) = {'Replacement string'};

defaultValue_avg{1} = handles.name_filtered.string_search;
defaultValue_avg{2} = handles.name_filtered.string_replace;

options.Resize='on';

userValue = inputdlg(prompt_avg,dlgTitle,1,defaultValue_avg,options);

%- Return results if specified
if( ~ isempty(userValue))
    handles.name_filtered.string_search  = userValue{1};
    handles.name_filtered.string_replace = userValue{2};
    guidata(hObject, handles);
end
    
    

% =========================================================================
% Thresholding
% =========================================================================

%== When selecting a new thresholding parameter
function handles = pop_up_threshold_Callback(hObject, eventdata, handles)

%- Extracted fitted spots for this cell
spots_fit  = handles.spots_fit_all;

%- Executes only if there are results
if not(isempty(spots_fit))
    
    thresh_all     = handles.img.settings.thresh;
    
    str = get(handles.pop_up_threshold,'String');
    val = get(handles.pop_up_threshold,'Value');
    popup_parameter = str{val};

    
    switch (popup_parameter)
        
        case 'Sigma - XY'
            
            thresh_sel = thresh_all.sigmaxy;
            set(handles.checkbox_th_lock, 'Value',thresh_all.sigmaxy.lock);

        case 'Sigma - Z'
            thresh_sel = thresh_all.sigmaz;
            
            %- Check if selection was locked
            set(handles.checkbox_th_lock, 'Value',thresh_all.sigmaz.lock);

            
        case 'Amplitude'
            thresh_sel = thresh_all.amp;
            
            %- Check if selection was locked
            set(handles.checkbox_th_lock, 'Value',thresh_all.amp.lock); 
            
        case 'Background'
            thresh_sel = thresh_all.bgd;
            
            %- Check if selection was locked
            set(handles.checkbox_th_lock, 'Value',thresh_all.bgd.lock); 
            
        case 'Pos (Z)'
            thresh_sel = thresh_all.pos_z;
            
            %- Check if selection was locked
            set(handles.checkbox_th_lock, 'Value',thresh_all.pos_z.lock); 
            
        case 'Pixel-intensity (Raw)'
            thresh_sel = thresh_all.int_raw;
            
            %- Check if selection was locked
            set(handles.checkbox_th_lock, 'Value',thresh_all.int_raw.lock); 
            
        case 'Pixel-intensity (Filtered)'
            thresh_sel = thresh_all.int_filt;
            
            %- Check if selection was locked
            set(handles.checkbox_th_lock, 'Value',thresh_all.int_filt.lock); 
    end


    %== For slider functions calls and call of threshold function
    thresh_all.min  = thresh_sel.min;   
    thresh_all.max  = thresh_sel.max;
    thresh_all.diff = thresh_sel.diff; 
    
    %== Set sliders and text box according to selection    
    %-  Locked - based on saved values
    if thresh_sel.lock == 1; 
        set(handles.checkbox_th_lock, 'Value',1);  
        
        value_min = (thresh_sel.min_th-thresh_sel.min)/thresh_sel.diff;
        if value_min < 0; value_min = 0; end    % Might be necessary if slider was at the left end
        
        value_max = (thresh_sel.max_th-thresh_sel.min)/thresh_sel.diff;
        if value_max > 1; value_max = 1; end   % Might be necessary if slider was at the right end        
        
        %- Slider for lower limit and corresponding text box
        set(handles.slider_th_min,'Value',value_min)
        set(handles.text_th_min,'String', num2str(thresh_sel.min_th));     
     
        %- Slider for upper limit and corresponding text box
        set(handles.slider_th_max,'Value',value_max)
        set(handles.text_th_max,'String', num2str(thresh_sel.max_th));
    
    %- Not locked - not thresholding
    else    
                
        set(handles.checkbox_th_lock, 'Value',0);
        
        %- Slider for lower limit and corresponding text box
        set(handles.slider_th_min,'Value',0)
        set(handles.text_th_min,'String', num2str(thresh_sel.min));     
     
        %- Slider for upper limit and corresponding text box
        set(handles.slider_th_max,'Value',1)
        set(handles.text_th_max,'String', num2str(thresh_sel.max));
    end
    
    %- Save handles-structure
    handles.img.settings.thresh = thresh_all;
    handles = button_threshold_Callback(hObject, eventdata, handles);
    guidata(hObject, handles);  

end


%== Threshold parameters
function handles = button_threshold_Callback(hObject, eventdata, handles)

%- Extracted fitted spots for this cell
spots_fit      = handles.spots_fit_all;
spots_detected = handles.spots_detected_all;
spots_range   = handles.spots_range;
cell_summary  = handles.cell_summary;
col_par       = handles.img.col_par;
pixel_size    = handles.img.par_microscope.pixel_size;
PSF           = handles.PSF;

%- Execute only if there are results
if not(isempty(spots_fit))
    
    thresh_all     = handles.img.settings.thresh;
    
    %- Locked threshold?
    th_lock  = get(handles.checkbox_th_lock, 'Value');
    
    %- Selected thresholds
    min_th = floor(str2double(get(handles.text_th_min,'String')));        % floor and ceil necessary for extreme slider position to select all points.
    max_th = ceil(str2double(get(handles.text_th_max,'String')));      
    
    thresh_all.min_th =  min_th;    
    thresh_all.max_th =  max_th;
    
    %- Thresholding parameter
    str = get(handles.pop_up_threshold,'String');
    val = get(handles.pop_up_threshold,'Value');
    popup_parameter = str{val};     
    
    switch (popup_parameter)
        case 'Sigma - XY'
            thresh_all.sigmaxy.lock     = th_lock;
            thresh_all.sigmaxy.min_th = min_th;
            thresh_all.sigmaxy.max_th = max_th;   
            
            values_for_th          = spots_fit(:,col_par.sigmax);
            thresh_all.sigmaxy.in  = ((values_for_th >= min_th) & ...
                                      (values_for_th <= max_th)) | ...
                                       isnan(values_for_th);
             
            
            thresh_all.in_sel           = thresh_all.sigmaxy.in; 
            
        case 'Sigma - Z'           
            thresh_all.sigmaz.lock     = th_lock;
            thresh_all.sigmaz.min_th = min_th;
            thresh_all.sigmaz.max_th = max_th;              
                  
            values_for_th         = spots_fit(:,col_par.sigmaz);
            thresh_all.sigmaz.in  = ((values_for_th >= min_th) & ...
                                      (values_for_th <= max_th)) | ...
                                       isnan(values_for_th);            
            
            thresh_all.in_sel          = thresh_all.sigmaz.in; 
            
        case 'Amplitude'            
            thresh_all.amp.lock     = th_lock;
            thresh_all.amp.min_th = min_th;
            thresh_all.amp.max_th = max_th;  
                   
            values_for_th          = spots_fit(:,col_par.amp);
            thresh_all.amp.in  = ((values_for_th >= min_th) & ...
                                      (values_for_th <= max_th)) | ...
                                       isnan(values_for_th);            
            
            thresh_all.in_sel       = thresh_all.amp.in;    
            
        case 'Background'            
            thresh_all.bgd.lock     = th_lock;
            thresh_all.bgd.min_th = min_th;
            thresh_all.bgd.max_th = max_th;            
                       
            values_for_th          = spots_fit(:,col_par.bgd);
            thresh_all.bgd.in  = ((values_for_th >= min_th) & ...
                                      (values_for_th <= max_th)) | ...
                                       isnan(values_for_th);            
            
            thresh_all.in_sel       = thresh_all.bgd.in;
 
        case 'Pos (Z)'            
            thresh_all.pos_z.lock     = th_lock;
            thresh_all.pos_z.min_th = min_th;
            thresh_all.pos_z.max_th = max_th;  
            
            values_for_th          = spots_fit(:,col_par.pos_z);
            thresh_all.pos_z.in  = ((values_for_th >= min_th) & ...
                                      (values_for_th <= max_th)) | ...
                                       isnan(values_for_th);            
            
            thresh_all.in_sel         = thresh_all.pos_z.in;          
        
        case 'Pixel-intensity (Raw)'            
            thresh_all.int_raw.lock     = th_lock;
            thresh_all.int_raw.min_th = min_th;
            thresh_all.int_raw.max_th = max_th; 
            
            values_for_th      = spots_detected(:,col_par.int_raw);
            thresh_all.int_raw.in  = ((values_for_th >= min_th) & ...
                                      (values_for_th <= max_th)) | ...
                                       isnan(values_for_th);            
            
            thresh_all.in_sel       = thresh_all.int_raw.in;
 
        case 'Pixel-intensity (Filtered)'            
            thresh_all.int_filt.lock     = th_lock;
            thresh_all.int_filt.min_th = min_th;
            thresh_all.int_filt.max_th = max_th;  
            
            values_for_th      = spots_detected(:,col_par.int_filt);
            thresh_all.int_filt.in  = ((values_for_th >= min_th) & ...
                                      (values_for_th <= max_th)) | ...
                                       isnan(values_for_th);            
            
            thresh_all.in_sel         = thresh_all.int_filt.in;                   
    end

    
    %=== Apply threshold

    %- Thresholding under consideration of locked ones
    %  Can be written in boolean algebra: Implication Z = x?y = ?x?y = not(x) or y
    %  http://en.wikipedia.org/wiki/Boolean_algebra_%28logic%29#Basic_operations
    %  x = [0,1] ... unlocked [0] and locked [1]
    %  y = [0,1] ... index is thresholded [0] or not [1]
    %  Number is always considered (z=1) unless paramter is locked (x=1) and number is thresholded (y=0)
    %          y
    %       |0   1
    %     ----------
    %   x 0 |1   1
    %     1 |0   1

    %- Save old thresholding
    thresh_all.in_old         = thresh_all.in;
    thresh_all.logic_out_man  = (thresh_all.in == -1);

    %- New thresholding only with locked values
    thresh_all.logic_in  = (not(thresh_all.sigmaxy.lock)  | thresh_all.sigmaxy.in) & ...
                           (not(thresh_all.sigmaz.lock)   | thresh_all.sigmaz.in) & ...
                           (not(thresh_all.amp.lock)      | thresh_all.amp.in) & ...
                           (not(thresh_all.bgd.lock)      | thresh_all.bgd.in) & ...
                           (not(thresh_all.pos_z.lock)    | thresh_all.pos_z.in)& ...
                           (not(thresh_all.int_raw.lock)  | thresh_all.int_raw.in) & ...
                           (not(thresh_all.int_filt.lock) | thresh_all.int_filt.in) ;          


    %- Loop over all cells 
    status_text = {' ';'RESULTS OF SPOT DETECTION FOR EACH CELL';'COUNTS BEFORE/AFTER THRESHOLDING, [Name of image: name of cell]'};
    status_update(hObject, eventdata, handles,status_text);  

    spot_count = [];  %- For the histogram of total spots 

    status_update_cell = get(handles.checkbox_show_quant_results,'Value');

    for ind_cell = 1: length(spots_range)

        %== Exclude spots that are too close

        spots_detected_cell = cell_summary(ind_cell,1).spots_detected;
        spots_fit_cell      = cell_summary(ind_cell,1).spots_fit;   

        %- Mask with relative distance and matrix with radius
        if not(isempty(spots_fit_cell))

            data    = spots_fit_cell(:,1:3);
            N_spots = size(data,1);
            dum = [];
            dum(1,:,:) = data';
            data_3D_1  = repmat(dum,[N_spots 1 1]);
            data_3D_2  = repmat(data,[1 1 N_spots]);

            d_coord = data_3D_1-data_3D_2;

            r = sqrt(squeeze(d_coord(:,1,:).^2 + d_coord(:,2,:).^2 + d_coord(:,3,:).^2)); 

            %- Determine spots that are too close
            r_min = str2double(get(handles.text_min_dist_spots,'String'));

            mask_close          = zeros(size(r));
            mask_close(r<r_min) = 1;
            mask_close_inv      = not(mask_close);

            %- Mask with intensity ratios
            data_int     = spots_detected_cell(:,col_par.int_raw);
            mask_int_3D1 = repmat(data_int,1,N_spots);
            mask_int_3D2 = repmat(data_int',N_spots,1);

            mask_int_ratio = mask_int_3D2 ./ mask_int_3D1;


            %- Find close spots and remove the ones with the dimmest pixel
            m_diag = logical(diag(1*(1:N_spots)));

            mask_close_spots                 = mask_int_ratio;
            mask_close_spots(mask_close_inv) = 10;
            mask_close_spots(m_diag)         = 10;  %- Set diagonal to 10;

            %== Find ratios of spot that are < 1 
            [row,col] = find(mask_close_spots < 1);
            ind_spots_too_close1 = unique(col);

            %== Find ratios of spot that are == 1 
            [row,col] = find(mask_close_spots == 1);
            ind_spots_too_close2 = unique(col(2:end));

            ind_spots_too_close = union(ind_spots_too_close1,ind_spots_too_close2);

            %== Get thresholds for this cell
            logic_in_cell                        = thresh_all.logic_in(spots_range(ind_cell).start:spots_range(ind_cell).end);
            logic_out_man_cell                   = thresh_all.logic_out_man(spots_range(ind_cell).start:spots_range(ind_cell).end);
            logic_in_cell (ind_spots_too_close)  = 0;   % Spots that are too close 

            thresh_in_cell = [];
            thresh_in_cell(logic_in_cell == 1) = 1;
            thresh_in_cell(logic_in_cell == 0) = 0;
            thresh_in_cell(logic_out_man_cell) = -1;

            thresh_out_cell = (thresh_in_cell == 0) | (thresh_in_cell == -1);

            cell_summary(ind_cell,1).thresh.in  = [];
            cell_summary(ind_cell,1).thresh.in(:,1)  = thresh_in_cell;

            cell_summary(ind_cell,1).thresh.out = [];
            cell_summary(ind_cell,1).thresh.out(:,1) = thresh_out_cell;

            thresh_all.logic_in(spots_range(ind_cell).start:spots_range(ind_cell).end)  = thresh_in_cell;  
            thresh_all.in(spots_range(ind_cell).start:spots_range(ind_cell).end)        = thresh_in_cell;
            thresh_all.out(spots_range(ind_cell).start:spots_range(ind_cell).end)       = thresh_out_cell;

            %== Cells counts and things like that
            N_total = cell_summary(ind_cell,1).N_total;
            if isempty(N_total)
                N_total = 0;
            end
            N_count = sum(cell_summary(ind_cell,1).thresh.in);

            %== Get number of spots in nucleus 

            if not(isempty(cell_summary(ind_cell).pos_Nuc))
                x_Nuc = cell_summary(ind_cell).pos_Nuc.x*pixel_size.xy;
                y_Nuc = cell_summary(ind_cell).pos_Nuc.y*pixel_size.xy; 

                spots_in = data(logical(thresh_in_cell),:);

                spots_y = spots_in(:,1);
                spots_x = spots_in(:,2);


                %- Find spots which are in nucleus
                in_Nuc  = inpolygon(spots_x,spots_y,x_Nuc,y_Nuc); % Points defined in Positions inside the polygon
                N_nuc = sum(in_Nuc);

            else
                N_nuc = N_count;
            end

            %== Summary of spot counts
            spot_count(ind_cell,:) = [N_count N_total N_nuc];
            cell_summary(ind_cell,1).N_count = N_count;
            cell_summary(ind_cell,1).N_nuc = N_nuc;

            %- Update status
            if status_update_cell
                name_list = cell_summary(ind_cell,1).name_list;
                name_cell = cell_summary(ind_cell,1).label;

                status_text = [ num2str(N_total), ' / ', num2str(N_count),',  [', name_list ,': ', name_cell,']'];
                status_update(hObject, eventdata, handles,status_text);
            end
        else

            spot_count(ind_cell,:) = [0 0 0];
            cell_summary(ind_cell,1).N_count = 0; 
            cell_summary(ind_cell,1).N_nuc = 0; 

            %- Update status
            if status_update_cell
                name_list = cell_summary(ind_cell,1).name_list;
                name_cell = cell_summary(ind_cell,1).label;

                status_text = [ num2str(0), ' / ', num2str(0),',  [', name_list ,': ', name_cell,']'];
                status_update(hObject, eventdata, handles,status_text);
            end
        end
    end

    thresh_all.in_display = thresh_all.in_sel & thresh_all.logic_in;

    %- Analyse distribution of detected spots
    N_total_mean = round(nanmean(spot_count(:,2)));
    N_total_std  = round(nanstd(spot_count(:,2)));

    N_th_mean = round(nanmean(spot_count(:,1)));
    N_th_std  = round(nanstd(spot_count(:,1)));

    %- Update status
    status_text = {' '; ...
                   ['AVG # spots per cell [total] ', num2str(N_total_mean), ' +/- ', num2str(N_total_std)]; ...
                   ['AVG # spots per cell [after threshold] ', num2str(N_th_mean), ' +/- ', num2str(N_th_std)]};

    status_update(hObject, eventdata, handles,status_text);  

    % Spots which are in considering the current selection even if it is not locked
    thresh_all.in_display = thresh_all.in_sel  & thresh_all.logic_in; 
    col_par = handles.img.col_par;

    %- Update experimental PSF settings    
    PSF.avg_OF.avg_sigmaxy  = round(nanmean(spots_fit(thresh_all.in_display,col_par.sigmax)));
    PSF.avg_OF.avg_sigmaz   = round(nanmean(spots_fit(thresh_all.in_display,col_par.sigmaz)));
    PSF.avg_OF.avg_amp      = round(nanmean(spots_fit(thresh_all.in_display,col_par.amp )));
    PSF.avg_OF.avg_bgd      = round(nanmean(spots_fit(thresh_all.in_display,col_par.bgd)));

    PSF.avg_OF.avg_sigmaxy_std = round(nanstd(spots_fit(thresh_all.in_display,col_par.sigmax)));
    PSF.avg_OF.avg_sigmaz_std  = round(nanstd(spots_fit(thresh_all.in_display,col_par.sigmaz)));
    PSF.avg_OF.avg_amp_std     = round(nanstd(spots_fit(thresh_all.in_display,col_par.amp )));
    PSF.avg_OF.avg_bgd_std     = round(nanstd(spots_fit(thresh_all.in_display,col_par.bgd)));

    disp(' ')
    disp('FIT TO 3D GAUSSIAN: avg of ALL spots ')
    disp(['Sigma (xy): ', num2str(PSF.avg_OF.avg_sigmaxy), ' +/- ', num2str(PSF.avg_OF.avg_sigmaxy_std)])
    disp(['Sigma (z) : ', num2str(PSF.avg_OF.avg_sigmaz), ' +/- ', num2str(PSF.avg_OF.avg_sigmaz_std )])
    disp(['Amplitude : ', num2str(PSF.avg_OF.avg_amp), ' +/- ', num2str(PSF.avg_OF.avg_amp_std)])
    disp(['BGD       : ', num2str(PSF.avg_OF.avg_bgd), ' +/- ', num2str(PSF.avg_OF.avg_bgd_std )])
    disp(' ')

    set(handles.text_psf_fit_sigmaX,'String',num2str(PSF.avg_OF.avg_sigmaxy))
    set(handles.text_psf_fit_sigmaZ,'String',num2str(PSF.avg_OF.avg_sigmaz))
    set(handles.text_psf_bgd,'String',num2str(PSF.avg_OF.avg_bgd))
    set(handles.text_psf_amp,'String',num2str(PSF.avg_OF.avg_amp))

    %=== Save data
    handles.PSF = PSF;
    handles.img.settings.thresh   = thresh_all;
    handles.cell_summary = cell_summary;
    handles.spot_count   = spot_count;

    %=== VARIOUS PLOTS

    %- Plot histogram
    handles = plot_hist_all(handles,handles.axes_histogram_all,values_for_th);

    %- Plot thresholded histogram
    handles = plot_hist_th(handles,handles.axes_histogram_th,values_for_th);


    %=== Save data
    guidata(hObject, handles); 

    %=== Make spots available
    global spots_fit_th 
    spots_fit_th = [];
    spots_fit_th = spots_fit(thresh_all.in == 1,:);
    
    %=== Save data
    guidata(hObject, handles); 
end


%==== Button to unlock all thresholds
function button_th_unlock_all_Callback(hObject, eventdata, handles)

thresh_all     = handles.img.settings.thresh;

thresh_all.sigmaxy.lock = 0; 
thresh_all.sigmaz.lock  = 0;
thresh_all.amp.lock     = 0; 
thresh_all.bgd.lock     = 0;               
thresh_all.pos_z.lock   = 0;
thresh_all.int_raw.lock     = 0;               
thresh_all.int_filt.lock   = 0; 

handles.img.settings.thresh = thresh_all;

handles = pop_up_threshold_Callback(hObject, eventdata, handles);
handles = button_threshold_Callback(hObject, eventdata, handles);

guidata(hObject, handles);


%=== Check-box for locking parameters
function checkbox_th_lock_Callback(hObject, eventdata, handles) 
handles = button_threshold_Callback(hObject, eventdata, handles);


%=== Slider for minimum values of threshold
function slider_th_min_Callback(hObject, eventdata, handles)

sliderValue = get(handles.slider_th_min,'Value');
thresh_all  = handles.img.settings.thresh;

%- Determine value at current slider position
value_thresh = sliderValue*thresh_all.diff+thresh_all.min;

%- Change text box and line in histogram
set(handles.text_th_min,'String', value_thresh);

axes(handles.axes_histogram_all);
if isfield(handles,'h_hist_min')
    if ishandle(handles.h_hist_min)
        delete(handles.h_hist_min);
    end
end

v = axis;
hold on, 
handles.h_hist_min = plot([value_thresh value_thresh] , [0 1e5],'r');
hold off
axis(v);

axes(handles.axes_histogram_th);
if isfield(handles,'h_hist_th_min')
    if ishandle(handles.h_hist_th_min)
        delete(handles.h_hist_th_min);
    end
end
v = axis;
hold on, 
handles.h_hist_th_min = plot([value_thresh value_thresh] , [0 1e5],'r');
hold off
axis(v);

guidata(hObject, handles);      % Update handles structure


%== Slider for maximum values of threshold
function slider_th_max_Callback(hObject, eventdata, handles)

sliderValue = get(handles.slider_th_max,'Value');
thresh_all     = handles.img.settings.thresh;

%- Determine value at current slider position
value_thresh = sliderValue*thresh_all.diff+thresh_all.min;

%- Change text box and line in histogram
set(handles.text_th_max,'String', value_thresh);

axes(handles.axes_histogram_all);
if isfield(handles,'h_hist_max')
    if ishandle(handles.h_hist_max)
        delete(handles.h_hist_max);
    end
end
v = axis;
hold on
handles.h_hist_max = plot([value_thresh value_thresh] , [0 1e5],'g');
hold off
axis(v);

axes(handles.axes_histogram_th);
if isfield(handles,'h_hist_th_max')
    if ishandle(handles.h_hist_th_max)
        delete(handles.h_hist_th_max);
    end
end
v = axis;
hold on
handles.h_hist_th_max = plot([value_thresh value_thresh] , [0 1e5],'g');
hold off
axis(v);

guidata(hObject, handles);      % Update handles structure


%=== Edit values of slider selection: minimum 
function text_th_min_Callback(hObject, eventdata, handles)
value_edit = str2double(get(handles.text_th_min,'String'));
thresh_all = handles.img.settings.thresh;

%- Set new slider value only if value is within range
if value_edit > thresh_all.min  && value_edit < thresh_all.max
    slider_new = (value_edit-thresh_all.min)/thresh_all.diff;
    set(handles.slider_th_min,'Value',slider_new);   
    slider_th_min_Callback(hObject, eventdata, handles)
else
    set(handles.text_th_min,'String',num2str(value_edit))    
end


%=== Edit values of slider selection: maximum 
function text_th_max_Callback(hObject, eventdata, handles)
value_edit = str2double(get(handles.text_th_max,'String'));
thresh_all = handles.img.settings.thresh;

%- Set new slider value only if value is within range    
if value_edit > thresh_all.min && value_edit < thresh_all.max
    slider_new = (value_edit-thresh_all.min)/thresh_all.diff;
    set(handles.slider_th_max,'Value',slider_new);
    slider_th_max_Callback(hObject, eventdata, handles)
else
    set(handles.text_th_max,'String',num2str(value_edit)) 
end


% =========================================================================
% Show detected spots
% =========================================================================

%== Show detected spots
function button_show_detected_spots_Callback(hObject, eventdata, handles)

str_list = get(handles.listbox_files,'String');

if not(isempty(str_list))
           
    cell_summary = handles.cell_summary;
    
    %- Extract index of highlighted cell
    i_file  = get(handles.listbox_files,'Value');

    if handles.file_summary(i_file).status_file_ok
    
        %- Get start and end index of all cells
        i_start = handles.file_summary(i_file).cells.start;
        i_end   = handles.file_summary(i_file).cells.end;

        cell_prop = {};
        
        spots_fit_all = [];
        for i_abs = i_start:i_end

            i_rel = i_abs-i_start +1;  

            cell_prop(i_rel).spots_fit = cell_summary(i_abs,1).spots_fit; 
            cell_prop(i_rel).spots_detected = cell_summary(i_abs,1).spots_detected; 
            cell_prop(i_rel).thresh.in = cell_summary(i_abs,1).thresh.in;
            cell_prop(i_rel).x         = cell_summary(i_abs,1).x; 
            cell_prop(i_rel).y         = cell_summary(i_abs,1).y;
            cell_prop(i_rel).pos_TS    = cell_summary(i_abs,1).pos_TS;
            cell_prop(i_rel).pos_Nuc   = cell_summary(i_abs,1).pos_Nuc;
            cell_prop(i_rel).label     = cell_summary(i_abs,1).label; 
            cell_prop(i_rel).FIT_Result = [];
            
            spots_fit_all = [spots_fit_all; cell_prop(i_rel).spots_fit cell_prop(i_rel).thresh.in];

        end
        
        if isempty(cell_prop)
            status_text = {' ';'NO CELLS IN IMAGE'};
            status_update(hObject, eventdata, handles,status_text); 
        else
        
            ind_th_in    = spots_fit_all(:,end) == 1;
            spots_fit_th = spots_fit_all(ind_th_in,:);

            %- Assign parameters
            handles_temp.img            = handles.img;            
            handles_temp.img.file_names = handles.file_summary(i_file).file_names; 
            handles_temp.img.cell_prop  = cell_prop;
            
            %- Make sure that path to image is attributed & load image
            if isempty(handles.img.path_names.img)
               path_name_image = handles.img.path_names.root;
            else
                path_name_image = handles.img.path_names.img;
            end
            
            file_name_full = fullfile(path_name_image, handles_temp.img.file_names.raw);
            status_file = handles_temp.img.load_img(file_name_full,'raw');
           
            %- Continue if ok
            if status_file

                %- Load image, make MIP along Z
                handles.img.project_Z('raw','max');
            else
                return
            end
            
            
            %- Open filtered image
            if ~isempty(handles_temp.img.file_names.filtered)
             
                file_name_full_filtered  = fullfile(path_name_image,handles_temp.img.file_names.filtered);
            
                if ~strcmp(file_name_full,file_name_full_filtered)
                    
                    %- Load filtered image
                    status_file = handles_temp.img.load_img(file_name_full_filtered,'filt');

                    if status_file

                        %- Assigng image
                        handles.img.project_Z('filt','max');
                    end     
                end
            end
            
            
%             handles_temp.col_par             = handles.img.col_par;
%             handles_temp.cell_prop           = cell_prop;
%             handles_temp.par_microscope      = handles.par_microscope;
%            
%             handles_temp.detect              = handles.detect;
%             
%             handles_temp.path_name_root     = handles.img.path_names.root;
            
%             %- Make sure that path to image is attributed
%             if isempty(handles.img.path_names.img)
%                 handles_temp.path_name_image = handles.img.path_names.root;
%             else
%                 handles_temp.path_name_image = handles.img.path_names.img;
%             end
%             
%             handles_temp.path_name_outline  = handles.img.path_names.outlines;
%             handles_temp.path_name_results  = handles.img.path_names.results;
%             handles_temp.FQ_which = 'batch'; 
            
%             %- Open image
%             file_name_full                          = fullfile(handles_temp.path_name_image,handles_temp.file_names.raw);
%             handles_temp.image_struct               = load_stack_data_v7(file_name_full);
% 
%             %- Open filtered image
%             if isempty(handles_temp.file_names.filtered)
%                 handles_temp.image_struct.data_filtered = handles_temp.image_struct.data;
%             
%             else
%                 file_name_full_filtered                          = fullfile(handles_temp.path_name_image,handles_temp.file_names.filtered);
%             
%                 if strcmp(file_name_full,file_name_full_filtered)
%                     handles_temp.image_struct.data_filtered = handles_temp.image_struct.data;
%                 else
%                     image_struct               = load_stack_data_v7(file_name_full_filtered);
%                     handles_temp.image_struct.data_filtered = image_struct.data;
%                 end
%             end
            
            %== Select visualization open
            vis_sel_str = get(handles.popup_vis_sel,'String');
            vis_sel_val = get(handles.popup_vis_sel,'Value');

            switch vis_sel_str{vis_sel_val}

                case 'Spot inspector'
                   
                   
                   FISH_QUANT_spots('HandlesMainGui',handles_temp);

                case 'ImageJ'        

                    MIJ_start(hObject, eventdata, handles)
                    
                    
                    %- Get path of image
                    if not(isempty(handles.img.path_names.img))
                       path_image = handles.img.path_names.img;
                    elseif not(isempty(handles.img.path_names.root))
                       path_image = handles.img.path_names.root; 
                    end

                    % Generate temporary result file
                    file_name_temp                      = fullfile(path_image,'FQ_results_tmp.txt');
                    parameters.cell_prop                = handles_temp.cell_prop;
                    parameters.par_microscope           = handles_temp.par_microscope;
                    parameters.path_name_image          = path_image;
                    parameters.file_name_image          = handles_temp.file_name_image;
                    parameters.file_name_image_filtered = handles_temp.file_name_image_filtered;
                    parameters.file_name_settings       = handles_temp.file_name_settings;
                    parameters.version                  = handles.version;
                    parameters.path_save                = path_image;
                    
                    FQ_save_results_v1(file_name_temp,parameters);                

                    %- Call macro
                    ij.IJ.runMacroFile(handles.imagej_macro_name,file_name_temp);                   

                 case '3D rendering'

                     if exist('vtkinit')

                         %- Get settings for rendering
                         settings_rendering = handles.settings_rendering;
                         factor_BGD = settings_rendering.factor_BGD;
                         factor_int = settings_rendering.factor_int;
                         flag_crop  = settings_rendering.flag_crop;

                         %- Get image data
                         volume1 = handles_temp.image_struct.data;
                         dim_Z   = size(volume1,3);

                         %- Get spot data
                         pos_plot = [];
                         pos_plot(:,1)  = spots_fit_th(:,1) ./ handles.par_microscope.pixel_size.xy;
                         pos_plot(:,2)  = spots_fit_th(:,2) ./ handles.par_microscope.pixel_size.xy;
                         pos_plot(:,3)  = spots_fit_th(:,3) ./ handles.par_microscope.pixel_size.z;

                         pos_plot_round = round(pos_plot)+1;
                         pos_linear = sub2ind(size(volume1), pos_plot_round(:,1),pos_plot_round(:,2),pos_plot_round(:,3));

                         %- Restrict to subvolume
                         if flag_crop
                             z_min = floor(min(pos_plot(:,3))) - handles.detect.region.z;
                             z_max = ceil(max(pos_plot(:,3)))  + handles.detect.region.z;

                             if z_min < 1
                                 z_min = 1;
                             end

                             if z_max > dim_Z
                                 z_max = dim_Z;
                             end

                             volume_sub        = volume1(:,:,z_min:z_max);
                             pos_plot_sub      = pos_plot;
                             pos_plot_sub(:,3) = pos_plot(:,3) - z_min+1;
                         else
                             volume_sub        = volume1;
                             pos_plot_sub      = pos_plot;
                         end

                         %- Missing parameters to plot spots
                         point_labels = ones(size(pos_plot,1),1);
                         point_color  = [0 0 0 0;  % black for value 0
                                         1 1 0 0];  % red for value 1
                         point_config.pointSize = 1.0;

                         %- Define default range for colormap and op
                         median_bgd = median(spots_fit_th(:,handles.col_par.bgd));
                         median_int = median(volume1(pos_linear))-median_bgd;

                         int_start = round(0);
                         int_end   = factor_int*median_int;
                         int_range = linspace(int_start,int_end,10)';

                         opp_range = linspace(0,settings_rendering.opacity,10)';
                         opacityLUT = [int_range,opp_range];

                         map_int  = colormap(gray(10));
                         colorMap = [int_range,map_int];


                         %- New instance of VTK
                         vtkinit;

                         %- Plot points
                         pos_plot_sub(:,3) = pos_plot_sub(:,3)*handles.par_microscope.pixel_size.z/handles.par_microscope.pixel_size.xy;
                         vtkplotpoints(pos_plot_sub,point_labels,point_color,point_config);

                         
                         %- Show a grid
                         grid_config.gridFly = 'staticTriad';
                         grid_config.gridZAxisVisibility = 1;
                         vtkgrid(grid_config);
                         
                         %- Plot volume
                         volume_config.volumeSpacing = [1 1 handles.par_microscope.pixel_size.z/handles.par_microscope.pixel_size.xy];
                         vtkplotvolume(volume_sub-factor_BGD*median_bgd, colorMap,opacityLUT,volume_config); 
                         

                     else
                         warndlg('vtkmat has to be installed first (see help file)','FISH-QUANT')
                     end
            end       
        end
        
    else
        status_text = {' ';'NO VALID OUTLINE FILE.'};
        status_update(hObject, eventdata, handles,status_text);         
    end
end


%== Settings for rendering
function menu_settings_rendering_Callback(hObject, eventdata, handles)
handles.settings_rendering = FQ_change_setting_VTK_v1(handles.settings_rendering);
status_update(hObject, eventdata, handles,{'  ';'## Settings for RENDERING are modified'});         
guidata(hObject, handles);



% =========================================================================
% MISC functions
% =========================================================================


%== Advanced settings
function menu_adv_settings_Callback(hObject, eventdata, handles)


%== Same outline for all images: load outline
function menu_load_outline_enable_Callback(hObject, eventdata, handles)
outline_unique = handles.status_outline_unique_enable;

if outline_unique
    default_answer = 'NO';
else
    default_answer = 'YES';
end

choice = questdlg('Use same outline for each image?', 'Outline definition', 'YES','NO',default_answer);


switch choice
    case 'YES'
        handles.status_outline_unique_enable = 1;
        set(handles.menu_load_outline_enable ,'Check','on') 
    case 'NO'
        handles.status_outline_unique_enable = 0;
        set(handles.menu_load_outline_enable ,'Check','off') 
end
guidata(hObject, handles);


%== Same outline for all images: load outline
function menu_load_outline_same_Callback(hObject, eventdata, handles)
[file_name_outline,path_name] = uigetfile({'*.txt'},'Select file with outline definition','MultiSelect', 'off');

if file_name_outline ~= 0 
      
    %- Load results
    handles.cell_prop_loaded  = FQ_load_results_WRAPPER_v1(fullfile(path_name,file_name_outline));
    
    %- Save and update status
    handles.status_outline_unique_loaded = 1;
    handles.status_outline_unique_enable = 1;
    set(handles.menu_load_outline_enable ,'Check','on') 
    guidata(hObject, handles);
    controls_enable(hObject, eventdata, handles)
end



% =========================================================================
% Save and load results
% =========================================================================


%== Settings for save
function menu_settings_save_Callback(hObject, eventdata, handles)
handles.settings_save = FQ_change_setting_save_v2(handles.settings_save);
status_update(hObject, eventdata, handles,{'  ';'## Settings for SAVING are modified'});         
guidata(hObject, handles);


%== Save settings from menu
function handles = menu_save_settings_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with outlines
current_dir = cd;

if  not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- User-dialog
dlgTitle      = 'File with detection settings';
default_name  = handles.file_name_settings_save;
name_settings = uiputfile(default_name,dlgTitle);

%- Save results
if( name_settings ~= 0)        
    
    handles.img.settings.thresh                = handles.img.settings.thresh;
    handles.img.settings.thresh.Spots_min_dist = get(handles.text_min_dist_spots,'String');
    [file_save, path_save]                     = handles.img.save_settings(fullfile(path_save,name_settings));
    
    handles.file_name_settings_new  = file_save;
    handles.file_name_settings_save = file_save;
    guidata(hObject, handles);   
end

%- Go back to 
cd(current_dir)
  
   
%== Check if settings file already saved
function handles = save_settings(hObject, eventdata, handles)
if not(isfield(handles,'file_name_settings_new'))
    handles = menu_save_settings_Callback(hObject, eventdata, handles);
    guidata(hObject, handles); 
else
    if isempty(handles.file_name_settings_new)
        handles = menu_save_settings_Callback(hObject, eventdata, handles);
        guidata(hObject, handles); 
    end
end
      
   
%== Save summary of parameters of all detected spots
function menu_save_Callback(hObject, eventdata, handles)


%== Function to save results of all spots
function save_summary_spots(hObject, eventdata, handles,flag_threshold)

%- Get current directory and go to directory with outlines
current_dir = cd;

if  not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)


%- Save settings
handles = save_settings(hObject, eventdata, handles);

%- User-dialog for file-name
dlgTitle      = 'File with all spots';
default_name  = ['_FISH-QUANT__all_spots_', datestr(date,'yymmdd'), '.txt'];;
[name_default path_default] = uiputfile(default_name,dlgTitle);


%- Save results
if name_default ~= 0
    
    %- Get name to save data
    file_name_full = fullfile(path_default,name_default);    
       
    %- Dialog to determine how rows should be labeled
    choice = questdlg('How should rows describing each spot be labeled?', 'Save summary file', ...
                       'None','Name of file & cell','File identifier','None');
    if not(strcmp(choice,''))
                   
        switch choice
            case 'Name of file & cell'
                options.flag_label = 1;
            case 'File identifier'
                options.flag_label = 2;
            case 'None'
                options.flag_label = 3;   
        end
    
        %- Save results       
        options.file_id_start         = handles.settings_save.file_id_start;
        options.file_id_end           = handles.settings_save.file_id_end;
        
        options.flag_only_thresholded = flag_threshold; 
        FISH_QUANT_save_results_all_v7(file_name_full,handles.file_summary,handles.cell_summary,handles.par_microscope,handles.img.path_names.img,handles.file_name_settings_new,handles.version,options);
    end
end

%- Go back to original folder
cd(current_dir)


%== Save summary of all spots in one file [all spots]
function menu_save_summary_spots_Callback(hObject, eventdata, handles)
save_summary_spots(hObject, eventdata, handles,0);


%== Save summary of all spots in one file [thresholded spots]
function menu_save_summary_thresolded_spots_Callback(hObject, eventdata, handles)
save_summary_spots(hObject, eventdata, handles,1);


%== Save results for each image
function save_results_image(hObject, eventdata, handles,flag_threshold)

%- Get current directory and go to directory with outlines
current_dir = cd;

if  not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- Save settings
handles        = save_settings(hObject, eventdata, handles);
suffix_results = handles.file_name_suffix_spots; 

%- User-dialog
dlgTitle  = 'Names for result files';
prompt(1) = {'Suffix for result files'};
defaultValue{1} = suffix_results;

options.Resize='on';

userValue = inputdlg(prompt,dlgTitle,1,defaultValue,options);

%- Save results of individual images
if( ~ isempty(userValue))
    suffix_results  = userValue{1};
    cell_summary    = handles.cell_summary;
    file_summary    = handles.file_summary;

    for i_file = 1:length(file_summary)

        if file_summary(i_file).status_file_ok
            
            par_microscope      = handles.par_microscope;
            file_names          = file_summary(i_file).file_names;
            file_name_list      = file_summary(i_file).file_name_list;
            file_names.settings = handles.file_name_settings_new;
            
            i_start = file_summary(i_file).cells.start;
            i_end = file_summary(i_file).cells.end;

            cell_prop = {};
            for i_abs = i_start:i_end

                i_rel = i_abs-i_start +1;  

                %- Save only thresholded spots
                spots_fit      = cell_summary(i_abs,1).spots_fit;
                spots_detected = cell_summary(i_abs,1).spots_detected;
                thresh.in      = cell_summary(i_abs,1).thresh.in;
                ind_save       = (thresh.in == 1);            
                
                %- Thresholding or not
                if flag_threshold
                    cell_prop(i_rel).spots_fit      = spots_fit(ind_save,:); 
                    cell_prop(i_rel).spots_detected = spots_detected(ind_save,:); 
                    cell_prop(i_rel).thresh.in      = thresh.in(ind_save);
                else
                    cell_prop(i_rel).spots_fit      = spots_fit; 
                    cell_prop(i_rel).spots_detected = spots_detected; 
                    cell_prop(i_rel).thresh.in      = thresh.in;
                end

                %- Other properties of the cell
                cell_prop(i_rel).x         = cell_summary(i_abs,1).x; 
                cell_prop(i_rel).y         = cell_summary(i_abs,1).y;
                cell_prop(i_rel).pos_TS    = cell_summary(i_abs,1).pos_TS;
                cell_prop(i_rel).pos_Nuc   = cell_summary(i_abs,1).pos_Nuc;
                cell_prop(i_rel).label     = cell_summary(i_abs,1).label; 

            end

            %- Save results - generate file-name
            [dum, name_file] = fileparts(file_name_list); 

            file_name_save   = [name_file,suffix_results];
            file_name_full   = fullfile(path_save,file_name_save);    

            
            %- General parameters
            parameters.par_microscope      = par_microscope;
            parameters.path_save           = path_save;
            parameters.path_name_image     = handles.img.path_names.img;
            parameters.file_names          = file_names;
            parameters.version             = handles.img.version;
            parameters.flag_type           = 'spots';  
            parameters.flag_th_only        = flag_threshold;
            
            %- Assign relevant parameters to img structure
            handles.img.cell_prop  = cell_prop;
            handles.img.file_names = file_names;
            handles.img.save_results(file_name_full,parameters);
               
        end
     end
end

%- Go back to original folder
cd(current_dir)


%== Save results for each image [all spots]
function menu_save_results_image_Callback(hObject, eventdata, handles)
save_results_image(hObject, eventdata, handles,0)


%== Save results for each image [thresholded spots]
function menu_save_results_image_only_th_Callback(hObject, eventdata, handles)
save_results_image(hObject, eventdata, handles,1)


%== Save results of TS quantification
function menu_save_nascent_Callback(hObject, eventdata, handles)

if isfield(handles,'TS_summary')
    
    %== Get current directory and go to directory with results
    current_dir = cd;

    if  not(isempty(handles.img.path_names.results)); 
        path_save = handles.img.path_names.results;
    elseif not(isempty(handles.img.path_names.root)); 
        path_save = handles.img.path_names.root;
    else
        path_save = cd;
    end

    cd(path_save)
    
    %== Parameters
    handles = save_settings_nascent(handles);
    guidata(hObject, handles);
    
    %== Parameters
    parameters.path_save          = path_save;
    parameters.file_name_settings = handles.file_name_settings_TS;
    parameters.file_name_default  = handles.file_name_summary_TS;
    parameters.version            = handles.img.version;
    parameters.mRNA_prop          = handles.img.mRNA_prop;
        
    FQ_TS_save_summary_v1([],handles.TS_summary,parameters)
    
    %== Get back to original directory
    cd(current_dir)

end


%== Save results of counting mature mRNA
function menu_save_mature_Callback(hObject, eventdata, handles)

%== Get current directory and go to directory with results
current_dir = cd;

if  not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- Save settings
handles = save_settings(hObject, eventdata, handles);

%- User-dialog
dlgTitle = 'File with counts of mature mRNA';
default_name  = handles.file_name_summary;
[name_summary path_name] = uiputfile(default_name,dlgTitle);

%- Save results
if name_summary ~= 0
    file_name_full                = fullfile(path_name,name_summary);
    parameters.cell_summary       = handles.cell_summary;
    parameters.path_save          = path_save;
    parameters.file_name_settings = handles.file_name_settings_new;
    parameters.version            = handles.version;
    
    FISH_QUANT_batch_save_summary_v6(file_name_full,parameters)
end

%== Get back to original directory
cd(current_dir)  


%== Save results of nascent and mature quantification
function menu_save_nascent_mature_Callback(hObject, eventdata, handles)
%== Get current directory and go to directory with results
current_dir = cd;

if  not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- User-dialog
dlgTitle                 = 'File with counts of mature and nascent mRNA';
default_name             = handles.file_name_summary_ALL;
[name_summary path_name] = uiputfile(default_name,dlgTitle);

%- Save results
if name_summary ~= 0
    file_name_full                = fullfile(path_name,name_summary);
    parameters.cell_summary       = handles.cell_summary;
    parameters.TS_summary         = handles.TS_summary;
    parameters.path_save          = path_save;
    parameters.file_name_settings = handles.file_name_settings_new;
    parameters.version            = handles.version;
    
    FQ_batch_save_summary_all_v5(file_name_full,parameters)
end


%== Get back to original directory
cd(current_dir)  


%== Save GUI handles structure
function menu_save_handles_Callback(hObject, eventdata, handles)
FQ_batch_save_handles_v3([],handles)


%== LOAD GUI handles structure
function menu_load_handles_Callback(hObject, eventdata, handles)


handles = FQ_batch_load_handles_v7(handles);

%- Only if handles are not empty
if not(isempty(handles))

    %-Assign some of the parameters
    set(handles.listbox_files,'String',handles.str_list);

    set(handles.checkbox_use_filtered,'Value',handles.checkbox_filtered);
    set(handles.checkbox_parallel_computing,'Value',handles.checkbox_parallel);    
    set(handles.checkbox_save_filtered,'Value',handles.checkbox_filtered_save);
    set(handles.status_save_results_TxSite_quant,'Value', handles.checkbox_save_TS_results);    
    set(handles.status_save_figures_TxSite_quant,'Value',handles.checkbox_save_TS_figure ); 
%    set(handles.checkbox_flag_GaussMix,'Value',handles.saved_checkbox_flag_GaussMix  ); 
    
    set(handles.text_th_auto_detect,'String', handles.string_TS_th_auto  );    
    
    %- Update auto-save buttons 
    set(handles.checkbox_auto_save,'Value',handles.val_auto_save_TS); 
    set(handles.checkbox_auto_save_mature,'Value',handles.val_auto_save_mature);

    %- Enable controls
    controls_enable(hObject, eventdata, handles)
    
    %- Activate parallel computing if specified
    if handles.checkbox_parallel
        checkbox_parallel_computing_Callback(hObject, eventdata, handles)
    end
    
    %- Show messages to indicate what should be done
    if handles.i_file_proc_mature > 1 && handles.status_fit == 0
         msgbox('Appears that mature mRNA detection did not finish. Press PROCESS in panel 3 to continue','Load FDQ analysis results','help') 
    end
   
    if handles.i_file_proc > 1
         msgbox('Appears that nascent mRNA quantification did not finish. Press Quantify TxSite in panel 5 to continue','Load FDQ analysis results','help') 
    end
    
    %- In case mature data is loaded - perform thresholding
    if handles.status_fit == 1
        handles = pop_up_threshold_Callback(hObject, eventdata, handles);
    end
    
    %- Save data
    guidata(hObject, handles);
end




% =========================================================================
% Average spots
% =========================================================================

% === SETTINGS of spot averaging --------------------------------------------------------------------
function menu_settings_avg_Callback(hObject, eventdata, handles)
status_change = handles.img.define_par_avg;

% If settings changed for the first time
if status_change && ~handles.status_avg_settings
    
    handles.status_avg_settings = 1;
    
    %- Save handles, enable controls
    guidata(hObject, handles);
    controls_enable(hObject, eventdata, handles)
end


%== Average all spots
function menu_avg_calc_Callback(hObject, eventdata, handles)

%- Update status
status_text = {' ';'=== Averaging spots: see command window for details'};
status_update(hObject, eventdata, handles,status_text);

%- Average spots from one cell
[spot_avg, spot_avg_os, pixel_size_os  ] = FQ_batch_avg_v1(handles);

handles.img.par_microscope.pixel_size_os = pixel_size_os;
handles.img.spot_avg                     = spot_avg;
handles.img.spot_avg_os                  = spot_avg_os;
handles.status_avg_calc                  = 1;  % Average calculated
handles.img.avg_spots_plot;

%- Save handles, enable controls
guidata(hObject, handles);
controls_enable(hObject, eventdata, handles)

%== Fit averaged spot
function menu_avg_fit_Callback(hObject, eventdata, handles)

%- Parameters needed for function call
flag_crop      = 1;
flag_output    = 2;
img_PSF.data   = handles.img.spot_avg_os;
pixel_size_os  = handles.img.par_microscope.pixel_size_os;
par_microscope = handles.img.par_microscope;

%- Crop region for fit
size_detect = handles.img.settings.detect.reg_size ;
fact_os     = handles.img.settings.avg_spots.fact_os; 

par_crop_fit.xy = size_detect.xy * fact_os.xy;
par_crop_fit.z  = size_detect.z  * fact_os.z;

%- Fit with 3D Gaussian
parameters.pixel_size     = pixel_size_os;
parameters.par_microscope = par_microscope;
parameters.flags.crop     = flag_crop;
parameters.flags.output   = flag_output;
parameters.par_crop       = par_crop_fit;

PSF_3D_Gauss_fit_v8(img_PSF,parameters);
    

%== Show averaged spot with normal sampling in ImageJ
function menu_imagej_ns_Callback(hObject, eventdata, handles)
MIJ_start(hObject, eventdata, handles)
MIJ.createImage('Matlab: PSF with normal sampling', uint32(handles.img.spot_avg),1); 


%== Show averaged spot with over-sampling in ImageJ
function menu_imagej_os_Callback(hObject, eventdata, handles)
MIJ_start(hObject, eventdata, handles)
MIJ.createImage('Matlab: PSF with normal sampling', uint32(handles.img.spot_avg_os),1); 


%== Save averaged spot with normal-sampling
function menu_avg_save_ns_Callback(hObject, eventdata, handles)
%- Get current directory and go to directory with images
current_dir = pwd;

if    not(isempty(handles.img.path_names.results))
   cd(handles.img.path_names.results)
elseif not(isempty(handles.path_name_root))
   cd(handles.img.path_names.root) 
end

%- Save image
handles.img.save_img('','avg_ns')

%- Go back to original directory
cd(current_dir)


%== Save averaged spot with over-sampling
function menu_avg_save_os_Callback(hObject, eventdata, handles)
%- Get current directory and go to directory with images
current_dir = pwd;

if    not(isempty(handles.img.path_names.results))
   cd(handles.img.path_names.results)
elseif not(isempty(handles.path_name_root))
   cd(handles.img.path_names.root) 
end

%- Save image
handles.img.save_img('','avg_os')

%- Go back to original directory
cd(current_dir)


%= Function to start MIJ
function MIJ_start(hObject, eventdata, handles)
if isfield(handles,'flag_MIJ')
    if handles.flag_MIJ == 0
       Miji;
       handles.flag_MIJ = 1;
    end
else
    Miji;
    handles.flag_MIJ = 1;
end
guidata(hObject, handles);



% =========================================================================
% TxSite detection
% =========================================================================


%== Load settings for TS detection
function button_load_settings_TS_detect_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with results/settings
current_dir = cd;

if    not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif  not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- Get settings
[file_name_settings,path_name_settings] = uigetfile({'*.txt'},'Select file with settings');

if file_name_settings ~= 0
    [handles.settings_TS_detect, file_ok] = FQ_TS_detect_settings_load_v2(fullfile(path_name_settings,file_name_settings),[]);
    
    
    if file_ok
    
        if isfield(handles.settings_TS_detect,'int_th')
            set(handles.text_th_auto_detect,'String',num2str(handles.settings_TS_detect.int_th));
            handles.status_settings_TS_detect = 1;
        else
            handles.status_settings_TS_detect = 0;
        end

        %- Older version might not have this parameter
        if not(isfield(handles.settings_TS_detect,'dist_max_offset_FISH_min_int'))
            handles.settings_TS_detect.dist_max_offset_FISH_min_int = 0;
        end


        guidata(hObject, handles)

        controls_enable(hObject, eventdata, handles)
    end
end


%== Detect transcription sites
function button_TS_detect_Callback(hObject, eventdata, handles)

%===== GENERAL PREPARATION 
current_dir = pwd;

%--- Path for saving outlines
if not(isempty(handles.img.path_names.outlines))
    path_save_outline  = handles.img.path_names.outlines;
elseif not(isempty(handles.img.path_names.img))
    path_save_outline  = handles.img.path_names.img;
elseif not(isempty(handles.img.path_names.root))
    path_save_outline  = handles.img.path_names.root;
else
    path_save_outline  = handles.path_name_list;
end



%- Create folder to save outlines
path_save = fullfile(path_save_outline,'_TS_detect');
if ~exist(path_save,'dir'); 
   mkdir(path_save)
end



%-- General parameters
par_microscope   = handles.par_microscope;
 
%-- Get detection parameters
parameters_auto_detect = handles.settings_TS_detect;
parameters_auto_detect.int_th = str2double(get(handles.text_th_auto_detect, 'String'));
parameters_auto_detect.flags.output       = 0;
parameters_auto_detect.pixel_size         = handles.par_microscope.pixel_size;

%=== Update status
status_text = {' ';'== Transcription site detection: STARTED.' ; '   See Workspace for details.'};
status_update(hObject, eventdata, handles,status_text); 

file_list = get(handles.listbox_files,'String');

N_file = size(file_list,1);
TS_counter = handles.TS_counter;
TS_summary = handles.TS_summary;

%== Loop over all files: includes autosave options 
i_start_file = handles.i_file_proc;
i_end_file   = size(file_list,1);

i_cell_proc     = handles.i_cell_proc;
i_TS_proc       = handles.i_TS_proc;

status_first_file = 1;  
status_first_cell = 1;


for i_file = i_start_file:i_end_file
    
    file_name_load  = file_list{i_file};
    
    
    disp(' '), disp(' ')
    disp('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    disp(['+++ Processing file ', num2str(i_file), ' of ', num2str(N_file)]);
    disp(['File-name (list): ', file_name_load])
    
    
    %== Determine what type of file we have and load it
    [pathstr, name_file, ext] = fileparts(file_name_load);

    flag_continue = 1;
    
    %-- Load data from outline definition file
    if strcmpi(ext,'.txt')
        if not(isempty(handles.img.path_names.img))
            path_image = handles.img.path_names.img;
        elseif not(isempty(handles.img.path_names.root))
            path_image = handles.img.path_names.root;
        elseif not(isempty(handles.path_name_list))
            path_image = handles.path_name_list;
        end
        file_name_load_full        = fullfile(handles.path_name_list,file_name_load);  
        [cell_prop dum file_names] = FQ_load_results_WRAPPER_v1(file_name_load_full);        
        [image_struct status_file] = load_stack_data_v7(fullfile(path_image,file_names.raw));
        
        if status_file == 0
            disp('FISH image could not be loaded')    
            flag_continue = 0;
        end
        
             
    %- Load image files 
    elseif strcmpi(ext,'.tif') || strcmpi(ext,'.stk')
        file_name_load_full = fullfile(handles.path_name_list,file_name_load);
        image_struct        = load_stack_data_v7(file_name_load_full);
        file_names.raw      = file_name_load;
        file_names.filtered = [];
        file_names.settings = [];
        file_names.DAPI     = [];
        file_names.TS_label = [];
        
        %- Dimension of entire image
        w = image_struct.w;
        h = image_struct.h;
        cell_prop(1).x      = [1 1 w w];
        cell_prop(1).y      = [1 h h 1];

        %- Other parameters
        cell_prop(1).pos_TS = [];
        cell_prop(1).label  = 'EntireImage';
        cell_prop(1).pos_TS = [];
    end
    
    %- Get settings file
    if not(isempty(handles.file_name_settings_new))
        file_name_settings = handles.file_name_settings_new;
    end
    
    %- Name of image
    [dum, name_image] = fileparts(file_names.raw);
    
    disp(['File-name (FISH): ', file_names.raw])
    disp(' ');
      
    %= Autodetection of TxSites 
    parameters_detect           = parameters_auto_detect;
    parameters_detect.cell_prop = cell_prop;
        
    
    %- Define which files are passed to the routine
    switch parameters_auto_detect.img_det_type
    
        case 'TS_label'
            
            if not(isempty(file_names.TS_label))
                file_name_load_full  = fullfile(path_image,file_names.TS_label);
                [image_TS_struct  status_file] = load_stack_data_v7(file_name_load_full);
                
                if status_file
                    disp(['File-name (TS_label): ', file_names.TS_label, ' loaded'])             
                    img_TS_label = image_TS_struct.data;
                    img_2nd = image_struct.data;
                else
                    disp(['File-name (TS_label): ', file_names.TS_label, ' NOT loaded.'])
                    disp(['Path (TS_label): ', path_image])
                    disp('NO DETECTION PERFORMED')
                    flag_continue = 0;

                end
                
            else
                disp('No file with TS_label defined')
                disp('NO DETECTION PERFORMED')
                flag_continue = 0;
            end
           
            
        case 'FISH_image' 
            img_TS_label = image_struct.data;
            img_2nd      = [];
    end
    
    %- Load DAPI file only if needed    
    if parameters_auto_detect.th_min_TS_DAPI > 0
        if not(isempty(file_names.DAPI))
            file_name_load_full  = fullfile(path_image,file_names.DAPI);
            [image_DAPI_struct, status_file] = load_stack_data_v7(file_name_load_full);

            if status_file
                disp(['File-name (DAPI): ', file_names.DAPI, ' loaded'])            
                img_DAPI = image_DAPI_struct.data;
            else
                disp(['File-name (DAPI): ', file_names.TS_label, ' NOT loaded. WILL NOT CONTINUE!!!'])
                disp(['Path (TS_label): ', path_image])
                img_DAPI = [];
                flag_continue = 0;

            end

        else
            disp('No file with DAPI defined')
            img_DAPI = [];
        end
    else
        img_DAPI = [];
    end
    
    %- Continue only if files are specified that are needed
    if flag_continue

        %- Assign parameters
        parameters_auto_detect.img_2nd    = img_2nd;
        parameters_auto_detect.img_DAPI   = img_DAPI;
        parameters_auto_detect.cell_prop  = cell_prop;   
        
        if not(isempty(cell_prop))

            %- Detect and analyse
            cell_prop = TxSite_detect_v7(img_TS_label,parameters_auto_detect);

            %=== Save new outline definition
            file_name_OUTLINE      = [name_image,'_outline_TS_detect_AUTO_',num2str(round(parameters_auto_detect.int_th)),'.txt'];         
            file_name_OUTLINE_full = fullfile(path_save,file_name_OUTLINE);
            disp(['Outline saved to: ',file_name_OUTLINE_full])

            %- Parameters to save results
            parameters.path_save           = path_save;
            parameters.cell_prop           = cell_prop;
            parameters.par_microscope      = par_microscope;
            parameters.path_name_image     = handles.img.path_names.img;
            parameters.file_names          = file_names;
            parameters.version             = handles.version;
            parameters.flag_type           = 'outline'; 

            FQ_save_results_v1(file_name_OUTLINE_full,parameters);
        else
            disp('No cell defined in outline file.')
        end
    end

end

%- Enable controls and update status
controls_enable(hObject, eventdata, handles)
status_text = {' ';'== Transcription site DETECTION: FINISHED'};
status_update(hObject, eventdata, handles,status_text); 
 
%- Change to previous directory
cd(current_dir)


% =========================================================================
% TxSite quantification
% =========================================================================


%== Save transcription site quantification settings
function handles = save_settings_nascent(handles)

%- Get current directory and go to directory with outlines
current_dir = cd;

if  not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- User-dialog
dlgTitle      = 'File with detection settings';
default_name  = handles.file_name_settings_nascent_save;
name_settings = uiputfile(default_name,dlgTitle);


%- Save results
if( name_settings ~= 0)  
    %global parameters_quant
    %parameters_quant = handles.parameters_quant;
   % handles.file_name_settings_nascent_save  = FQ_TS_settings_save_v9(fullfile(path_save,name_settings),handles);
    
    [handles.file_name_settings_nascent_save, handles.path_name_settings_TS] = handles.img.save_settings_TS(fullfile(path_save,name_settings));
end

%- Go back to 
cd(current_dir)


%== Settings of quantification
function menu_settings_TS_Callback(hObject, eventdata, handles)

if ~isfield(handles,status_TS_simple_only)
    handles.status_TS_simple_only = 0;
end

handles.parameters_quant = FQ_TS_settings_modify_v5(handles.parameters_quant,handles.status_TS_simple_only);
status_update(hObject, eventdata, handles,{'  ';'## Options for transcription site quantification modified'});         
guidata(hObject, handles);


%== Load settings
function button_load_settings_TxSite_Callback(hObject, eventdata, handles)

%- Get current directory and go to directory with results/settings
set(handles.h_gui_batch,'Pointer','watch'); %= Pointer to watch

current_dir = cd;

if    not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif  not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)

%- Get settings
[file_name_settings_TS,path_name_settings_TS] = uigetfile({'*.txt'},'Select file with settings for TS quantification');
text_update_amp = 'NO settings loaded';

if file_name_settings_TS ~= 0

    status_update(hObject, eventdata, handles,'LOAD settings ....');

    %- Load settings
    [dum,file_ok] = handles.img.load_settings_TS(fullfile(path_name_settings_TS,file_name_settings_TS));
 
%     %- Load settings
%     [handles, file_ok] = FQ_TS_settings_load_v3(fullfile(path_name_settings_TS,file_name_settings_TS),handles); 
%     
    
    %- Only if settings are ok
    if file_ok
        
        handles.file_name_settings_TS = file_name_settings_TS;
        handles.path_name_settings_TS = path_name_settings_TS;   
        handles.status_settings_TS = 1; 
        guidata(hObject, handles);    

        %= Check if image of mRNA can be found otherwise load it
        if isfield(handles.img.mRNA_prop, 'file_name')
            
            %- Is folder of mRNA defined?
            if isempty(handles.img.mRNA_prop.path_name)
                handles.img.mRNA_prop.path_name = handles.path_name_settings_TS;
            end
            
            PSF_name_full = fullfile(handles.img.mRNA_prop.path_name , handles.img.mRNA_prop.file_name);

            if exist(PSF_name_full,'file') ~= 2
                PSF_name_full = fullfile(handles.path_name_settings_TS, handles.PSF_file_name);

                if not(exist(PSF_name_full,'file') == 2)
                    [handles.img.mRNA_prop.file_name,handles.img.mRNA_prop.path_name] = uigetfile('.tif','Select averaged image of mRNA.','MultiSelect','off');
%                 else
%                     handles.PSF_path_name = handles.path_name_settings_TS;
%                 end
                end
            end
        end
    
        %== Background
        if handles.img.settings.TS_quant.flags.bgd_local 
            set(handles.button_TS_bgd,'Value',0);
        else
            set(handles.button_TS_bgd,'Value',1);
            set(handles.txt_TS_bgd,'String',num2str(handles.img.settings.TS_quant.BGD.amp)),
        end

         
         %- Only simple TS methods
         if handles.img.settings.TS_quant.flags.quant_simple_only
             
             set(handles.panel_PSF_superposition,'Visible','off')              
             handles.img = handles.img.load_mRNA_avg(fullfile(handles.img.mRNA_prop.path_name , handles.img.mRNA_prop.file_name));
             
         %- PSF superposition approach   
         else
         
             set(handles.panel_PSF_superposition,'Visible','on')
             
             %- Default status and text is set for NO amplitudes
             handles.status_AMP = 0;
             text_update_amp = '## File with amplitudes was NOT defined';

             if isfield(handles.img.mRNA_prop,'AMP_path_name')       && isfield(handles.img.mRNA_prop,'AMP_file_name')                
                
                 if not(isempty(handles.img.mRNA_prop.AMP_file_name))
%                     if isempty(handles.img.mRNA_prop.AMP_path_name)
%                         name_full_1 = fullfile(handles.path_name_settings_TS,handles.AMP_file_name );
%                     else
%                         name_full_1 = fullfile(handles.img.mRNA_prop.AMP_path_name,handles.img.mRNA_prop.AMP_file_name );
%                     end

                    name_full = fullfile(handles.img.mRNA_prop.AMP_path_name,handles.img.mRNA_prop.AMP_file_name );
   
                    %- Check if one of the names exists
                    if exist(name_full,'file') == 2
                                               
                        img_dum = FQ_img; 
                        status_open = img_dum.load_results(name_full,-1);  % -1 means don't open image
                        
                        if status_open.outline
                            
                            spots_fit      = img_dum.cell_prop(1).spots_fit;
                            spots_detected = img_dum.cell_prop(1).spots_detected;

                            if not(isempty(spots_fit))

                                %- Get amplitudes
                                figure
                                parameters.h_plot  = gca;
                                parameters.col_par = img_dum.col_par;

                                thresh.in          = logical(img_dum.cell_prop(1).thresh.in);
                                handles.img.mRNA_prop  = FQ_AMP_analyze_v3(spots_fit,spots_detected,thresh,parameters,handles.img.mRNA_prop); 
                                
                                %- Save data
                                handles.status_AMP = 1;
                                guidata(hObject, handles);

                                %- Update status
                                text_update_amp = {'  '; ...
                                               '## Amplitudes defined'; ...
                                               'Fit with skewed normal distribution'; ...
                                               ['Mean:     ', num2str(handles.img.mRNA_prop.amp_mean )]; ...
                                               ['Sigma:    ', num2str(handles.img.mRNA_prop.amp_sigma)]; ...
                                               ['Skewness: ', num2str(handles.img.mRNA_prop.amp_skew)]; ...
                                               ['Kurtosis: ', num2str(handles.img.mRNA_prop.amp_kurt)]};        


                            else
                                text_update_amp = {'  '; ...
                                               '## NO SPOTS FOUND in file. Amplitudes are NOT defined'};        
                            end     
                        end
                    end 
                end
              end                
         end
    end
end


%- Update status
status_update(hObject, eventdata, handles,text_update_amp);  

%- Save and update enable
controls_enable(hObject, eventdata, handles)
guidata(hObject, handles);
status_update(hObject, eventdata, handles,'Settings Loaded');
set(handles.h_gui_batch,'Pointer','arrow');

%- Go back to original folder
cd(current_dir)


%=== Load PSF
function handles = load_PSF(hObject, eventdata, handles)

%global parameters_quant

%- Same cropping as for TS quant
par_crop_TS                     = handles.parameters_quant.crop_image;
pixel_size                      = handles.par_microscope.pixel_size;
parameters.par_crop_NS_quant.xy = ceil(par_crop_TS.xy_nm / pixel_size.xy);
parameters.par_crop_NS_quant.z  = ceil(par_crop_TS.z_nm / pixel_size.z);

%- Sum of pixels
parameters.N_pix_sum            = handles.parameters_quant.N_pix_sum;

%- Same cropping as for detection
parameters.par_crop_NS_detect = handles.detect.region; 
    
%- Load PSF    
parameters.flags.output = 0;
parameters.flags.norm   = 0;      
handles                 = FQ_TS_analyze_PSF_v3(handles,parameters); 

%- Get mRNA properties 
handles.mRNA_prop.sigma_xy           = handles.img_PSF_OS_struct.PSF_fit.sigma_xy;
handles.mRNA_prop.sigma_z            = handles.img_PSF_OS_struct.PSF_fit.sigma_z;
handles.mRNA_prop.amp_mean_fit_QUANT = handles.img_PSF_OS_struct.PSF_fit.amp;
handles.mRNA_prop.sum_pix            = handles.PSF_sum_pix;
handles.mRNA_prop.bgd_value          = handles.bgd_value;
handles.mRNA_prop.N_pix_sum          = (2*parameters.N_pix_sum.xy+1) * (2*parameters.N_pix_sum.xy+1)  * (2*parameters.N_pix_sum.z+1); 

%- Save       
guidata(hObject, handles);         

%== Define amplitudes of individual mRNA
function button_PSF_amp_Callback(hObject, eventdata, handles)

choice = questdlg('Use current value OR load from file', 'Amplitudes of mRNA', 'Current analysis','File','Current analysis');

text_update = {'  '; '## DEFINING Amplitudes for TxSite quantification'; '... please wait ... '};        
status_update(hObject, eventdata, handles,text_update);
set(handles.h_gui_batch,'Pointer','watch');

if not(strcmp(choice,''))

    switch (choice)
        case 'Current analysis'
            spots_fit      = handles.spots_fit_all;
            spots_detected = handles.spots_detected_all;
            thresh.in = handles.img.settings.thresh.in;            
  
        case 'File'
            
            %- Get current directory and go to directory with results/settings
            current_dir = cd;

            if    not(isempty(handles.img.path_names.results)); 
                path_save = handles.img.path_names.results;
            elseif  not(isempty(handles.img.path_names.root)); 
                path_save = handles.img.path_names.root;
            else
                path_save = cd;
            end

            cd(path_save)
            
            %- Get file
            [file_name_results,path_name_results] = uigetfile({'*.txt'},'Select file with results of spot detection','MultiSelect', 'off');
            
            handles.AMP_file_name = file_name_results;
            handles.AMP_path_name = path_name_results;            
            
            if file_name_results ~= 0 
                
                cell_prop = FQ_load_results_WRAPPER_v1(fullfile(path_name_results,file_name_results));
                spots_fit = cell_prop(1).spots_fit;
                spots_detected = cell_prop(1).spots_detected;
                
                %- Make sure that spots are loaded - empty otherwise
                if not(isempty(spots_fit))
                    thresh.in      = logical(cell_prop(1).thresh.in);
                else
                    text_update = {' ';'NO SPOTS FOUND IN FILE. Please check format. Results file has to be stored with NO labels for the spots';
                                   'Consult FISH-QUANt documentation for more details.'; ' ' };
                    status_update(hObject, eventdata, handles,text_update);
                end
                
            else
                spots_fit = [];
            end
            
            %- Go back to original folder
            cd(current_dir) 
            
    end
        
    if not(isempty(spots_fit))
        
        %- Get amplitudes
        figure
        parameters.h_plot  = gca;
        parameters.col_par = handles.col_par;
        handles.img.mRNA_prop  = FQ_AMP_analyze_v3(spots_fit,spots_detected,thresh,parameters,handles.img.mRNA_prop); 
         
        button = questdlg('Use distribution of mean value of mRNA amplitudes for quantification?','TxSite quantication','Distribution','Mean','Distribution');
        handles.img.settings.TS_quant.flags.amp_quant = button;
        
        
        %- Save data
        handles.status_AMP = 1;
        guidata(hObject, handles);
        controls_enable(hObject, eventdata, handles)
        
        %- Update status
        text_update = {'  '; ...
                       '## Amplitudes defined'; ...
                       'Fit with skewed normal distribution'; ...
                       ['Mean:     ', num2str(handles.mRNA_prop.amp_mean )]; ...
                       ['Sigma:    ', num2str(handles.mRNA_prop.amp_sigma)]; ...
                       ['Skewness: ', num2str(handles.mRNA_prop.amp_skew)]; ...
                       ['Kurtosis: ', num2str(handles.mRNA_prop.amp_kurt)]};        
        status_update(hObject, eventdata, handles,text_update);
        
    else
        handles.status_AMP = 0;
        text_update = {'  '; ...
                       '## NO SPOTS FOUND. Amplitudes are NOT defined'};        
        status_update(hObject, eventdata, handles,text_update);
    
    end
                
end

%- Save and update enable
controls_enable(hObject, eventdata, handles)
guidata(hObject, handles);
set(handles.h_gui_batch,'Pointer','arrow');


%== Analyze PSF and amplitudes
function button_analyze_TxSite_Callback(hObject, eventdata, handles)

set(handles.h_gui_batch,'Pointer','watch'); %= Pointer to watch


% %== Analyze PSF: load and sub-pixel placement
handles.img = handles.img.load_mRNA_avg(fullfile(handles.img.mRNA_prop.path_name , handles.img.mRNA_prop.file_name));


%handles = load_PSF(hObject, eventdata, handles);
% 
% %- Same cropping as for TS quant
% par_crop_TS                     = handles.parameters_quant.crop_image;
% pixel_size                      = handles.par_microscope.pixel_size;
% parameters.par_crop_NS_quant.xy = ceil(par_crop_TS.xy_nm / pixel_size.xy);
% parameters.par_crop_NS_quant.z  = ceil(par_crop_TS.z_nm / pixel_size.z);
% 
% %- Same cropping as for detection
% parameters.par_crop_NS_detect   = handles.detect.region; 
% 
% %- Sum of pixels
% parameters.N_pix_sum            = handles.parameters_quant.N_pix_sum;
% 
% %- Load PSF    
% parameters.flags.output = 0;
% parameters.flags.norm   = 0; 
% handles = FQ_TS_analyze_PSF_v3(handles,parameters); 
% 
% %- Get mRNA properties 
% handles.mRNA_prop.sigma_xy           = handles.img_PSF_OS_struct.PSF_fit.sigma_xy;
% handles.mRNA_prop.sigma_z            = handles.img_PSF_OS_struct.PSF_fit.sigma_z;
% handles.mRNA_prop.amp_mean_fit_QUANT = handles.img_PSF_OS_struct.PSF_fit.amp;
% handles.mRNA_prop.sum_pix            = handles.PSF_sum_pix;
% handles.mRNA_prop.bgd_value          = handles.bgd_value; 
% handles.mRNA_prop.N_pix_sum          = (2*parameters.N_pix_sum.xy+1) * (2*parameters.N_pix_sum.xy+1)  * (2*parameters.N_pix_sum.z+1); 

%- Update status for PSF
if not(isempty(handles.img.mRNA_prop.PSF_shift))
    handles.status_settings_PSF_proc = 1; 
    text_update = {'  '; '## Image of mRNA loaded and analysed.'};

else
    handles.status_settings_PSF_proc = 0; 
    text_update = {'  '; '## Image of mRNA NOT loaded. Specify image.'};
end
status_update(hObject, eventdata, handles,text_update);  

%- Analyze PSF and amplitudes
if handles.status_settings_PSF_proc
    if handles.status_AMP
        handles = test_PSF_placements(hObject, eventdata, handles);
        handles.status_AMP_PROC = 1;
    else
        handles.status_AMP_PROC = 0;
    end
        
    handles.status_PSF_PROC = 1; 
    text_update = {'  '; '## PSF is analyzed.'}; 
else
    handles.status_PSF_PROC = 0; 
    handles.status_AMP_PROC = 0;
    text_update = {'  '; '## PSF is NOT analyzed.'}; 
end
status_update(hObject, eventdata, handles,text_update);  

%- Save and update enable
controls_enable(hObject, eventdata, handles)
guidata(hObject, handles);
set(handles.h_gui_batch,'Pointer','arrow');
          

%== Test placements
function handles = test_PSF_placements(hObject, eventdata, handles)

%- Get relevant parameters
mRNA_prop      = handles.img.mRNA_prop;  
PSF_shift_all  = handles.img.mRNA_prop.PSF_shift;
N_PSF_shift    = length(PSF_shift_all);

%- Same cropping as for TS
par_crop_TS     = handles.img.settings.TS_quant.crop_image;
pixel_size      = handles.img.par_microscope.pixel_size;
parameters_fit.par_crop.xy = ceil(par_crop_TS.xy_nm / pixel_size.xy);
parameters_fit.par_crop.z  = ceil(par_crop_TS.z_nm / pixel_size.z);
parameters_fit.flags.crop      = 1;

%- Parameters for fitting
parameters_fit.pixel_size      = pixel_size;
parameters_fit.par_microscope  = handles.img.par_microscope ;
parameters_fit.flags.output    = 0;

%-- Perform a certain number of test placements
if not(isfield(handles.img.settings.TS_quant.flags,'amp_quant'))
    button = questdlg('Use distribution of mean value of mRNA amplitudes for quantification?','TxSite quantication','Distribution','Mean','Distribution');
    handles.img.settings.TS_quant.flags.amp_quant = button;
end

switch handles.img.settings.TS_quant.flags.amp_quant

    case 'Distribution' 
        N_test        = ceil(500/N_PSF_shift);
        N_total       = N_PSF_shift*N_test;
        flag_amp_rand = 1;
        
    case 'Mean'
        N_test        = 1;
        N_total       = N_PSF_shift*N_test;
        flag_amp_rand = 0;
end

fit_summ_loop = zeros(N_total,7);

fprintf('Testing placements: (of %d):     1',N_total);
i_sim = 1;
for i_PSF =  1: N_PSF_shift

    %- Get PSF
    psf_loop = PSF_shift_all(i_PSF).data;

    for i_test = 1:N_test;

       fprintf('\b\b\b\b%4i',i_sim); 

       %- Simulate PSF as if they would be placed --> amplitudes from fitting small area 
       if flag_amp_rand
             amp_loop = pearsrnd(mRNA_prop.amp_mean,mRNA_prop.amp_sigma,mRNA_prop.amp_skew,mRNA_prop.amp_kurt,1,1);
       else
           amp_loop = mRNA_prop.amp_mean;
       end

       factor_scale = amp_loop / PSF_shift_all(i_PSF).PSF_fit_detect.amp;
       psf_new  = factor_scale*psf_loop; 

       %- Fit over larger area as used for TS quant
       img_PSF.data = psf_new;
       PSF_fit = PSF_3D_Gauss_fit_v8(img_PSF,parameters_fit);

       fit_summ_loop(i_sim,:) = [i_PSF amp_loop PSF_fit.amp  PSF_fit.bgd PSF_fit.sigma_xy PSF_fit.sigma_z max(psf_new(:))];
       i_sim = i_sim+1;
    end   
end

fprintf('\n');

%- Summarize results of fit
fit_summ_loop_avg = mean(fit_summ_loop,1);
handles.img.mRNA_prop.amp_mean_fit   = fit_summ_loop_avg(3); 

%- Save data
guidata(hObject, handles);      

 
%== Quantify transcription site
function button_process_TxSite_Callback(hObject, eventdata, handles)    
handles = process_TxSite(hObject, eventdata, handles);
guidata(hObject, handles); 


%== Function for transcription site quantification and autodetection
function handles = process_TxSite(hObject, eventdata, handles)


%===== GENERAL PREPARATION 
current_dir = pwd;

% %--- Path for saving outlines
% if not(isempty(handles.img.path_names.outlines))
%     path_save_outline  = handles.img.path_names.outlines;
% elseif not(isempty(handles.img.path_names.img))
%     path_save_outline  = handles.img.path_names.img;
% elseif not(isempty(handles.img.path_names.root))
%     path_save_outline  = handles.img.path_names.root;
% else
%     path_save_outline  = handles.path_name_list;
% end

%--- Path for saving results
if not(isempty(handles.img.path_names.results))
    path_save_results  = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.img))
    path_save_results  = handles.img.path_names.img;
elseif not(isempty(handles.img.path_names.root))
    path_save_results  = handles.img.path_names.root;
else
    path_save_results  = handles.path_name_list;
end

%-- General parameters
par_microscope   = handles.img.par_microscope;

%===== PREPARATION FOR FIT 

%-- Get status to save various aspects of TxSite quantification
status_save_results = get(handles.status_save_results_TxSite_quant,'Value');
status_save_figures = get(handles.status_save_figures_TxSite_quant,'Value');
status_save_auto    = get(handles.checkbox_auto_save,'Value');

%== Quantification parameters
parameters_quant                     = handles.img.settings.TS_quant;
parameters_quant.flags.output        = 0;


%=== Integration range
range_int.x_int.min =  - parameters_quant.crop_image.xy_nm;
range_int.x_int.max =  + parameters_quant.crop_image.xy_nm;

range_int.y_int.min =  - parameters_quant.crop_image.xy_nm;
range_int.y_int.max =  + parameters_quant.crop_image.xy_nm;

range_int.z_int.min =  - parameters_quant.crop_image.z_nm;
range_int.z_int.max =  + parameters_quant.crop_image.z_nm;

parameters_quant.range_int = range_int;

%== Background
status_bgd = get(handles.button_TS_bgd,'Value');

if status_bgd == 1
    parameters_quant.flags.bgd_local = 0;
    parameters_quant.BGD.amp         = str2num(get(handles.txt_TS_bgd,'String'));   
else
    parameters_quant.flags.bgd_local = 2;
end

%=== Parameters for quantificaiton
fact_os           = handles.img.settings.avg_spots.fact_os;
PSF_shift         = handles.img.mRNA_prop.PSF_shift;
pixel_size_os.xy  = par_microscope.pixel_size.xy / fact_os.xy;
pixel_size_os.z   = par_microscope.pixel_size.z  / fact_os.z;

parameters_quant.dist_max            = inf;
parameters_quant.pixel_size          = par_microscope.pixel_size;
parameters_quant.pixel_size_os       = pixel_size_os;
parameters_quant.N_mRNA_analysis_MAX = [];
parameters_quant.fact_os             = fact_os;
parameters_quant.par_microscope      = par_microscope;
parameters_quant.pad_image           = [];
parameters_quant.col_par             = handles.img.col_par;

%= mRNA properties
parameters_quant.mRNA_prop           = handles.img.mRNA_prop;

%= FLAGS for QUANTIFICATION
parameters_quant.flags.parallel      = get(handles.checkbox_parallel_computing,'Value');

%=== Which quantification methods: simple or all
parameters_quant.flags.quant_simple_only = handles.status_TS_simple_only; %not(get(handles.checkbox_flag_GaussMix,'Value'));
handles.status_TS_simple_only            = parameters_quant.flags.quant_simple_only;

%- BGD for fitting of TS is a free fitting paramter 
parameters_quant.flags.IntegInt_bgd_free = 1;   


%=== Update status
status_text = {' ';'== Transcription site quantification: STARTED.' ; '   See Workspace for details.'};
status_update(hObject, eventdata, handles,status_text); 

file_list = get(handles.listbox_files,'String');

N_file = size(file_list,1);
TS_counter = handles.TS_counter;
TS_summary = handles.TS_summary;

%== Loop over all files: includes autosave options 
i_start_file = handles.i_file_proc;
i_end_file   = size(file_list,1);

i_cell_proc     = handles.i_cell_proc;
i_TS_proc       = handles.i_TS_proc;

status_first_file = 1;  
status_first_cell = 1;


for i_file = i_start_file:i_end_file
    
    file_name_load  = file_list{i_file};
    
    
    disp(' '), disp(' ')
    disp('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    disp(['+++ Processing file ', num2str(i_file), ' of ', num2str(N_file)]);
    disp(['File-name (list): ', file_name_load])
    
    
    %== Determine what type of file we have and load it
    [pathstr, name_file, ext] = fileparts(file_name_load);


    %-- Load data from outline definition file
    if strcmpi(ext,'.txt')
        if not(isempty(handles.img.path_names.img))
            path_image = handles.img.path_names.img;
        elseif not(isempty(handles.img.path_names.root))
            path_image = handles.img.path_names.root;
        elseif not(isempty(handles.path_name_list))
            path_image = handles.path_name_list;
        end
        file_name_load_full        = fullfile(handles.path_name_list,file_name_load);
        
        img_dum = FQ_img;
        img_dum = handles.img;
        img_dum.load_results(file_name_load_full,-1);
        
        %- Check if there are transcription-site in the property file
        status_TS_present = 0;
        N_cell = length(img_dum.cell_prop);
        
        for i_cell =1:N_cell    
            
            if not(isempty(img_dum.cell_prop(i_cell).pos_TS))
                status_TS_present = 1;
            end
        end
        
        %- Load image only if TS is present
        if status_TS_present         
            img_dum.load_img(fullfile(img_dum.path_names.img,img_dum.file_names.raw),'raw');
            status_TS = 1;
        else
            disp(' '); disp('NO transcription site defined - image will not be loaded.'); disp(' '); 
            status_TS = 0;
        end
        
    %- Load image files 
    elseif strcmpi(ext,'.tif') || strcmpi(ext,'.stk')
        disp(' '); disp('Transcripiton site quantification only for OUTLINE FLES.'); disp(' '); 
        status_TS = 0;
    end
    
    %- Continue with TS quantification
    if status_TS
    
        %- Get settings file
        if not(isempty(handles.file_name_settings_new))
            file_name_settings = handles.file_name_settings_new;
        end

        %- Name of image
        [dum, name_image] = fileparts(img_dum.file_names.raw);

        disp(['File-name (image): ', img_dum.file_names.raw])
        disp(' ');

        %== Quantify only if TxSite only if specified 
        if status_TS

            %- Create folder to save results
            if status_save_results || status_save_figures

               [dum name_load] = fileparts(file_name_load);
               folder_new = fullfile(path_save_results,['TS_QUANT_',datestr(date,'yymmdd')],name_load);               

               is_dir = exist(folder_new,'dir'); 

               if is_dir == 0
                   mkdir(folder_new)
               end

               cd(folder_new)
            end

            handles.parameters_quant = parameters_quant;
            parameters_quant.flags.bound = 1;    % Boundaries for fitting parameters

            N_cell = length(img_dum.cell_prop);
            cell_prop = img_dum.cell_prop;
            
            %- Set parameters for loop
            if status_first_file 
                i_start_cell = i_cell_proc;
            else
                i_start_cell = 1;
            end

            i_end_cell = N_cell;


            %== [2] Loop over all cells and all TxSites
            for ind_cell = i_start_cell:i_end_cell

                disp(' ') 
                disp(' ')
                disp(['+++ Cell ', num2str(ind_cell), ' of ', num2str(N_cell)]);

                %- Binary mask for outline of cell: needed for BGD estimation
                parameters_quant.cell_bw =  roipoly(handles.img.raw(:,:,1),cell_prop(ind_cell).x,cell_prop(ind_cell).y);

                %- Binary mask for image
               % parameters_quant.cell_bw =  roipoly(image_struct.data(:,:,1),cell_prop(ind_cell).x,cell_prop(ind_cell).y);

                if not(isempty(cell_prop(ind_cell).pos_Nuc))
                    parameters_quant.nuc_bw =  roipoly(handles.img.raw(:,:,1),cell_prop(ind_cell).pos_Nuc.x,cell_prop(ind_cell).pos_Nuc.y);
                else
                    parameters_quant.nuc_bw =  [];
                end


                %- Loop over transcription site
                pos_TS_all = cell_prop(ind_cell).pos_TS;
                N_TS = length(pos_TS_all);


                %- Set parameters for loops
                if status_first_cell 
                    i_start_TS = i_TS_proc;
                else
                    i_start_TS = 1;
                end

                i_end_TS = N_TS; 

                for ind_TS = i_start_TS: i_end_TS

                    %- Get transcription site
                    disp(' ')
                    disp(['+++ TxSite ', num2str(ind_TS), ' of ', num2str(N_TS)]);
                    pos_TS = pos_TS_all(ind_TS); 

                    %- Status of transcription sit quantification can be saved to a txt file
                    if status_save_results

                        parameters_quant.file_name_save_STATUS = [cell_prop(ind_cell).label,'__',pos_TS.label , '__STATUS.txt'];
                        parameters_quant.name_file  = file_name_load;
                        parameters_quant.name_cell  = cell_prop(ind_cell).label;
                        parameters_quant.name_TS    = pos_TS.label;

                    else
                        parameters_quant.file_name_save_STATUS = [];
                    end

                    %- Save figure of reconstruction
                    if status_save_figures
                        parameters_quant.file_name_save_PLOTS_PS  = [cell_prop(ind_cell).label,'__',pos_TS.label , '__PLOTS.PS'];
                        parameters_quant.file_name_save_PLOTS_PDF = [cell_prop(ind_cell).label,'__',pos_TS.label , '__PLOTS.PDF'];
                    else
                        parameters_quant.file_name_save_PLOTS_PS  = [];
                        parameters_quant.file_name_save_PLOTS_PDF = [];

                    end

                    %- Quantify
                    image_struct.data = handles.img.raw;  % HAS TO BE CHANGED - but then in all functions in TS_quant_v16 ....

                    [TxSite_quant REC_prop TS_analysis_results TS_rec Q_all] = TS_quant_v16(image_struct,pos_TS,PSF_shift,parameters_quant);

                    %== [3] Save results in summary file
                    TS_summary(TS_counter).file_name_list      = file_name_load;
                    TS_summary(TS_counter).file_name_image     = img_dum.file_names.raw;

                    TS_summary(TS_counter).TxSite_quant        = TxSite_quant;
                    TS_summary(TS_counter).TS_analysis_results = TS_analysis_results;
                    TS_summary(TS_counter).REC_prop            = REC_prop;
                    TS_summary(TS_counter).TS_rec              = TS_rec;
                    TS_summary(TS_counter).Q_all               = Q_all;

                    TS_summary(TS_counter).cell_label          = cell_prop(ind_cell).label;
                    TS_summary(TS_counter).TS_label            = pos_TS.label;
                    TS_counter = TS_counter +1;

                    if status_save_results
                        parameters.file_name_save_REC = [cell_prop(ind_cell).label,'__',pos_TS.label , '__REC.tif'];
                        parameters.file_name_save_RES = [cell_prop(ind_cell).label,'__',pos_TS.label , '__RESIDUAL.tif'];
                        TxSite_quant_save_results_v2( REC_prop, parameters);
                    end  

                    %== Auto-save results if enabled
                    handles.TS_summary  = TS_summary;
                    handles.i_file_proc = i_file;
                    handles.i_cell_proc = ind_cell;
                    handles.i_TS_proc   = ind_TS;
                    handles.TS_counter  = TS_counter - 1;

                    if status_save_auto 
                        file_name      = ['_FQ_analysis_AUTOSAVE_', datestr(date,'yymmdd'), '.mat'];
                        file_name_full = fullfile(path_save_results,file_name);       
                        FQ_batch_save_handles_v3(file_name_full,handles);
                    end                

                end
            end
            status_first_cell = 0;
        else
            disp('Image not found: TS quantification not performed.'); disp(' '); 
        end   
    end
    status_first_file = 0;
end

%- Update status and save results
handles.TS_summary         = TS_summary;

handles.TS_counter         = 1; 
handles.i_file_proc        = 1;
handles.i_cell_proc        = 1;
handles.i_TS_proc          = 1;

%- Same parameters for detection and quantification
handles.parameters_quant       = parameters_quant;

%- Enable controls and update status
controls_enable(hObject, eventdata, handles)
status_text = {' ';'== Transcription site quantification: FINISHED'};
status_update(hObject, eventdata, handles,status_text); 
 
%- Change to previous directory
cd(current_dir)


%== Restrict size
function button_TS_restrict_size_Callback(hObject, eventdata, handles)

status_text = {' ';'== TS quantification: restriction of size in progress ...'};
status_update(hObject, eventdata, handles,status_text); 
set(handles.h_gui_batch,'Pointer','watch');

%== Get status to save various aspects of TxSite quantification
current_dir = pwd;
status_save_results = get(handles.status_save_results_TxSite_quant_restrict,'Value');
status_save_figures = get(handles.status_save_figures_TxSite_quant_restrict,'Value');

%== Path for saving results
if not(isempty(handles.img.path_names.results))
    path_save_results  = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.img))
    path_save_results  = handles.img.path_names.img;
elseif not(isempty(handles.img.path_names.root))
    path_save_results  = handles.img.path_names.root;
else
    path_save_results  = handles.path_name_list;
end

%- Parameters
parameters                         = handles.parameters_quant;
parameters.fid                     = -1;
parameters.flags.output            = 0;
parameters.file_name_save_PLOTS_PS = [];
parameters.dist_max                = str2double(get(handles.text_TS_dist_max,'String'));

%- Get results of analysis
TS_summary = handles.TS_summary;
N_TS = length(TS_summary);

%- Loop over TxSites
for i_TS = 1 : N_TS
    
    %- Get data
    TS_rec      = TS_summary(i_TS).TS_rec;
    Q_all       = TS_summary(i_TS).Q_all;    
    TS_analysis = TS_summary(i_TS).TS_analysis_results;    
    
    %- Get name of files and cells and TS
    file_name_list = TS_summary(i_TS).file_name_list;
    [dum name_load] = fileparts(file_name_list);
    cell_label = TS_summary(i_TS).cell_label;
    TS_label   = TS_summary(i_TS).TS_label;
    
    %- Create folder to save results
    if status_save_results || status_save_figures

       %- Create folder to save results    
       folder_new = fullfile(path_save_results,['TS_QUANT__REST_',num2str(parameters.dist_max),'nm_',datestr(date,'yymmdd')],name_load);               

       is_dir = exist(folder_new,'dir'); 

       if is_dir == 0
           mkdir(folder_new)
       end

       cd(folder_new)
    end
    
    %- Prepare files for saving
     if status_save_results

        parameters.file_name_save_STATUS = [cell_label,'__',TS_label, '__STATUS_RESTRICT.txt'];
        parameters.name_file  = file_name_list;
        parameters.name_cell  = cell_label;
        parameters.name_TS    = TS_label;
        
        %== Open text file to save status
        parameters.fid = fopen(parameters.file_name_save_STATUS,'w'); 
   
       if parameters.fid == -1
          warndlg(['Status of TxSite quantifcation cannot be saved. Invalid file: ', file_name_save_STATUS],'TS_quant_v9');
       else  
           fprintf(parameters.fid, '== FISH-QUANT: TxSITE quantification performed on %s \n\n', datestr(date,'dd-mm-yyyy'));
           fprintf(parameters.fid, 'File  : %s \n', parameters.name_file);
           fprintf(parameters.fid, 'Cell  : %s \n', parameters.name_cell);
           fprintf(parameters.fid, 'TxSite: %s \n\n', parameters.name_TS);
       end    
        
    else
        parameters.fid = -1; 
        parameters.file_name_save_STATUS = [];
    end

    %- Save figure of reconstruction
    if status_save_figures
        parameters.file_name_save_PLOTS_PS  = [cell_label,'__',TS_label , '__PLOTS.PS'];
        parameters.file_name_save_PLOTS_PDF = [cell_label,'__',TS_label , '__PLOTS.PDF'];
    else
        parameters.file_name_save_PLOTS_PS  = [];
        parameters.file_name_save_PLOTS_PDF = [];

    end
    
    
    %====== Restrict analysis
    [TxSite_quant REC_prop] = FQ_TS_analyze_results_v8(TS_rec,Q_all,TS_analysis, parameters);

    %- Asign results
    TS_summary(i_TS).TxSite_quant = TxSite_quant;
    TS_summary(i_TS).REC_prop     = REC_prop;
    
    %== Convert FILE to PDF
    if not(isempty(parameters.file_name_save_PLOTS_PS))
       ps2pdf('psfile', parameters.file_name_save_PLOTS_PS, ...
              'pdffile', parameters.file_name_save_PLOTS_PDF, ...
              'gspapersize', 'a4', 'deletepsfile', 1);
    end

    %== Close file
    if  parameters.fid ~= -1;
        fclose(parameters.fid);
    end
end

%- Save results
handles.TS_summary = TS_summary;
guidata(hObject, handles); 

%- Change to previous directory
cd(current_dir)

%- Update status
status_text = {'   ...... restriction of size FINISHED'};
status_update(hObject, eventdata, handles,status_text); 
set(handles.h_gui_batch,'Pointer','arrow');



% =========================================================================
% PLOTS
% =========================================================================

%=== Plot-histogram of all values
function handles = plot_hist_all(handles,axes_select,values_for_th)

thresh_all = handles.img.settings.thresh;

if isempty(axes_select)
    figure
    hist(values_for_th,25); 
    v = axis;
    hold on
         plot([thresh_all.min_th thresh_all.min_th] , [0 1e5],'r');
         plot([thresh_all.max_th thresh_all.max_th] , [0 1e5],'g');
    hold off
    axis(v);
    colormap jet; 
    
% Handles for min and max line are returned for slider callback function    
else
    axes(axes_select); 
    hist(values_for_th,25); 
    h = findobj(axes_select);
    v = axis;
    hold on
         handles.h_hist_min = plot([thresh_all.min_th thresh_all.min_th] , [0 1e5],'r');
         handles.h_hist_max = plot([thresh_all.max_th thresh_all.max_th] , [0 1e5],'g');
    hold off
    axis(v);
    colormap jet;
    freezeColors;
    %set(h,'ButtonDownFcn',@axes_histogram_all_ButtonDownFcn);   % Button-down function has to be set again
end
 
title(strcat('Total # of spots: ',sprintf('%d' ,length(thresh_all.in_old) )),'FontSize',9);    
    

%=== Plot-histogram of thresholded parameters
function handles = plot_hist_th(handles,axes_select,values_for_th)

thresh_all     = handles.img.settings.thresh;

if isempty(axes_select)
    figure
    hist(values_for_th(handles.img.settings.thresh.in_display),25); 
    v = axis;
    hold on
         plot([thresh_all.min_th thresh_all.min_th] , [0 1e5],'r');
         plot([thresh_all.max_th thresh_all.max_th] , [0 1e5],'g');
    hold off
    axis(v);
    colormap jet; 
    
% Handles for min and max line are returned for slider callback function    
else
    axes(axes_select); 
    hist(values_for_th(thresh_all.in_display),25); 
    h = findobj(axes_select);
    v = axis;
    hold on
         handles.h_hist_th_min = plot([thresh_all.min_th thresh_all.min_th] , [0 1e5],'r');
         handles.h_hist_th_max = plot([thresh_all.max_th thresh_all.max_th] , [0 1e5],'g');
    hold off
    axis(v);
    colormap jet;
    freezeColors;
   % set(h,'ButtonDownFcn',@axes_histogram_th_ButtonDownFcn);   % Button-down function has to be set again
end
    
title(strcat('Thresholded # of spots: ',sprintf('%d' ,sum(thresh_all.in_display) )),'FontSize',9);     


% =========================================================================
% VARIOUS FUNCTIONS
% =========================================================================

%== Activate parallel computing
function checkbox_parallel_computing_Callback(hObject, eventdata, handles)

flag_parallel = get(handles.checkbox_parallel_computing,'Value');

if exist('gcp','file')

    %- Parallel computing - open MATLAB session for parallel computation 
    if flag_parallel == 1    
        
        p = gcp('nocreate'); % If no pool, do not create new one.

        if isempty(p)
            
            %- Update status
            set(handles.h_gui_batch,'Pointer','watch');
            status_text = {' ';'== STARTING matlabpool for parallel computing ... please wait ... '};
            status_update(hObject, eventdata, handles,status_text);

            parpool;

            %- Update status
            status_text = {' ';'    ... STARTED'};
            status_update(hObject, eventdata, handles,status_text);        
            set(handles.h_gui_batch,'Pointer','arrow');
        end

    %- Parallel computing - close MATLAB session for parallel computation     
    else
        
        p = gcp('nocreate'); % If no pool, do not create new one.
        
        if ~isempty(p)
            
            %- Update status
            set(handles.h_gui_batch,'Pointer','watch');
            status_text = {' ';'== STOPPING matlabpool for parallel computing ... please wait ... '};
            status_update(hObject, eventdata, handles,status_text);

            delete(p)

            %- Update status
            status_text = {' ';'    ... STOPPED'};
            status_update(hObject, eventdata, handles,status_text);
            set(handles.h_gui_batch,'Pointer','arrow');
        end
    end
    
else
    warndlg('Parallel toolbox not available','FISH_QUANT')
    set(handles.checkbox_parallel_computing,'Value',0);
end


%=== Close request
function h_gui_batch_CloseRequestFcn(hObject, eventdata, handles)
button = questdlg('Are you sure that you want to close the GUI?','RESET GUI','Yes','No','No');

if strcmp(button,'Yes')    
   delete(hObject);   
end


%=== Stop button
function button_STOP_Callback(hObject, eventdata, handles)
error('FQ-batch: Excecution terminated by user.')


% =========================================================================
% Functions without function
% =========================================================================

function varargout = FISH_QUANT_batch_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function listbox_files_Callback(hObject, eventdata, handles)

function listbox_files_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox2_Callback(hObject, eventdata, handles)

function text_results_file_suffix_Callback(hObject, eventdata, handles)

function text_results_file_suffix_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function listbox_status_Callback(hObject, eventdata, handles)

function listbox_status_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_status_2_Callback(hObject, eventdata, handles)

function text_status_2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_psf_fit_sigmaX_Callback(hObject, eventdata, handles)

function text11_Callback(hObject, eventdata, handles)

function text_psf_fit_sigmaZ_Callback(hObject, eventdata, handles)

function text_psf_bgd_Callback(hObject, eventdata, handles)

function popup_psf_spots_select_Callback(hObject, eventdata, handles)

function popup_psf_spots_select_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_results_file_suffix_fixed_Callback(hObject, eventdata, handles)

function text_results_file_suffix_fixed_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_results_file_summary_Callback(hObject, eventdata, handles)

function text_results_file_summary_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function menu_avg_Callback(hObject, eventdata, handles)

function menu_load_save_Callback(hObject, eventdata, handles)

function menu_imagej_Callback(hObject, eventdata, handles)

function menu_avg_construct_Callback(hObject, eventdata, handles)

function checkbox_use_filtered_Callback(hObject, eventdata, handles)

function checkbox_save_filtered_Callback(hObject, eventdata, handles)

function pop_up_threshold_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function slider_th_min_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function slider_th_max_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function text_th_min_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_th_max_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_file_name_settings_Callback(hObject, eventdata, handles)

function text_file_name_settings_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox7_Callback(hObject, eventdata, handles)

function button_PSF_define_model_Callback(hObject, eventdata, handles)

function popup_placement_Callback(hObject, eventdata, handles)

function popup_placement_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_residuals_Callback(hObject, eventdata, handles)

function popup_residuals_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox8_Callback(hObject, eventdata, handles)

function Untitled_1_Callback(hObject, eventdata, handles)

function Untitled_2_Callback(hObject, eventdata, handles)

function checkbox_parallel_computing1_Callback(hObject, eventdata, handles)

function text_th_auto_detect_Callback(hObject, eventdata, handles)

function text_th_auto_detect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function button_TS_bgd_Callback(hObject, eventdata, handles)

function txt_TS_bgd_Callback(hObject, eventdata, handles)

function txt_TS_bgd_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function status_save_results_TxSite_quant_Callback(hObject, eventdata, handles)

function menu_settings_detect_Callback(hObject, eventdata, handles)

function popup_vis_sel_Callback(hObject, eventdata, handles)

function popup_vis_sel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function menu_avg_save_tif_Callback(hObject, eventdata, handles)

function Untitled_5_Callback(hObject, eventdata, handles)

function menu_folders_Callback(hObject, eventdata, handles)

function status_save_figures_TxSite_quant_Callback(hObject, eventdata, handles)

function Untitled_4_Callback(hObject, eventdata, handles)

function checkbox_auto_save_Callback(hObject, eventdata, handles)

function text_TS_dist_max_Callback(hObject, eventdata, handles)

function text_TS_dist_max_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function status_save_results_TxSite_quant_restrict_Callback(hObject, eventdata, handles)

function status_save_figures_TxSite_quant_restrict_Callback(hObject, eventdata, handles)

function checkbox_flag_GaussMix_Callback(hObject, eventdata, handles)

function text_min_dist_spots_Callback(hObject, eventdata, handles)

function text_min_dist_spots_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function axes_histogram_th_ButtonDownFcn(hObject, eventdata, handles)

function axes_histogram_all_ButtonDownFcn(hObject, eventdata, handles)

function checkbox_auto_save_mature_Callback(hObject, eventdata, handles)

function checkbox_show_quant_results_Callback(hObject, eventdata, handles)
