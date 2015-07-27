function varargout = FISH_QUANT_batch_folder(varargin)
% FISH_QUANT_BATCH_FOLDER MATLAB code for FISH_QUANT_batch_folder.fig
%      FISH_QUANT_BATCH_FOLDER, by itself, creates a new FISH_QUANT_BATCH_FOLDER or raises the existing
%      singleton*.
%
%      H = FISH_QUANT_BATCH_FOLDER returns the handle to a new FISH_QUANT_BATCH_FOLDER or the handle to
%      the existing singleton*.
%
%      FISH_QUANT_BATCH_FOLDER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FISH_QUANT_BATCH_FOLDER.M with the given input arguments.
%
%      FISH_QUANT_BATCH_FOLDER('Property','Value',...) creates a new FISH_QUANT_BATCH_FOLDER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FISH_QUANT_batch_folder_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FISH_QUANT_batch_folder_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FISH_QUANT_batch_folder

% Last Modified by GUIDE v2.5 23-Jan-2014 11:02:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_batch_folder_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_batch_folder_OutputFcn, ...
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


% --- Executes just before FISH_QUANT_batch_folder is made visible.
function FISH_QUANT_batch_folder_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FISH_QUANT_batch_folder (see VARARGIN)


%- Settings for saving
handles.settings_save.file_id_start = 4;
handles.settings_save.file_id_end   = 0;

handles.file_name_suffix_spots  = ['_spots_', datestr(date,'yymmdd'), '.txt'];


%- Names for filtering
handles.name_filtered.string_search  = '';
handles.name_filtered.string_replace = '_filtered_batch';
    
    

% Choose default command line output for FISH_QUANT_batch_folder
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FISH_QUANT_batch_folder wait for user response (see UIRESUME)
% uiwait(handles.h_gui_FQ_batch_folder);


% --- Outputs from this function are returned to the command line.
function varargout = FISH_QUANT_batch_folder_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;

%==========================================================================
% FOLDER LIST
%==========================================================================

%=== Add folders
function button_add_folders_Callback(hObject, eventdata, handles)

choice  = 'Yes';
ind_dir = 1;

status_advanced = get(handles.checkbox_advanced_folder_selection,'Value');

while strcmp(choice,'Yes')
    
    %- Ask for folder and add it if specified        
    if status_advanced
        folder_name = uipickfiles('REFilter','^')';
    else
        folder_name = uigetdir(pwd,'Specify folder data to analyze') ; 
    end
    if ~iscell(folder_name)
        dum=folder_name;
        folder_name={dum};
    end
    
    
    if folder_name{1} ~= 0

        str_list_old = get(handles.listbox_files,'String');

        if isempty(str_list_old)
            str_list_new = folder_name;
        else
            str_list_new = [str_list_old;folder_name];
        end

        %- Sometimes there are problems with the list-box value
        if isempty(get(handles.listbox_files,'Value'))
            set(handles.listbox_files,'Value',1);
        end

        set(handles.listbox_files,'String',str_list_new);

        %- Save results
        guidata(hObject, handles); 

    end

    
    %- Ask if more folders should be added
    choice = questdlg('Add another folder for quantification?','FQ-batch', 'Yes','No','Yes'); 
end


%=== Delete selected file
function button_folder_delete_Callback(hObject, eventdata, handles)

str_list = get(handles.listbox_files,'String');

if not(isempty(str_list))

    %- Ask user to confirm choice
    choice = questdlg('Do you really want to remove this folder?', 'FISH-QUANT', 'Yes','No','No');

    if strcmp(choice,'Yes')

        %- Extract index of highlighted cell
        ind_sel  = get(handles.listbox_files,'Value');

        %- Delete highlighted cell
        str_list(ind_sel) = [];
        set(handles.listbox_files,'String',str_list)
        handles.file_list(ind_sel) = [];
        
        %- Save results
        guidata(hObject, handles);    
        
        %- Update status
        set(handles.listbox_files,'Value',1)
    end
end


%== Delete all files
function button_delete_all_Callback(hObject, eventdata, handles)

%- Ask user to confirm choice
choice = questdlg('Do you really want to remove all folders?', 'FISH-QUANT', 'Yes','No','No');

if strcmp(choice,'Yes')
    
    set(handles.listbox_files,'String',{})
    set(handles.listbox_files,'Value',1)
    handles.file_list = {};
    
    %- Save results
    guidata(hObject, handles);
end



%==========================================================================
% Processing
%==========================================================================

%== Process all files
function button_process_Callback(hObject, eventdata, handles)

set(handles.h_gui_FQ_batch_folder,'Pointer','watch');

%- Get parameters of analysis
file_ext              = get(handles.text_file_ext,'String');
flag_struct.parallel  = get(handles.checkbox_parallel_computing,'Value');
handles.status_outline_unique_enable = 0;

flag_save_indiv       = get(handles.checkbox_save_results_indiv,'Value');
flag_save_threshold   = get(handles.checkbox_save_threshold,'Value');


%- Fitting range
mode_fit        = 'sigma_free_xz';
par_start       = [];
handles.par_fit = [];

%- Get files
file_list = get(handles.listbox_files,'String');
N_folder  = length(file_list);

%- Loop over all folders   
for i_folder = 1:N_folder
    
    disp(' ')
    disp(['++++++ Folder ', num2str(i_folder) , ' of ', num2str(N_folder), ' +++']) 
    flag_continue = 1;
    
    %- Get content of folder
    dir_path = file_list{i_folder};
    
    disp(' ')
    disp(['=== Folder: ', dir_path])
    
    dir_struct     = dir(dir_path);
    [sorted_names] = sortrows({dir_struct.name}');
    
    %- Find settings file
    cell_ind_settings = strfind(sorted_names,'_settings_');
    ind_sett_file = find(~cellfun(@isempty, cell_ind_settings));
    
    if ~isempty(ind_sett_file)
        name_sett = sorted_names{ind_sett_file};
        disp(['Settings-file: ', name_sett])
        
    else
        
        disp('No SETTINGS file found')
        flag_continue = 0;
    end
    
    %- Find image-files
    cell_ind_img = strfind(sorted_names,file_ext);
    ind_img_file = find(~cellfun(@isempty, cell_ind_img));
    
    if ~isempty(ind_img_file)       
        disp(['# of image files: ', num2str(length(ind_img_file))])
    else
        
        disp('No IMAGE file(s) found')
        flag_continue = 0;
    end    
    

    %====== Continue only if settings and image files were found
    if flag_continue
        
        %- Parameters to save results
        handles.file_summary   = [];
        handles.cell_summary   = {};
        handles.cell_counter   = 1;

        handles.TS_summary     = {};
        handles.TS_counter     = 1;

        handles.spots_fit_all  = [];
        handles.thresh_all     = [];
        handles.spots_range    = [];

             
        %======= Load settings
        name_full = fullfile(dir_path,name_sett);
        handles = FISH_QUANT_load_settings_v3(name_full,handles);   
        handles.file_name_settings = dir_path;
        handles.path_name_settings = name_sett;    

        %- Check if there are limits
        if not(isfield(handles,'fit_limits'))
           handles.fit_limits.sigma_xy_min = 0;
           handles.fit_limits.sigma_xy_max = 1000;

           handles.fit_limits.sigma_z_min = 0;
           handles.fit_limits.sigma_z_max = 2000;
        end

        %======= Setup fit
        fit_limits = handles.fit_limits;
        bound.lb = [fit_limits.sigma_xy_min fit_limits.sigma_z_min -inf -inf -inf 0   0]; 
        bound.ub = [fit_limits.sigma_xy_max fit_limits.sigma_z_max inf  inf  inf  inf inf];

        %--- Path for saving results
        path_save_results  = dir_path; 
        parameters.path_name_image   = dir_path;
        parameters.path_name_outline = [];
        parameters.path_name_list    = dir_path;    
            
        
        %- Path to files in list
        %parameters.path_name_list     = handles.path_name_list;
        
        %- Other parameters
        parameters.mode_fit           = mode_fit;
        parameters.par_start          = par_start;
        parameters.bound              = bound;
        parameters.par_microscope     = handles.par_microscope;
        parameters.file_name_settings = handles.file_name_settings;
        parameters.flag_struct        = flag_struct; 
        parameters.name_filtered       = handles.name_filtered;
        
        %- Other parameters
        cell_counter = handles.cell_counter;
        cell_summary = handles.cell_summary;
        file_summary = handles.file_summary;
            
        %=== LOOP OVER ALL FILES and ALL CELLS    
        N_file = length(ind_img_file);
        
        for i_file=1:N_file
        

            %======= Get image
            name_img = sorted_names{ind_img_file(i_file)};             
            disp(['== Processing file ', num2str(i_file), ' of ', num2str(N_file)]);
            disp(['Processing image: ', name_img])
            
            
            %- Process files  
            parameters.file_name_load = name_img; 
            [cell_prop, par_microscope, file_names, status_file_ok] = spot_detect_fit_v31(handles,parameters);  
            
            file_summary(i_file).file_name_list   = name_img;
            file_summary(i_file).file_names       = file_names;
            file_summary(i_file).par_microscope   = par_microscope;
            file_summary(i_file).status_file_ok   = status_file_ok;
            
            %- Summarize results and loop over all processed cells for this file
            N_cell =  size(cell_prop,2);
        
            if N_cell == 0
                
                file_summary(i_file).cells.start = [];
                file_summary(i_file).cells.end   = [];        
                
            else
                file_summary(i_file).cells.start = cell_counter;
           
                for i_cell = 1:N_cell
        
                    N_total                                               = size(cell_prop(i_cell).spots_fit,1);        
                    cell_summary(cell_counter,1).name_list                = name_img; %file_list{i_file};
                    cell_summary(cell_counter,1).name_image               = file_names.raw;
                    cell_summary(cell_counter,1).file_name_image_filtered = file_names.filtered;
                    cell_summary(cell_counter,1).cell                     = cell_prop(i_cell).label;
                    cell_summary(cell_counter,1).N_total                  = N_total;
                    cell_summary(cell_counter,1).spots_fit                = cell_prop(i_cell).spots_fit;
                    cell_summary(cell_counter,1).spots_detected           = cell_prop(i_cell).spots_detected;
                    cell_summary(cell_counter,1).thresh.in                = ones(size(cell_prop(i_cell).spots_fit,1),1);
        
                    cell_summary(cell_counter,1).label                    = cell_prop(i_cell).label; 
                    cell_summary(cell_counter,1).x                        = cell_prop(i_cell).x; 
                    cell_summary(cell_counter,1).y                        = cell_prop(i_cell).y;  
                    cell_summary(cell_counter,1).pos_TS                   = cell_prop(i_cell).pos_TS; 
                    cell_summary(cell_counter,1).pos_Nuc                  = cell_prop(i_cell).pos_Nuc;   
                    
                    %-Get area of cell and nucleus
                    area_cell = polyarea(cell_prop(i_cell).x,cell_prop(i_cell).y);
                    
                    if ~isempty(cell_prop(i_cell).pos_Nuc)
                        area_nuc = polyarea(cell_prop(i_cell).pos_Nuc.x,cell_prop(i_cell).pos_Nuc.y);
                    else
                        area_nuc = 0;
                    end
        
                    cell_summary(cell_counter,1).area_cell = area_cell;
                    cell_summary(cell_counter,1).area_nuc  = area_nuc;
                    
                    
                    
                    %=== ADD thresholding 
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    %- Update cell counter
                    cell_counter = cell_counter +1;
                      
                end
            
                file_summary(i_file).cells.end = cell_counter-1;
            end
           
           handles.cell_summary       = cell_summary;
           handles.file_summary       = file_summary;
           handles.cell_counter       = cell_counter;
           handles.i_file_proc_mature = i_file+1;
           
            
        end
        
        handles.cell_summary = cell_summary; 
        handles.file_summary = file_summary;
        
        
%         %- Analyze and save results
%         handles.status_fit = 1;
%         handles = results_summarize(hObject, eventdata, handles);
%         
%         if not(isempty(handles.spots_fit_all))
%             handles = results_analyse(hObject, eventdata, handles);
%             handles = pop_up_threshold_Callback(hObject, eventdata, handles);
%             guidata(hObject, handles); 
%         else
%             status_text = {' ';'NO SPOTS DETECTED'};
%             status_update(hObject, eventdata, handles,status_text); 
%         end
        
            %==== SAVE RESULTS
            handles.path_name_results = path_save_results;
            handles.file_name_settings_new = name_sett;
            handles.path_name_image   = dir_path;
            handles.version = 'v2d';

           %- Save results of individual images
           if flag_save_indiv   
                save_results_image(hObject, eventdata, handles,0)
           end   

            %- Save summary
            save_summary_spots(hObject, eventdata, handles,flag_save_threshold)


        %- Auto-save
%         if flag_save_threshold 
%             file_name      = ['_FQ_analysis_AUTOSAVE_', datestr(date,'yymmdd'), '.mat'];
%             file_name_full = fullfile(path_save_results,file_name);       
%             FQ_batch_save_handles_v3(file_name_full,handles);
%         else
%             
%         end  
    end
end

set(handles.h_gui_FQ_batch_folder,'Pointer','arrow');



%== Save results of individual image
function save_results_image(hObject, eventdata, handles,flag_threshold)


%- Save settings
path_save = handles.path_name_results;
suffix_results = handles.file_name_suffix_spots; 

%- Save results of individual images
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

        %- Save results
        [dum, name_file] = fileparts(file_name_list); 

        file_name_save   = [name_file,suffix_results];
        file_name_full   = fullfile(path_save,file_name_save);    

        parameters.cell_prop           = cell_prop;
        parameters.par_microscope      = par_microscope;
        parameters.path_save           = path_save;
        parameters.path_name_image     = handles.path_name_image;
        parameters.file_names          = file_names;
        parameters.version             = handles.version;
        parameters.flag_type           = 'spots';  
        parameters.flag_th_only        = 0;

        FQ_save_results_v1(file_name_full,parameters);     
    end
 end



%== Save summary of all spots
function save_summary_spots(hObject, eventdata, handles,flag_threshold)


%- User-dialog for file-name
name_default   = ['_FISH-QUANT__all_spots_', datestr(date,'yymmdd'), '.txt'];
file_name_full = fullfile(handles.path_name_results,name_default);    
       
%- Save results       
options.flag_label = 2;        %- File-identifier as row label
options.file_id_start         = handles.settings_save.file_id_start;
options.file_id_end           = handles.settings_save.file_id_end;

options.flag_only_thresholded = flag_threshold; 
FISH_QUANT_save_results_all_v7(file_name_full,handles.file_summary,handles.cell_summary,handles.par_microscope,handles.path_name_image,handles.file_name_settings_new,handles.version,options);




% =========================================================================
% VARIOUS FUNCTIONS
% =========================================================================

%== Activate parallel computing
function checkbox_parallel_computing_Callback(hObject, eventdata, handles)

flag_parallel = get(handles.checkbox_parallel_computing,'Value');

if exist('matlabpool')

    %- Parallel computing - open MATLAB session for parallel computation 
    if flag_parallel == 1    
        isOpen = matlabpool('size') > 0;
        if (isOpen==0)

            %- Update status
            set(handles.h_gui_FQ_batch_folder,'Pointer','watch');
            status_text = {' ';'== STARTING matlabpool for parallel computing ... please wait ... '};
            status_update(hObject, eventdata, handles,status_text);

            matlabpool open;

            %- Update status
            status_text = {' ';'    ... STARTED'};
            status_update(hObject, eventdata, handles,status_text);        
            set(handles.h_gui_FQ_batch_folder,'Pointer','arrow');
        end

    %- Parallel computing - close MATLAB session for parallel computation     
    else
        isOpen = matlabpool('size') > 0;
        if (isOpen==1)

            %- Update status
            set(handles.h_gui_FQ_batch_folder,'Pointer','watch');
            status_text = {' ';'== STOPPING matlabpool for parallel computing ... please wait ... '};
            status_update(hObject, eventdata, handles,status_text);

            matlabpool close;

            %- Update status
            status_text = {' ';'    ... STOPPED'};
            status_update(hObject, eventdata, handles,status_text);
            set(handles.h_gui_FQ_batch_folder,'Pointer','arrow');
        end
    end
else
    warndlg('Parallel toolbox not available','FISH_QUANT')
    set(handles.checkbox_parallel_computing,'Value',0);
end


%== Update status
function status_update(hObject, eventdata, handles,status_text)
status_old = get(handles.listbox_status,'String');
status_new = [status_old;status_text];
set(handles.listbox_status,'String',status_new)
set(handles.listbox_status,'ListboxTop',round(size(status_new,1)))
drawnow
guidata(hObject, handles); 




%== Settings to save summary file
function button_settings_summary_file_Callback(hObject, eventdata, handles)
handles.settings_save = FQ_change_setting_save_v2(handles.settings_save);
status_update(hObject, eventdata, handles,{'  ';'## Settings for SAVING are modified'});         
guidata(hObject, handles);



%==========================================================================
% Not used
%==========================================================================

function listbox_files_Callback(hObject, eventdata, handles)

function listbox_files_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_save_results_indiv_Callback(hObject, eventdata, handles)

function checkbox_save_threshold_Callback(hObject, eventdata, handles)

function text_file_ext_Callback(hObject, eventdata, handles)

function text_file_ext_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function checkbox_advanced_folder_selection_Callback(hObject, eventdata, handles)

function listbox_status_Callback(hObject, eventdata, handles)

function listbox_status_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
