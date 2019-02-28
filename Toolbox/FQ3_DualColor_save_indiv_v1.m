function FQ3_DualColor_save_indiv_v1(par_coloc,summary_coloc,results_channel,channel)


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
    
    case 'ch2'     
        ident_ch   =  par_coloc.ident_ch2;
    
end


%% Co-localized spots

%- Get file-name
file_name_save = ['_FQ_coloc_SPOTS__INDIV_',ident_ch,'_', datestr(now,'yymmdd'),'.txt'];  % Name to save the results
file_save_full = fullfile(folder_coloc,file_name_save);

%- Wich part should be saved
% Pos-x, Pos-Y,Pos-Z,amp,bgd,simga-x,sigma-z, int-raw, int-filt
ind_save = [1 2 3 4 5 7 9 26 27];
data_save = [results_channel(:,ind_save) results_channel(:,end)];

%- Get number of parameters and sort by last one
N_par = size(data_save,2);
data_save = sortrows(data_save,N_par);  

%- Generate string to save data
string_write   = ['%g',repmat('\t%g',1,N_par-1),'\n']; 

%- Write file    
fid = fopen(file_save_full,'w');
fprintf(fid,'FISH-QUANT\n');
fprintf(fid,'Co-localization analysis\n\n');

fprintf(fid,'Identifier - channel 1:  %s \n',par_coloc.ident_ch1);
fprintf(fid,'Identifier - channel 2:  %s \n',par_coloc.ident_ch2);

fprintf(fid,'Maximum number of spots: \t%g\n\n',par_coloc.N_spots_max);

fprintf(fid,'ch1_x\tch1_y\tch1_Z\tch1_amp\tch1_bgd\tch1_simgaX\tch1_sigmaZ\tch1_int\tch1_intFilt\tCoLoc\n');
fprintf(fid,string_write,data_save');      
        
fclose(fid);

%- Display file name
disp(' ')
disp('===== RESULTS SAVED')
disp(file_save_full)      

