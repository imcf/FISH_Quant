function FQ_batch_save_summary_all_v4(file_name_full,parameters)


%% Get current directory
current_dir = pwd;


%% Parameters
TS_summary         = parameters.TS_summary;
cell_summary       = parameters.cell_summary;
path_save          = parameters.path_save;
file_name_settings = parameters.file_name_settings;
version            = parameters.version;
  
%% Get names of images and cells for all TS
TS_name_list  = {TS_summary.file_name_list}';
TS_name_cell  = {TS_summary.cell_label}';


%% Ask for file-name if it's not specified
if isempty(file_name_full)
    cd(path_save);

    %- Ask user for file-name for spot results
    file_name_default = ['_FQ__batch_summary_all', datestr(date,'yyyy-mm-dd'), '.txt'];

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


%% Ask which quantification for nascent mRNA should be used
choice_quant = questdlg('Which quantification method for the TxSite should be used for output in file?', 'Save summary of quantification','Integrated intensity', 'PSF superposition','Maximum intensity','Integrated intensity');


%% Only write if FileName specified
if file_save ~= 0 && not(isempty(answer)) && not(isempty(choice_quant))
    
    fid = fopen(file_name_full,'w');
    
    %- Header    
    fprintf(fid,'FISH-QUANT\t%s\n', version );
    fprintf(fid,'RESULTS TxSite quantification performed ON %s \n', date);
    fprintf(fid,'%s\t%s\n','COMMENT',char(answer)); 
    fprintf(fid,'ANALYSIS-SETTINGS \t%s\n', file_name_settings);   
    fprintf(fid,'FILE\tCELL\tN_MATURE_Total\tN_MATURE_Nucleus\tN_NASCENT_FOR_EACH_TS_IN_CELL\n');    
    
    
    %- Summary for each cell
    for i_cell = 1:size(cell_summary,1)                
        
        %- Find list of all transcription sites in the same cell
        name_list  = cell_summary(i_cell).name_list;
        cell_label = cell_summary(i_cell).label;
        
        ind_TS_list = strcmpi(name_list,TS_name_list);
        ind_TS_cell = strcmpi(cell_label,TS_name_cell);
        
        ind_TS_write_logic = ind_TS_list & ind_TS_cell;
        ind_TS_write       = find(ind_TS_write_logic == 1);
        
        N_TS_write         = length(ind_TS_write);
        
        %- Create output for cell
        summary_write = [];
        summary_write =  [cell_summary(i_cell,1).N_count cell_summary(i_cell,1).N_nuc];
        for i=1:N_TS_write
            ind_loop = ind_TS_write(i);
            
            switch choice_quant
                case 'PSF superposition'
                    N_nascent_loop = TS_summary(ind_loop).TxSite_quant.N_mRNA_TS_mean_all;

                case 'Integrated intensity'
                    N_nascent_loop = TS_summary(ind_loop).TxSite_quant.N_mRNA_integrated_int;            
                
                case 'Maximum intensity'
                    N_nascent_loop = TS_summary(ind_loop).TxSite_quant.N_mRNA_trad;                
            end 
                
            summary_write  = [summary_write, N_nascent_loop];
        end
        
        %- Create string to write output
        N_write = length(summary_write);
        string_write = ['%s\t%s',repmat('\t%g',1,N_write),'\n'];
        
        %- Write output
        fprintf(fid,string_write,cell_summary(i_cell,1).name_list, cell_summary(i_cell,1).label, summary_write);        
    end
    
end
fclose(fid);

%% Go back to original folder
cd(current_dir)

       
        
       