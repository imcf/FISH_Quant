function FQ_batch_save_summary_v1(file_name_full,parameters)

%- Parameters
cell_summary       = parameters.cell_summary;
path_save          = parameters.path_save;
file_name_settings = parameters.file_name_settings;
version            = parameters.version;

%- Get current directory
current_dir = pwd;

%- Ask for file-name if it's not specified
if isempty(file_name_full)
    cd(path_save);

    %- Ask user for file-name for spot results
    file_name_default = ['FISH-QUANT__batch_summary_', datestr(date,'yyyy-mm-dd'), '.txt'];

    [file_save,path_save] = uiputfile(file_name_default,'Save results of batch processing');
    file_name_full = fullfile(path_save,file_save);
    
    %- Ask user to specify comment
    prompt = {'Comment (cancel for no comment):'};
    dlg_title = 'User comment for file';
    num_lines = 1;
    def = {''};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
else   

    file_save = 1;
    answer = 'Batch detection';
end


% Only write if FileName specified
if file_save ~= 0
    
    fid = fopen(file_name_full,'w');
    
    %- Header    
    fprintf(fid,'FISH-QUANT\t%s\n', version );
    fprintf(fid,'RESULTS OF SPOT DETECTION PERFORMED IN BATCH MODE ON %s \n', date);
    fprintf(fid,'%s\t%s\n','COMMENT',char(answer)); 
    fprintf(fid,'ANALYSIS-SETTINGS \t%s\n', file_name_settings);   
    fprintf(fid,'FILE\tCELL\tAREA_cell\tAREA_nuc\tN_total\tN_thres_Total\tN_thres_Nuc\n');    
    
    %- Summary for each cell
    for i_cell = 1:size(cell_summary,1)                
        fprintf(fid,'%s\t%s\t%g\t%g\t%g\t%g\t%g\n',cell_summary(i_cell,1).name_list, cell_summary(i_cell,1).label, cell_summary(i_cell,1).area_cell, cell_summary(i_cell,1).area_nuc, cell_summary(i_cell,1).N_total, cell_summary(i_cell,1).N_count, cell_summary(i_cell,1).N_nuc );        
    end
end
fclose(fid);

%== Go back go to original directory
cd(current_dir)

       


       