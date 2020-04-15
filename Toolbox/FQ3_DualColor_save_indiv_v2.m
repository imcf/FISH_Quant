function FQ3_DualColor_save_indiv_v2(par_coloc,summary_coloc,results_coloc,channel)


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
folder_coloc   = summary_coloc.folder_coloc;

switch channel
    
    case 'ch1'
        ident_ch   =  par_coloc.ident_ch1;
        data_all = results_coloc.ch1_all;
    
    case 'ch2'     
        ident_ch   =  par_coloc.ident_ch2;
        data_all = results_coloc.ch2_all;
    
end

N_files   = length(data_all);

%% Compile data
cell_write_all = {}';
ind_save = [1 2 3 4 5 7 9 26 27];

for i_cell = 1:N_files

    data_loop      = data_all{i_cell};
       
    if not(isempty(data_loop))
        
       %- Analyze data 
       N_spots = size(data_loop,1);
       
       %- Wich part should be saved
       % Pos-x, Pos-Y,Pos-Z,amp,bgd,simga-x,sigma-z, int-raw, int-filt, co-loc
       data_save = [data_loop(:,ind_save) data_loop(:,end)];
       cell_data    = num2cell(data_save);  

       %- Create labels
       name_image     = results_coloc.name_ch1{i_cell};
       name_cell      = results_coloc.name_cell{i_cell};
       
       cell_label = {};   
       [cell_label{1:N_spots,1}] = deal(name_image);  
       [cell_label{1:N_spots,2}] = deal(name_cell);  
         
        cell_write      = [cell_label,cell_data];
        
        %- Save entire structure
        if ~isempty(cell_write)
            cell_write_all  = [cell_write_all;cell_write];
        end
    end
end


%% Co-localized spots

%- Get file-name
file_name_save = ['_FQ_coloc_SPOTS__INDIV_',ident_ch,'_', datestr(now,'yymmdd'),'.txt'];  % Name to save the results
file_save_full = fullfile(folder_coloc,file_name_save);

%- Generate string to save data
N_par = length(ind_save);
string_write   = ['%s\t%s\t%g',repmat('\t%g',1,N_par),'\n']; 
cell_write_all = cell_write_all';  %- fprintf works on colums - data has to therefore be transformed 

%- Write file    
fid = fopen(file_save_full,'w');
fprintf(fid,'FISH-QUANT\n');
fprintf(fid,'Co-localization analysis\n\n');

fprintf(fid,'Identifier - channel 1:  %s \n',par_coloc.ident_ch1);
fprintf(fid,'Identifier - channel 2:  %s \n',par_coloc.ident_ch2);

fprintf(fid,'Maximum number of spots: \t%g\n\n',par_coloc.N_spots_max);

fprintf(fid,'file\tcell\tch1_y\tch1_x\tch1_Z\tch1_amp\tch1_bgd\tch1_simgaX\tch1_sigmaZ\tch1_int\tch1_intFilt\tCoLoc\n');
fprintf(fid,string_write,cell_write_all{:});      
        
fclose(fid);

%- Display file name
disp(' ')
disp('===== RESULTS SAVED')
disp(file_save_full)      

