function FQ3_DualColor_save_details_v1(par_coloc,summary_coloc,results_coloc)


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

ident_ch1   =  par_coloc.ident_ch1;
ident_ch2   =  par_coloc.ident_ch2;
flags_drift =  summary_coloc.flags_drift;
dist_th     =  summary_coloc.dist_th;
N_spots_max =  summary_coloc.N_spots_max;


%% Co-localized spots

%- Get file-name
file_name_save = ['_FQ_coloc_SPOTS__',ident_ch1,'-',ident_ch2,'__' , datestr(now,'yymmdd'),'.txt'];  % Name to save the results
file_save_full = fullfile(folder_coloc,file_name_save);

%- Wich part should be saved
% Pos-x, Pos-Y,Pos-Z,amp,bgd,simga-x,sigma-z
ind_save = [1 2 3 4 5 7 9];
ind_det_save = [10 11];


%- Dummy object
img_dum = FQ_img;
img_dum.settings.detect.reg_size.xy  = 2;
img_dum.settings.detect.reg_size.z   = 2;
img_dum.par_microscope.pixel_size.xy = 100;
img_dum.par_microscope.pixel_size.z  = 300;

%- Loop over all cells 
N_files = length(results_coloc.data_ch1);
cell_write_all = {}';

for i_cell = 1:N_files

    data_ch1      = results_coloc.data_ch1{i_cell};
    data_ch2      = results_coloc.data_ch2{i_cell};
    
    data_det_ch1  = results_coloc.data_det_ch1{i_cell};
    data_det_ch2  = results_coloc.data_det_ch2{i_cell};
    
    ind_match     = results_coloc.index_match{i_cell};
     
    %- Calculate pairwise distance
    distance = sqrt(sum((data_ch1(:,1:3) - data_ch2(:,1:3)).^2,2));
    
    %- Calculate integrated intensity
    img_dum.cell_prop(1).spots_fit = data_ch1;
    img_dum.calc_intint;
    intint1 = img_dum.cell_prop(1).intint;
    
    img_dum.cell_prop(1).spots_fit = data_ch2;
    img_dum.calc_intint;
    intint2 = img_dum.cell_prop(1).intint;
    

    if not(isempty(data_ch1))
       data_all = [ind_match intint1 data_ch1(:,ind_save) data_det_ch1(:,ind_det_save) intint2 data_ch2(:,ind_save) data_det_ch2(:,ind_det_save) distance];
       N_par        = size(data_all,2);  
       cell_data    = num2cell(data_all);  

       %- Get number of file 
       name_image      = results_coloc.name_ch1{i_cell};
       name_cell      = results_coloc.name_cell{i_cell};
       
       N_spots = size(data_ch1,1);
       
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

%terminate if no co-localization found
if isempty(cell_write_all); return; end

% Sort results
cell_write_all = sortrows(cell_write_all,[1 2]);    %- Sort by column 1 and then by 2
cell_write_all = cell_write_all';  %- fprintf works on colums - data has to therefore be transformed 
string_write   = ['%s\t%s',repmat('\t%g',1,N_par),'\n']; 
 
%- Write file    
fid = fopen(file_save_full,'w');
fprintf(fid,'FISH-QUANT\n');
fprintf(fid,'Co-localization analysis\n\n');

fprintf(fid,'Identifier - channel 1:  %s \n',ident_ch1);
fprintf(fid,'Identifier - channel 2:  %s \n',ident_ch2);

fprintf(fid,'\nDrift-correction: \t%g\n',flags_drift);
fprintf(fid,'Dist_threshold: \t%g\n\n',dist_th);
fprintf(fid,'Maximum number of spots: \t%g\n\n',N_spots_max);

fprintf(fid,'File\tCell\tch1_ind\tch2_ind\tIntInt_ch1\tch1_x\tch1_y\tch1_Z\tch1_amp\tch1_bgd\tch1_simgaX\tch1_sigmaZ\tch1_int\tch1_intFilt\tIntInt_ch2\tch2_x\tch2_y\tch2_Z\tch2_amp\tch2_bgd\tch2_simgaX\tch2_sigmaZ\tch2_int\tch2_intFilt\tDISTANCE\n');
fprintf(fid,string_write,cell_write_all{:});      
        
fclose(fid);

%- Display file name
disp(' ')
disp('===== RESULTS SAVED')
disp(file_save_full)      