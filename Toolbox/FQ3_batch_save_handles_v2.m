function FQ3_batch_save_handles_v2(file_name_full,handles)

% Function to write handles structure of GUI to m-file

current_dir = pwd;

%== Go to results folder
if  not(isempty(handles.img.path_names.results)); 
    path_save = handles.img.path_names.results;
elseif not(isempty(handles.img.path_names.root)); 
    path_save = handles.img.path_names.root;
else
    path_save = cd;
end

cd(path_save)
    

%== Ask for file-name if it's not specified
if isempty(file_name_full)
     
    %- Ask user for file-name   
    file_name_default = ['_FQ_batch_ANALYSIS_', datestr(date,'yymmdd'),'.mat'];
    [file_save,path_save] = uiputfile(file_name_default,'Save results of analysis [mat file]');
    file_name_full = fullfile(path_save,file_save);
    
else   
    file_save = 1;
end


%==== Save information of sites

if file_save ~= 0
    
    %- Save some additional parameters
    handles_GUI.str_list = get(handles.listbox_files,'String');
    
    handles_GUI.checkbox_filtered        = get(handles.checkbox_use_filtered,'Value');   
    handles_GUI.checkbox_filtered_save   = get(handles.checkbox_save_filtered,'Value');
    handles_GUI.checkbox_save_TS_results = get(handles.status_save_results_TxSite_quant,'Value');    
    handles_GUI.checkbox_save_TS_figure  = get(handles.status_save_figures_TxSite_quant,'Value'); 
        
    handles_GUI.string_TS_th_auto        = get(handles.text_th_auto_detect,'String');
       
    handles_GUI.val_auto_save_TS     = get(handles.checkbox_auto_save,'Value'); 
    handles_GUI.val_auto_save_mature = get(handles.checkbox_auto_save_mature,'Value'); 
       
    %- Save handles
    handles_GUI.img.raw = [];
    handles_GUI.img.filt = [];
    handles_GUI.img.DAPI = [];
    handles_GUI.img.TS_label = [];
    
    %- Image structure
    handles_GUI.img = handles.img;
    
    %== Folders
    handles_GUI.path_name_list                     = handles.path_name_list; 
     
    %- Parameters to save results
    handles_GUI.file_summary        = handles.file_summary; 
    handles_GUI.cell_summary        = handles.cell_summary;
    handles_GUI.TS_summary          = handles.TS_summary;
    
    handles_GUI.spots_fit_all       = handles.spots_fit_all; 
    if isfield(handles,'spots_detected_all')
        handles_GUI.spots_detected_all  = handles.spots_detected_all; 
    else
        handles_GUI.spots_detected_all  = [];
    end
    handles_GUI.spots_range         = handles.spots_range;     
       
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
    handles_GUI.PSF               = handles.PSF;
    handles_GUI.flag_fit          = handles.flag_fit;

    handles_GUI.i_file_proc_mature =  handles.i_file_proc_mature;
    handles_GUI.cell_counter       =  handles.cell_counter; 
    
    handles_GUI.val_auto_save_TS     = get(handles.checkbox_auto_save,'Value'); 
    handles_GUI.val_auto_save_mature = get(handles.checkbox_auto_save_mature,'Value'); 
       
    %=== Options for TxSite quantification
    handles_GUI.i_file_proc          = handles.i_file_proc;
    handles_GUI.i_cell_proc          = handles.i_cell_proc;
    handles_GUI.i_TS_proc            = handles.i_TS_proc;
    
    handles_GUI.TS_counter           = handles.TS_counter;        

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
        handles_GUI.settings_save.file_id_start = handles.settings_save.file_id_start;
        handles_GUI.settings_save.file_id_end   = handles.settings_save.file_id_end; 
    end
    
    %- Plot rendering
    handles_GUI.settings_rendering           = handles.settings_rendering;
   
    if isfield(handles,'saved_checkbox_flag_GaussMix')
        handles_GUI.saved_checkbox_flag_GaussMix = handles.saved_checkbox_flag_GaussMix;
    else
        handles_GUI.saved_checkbox_flag_GaussMix = 1;
    end  

    %- Remove field
    handles = handles_GUI;
    eval('save(file_name_full,''handles'',''-v6'')')
end

cd(current_dir)