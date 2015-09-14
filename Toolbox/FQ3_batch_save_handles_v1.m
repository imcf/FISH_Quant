function FQ3_batch_save_handles_v1(file_name_full,handles)

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
    handles.str_list = get(handles.listbox_files,'String');
    
    handles.checkbox_filtered        = get(handles.checkbox_use_filtered,'Value');
    handles.checkbox_parallel        = get(handles.checkbox_parallel_computing,'Value');    
    handles.checkbox_filtered_save   = get(handles.checkbox_save_filtered,'Value');
    handles.checkbox_save_TS_results = get(handles.status_save_results_TxSite_quant,'Value');    
    handles.checkbox_save_TS_figure  = get(handles.status_save_figures_TxSite_quant,'Value'); 
        
    handles.string_TS_th_auto        = get(handles.text_th_auto_detect,'String');
       
    handles.val_auto_save_TS     = get(handles.checkbox_auto_save,'Value'); 
    handles.val_auto_save_mature = get(handles.checkbox_auto_save_mature,'Value'); 
       
    %- Save handles
    eval('save(file_name_full,''handles'',''-v6'')')
end

cd(current_dir)