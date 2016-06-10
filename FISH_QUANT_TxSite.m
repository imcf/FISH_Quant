function varargout = FISH_QUANT_TxSite(varargin)
% FISH_QUANT_TXSITE MATLAB code for FISH_QUANT_TxSite.fig
% Last Modified by GUIDE v2.5 18-Apr-2014 11:26:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FISH_QUANT_TxSite_OpeningFcn, ...
                   'gui_OutputFcn',  @FISH_QUANT_TxSite_OutputFcn, ...
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


% --- Executes just before FISH_QUANT_TxSite is made visible.
function FISH_QUANT_TxSite_OpeningFcn(hObject, eventdata, handles, varargin)

%- Set font-size to 10
%  For whatever reason are all the fonts on windows are set back to 8 when the .fig is openend
h_font_8 = findobj(handles.h_FQ_TxSite,'FontSize',8);
set(h_font_8,'FontSize',10)
    
%- Export figure handle to workspace - will be used in Close All button of main Interface
assignin('base','h_TxSite',handles.h_FQ_TxSite)

%- Columns of results file
handles.col_par = FQ_define_col_results_v1; 

%=== Options for TxSite quantification
% %    Initiate only once then use global
% global parameters_quant
% if isempty(parameters_quant)
% 	parameters_quant = FQ_TS_settings_init_v3;
% end

%- Some parameters
handles.status_PSF   = 0;
handles.status_BGD   = 0;
handles.status_AMP   = 0;
handles.status_AMP_PROC = 0;
handles.status_PSF_PROC  = 0;
handles.status_QUANT = 0;
handles.status_QUANT_ALL = 0;
handles.status_auto_detect = 0;
handles.img.cell_prop    = {};
handles.file_name_image = [];
handles.status_TS_simple_only = 0;

%- Default for PSF quantification
handles.status_TS_simple_only = 1;
handles.bgd_value  = 0;

% File-names for PSF and BGD
handles.PSF_path_name = [];
handles.PSF_file_name = [];
handles.BGD_path_name = [];
handles.BGD_file_name = [];
handles.AMP_path_name = [];
handles.AMP_file_name = [];

%- File-names
handles.file_names.raw =[];


%- File-name for settings
handles.file_name_settings_TS = [];

%- Default for oversampling
handles.fact_os.xy = 1;
handles.fact_os.z  = 1;

%- Check if called from another GUI

if not(isempty(varargin))
    
    if      strcmp( varargin{1},'HandlesMainGui') 
        
        %- Read data from Main GUI
        handles_MAIN = varargin{2};
        
        %- Get folder structure of main interface
        handles.img = handles_MAIN.img;        
        
        if not(isempty(handles.img.cell_prop))
            ind_cell           = get(handles_MAIN.pop_up_outline_sel_cell,'Value');
            str_cells          = get(handles_MAIN.pop_up_outline_sel_cell,'String');

            %- Change name of GUI
            set(handles.h_FQ_TxSite,'Name', ['FISH-QUANT ', handles.img.version, ': TxSite quantification']);           

            %- Save everything
            guidata(hObject, handles); 

            set(handles.text_data,'String','IMG defined')
            set(handles.text_data,'ForegroundColor','g')
            
            set(handles.pop_up_outline_sel_cell,'String',str_cells);
            set(handles.pop_up_outline_sel_cell,'Value',ind_cell);           
            
            %- Analyze selected cell and plot
            handles = analyze_cellprop(hObject, eventdata, handles);
            pop_up_outline_sel_cell_Callback(hObject, eventdata, handles);
            plot_image(handles,handles.axes_main);            
            
        end
    end
end


% Update handles structure
handles.output = hObject;
guidata(hObject, handles);
enable_controls(hObject, eventdata, handles)


% --- Outputs from this function are returned to the command line.
function varargout = FISH_QUANT_TxSite_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



%==========================================================================
%==== TxSite quantification: enable
%==========================================================================

function enable_controls(hObject, eventdata, handles)

%- Change name of GUI
if not(isempty(handles.img.file_names.raw))
    set(handles.h_FQ_TxSite,'Name', ['FISH-QUANT ', handles.img.version, ': TS quant - ', handles.img.file_names.raw ]);
else
    set(handles.h_FQ_TxSite,'Name', ['FISH-QUANT ', handles.img.version, ': TS quant']);
end

%- Enable selection of cells and TS
if   not(isempty(handles.img.cell_prop))
    set(handles.pop_up_outline_sel_cell,'Enable','on');
    set(handles.pop_up_outline_sel_TS,'Enable','on');
else
    set(handles.pop_up_outline_sel_cell,'Enable','off');   
    set(handles.pop_up_outline_sel_TS,'Enable','off');   
end


%- Only simple TS quantification

if handles.status_TS_simple_only

    %- Enable processing of PSF
    if   handles.status_PSF 
        set(handles.button_process,'Enable','on');
        set(handles.button_process_all,'Enable','on');
        
        set(handles.text_PSF_img,'String','Image of mRNA defined')
        set(handles.text_PSF_img,'ForegroundColor','g')
        
    else
        set(handles.button_process,'Enable','off');   
        set(handles.button_process_all,'Enable','off');  
        
        set(handles.text_PSF_img,'String','Define image of mRNA')
        set(handles.text_PSF_img,'ForegroundColor','r')
    end
    
    
else
    
    %- Enable processing of PSF
    if   handles.status_PSF && handles.status_BGD
        set(handles.button_analyze_PSF,'Enable','on');
    else
        set(handles.button_analyze_PSF,'Enable','off');   
    end

    %- Enable processing
    if   handles.status_PSF_PROC
        set(handles.button_process,'Enable','on');
        set(handles.button_process_all,'Enable','on');
    else
        set(handles.button_process,'Enable','off');   
        set(handles.button_process_all,'Enable','off');   
    end


    %- Visualize results
    if   handles.status_QUANT
        set(handles.button_visualize_results,'Enable','on');    
        set(handles.menu_save_settings,'Enable','on');    
  
    else
        set(handles.button_visualize_results,'Enable','off');
        set(handles.menu_save_settings,'Enable','off'); 
    end

    %- Restrict size
    if handles.status_QUANT && not(handles.status_TS_simple_only)
        set(handles.button_TS_restrict_size,'Enable','on');  
        set(handles.button_visualize_results,'Enable','on');  
    else
        set(handles.button_TS_restrict_size,'Enable','off');
        set(handles.button_visualize_results,'Enable','off'); 
    end

    %- Restrict size for all sites
    if handles.status_QUANT && not(handles.status_TS_simple_only) && handles.status_QUANT_ALL
        set(handles.button_TS_restrict_size_all,'Enable','on');  
    else
         set(handles.button_TS_restrict_size_all,'Enable','off');     
    end


end


%- Enable saving processing
if   handles.status_QUANT_ALL
    set(handles.menu_save_quantification,'Enable','on');   
else
    set(handles.menu_save_quantification,'Enable','off');   
end
    
    
%==========================================================================
%==== Load image data
%==========================================================================

function button_load_data_Callback(hObject, eventdata, handles)

%- Load new outline
status_open = load_results(handles.img,[],[]);

%- Continue only if outline and image were loaded
if status_open.outline && status_open.img
    
    %- Analyze detected regions
    status_update(hObject, eventdata, handles,{'Outlines loaded.'})           
    handles = analyze_cellprop(hObject, eventdata, handles);   
    
    %- Save everything
    guidata(hObject, handles); 
    
    %- Update status
    set(handles.text_data,'String','IMG defined')
    set(handles.text_data,'ForegroundColor','g')    
        
    %- Analyze selected cell and plot
    pop_up_outline_sel_cell_Callback(hObject, eventdata, handles)
    plot_image(handles,handles.axes_main)
end


%= Function to analyze detected regions
function handles = analyze_cellprop(hObject, eventdata, handles)

cell_prop = handles.img.cell_prop;

%- Populate pop-up menu with labels of cells
N_cell = size(cell_prop,2);

if N_cell > 0

    %- Call pop-up function to show results and bring values into GUI
    for i = 1:N_cell
        str_menu{i,1} = cell_prop(i).label;
        
        %- Analyze transcription sites
        pos_TS = cell_prop(i).pos_TS;       
        N_TS   =  size(pos_TS,2);
        
        if N_TS == 0
            str_menu_TS = {' '};
        else
            str_menu_TS = {};

            for i_TS = 1:N_TS
                str_menu_TS{i_TS,1} = pos_TS(i_TS).label; 
                cell_prop(i).pos_TS(i_TS).status_QUANT = 0;
            end    
        end
        
        cell_prop(i).str_menu_TS = str_menu_TS;
    end  
else
    str_menu = {' '};
end

%- Save everything
handles.img.cell_prop = cell_prop;
guidata(hObject, handles); 

%- Save and analyze results
set(handles.pop_up_outline_sel_cell,'String',str_menu);
set(handles.pop_up_outline_sel_cell,'Value',1);

set(handles.pop_up_outline_sel_TS,'String',cell_prop(1).str_menu_TS);
set(handles.pop_up_outline_sel_TS,'Value',1);

    
%- Enable outline selection
enable_controls(hObject, eventdata, handles)
status_update(hObject, eventdata, handles,{'Outlines analyzed.'})        


%==========================================================================
%==== Settings
%==========================================================================

%=== Load settings
function menu_load_settings_Callback(hObject, eventdata, handles)

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
[file_name_settings_TS,path_name_settings_TS] = uigetfile({'*.txt'},'Select file with settings for TS quantification');

if file_name_settings_TS ~= 0

    %- Load settings
    handles.img.load_settings_TS(fullfile(path_name_settings_TS,file_name_settings_TS));
    
    handles.file_name_settings_TS = file_name_settings_TS;
    handles.path_name_settings_TS = path_name_settings_TS;   
    
    %- Check if only simple methods
    if ~handles.img.settings.TS_quant.flags.quant_simple_only
        set(handles.checkbox_flag_GaussMix,'Value', 1);
        checkbox_flag_GaussMix_Callback(hObject, eventdata, handles)
    end
    
    %- File-name of image
    set(handles.text_PSF_img,'String','NOT defined')
    set(handles.text_PSF_img,'ForegroundColor','r')
    handles.status_PSF = 0; 
    
    if isfield(handles.img.mRNA_prop, 'file_name')

        PSF_name_full = fullfile(handles.img.mRNA_prop.path_name, handles.img.mRNA_prop.file_name);
        
        if exist(PSF_name_full,'file') ~= 2
            PSF_name_full = fullfile(handles.path_name_settings_TS, handles.PSF_file_name);
            
            if exist(PSF_name_full,'file') == 2
                set(handles.text_PSF_img,'String','Image defined')
                set(handles.text_PSF_img,'ForegroundColor','g')
                handles.status_PSF = 1; 
                
                handles.PSF_path_name = handles.path_name_settings_TS;
            end
        else
            set(handles.text_PSF_img,'String','Image defined')
            set(handles.text_PSF_img,'ForegroundColor','g')
            handles.status_PSF = 1;  
        end
    end

   %- BGD value 
   if isfield(handles.img.mRNA_prop, 'bgd_value') || isfield(handles.img.mRNA_prop, 'BGD_file_name') 
        set(handles.text_PSF_bgd,'String','BGD defined')
        set(handles.text_PSF_bgd,'ForegroundColor','g')
        handles.status_BGD = 1;        
   end
     
   if handles.img.settings.TS_quant.flags.bgd_local
       set(handles.button_TS_bgd,'Value',0);
   else
       set(handles.button_TS_bgd,'Value',1);
       set(handles.txt_TS_bgd,'String',num2str(parameters_quant.BGD.amp));
   end   
   
   %=== Amplitudes
    handles.status_AMP = 0;
    text_update_amp = '## File with amplitudes was NOT defined';

    if isfield(handles,'AMP_path_name')  && isfield(handles,'AMP_file_name')                
        if not(isempty(handles.AMP_file_name))
            
            if isempty(handles.AMP_path_name)
                name_full_1 = fullfile(handles.path_name_settings_TS,handles.AMP_file_name );
            else
                name_full_1 = fullfile(handles.AMP_path_name,handles.AMP_file_name );
            end
 
            name_full_2 = fullfile(handles.path_name_settings_TS,handles.AMP_file_name );
            exist_1 = (exist(name_full_1,'file') == 2);
            exist_2 = (exist(name_full_2,'file') == 2);

            %- Check if one of the names exists
            if exist_1  || exist_2 

                if exist_1
                    cell_prop = FQ_load_results_WRAPPER_v1(name_full_1);
                else
                    cell_prop = FQ_load_results_WRAPPER_v1(name_full_2);
                    handles.AMP_path_name = path_name_settings_TS;
                end

                spots_fit      = cell_prop(1).spots_fit;
                spots_detected = cell_prop(1).spots_detected;
                thresh.in      = logical(cell_prop(1).thresh.in);

                if not(isempty(spots_fit))

                    handles.spots_fit      = spots_fit;
                    handles.spots_detected = spots_detected;
                    handles.thresh         = thresh;
                    handles = analyze_AMP(hObject, eventdata, handles);   
                else
                    text_update_amp = {'  '; ...
                                   '## NO SPOTS FOUND in file. Amplitudes are NOT defined'};        
                end     
            end 
        end      
    end
   
   %- Update status
   guidata(hObject, handles); 
   enable_controls(hObject, eventdata, handles)    
end

%- Go back to original directory
cd(current_dir) 


%=== Save settings
function menu_save_settings_Callback(hObject, eventdata, handles)

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

[handles.file_name_settings_TS, handles.path_name_settings_TS] = handles.img.save_settings_TS([]);
guidata(hObject, handles);

%- Go back to original directory
cd(current_dir) 



%==========================================================================
%==== TxSite quantification: parameters, options, and quantificatiion
%==========================================================================

%=== Load image of PSF
function button_PSF_img_Callback(hObject, eventdata, handles)

%- Load PSF
set(handles.h_FQ_TxSite,'Pointer','watch');
handles.img = handles.img.load_mRNA_avg([]);
set(handles.h_FQ_TxSite,'Pointer','arrow');

%- Continue if PSF is loaded
if handles.img.status_mRNA_avg
    
    %- Update status
    handles.status_PSF = 1;
    text_update = {'  '; '## Averaged image of mRNA defined.';handles.img.mRNA_prop.file_name};        
    status_update(hObject, eventdata, handles,text_update);         
    guidata(hObject, handles); 
end


%=== Quantify transcription site
function handles = button_process_Callback(hObject, eventdata, handles)


%== Update status and change cursor
status_text = {' ';'== Transcription site quantification: STARTED ...'};
status_update(hObject, eventdata, handles,status_text); 
set(handles.h_FQ_TxSite,'Pointer','watch'); %= Pointer to watch

%== What type of quantification
handles.img.settings.TS_quant.flags.quant_simple_only = not(get(handles.checkbox_flag_GaussMix,'Value'));
handles.status_TS_simple_only                         = handles.img.settings.TS_quant.flags.quant_simple_only;

%== Some flags
handles.img.settings.TS_quant.flags.output      = get(handles.checkbox_output,'Value'); 

%== Background
if get(handles.button_TS_bgd,'Value') == 1
    handles.img.settings.TS_quant.flags.bgd_local = 0;
    handles.img.settings.TS_quant.BGD.amp         = str2num(get(handles.txt_TS_bgd,'String'));  

else
    handles.img.settings.TS_quant.flags.bgd_local = 2;    
end
   
%== Specify files to save results
handles.img.settings.TS_quant.file_name_save_STATUS    = [];
handles.img.settings.TS_quant.file_name_save_PLOTS_PS  = [];
handles.img.settings.TS_quant.file_name_save_PLOTS_PDF = [];

%== Which cell and which TS
ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');            
ind_TS    = get(handles.pop_up_outline_sel_TS,'Value');

%== Start quantification
status_text = handles.img.TS_quant(ind_cell,ind_TS);

status_update(hObject, eventdata, handles,status_text);
set(handles.h_FQ_TxSite,'Pointer','arrow');

%- Save results
guidata(hObject, handles); 

%- Plot summary of quantification
if ~handles.status_TS_simple_only
    axes(handles.axes_main)
    cla(handles.axes_main,'reset')
    plot(handles.img.cell_prop(ind_cell).pos_TS(ind_TS).REC_prop.summary_Q_run_N_MRNA,  handles.img.cell_prop(ind_cell).pos_TS(ind_TS).REC_prop.mean_Q)
    v = axis; axis(v)    
    xlabel('Number of placed mRNA')
    ylabel('Quality score')
    title(['Estimated # of nascent transcripts: ', num2str(round(handles.img.cell_prop(ind_cell).pos_TS(ind_TS).TxSite_quant.N_mRNA_TS_global ))])
    
else
    pop_up_outline_sel_TS_Callback(hObject, eventdata, handles)
end



%=== Quantify transcription site
function button_process_all_Callback(hObject, eventdata, handles)

%- Old selections
ind_cell_old = get(handles.pop_up_outline_sel_cell,'Value');
ind_TS_old   = get(handles.pop_up_outline_sel_TS,'Value');

%- Loop over all cells
cell_prop = handles.img.cell_prop;
N_cell    = length(cell_prop);

TS_counter = 1;

for i_cell = 1:N_cell
    
    set(handles.pop_up_outline_sel_cell,'Value',i_cell);
    
    %- Get TS
    pos_TS      = cell_prop(i_cell).pos_TS;
    N_TS        = length(pos_TS);

    %- Update list with TS names (otherwise warnings)
    str_menu_TS = cell_prop(i_cell).str_menu_TS;
    set(handles.pop_up_outline_sel_TS,'String',str_menu_TS);
    
    
    for i_TS = 1:N_TS
        
        TS_look_up(i_TS,:) = [i_cell i_TS];
        
        %== New selection for TxSite
        set(handles.pop_up_outline_sel_TS,'Value',i_TS);
        
        %== Process the selection
        handles = button_process_Callback(hObject, eventdata, handles);
        
        %== Save results         
        TS_summary(TS_counter).file_name_image = handles.file_name_image;
        TS_summary(TS_counter).file_name_list  = handles.file_name_image;
        TS_summary(TS_counter).TxSite_quant    = handles.img.cell_prop(i_cell).pos_TS(i_TS).TxSite_quant;
        TS_summary(TS_counter).TS_rec          = handles.img.cell_prop(i_cell).pos_TS(i_TS).TS_rec;
        TS_summary(TS_counter).Q_all           = handles.img.cell_prop(i_cell).pos_TS(i_TS).Q_all;
        TS_summary(TS_counter).REC_prop        = handles.img.cell_prop(i_cell).pos_TS(i_TS).REC_prop;
        TS_summary(TS_counter).TS_analysis_results    = handles.img.cell_prop(i_cell).pos_TS(i_TS).TS_analysis_results;
        TS_summary(TS_counter).cell_label      = handles.img.cell_prop(i_cell).label;
        TS_summary(TS_counter).TS_label        = handles.img.cell_prop(i_cell).pos_TS(i_TS).label;
        TS_counter = TS_counter +1;
    end
end


%- Save results
handles.TS_summary = TS_summary;
handles.TS_look_up = TS_look_up;
handles.status_QUANT_ALL = 1;
guidata(hObject, handles); 
set(handles.pop_up_outline_sel_cell,'Value',ind_cell_old);
set(handles.pop_up_outline_sel_TS,'Value',ind_TS_old);
enable_controls(hObject, eventdata, handles)


%=== Define background
function button_PSF_bgd_Callback(hObject, eventdata, handles)


choice = questdlg('Background subtraction with file or scalar value?', 'Background subtraction', 'Scalar','File','Scalar');

if not(strcmp(choice,''))

    switch (choice)
        case 'Scalar'
            

            dlgTitle = 'Background';
            prompt(1) = {'Value'};
            defaultValue{1} = '0';
            userValue = inputdlg(prompt,dlgTitle,1,defaultValue);

            if( ~ isempty(userValue))
                bgd_value = str2double(userValue{1});
            
                handles.img.mRNA_prop.BGD_file_name = [];
                handles.img.mRNA_prop.BGD_path_name = []; 
                
                handles.img.mRNA_prop.bgd_value     = bgd_value;
                
                %- Update status
                set(handles.text_PSF_bgd,'String','BGD defined')
                set(handles.text_PSF_bgd,'ForegroundColor','g')
                handles.status_BGD = 1;        

                %- Update status
                text_update = {'  '; ['## BGD defined. Scalar: ', num2str(bgd_value)]};        
                status_update(hObject, eventdata, handles,text_update);         
                guidata(hObject, handles);
                
                
            end
            
      
        case 'File'
            [BGD_file_name,BGD_path_name] = uigetfile('.tif','Select 3D-image of BGD - cancel for no bgd','MultiSelect','off');

            if BGD_file_name ~= 0
                handles.img.mRNA_prop.BGD_file_name = BGD_file_name;
                handles.img.mRNA_prop.BGD_path_name = BGD_path_name; 
                handles.img.mRNA_prop.bgd_value     = 0;
                
                %- Update status
                set(handles.text_PSF_bgd,'String','BGD defined')
                set(handles.text_PSF_bgd,'ForegroundColor','g')
                handles.status_BGD = 1;        

                %- Update status
                text_update = {'  '; '## BGD defined';handles.BGD_file_name};        
                status_update(hObject, eventdata, handles,text_update);         
                guidata(hObject, handles);
            end
            
    end

else
    handles.img.mRNA_prop.BGD_file_name = [];
    handles.img.mRNA_prop.BGD_path_name = []; 
    handles.img.mRNA_prop.bgd_value     = 0;   
    
    %- Update status
    set(handles.text_PSF_bgd,'String','NO BGD correction')
    set(handles.text_PSF_bgd,'ForegroundColor','g')
    handles.status_BGD = 1;        

    %- Update status
    text_update = {'  '; '## BGD will NOT be corrected'};        
    status_update(hObject, eventdata, handles,text_update);         
    guidata(hObject, handles); 
    
end

                
%=== Define amplitude
function button_PSF_amp_Callback(hObject, eventdata, handles)

choice = questdlg('Use current value OR load from file', 'Amplitudes of mRNA', 'File','Current analysis','File');
set(handles.h_FQ_TxSite,'Pointer','watch');
text_update = {'  '; '## DEFINING Amplitudes for TxSite quantification'; '... please wait ... '};        
status_update(hObject, eventdata, handles,text_update);

if not(strcmp(choice,''))

    switch (choice)
        case 'Current analysis'
            
            if isempty(handles.img.cell_prop(1).spots_fit)                              
                warndlg('No results of spot detection in current analysis','mRNA - define amplitude')
                return
            else
                
                ind_cell        = get(handles.pop_up_outline_sel_cell,'Value');
                spots_fit       = handles.img.cell_prop(ind_cell).spots_fit;
                spots_detected  = handles.img.cell_prop(ind_cell).spots_detected;
                thresh.in       = handles.img.cell_prop(ind_cell).thresh.in;
                handles.img.mRNA_prop.AMP_file_name = 'current analysis';
                handles.img.mRNA_prop.AMP_path_name = 'current analysis';
            end

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
            
            %- Load file
            img_dum = FQ_img;
            spots_fit = [];
            spots_detected = [];
                
            [file_name_results,path_name_results] = uigetfile({'*.txt'},'Select file with results of spot detection','MultiSelect', 'off');
            
            if file_name_results ~= 0 
                
                status_open = img_dum.load_results(fullfile(path_name_results,file_name_results),-1);  % -1 means don't open image
            
                if status_open.outline
                    handles.img.mRNA_prop.AMP_file_name = file_name_results;
                    handles.img.mRNA_prop.AMP_path_name = path_name_results;        
                    spots_fit      = img_dum.cell_prop(1).spots_fit;
                    spots_detected = img_dum.cell_prop(1).spots_detected;
                
                    %- Make sure that spots are loaded - empty otherwise
                    if not(isempty(spots_fit))
                        thresh.in      = logical(img_dum.cell_prop(1).thresh.in);
                    else
                        text_update = {' ';'NO SPOTS FOUND IN FILE. Please check format. Results file has to be stored with NO labels for the spots';
                                   'Consult FISH-QUANt documentation for more details.'; ' ' };
                        status_update(hObject, eventdata, handles,text_update);
                    end
                end
            end
    end
    
    if not(isempty(spots_fit))
        
        %- Get amplitudes
        handles.spots_fit      = spots_fit;
        handles.spots_detected = spots_detected;
        handles.thresh         = thresh;
        handles = analyze_AMP(hObject, eventdata, handles);      
        
        button = questdlg({'Use distribution of mean value of mRNA amplitudes for quantification?';'If only integrated intensity is used choose Mean.'},'TxSite quantification','Distribution','Mean','Distribution');  
        handles.img.settings.TS_quant.flags.amp_quant = button;
        guidata(hObject, handles);
    end
                
end
set(handles.h_FQ_TxSite,'Pointer','arrow');


%=== Analyze AMP
function handles = analyze_AMP(hObject, eventdata, handles)

%- Get parameters
parameters.h_plot       = handles.axes_main;
parameters.col_par     = handles.img.col_par;
handles.img.mRNA_prop  = FQ_AMP_analyze_v3(handles.spots_fit,handles.spots_detected,handles.thresh,parameters,handles.img.mRNA_prop); 

%- Update status
handles.status_AMP = 1; 
guidata(hObject, handles);

%- Update status
set(handles.text_AMP,'String','AMPs defined')
set(handles.text_AMP,'ForegroundColor','g')

%- Update status
text_update = {'  '; ...
               '## Amplitudes defined'; ...
               'Fit with skewed normal distribution'; ...
               ['Mean:     ', num2str(handles.img.mRNA_prop.amp_mean )]; ...
               ['Sigma:    ', num2str(handles.img.mRNA_prop.amp_sigma)]; ...
               ['Skewness: ', num2str(handles.img.mRNA_prop.amp_skew)]; ...
               ['Kurtosis: ', num2str(handles.img.mRNA_prop.amp_kurt)]};        
status_update(hObject, eventdata, handles,text_update);


%=== Analyze PSF
function button_analyze_PSF_Callback(hObject, eventdata, handles)

set(handles.h_FQ_TxSite,'Pointer','watch'); %= Pointer to watch

%- Load PSF
name_load   = fullfile(handles.img.mRNA_prop.path_name,handles.img.mRNA_prop.file_name);
handles.img = handles.img.load_mRNA_avg(name_load);
% handles = load_PSF(hObject, eventdata, handles);

%- Update status
text_update = {'  '; ...
               '## Image of mRNA analysed!'};        
status_update(hObject, eventdata, handles,text_update);  

%- Test placements if amplitudes are defined
if handles.status_AMP
    handles = test_PSF_placements(hObject, eventdata, handles);
    handles.status_AMP_PROC = 1;
else
    handles.status_AMP_PROC = 0;
end

%- Save data
handles.status_PSF_PROC = 1; 

%- Update status
set(handles.text_PROC,'String','Settings analyzed')
set(handles.text_PROC,'ForegroundColor','g') 

text_update = {'  '; '## SETTINGS are analyzed.'};        
status_update(hObject, eventdata, handles,text_update); 
guidata(hObject, handles); 
set(handles.h_FQ_TxSite,'Pointer','arrow');


%== Test placements
function handles = test_PSF_placements(hObject, eventdata, handles)


%- Get relevant parameters
mRNA_prop      = handles.img.mRNA_prop;  
PSF_shift_all  = handles.img.mRNA_prop.PSF_shift;
N_PSF_shift    = length(PSF_shift_all);

%- Same cropping as for TS
par_crop_TS                = handles.img.settings.TS_quant.crop_image;
pixel_size                 = handles.img.par_microscope.pixel_size;
parameters_fit.par_crop.xy = par_crop_TS.xy_pix;
parameters_fit.par_crop.z  = par_crop_TS.z_pix;
parameters_fit.flags.crop  = 1;

%- Parameters for fitting
parameters_fit.pixel_size      = pixel_size;
parameters_fit.par_microscope  = handles.img.par_microscope ;
parameters_fit.flags.output    = 0;
    
%-- Perform a certain number of test placements
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


fprintf('Testing placements: (of %d):     1',N_total);

i_sim = 1;
fit_summ_loop = zeros(N_total,7);

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
fit_summ_loop_avg              = mean(fit_summ_loop,1);
handles.mRNA_prop.amp_mean_fit = fit_summ_loop_avg(3); 

%- Save data
guidata(hObject, handles); 


%== BGD of transcription site
function button_TS_bgd_Callback(hObject, eventdata, handles)
status_button = get(handles.button_TS_bgd,'Value');

if status_button == 1
    set(handles.txt_TS_bgd,'Enable','on');
else
    set(handles.txt_TS_bgd,'Enable','off');    
end



%==========================================================================
%====  PSF superposition approach
%==========================================================================

%=== Check 
function checkbox_flag_GaussMix_Callback(hObject, eventdata, handles)

status_use_PSF = get(handles.checkbox_flag_GaussMix,'Value');

if status_use_PSF
    handles.status_TS_simple_only = 0;
    
    set(handles.panel_PSF_superpos,'Visible','on');
    set(handles.panel_restrict_size,'Visible','on');
    
else
    handles.status_TS_simple_only = 1;   
    
    set(handles.panel_PSF_superpos,'Visible','off');
    set(handles.panel_restrict_size,'Visible','off');
    
end
enable_controls(hObject, eventdata, handles)
guidata(hObject, handles); 

%=== Restrict size of transcription site
function button_TS_restrict_size_Callback(hObject, eventdata, handles)


%- Get results of analysis
ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');

if not(isempty(handles.img.cell_prop(ind_cell).pos_TS))

    ind_TS    = get(handles.pop_up_outline_sel_TS,'Value');

    TS_rec      = handles.img.cell_prop(ind_cell).pos_TS(ind_TS).TS_rec;
    Q_all       = handles.img.cell_prop(ind_cell).pos_TS(ind_TS).Q_all;
    TS_analysis = handles.img.cell_prop(ind_cell).pos_TS(ind_TS).TS_analysis_results;  

    %- Parameters for restriction
    parameters                         = handles.img.settings.TS_quant;
    parameters.mRNA_prop               = handles.img.mRNA_prop;
    parameters.range_int               = handles.img.settings.TS_quant.range_int;
    parameters.fid                     = -1;
    parameters.flags.output            = 1;
    parameters.file_name_save_PLOTS_PS = [];
    parameters.dist_max                = str2double(get(handles.text_TS_dist_max,'String'));

    %- Restrict analysis
    [TxSite_quant, REC_prop] = FQ_TS_analyze_results_v8(TS_rec,Q_all,TS_analysis, parameters);

    %- Assign new parameters
    handles.img.cell_prop(ind_cell).pos_TS(ind_TS).TxSite_quant = TxSite_quant;
    handles.img.cell_prop(ind_cell).pos_TS(ind_TS).REC_prop     = REC_prop;

    %- Save results
    guidata(hObject, handles); 
end


%=== Restrict size of all transcription sites
function button_TS_restrict_size_all_Callback(hObject, eventdata, handles)

global parameters_quant

%- Parameters for restriction
parameters                         = parameters_quant;
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
    
    %====== Restrict analysis
    [TxSite_quant, REC_prop] = FQ_TS_analyze_results_v8(TS_rec,Q_all,TS_analysis, parameters);

    %- Assign results
    TS_summary(i_TS).TxSite_quant = TxSite_quant;
    TS_summary(i_TS).REC_prop     = REC_prop;
    
end

%- Save results
handles.TS_summary = TS_summary;
guidata(hObject, handles); 

status_text = {' ';'== SIZE RESTRICTION FINISHED'};
status_update(hObject, eventdata, handles,status_text);

    
%=== Options for quantification
function menu_options_Callback(hObject, eventdata, handles)

handles.img.modify_settings_TS(handles.status_TS_simple_only);

handles.status_PSF = 0;
status_update(hObject, eventdata, handles,{'  ';'## Options modified'});
guidata(hObject, handles);


%==========================================================================
%==== Save and plot
%==========================================================================

%=== Save results of quantification
function menu_save_quantification_Callback(hObject, eventdata, handles)

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
        
    %== Settings
    if ~isfield(handles,'path_name_settings_TS') || isempty(handles.path_name_settings_TS)
        [handles.file_name_settings_TS, handles.path_name_settings_TS] = handles.img.save_settings_TS([]);
    end
  
    %== Parameters
    if not(isempty(handles.file_name_settings_TS))
        parameters.path_save          = path_save;
        parameters.file_name_settings = handles.file_name_settings_TS;
        parameters.version            = handles.img.version;
        parameters.mRNA_prop          = handles.img.mRNA_prop;
        
        [dum, file_name] = fileparts(handles.img.file_names.raw);
        
        parameters.file_name_default = [file_name,'__TS_quant_summary_', datestr(date,'yymmdd'), '.txt'];
   
        FQ_TS_save_summary_v1([],handles.TS_summary,parameters)
    end
    
    guidata(hObject, handles);
    
    cd(current_dir);
end


%=== Visualize results of TS quantification
function button_visualize_results_Callback(hObject, eventdata, handles)
MIJ_start(hObject, eventdata, handles)

ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
pos_TS    = handles.img.cell_prop(ind_cell).pos_TS;

i_TS    = get(handles.pop_up_outline_sel_TS,'Value');


label_TS = pos_TS(i_TS).label;
img_res  = pos_TS(i_TS).REC_prop.img_res;
img_TS   =  pos_TS(i_TS).TS_analysis_results.img_TS_crop_xyz;
img_fit  = pos_TS(i_TS).REC_prop.img_fit;

%- Plot TS and Fit
MIJ.createImage('TS_img', uint32(img_TS),1);
MIJ.createImage('TS_fit', uint32(img_fit),1);

%-Combine stacks next to each other, rename and autoscale
MIJ.run('Combine...', 'stack1=TS_img stack2=TS_fit');

label_img = ['FQ: ',label_TS , ' : LEFT: image | RIGHT: fit' ];
string_rename = ['rename("',label_img,'")'];
ij.IJ.runMacro(string_rename);    

ij.IJ.setSlice(round(size(img_res,3)/2))
MIJ.run('Enhance Contrast', 'saturated=0.35');
MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');

%- Residuals

img_res_pos = img_res.*(img_res > 0); 
img_res_neg = img_res.*(img_res < 0)*(-1);

MIJ.createImage('res_pos', uint32(img_res_pos),1);   
MIJ.createImage('res_neg', uint32(img_res_neg),1);


title_resid = ['FQ: ',label_TS, ' : resid of fit - red:pos - green:neg'];
MIJ.run('Concatenate...', ['stack1=[res_pos] stack2=[res_neg] title=[', title_resid , ']']);
MIJ.run('Stack to Hyperstack...', ['order=xyzct channels=2 slices=',num2str(size(img_res,3)) ,' frames=1 display=Composite']);
MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');MIJ.run('In');

ij.IJ.runMacro('Stack.setChannel(1)');
ij.IJ.runMacro('run("Red")');

ij.IJ.runMacro('Stack.setChannel(2)');
ij.IJ.runMacro('run("Green")');   
    


%==========================================================================
%==== VISUALIZATION
%==========================================================================

%==========================================================================
%==== Functions for the different plots

%=== Image with position of detected spots
function plot_image(handles,axes_select)

ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
cell_prop = handles.img.cell_prop;
            
%- Calculate maximum projection of loaded image
img_plot = handles.img.raw_proj_z;

%- 1. Plot image
if isempty(axes_select)
    figure
    imshow(img_plot,[]);
else
    axes(axes_select);
    cla(axes_select,'reset')
    h = imshow(img_plot,[]);
end

title('Maximum projection of loaded image','FontSize',9);
colormap(hot)

   
%- Plot outline of cell and TS
hold on
%if isfield(handles,'cell_prop')    

    if not(isempty(cell_prop))  
        
        for i_cell = 1:size(cell_prop,2)
            x = cell_prop(i_cell).x;
            y = cell_prop(i_cell).y;
            plot([x,x(1)],[y,y(1)],'b','Linewidth', 2)   
            
            
            %- Nucleus
            pos_Nuc   = handles.img.cell_prop(i_cell).pos_Nuc;   
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
        
            %- Plot selected cell in different color
            ind_TS  = get(handles.pop_up_outline_sel_TS,'Value');
            x = pos_TS(ind_TS).x;
            y = pos_TS(ind_TS).y;
            plot([x,x(1)],[y,y(1)],'g','Linewidth', 2)  
        
        end 
    end        
%end
hold off
    

%==========================================================================
%==== Various Functions
%==========================================================================


%=== Parallel computing
function checkbox_parallel_computing_Callback(hObject, eventdata, handles)
% 
% flag_parallel = get(handles.checkbox_parallel_computing,'Value');
% 
% if exist('matlabpool')
% 
%     %- Parallel computing - open MATLAB session for parallel computation 
%     if flag_parallel == 1    
%         isOpen = matlabpool('size') > 0;
%         if (isOpen==0)
%             
%             set(handles.h_FQ_TxSite,'Pointer','watch');
%             %- Update status
%             status_text = {' ';'== STARTING matlabpool for parallel computing ... please wait ... '};
%             status_update(hObject, eventdata, handles,status_text);
% 
%             matlabpool open;
% 
%             %- Update status
%             status_text = {' ';'    ... STARTED'};
%             status_update(hObject, eventdata, handles,status_text);        
%             set(handles.h_FQ_TxSite,'Pointer','arrow');
%         end
% 
%     %- Parallel computing - close MATLAB session for parallel computation     
%     else
%         isOpen = matlabpool('size') > 0;
%         if (isOpen==1)
%             
%             set(handles.h_FQ_TxSite,'Pointer','watch');
%             %- Update status
%             status_text = {' ';'== STOPPING matlabpool for parallel computing ... please wait ... '};
%             status_update(hObject, eventdata, handles,status_text);
% 
%             matlabpool close;
% 
%             %- Update status
%             status_text = {' ';'    ... STOPPED'};
%             status_update(hObject, eventdata, handles,status_text);
%             set(handles.h_FQ_TxSite,'Pointer','arrow');
%         end
%     end
%     
% else
%     warndlg('Parallel toolbox not available','FISH_QUANT')
%     set(handles.checkbox_parallel_computing,'Value',0);
% end


%== Update status
function status_update(hObject, eventdata, handles,status_text)
status_old = get(handles.list_box_status,'String');
status_new = [status_old;status_text];
set(handles.list_box_status,'String',status_new)
set(handles.list_box_status,'ListboxTop',round(size(status_new,1)))
drawnow
enable_controls(hObject, eventdata, handles)
guidata(hObject, handles); 


%= Function to start MIJ
function MIJ_start(hObject, eventdata, handles)
if isfield(handles,'flag_MIJ')
    if handles.flag_MIJ == 0
       Miji;                          % Start MIJ/ImageJ by running the Matlab command: MIJ.start("imagej-path")
       handles.flag_MIJ = 1;       
    end
else
   try 
        Miji;                          % Start MIJ/ImageJ by running the Matlab command: MIJ.start("imagej-path")
        handles.flag_MIJ = 1;
   catch
       disp(' ')
       disp('Fiji could not be started. Maybe path-definition was not set. Please consult help file.')
   end
end
guidata(hObject, handles);


%= Pop-up to select cells
function pop_up_outline_sel_cell_Callback(hObject, eventdata, handles)

ind_cell    = get(handles.pop_up_outline_sel_cell,'Value');
str_menu_TS = handles.img.cell_prop(ind_cell).str_menu_TS;

set(handles.pop_up_outline_sel_TS,'String',str_menu_TS);
set(handles.pop_up_outline_sel_TS,'Value',1);

pop_up_outline_sel_TS_Callback(hObject, eventdata, handles) 
       

%= Pop-up to select TxSite
function pop_up_outline_sel_TS_Callback(hObject, eventdata, handles)           

%- Get cell and transcription site
ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
ind_TS    = get(handles.pop_up_outline_sel_TS,'Value');

%- Plot cell
plot_image(handles,handles.axes_main)   

%- Check if transcription site is defined
if not(isempty(handles.img.cell_prop(ind_cell).pos_TS))

    %- Check if all sites were quantified
    if handles.status_QUANT_ALL
        
        
        i_TS = find(ismember(handles.TS_look_up, [ ind_cell ind_TS], 'rows'));
        
        if not(isempty(i_TS))
            handles.status_QUANT = 1;
            TxSite_quant        = handles.TS_summary(i_TS).TxSite_quant;
            REC_prop            = handles.TS_summary(i_TS).REC_prop;
        else
            handles.status_QUANT = 0;
        end
        
    else
        handles.status_QUANT = handles.img.cell_prop(ind_cell).pos_TS(ind_TS).status_QUANT;
        
        if handles.status_QUANT
        	TxSite_quant        = handles.img.cell_prop(ind_cell).pos_TS(ind_TS).TxSite_quant;
            REC_prop            = handles.img.cell_prop(ind_cell).pos_TS(ind_TS).REC_prop;
        end
    end
    

    %- Enable results
    guidata(hObject, handles); 
    enable_controls(hObject, eventdata, handles)
    

    %- If sites was quantified
    if handles.status_QUANT

        %- Update status
        status_text = { ' ';
                        '== Results of quantification ' ; ...

                        ['# of nascent mRNA [PSF superimposition]  : ' , num2str(TxSite_quant.N_mRNA_TS_mean_all), ...
                              '+/-'                              , num2str(TxSite_quant.N_mRNA_TS_std_all)]; ...
                              
                        ['# of nascent mRNA [Integrated intensity] : ' , num2str(TxSite_quant.N_mRNA_integrated_int)]; ...
                        ['# of nascent mRNA [Maximum intensity]    : ' , num2str(TxSite_quant.N_mRNA_trad)]; ...
                        ['# of nascent mRNA [Estimated amplitude]  : ' , num2str(TxSite_quant.N_mRNA_fitted_amp)]; ...
                       
                        ' '; 
                        ...
                       ['Dist AVG [CENTERED DATA]            : ', num2str(REC_prop.TS_dist_all_IN_mean,'%10.0f'),' nm']};
         status_update(hObject, eventdata, handles,status_text);          

         %- Plot results if specified
         flag_plot = get(handles.checkbox_output,'Value');    % Can be a list - corresponding constructions will be plotted

         if flag_plot  
             parameters.flags.output = 2;
             parameters.file_name_save_PLOTS_PS = [];
             parameters.factor_Q_ok  = handles.img.settings.TS_quant.factor_Q_ok;         
             TxSite_reconstruct_Output_v5(TxSite_quant, REC_prop, parameters)
         end

    else
        status_text = { ' '; 'Site is not quantified .... ' };
        status_update(hObject, eventdata, handles,status_text);   
    end
    
else
    status_text = { ' '; 'Not TxSite defined .... ' };
    status_update(hObject, eventdata, handles,status_text);      
    
end



%==========================================================================
%==== Not used functions
%==========================================================================

function list_box_status_Callback(hObject, eventdata, handles)

function list_box_status_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_OS_z_Callback(hObject, eventdata, handles)

function text_OS_z_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_OS_xy_Callback(hObject, eventdata, handles)

function text_OS_xy_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_outline_sel_cell_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pop_up_outline_sel_TS_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function aux_Callback(hObject, eventdata, handles)

function checkbox_output_Callback(hObject, eventdata, handles)

function txt_TS_bgd_Callback(hObject, eventdata, handles)

function txt_TS_bgd_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_th_auto_detect_Callback(hObject, eventdata, handles)

function text_th_auto_detect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function text_TS_dist_max_Callback(hObject, eventdata, handles)

function text_TS_dist_max_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function button_par_PSF_Callback(hObject, eventdata, handles)

function Untitled_1_Callback(hObject, eventdata, handles)




