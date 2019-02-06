function FQ3_DualColor_save_summary_v1(par_coloc,summary_coloc,results_coloc)


%- Generate folder if not already present
if isempty(summary_coloc.folder_coloc)

    if par_coloc.flags.drift_apply == 0
        folder_coloc = fullfile(par_coloc.folder_ch1, ['_results_coloc_NoDriftCorrection',datestr(date,'yymmdd')]);
    else
        folder_coloc = fullfile(par_coloc.folder_ch1, ['_results_coloc_DriftCorrection',datestr(date,'yymmdd')]);
    end
    if ~(exist(folder_coloc,'dir')); mkdir(folder_coloc); end
    
    summary_coloc.folder_coloc = folder_coloc;
end


%- Get values
values_coloc   = summary_coloc.values;
folder_coloc   = summary_coloc.folder_coloc;

ident_ch1   =  par_coloc.ident_ch1;
ident_ch2   =  par_coloc.ident_ch2;
flags_drift =  summary_coloc.flags_drift;
dist_th     =  summary_coloc.dist_th;
N_spots_max =  summary_coloc.N_spots_max;

%- Get file-name
file_name_save = ['__FQ_coloc_summary__',ident_ch1,'-',ident_ch2,'__',datestr(now,'yymmdd'),'.txt'];  % Name to save the results
file_save_full = fullfile(folder_coloc,file_name_save);

%- Summarize all outputs
cell_data    = num2cell(values_coloc);   

cell_write_all  = [results_coloc.name_ch1,results_coloc.name_cell,cell_data];
cell_write_FILE = cell_write_all';

N_col = size(cell_data,2); 
string_write = ['%s\t%s',repmat('\t%g',1,N_col), '\n'];

N_ch1_total  = sum(values_coloc(:,5));
N_ch1_coloc  = sum(values_coloc(:,6));
N_ch2_total  = sum(values_coloc(:,3));
N_ch2_coloc  = sum(values_coloc(:,4));

%- Write file    
fid = fopen(file_save_full,'w');
fprintf(fid,'FISH-QUANT\n');
fprintf(fid,'Colocalization analysis of images: %s \n\n',ident_ch1);

fprintf(fid,'\nDrift-correction: \t%g\n',flags_drift);
fprintf(fid,'Dist_threshold: \t%g\n\n',dist_th);
fprintf(fid,'Maximum number of spots: \t%g\n\n',N_spots_max);
fprintf(fid,'CH1: perc-coloc, total, coloc : \t%g\t%g\t%g\n', round(100*N_ch1_coloc/N_ch1_total),N_ch1_total,N_ch1_coloc);
fprintf(fid,'CH2: perc-coloc, total, coloc : \t%g\t%g\t%g\n\n', round(100*N_ch2_coloc/N_ch2_total),N_ch2_total,N_ch2_coloc);

fprintf(fid,'Name_File\tName_Cell\tPERC_coloc_CH2\tPERC_coloc_CH1\tCH2_N_total\tCH2_N_coloc\tCH1_N_total\tCH1_N_coloc\n');        
fprintf(fid,string_write, cell_write_FILE{:});
fclose(fid);

%- Display file name
disp(' ')
disp('===== RESULTS SAVED')
disp(file_save_full)      