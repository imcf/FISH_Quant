function [handles_GUI, status_load] = FQ3_batch_load_handles_v1(handles_GUI)
% Function to read analysis results from .mat file

    
status_load = 1;

%- Ask user for file-name for spot results
[file_load,path_load] =  uigetfile('*.mat','Results of analysis [.mat file]');

if file_load ~= 0

    load(fullfile(path_load,file_load));

    %=== CHECK IF GOOD VERSION
    if ~isfield(handles,'img')
        warndlg('OLD version of autosave file. Not compatible with this version of FQ.',mfilename)
        status_load = 0;
        return
    end
    
    %======================================================================
    % === Assign parameters that are initiated at the beginning
    
    
    %- Image structure
    handles_GUI.img = handles.img;
    
    %== Folders
    handles_GUI.path_name_list                     = handles.path_name_list; 

%     handles_GUI.path_name_root          = handles.path_name_root;
%     handles_GUI.path_name_image         = handles.path_name_image;
%     handles_GUI.path_name_outline       = handles.path_name_outline;
%     handles_GUI.path_name_results       = handles.path_name_results;
%     handles_GUI.path_name_settings      = handles.path_name_settings;
%     
    %- Parameters to save results
    handles_GUI.file_summary        = handles.file_summary; 
    handles_GUI.cell_summary        = handles.cell_summary;
    handles_GUI.TS_summary          = handles.TS_summary;
    
    handles_GUI.spots_fit_all       = handles.spots_fit_all; 
   % handles_GUI.thresh_all          = handles.thresh_all;     
    handles_GUI.spots_range          = handles.spots_range;     
       
    %== Status
    handles_GUI.status_setting               = handles.status_setting;
    handles_GUI.status_files                 = handles.status_files;
    handles_GUI.status_fit                   = handles.status_fit;
    handles_GUI.status_AMP                   = handles.status_AMP;
    handles_GUI.status_settings_TS           = handles.status_settings_TS;
    handles_GUI.status_QUANT                 = handles.status_QUANT;
    handles_GUI.status_settings_TS_proc      = handles.status_settings_TS_proc;
    handles_GUI.status_outline_unique_loaded = handles.status_outline_unique_loaded;
    handles_GUI.status_outline_unique_enable = handles.status_outline_unique_enable;
    handles_GUI.status_PSF_PROC              = handles.status_PSF_PROC;
    
    if isfield(handles,'status_AMP_PROC')
    	handles_GUI.status_AMP_PROC = handles.status_AMP_PROC; 
    else
        handles_GUI.status_AMP_PROC = handles_GUI.status_PSF_PROC;
    end

    
    %- Other parameters
   % handles_GUI.par_microscope    = handles.par_microscope; 
    handles_GUI.PSF               = handles.PSF;
    handles_GUI.flag_fit          = handles.flag_fit; 
    
    
    %== Columns where parameters are stored
  %  handles_GUI.col_par               = handles.col_par;

    
    %=== Options for autosave of mRNA quantification (new in v2b)
    if isfield(handles,'i_file_proc_mature')
        handles_GUI.i_file_proc_mature =  handles.i_file_proc_mature;
        handles_GUI.cell_counter       =  handles.cell_counter; 
    
        handles_GUI.val_auto_save_TS     = handles.val_auto_save_TS;
        handles_GUI.val_auto_save_mature = handles.val_auto_save_mature;
        
    else
        handles_GUI.i_file_proc_mature  =  1;
        handles_GUI.cell_counter        =  1;
        handles_GUI.val_autosave_TS     = 0;
        handles_GUI.val_autosave_mature = 0;
    end
    
    
    %=== Options for TxSite quantification
    handles_GUI.i_file_proc          = handles.i_file_proc;
    handles_GUI.i_cell_proc          = handles.i_cell_proc;
    handles_GUI.i_TS_proc            = handles.i_TS_proc;
    
    handles_GUI.TS_counter           = handles.TS_counter;        
    %handles_GUI.parameters_quant     = handles.parameters_quant; 
        
    %- Options for autodetect   
    if isfield(handles,'parameters_auto_detect')
    	handles_GUI.parameters_auto_detect = handles.parameters_auto_detect; 
    else
        handles_GUI.parameters_auto_detect = {};
    end
    
    %- How are amplitudes treated? Average or distribution?
    if isfield(handles,'flag_amp_quant')
    	handles_GUI.flag_amp_quant = handles.flag_amp_quant; 
    else
        handles_GUI.flag_amp_quant = 'Distribution';
    end
         
    handles_GUI.mRNA_prop     = handles.mRNA_prop;
    handles_GUI.PSF_shift     = handles.PSF_shift;
    handles_GUI.PSF_path_name = handles.PSF_path_name;
    handles_GUI.PSF_file_name = handles.PSF_file_name;
    handles_GUI.BGD_path_name = handles.BGD_path_name;
    handles_GUI.BGD_file_name = handles.BGD_file_name;
    handles_GUI.bgd_value     = handles.bgd_value;    
    handles_GUI.AMP_path_name = handles.AMP_path_name;
    handles_GUI.AMP_file_name = handles.AMP_file_name;    
    handles_GUI.fact_os       = handles.fact_os;    
    
    %- File-names
    handles_GUI.file_name_settings_new = handles.file_name_settings_new;
    handles_GUI.file_name_settings     = handles.file_name_settings;
    
    handles_GUI.file_name_settings_TS  = handles.file_name_settings_TS;
        
    %- Default file-names
    handles_GUI.file_name_suffix_spots       = handles.file_name_suffix_spots;
    handles_GUI.file_name_summary            = handles.file_name_summary;
    handles_GUI.file_name_summary_TS         = handles.file_name_summary_TS;
    handles_GUI.file_name_summary_ALL        = handles.file_name_summary_ALL;
    
    handles_GUI.file_name_settings_save         = handles.file_name_settings_save;
    handles_GUI.file_name_settings_nascent_save = handles.file_name_settings_nascent_save;  
    
    %== Settings for saving
    if isfield(handles.settings_save, 'N_ident')
        handles_GUI.settings_save.file_id_start = handles.settings_save.N_ident;
        handles_GUI.settings_save.file_id_end   = 0;    
    else
        handles_GUI.settings_save.file_id_start = handles_GUI.settings_save.file_id_start;
        handles_GUI.settings_save.file_id_end   = handles_GUI.settings_save.file_id_end; 
    end
    
    
  %  handles_GUI.settings_save.file_id_start = 4;
  %  handles_GUI.settings_save.file_id_end   = 0;
    
    
    %- Plot rendering
    handles_GUI.settings_rendering           = handles.settings_rendering;
    
    %=== Get ImageJ directories
 %   handles_GUI.imagej_macro_name            = handles.imagej_macro_name;
        
    
    %======================================================================
    % === Other parameters that are important for GUI
       
        
    %= Detection parameters
   % handles_GUI.fit_limits = handles.fit_limits;
   % handles_GUI.detect     = handles.detect;
    %handles_GUI.filter     = handles.filter;   
   % handles_GUI.average    = handles.average;   
        
    %=== Other parameters
    handles_GUI.str_list = handles.str_list;
    
    handles_GUI.checkbox_filtered          = handles.checkbox_filtered;
    handles_GUI.checkbox_parallel          = handles.checkbox_parallel;
    handles_GUI.checkbox_filtered_save     = handles.checkbox_filtered_save;
    handles_GUI.checkbox_save_TS_results   = handles.checkbox_save_TS_results;
    handles_GUI.checkbox_save_TS_figure    = handles.checkbox_save_TS_figure;     
    handles_GUI.string_TS_th_auto          = handles.string_TS_th_auto;

    
    if isfield(handles,'saved_checkbox_flag_GaussMix')
        handles_GUI.saved_checkbox_flag_GaussMix = handles.saved_checkbox_flag_GaussMix;
    else
        handles_GUI.saved_checkbox_flag_GaussMix = 1;
    end

    
else
    handles_GUI = {};
end


