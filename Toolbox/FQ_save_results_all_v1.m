function [file_save, path_save] = FQ_save_results_all_v1(file_name_full,file_summary,cell_summary,par_microscope,path_name_image,file_name_settings,version,options)

%=== Parameters
flag_only_thresholded = options.flag_only_thresholded;
flag_label            = options.flag_label;
file_id_start         = options.file_id_start;
file_id_end           = options.file_id_end;

%=== Determine file-name
current_dir = pwd;

%- Ask for file-name if it's not specified
if isempty(file_name_full)
    cd(path_name_image);

    %- Ask user for file-name for spot results
  %  [dum, name_file] = fileparts(file_name_image); 
    file_name_default_spot = ['Summary_all_spots.txt'];

    [file_save,path_save] = uiputfile(file_name_default_spot,'Save results of spot detection');
    file_name_full = fullfile(path_save,file_save);
    
    %- Ask user to specify comment
    prompt = {'Comment (cancel for no comment):'};
    dlg_title = 'User comment for file';
    num_lines = 1;
    def = {''};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
else   
    file_save = 1;
    path_save = fileparts(file_name_full); 
    answer = 'Batch detection';
end


%=== Write results

% Only write if FileName specified
if file_save ~= 0
    
    cell_write_all = {}';
    
    %=== Extract results of individual images 
    
    %-- Loop over all images
    for i_file = 1:length(file_summary)
            
        i_start = file_summary(i_file).cells.start;
        i_end   = file_summary(i_file).cells.end;
    
        %- Loop over all cells 
        for i_abs = i_start:i_end
   
            spots_fit       = cell_summary(i_abs,1).spots_fit; 
            spots_detected  = cell_summary(i_abs,1).spots_detected; 
            thresh.in       = cell_summary(i_abs,1).thresh.in;
            
           %- Is field with spots in nucleus defined
            if isfield(cell_summary(i_abs,1),'in_Nuc') && not(isempty(cell_summary(i_abs,1).in_Nuc))
                in_Nuc = double(cell_summary(i_abs,1).in_Nuc);
            else 
                N_spots = size(spots_fit,1);
                in_Nuc  = -ones(N_spots,1);
            end
            
            
            cell_label = {};
            
            %=== Write out results (if specified)
            %- NOTE: fprintf works on columns
            if not(isempty(spots_fit))
                
                 % === Create cell array with data
                 spots_output = [spots_fit, spots_detected,thresh.in,in_Nuc];
                 
                 %- Check if all spots or only thresholded spots should be saved
                 if flag_only_thresholded
                    ind_spots_save = (thresh.in ==1);
                 else
                    ind_spots_save = true(size(thresh.in));
                 end
                 
                spots_output = spots_output(ind_spots_save,:);   
                N_par        = size(spots_output,2);                
                
                cell_data    = num2cell(spots_output);   
            
                % === Create cell array with labels
                
                %- Each row is labeled with the image name followed by the name of the cell
                N_spots                   = size(spots_output,1);
                
                if      flag_label == 1 
                     name_image      = cell_summary(i_abs,1).name_image;
                     name_cell       = cell_summary(i_abs,1).label;       
                    
                    [cell_label{1:N_spots,1}] = deal(name_image);
                    [cell_label{1:N_spots,2}] = deal(name_cell);                    
                    
                    cell_write      = [cell_label,cell_data];
                    
                %- Each row is labeled with the index of file-name (last number in file-name separated by _ from the rest)    
                elseif flag_label == 2
                    
                    %- Get number of file 
                    name_image      = cell_summary(i_abs,1).name_image;
                    [dum name_only] = fileparts(name_image);   
                   
                    file_ident      = name_only(end-file_id_start+1:end-file_id_end);    
                    [cell_label{1:N_spots,1}] = deal(file_ident);  
                    
                    cell_write      = [cell_label,cell_data];

                %- No label - results can be read-in again 
                elseif flag_label == 3
                    cell_write      = cell_data;
                    
                %- Label from index variable in file_summary    
                elseif flag_label == 4
                    file_index = num2str(file_summary(i_file).index);
                    [cell_label{1:N_spots,1}] = deal(file_index);
                
                     cell_write      = [cell_label,cell_data];
                end
                
                %- Save entire structure
                if ~isempty(cell_write)
                    cell_write_all  = [cell_write_all;cell_write];
               end
            end
        end
    end
    
    
    %=== Write results to file
    
    fid = fopen(file_name_full,'w');
    
    %- Header    
    fprintf(fid,'FISH-QUANT\t%s\n', version );
    fprintf(fid,'RESULTS OF SPOT DETECTION PERFORMED ON %s \n', date);
    fprintf(fid,'%s\t%s\n','COMMENT',char(answer));     
        
    %- File Name
    fprintf(fid,'%s\t%s\n','FILE','__SUMMARY_OF_MANY_FILES___');    
    fprintf(fid,'%s\t%s\n','FILTERED','__SUMMARY_OF_MANY_FILES___'); 
    
    
    %- Experimental parameters and analysis settings
    fprintf(fid,'PARAMETERS\n');
    fprintf(fid,'Pix-XY\tPix-Z\tRI\tEx\tEm\tNA\tType\n');
    fprintf(fid,'%g\t%g\t%g\t%g\t%g\t%g\t%s\n', par_microscope.pixel_size.xy, par_microscope.pixel_size.z, par_microscope.RI, par_microscope.Ex, par_microscope.Em,par_microscope.NA, par_microscope.type );
    
    fprintf(fid,'ANALYSIS-SETTINGS \t%s\n', file_name_settings); 
     
    %- Outline of cell
    fprintf(fid,'%s\t%s\n', 'CELL', 'NO_CELLS_DEFINED');
    fprintf(fid,'X_POS\t');
    fprintf(fid,'%g\t',0);
    fprintf(fid,'END\n');
    fprintf(fid,'Y_POS\t');
    fprintf(fid,'%g\t',0);
    fprintf(fid,'END\n');
    
    fprintf(fid,'%s\n', 'SPOTS'); 
    
                
    %- Results of spot detection
    if not(isempty(cell_write_all))
        if      flag_label == 1 
            fprintf(fid,'File\tCell\tPos_Y\tPos_X\tPos_Z\tAMP\tBGD\tRES\tSigmaX\tSigmaY\tSigmaZ\tCent_Y\tCent_X\tCent_Z\tMuY\tMuX\tMuZ\tITERY_det\tY_det\tX_det\tZ_det\tY_min\tY_max\tX_min\tX_max\tZ_min\tZ_max\tINT_raw\tINT_filt\tSC_det\tSC_det_norm\tTH_det\tTH_fit\tin_Nuc\n');
            string_write   = ['%s\t%s',repmat('\t%g',1,N_par),'\n'];  

            cell_write_all = sortrows(cell_write_all,[1 2]);    %- Sort by column 1 and then by 2

        elseif  flag_label == 2
            fprintf(fid,'File#\tPos_Y\tPos_X\tPos_Z\tAMP\tBGD\tRES\tSigmaX\tSigmaY\tSigmaZ\tCent_Y\tCent_X\tCent_Z\tMuY\tMuX\tMuZ\tITERY_det\tY_det\tX_det\tZ_det\tY_min\tY_max\tX_min\tX_max\tZ_min\tZ_max\tINT_raw\tINT_filt\tSC_det\tSC_det_norm\tTH_det\tTH_fit\tin_Nuc\n');
            string_write   = ['%s',repmat('\t%g',1,N_par),'\n']; 

            cell_write_all = sortrows(cell_write_all,1);    %- Sort by column 1 

        elseif  flag_label == 3
            fprintf(fid,'Pos_Y\tPos_X\tPos_Z\tAMP\tBGD\tRES\tSigmaX\tSigmaY\tSigmaZ\tCent_Y\tCent_X\tCent_Z\tMuY\tMuX\tMuZ\tITERY_det\tY_det\tX_det\tZ_det\tY_min\tY_max\tX_min\tX_max\tZ_min\tZ_max\tINT_raw\tINT_filt\tSC_det\tSC_det_norm\tTH_det\tTH_fit\tin_Nuc\n');
            string_write   = ['%g', repmat('\t%g',1,N_par-1),'\n']; 

            cell_write_all = sortrows(cell_write_all,1);    %- Sort by column 1 
            
        elseif  flag_label == 4
            fprintf(fid,'File_Index#\tPos_Y\tPos_X\tPos_Z\tAMP\tBGD\tRES\tSigmaX\tSigmaY\tSigmaZ\tCent_Y\tCent_X\tCent_Z\tMuY\tMuX\tMuZ\tITERY_det\tY_det\tX_det\tZ_det\tY_min\tY_max\tX_min\tX_max\tZ_min\tZ_max\tINT_raw\tINT_filt\tSC_det\tSC_det_norm\tTH_det\tTH_fit\tin_Nuc\n');
            string_write   = ['%s',repmat('\t%g',1,N_par),'\n']; 

            cell_write_all = sortrows(cell_write_all,1);    %- Sort by column 1 
        end


        %- fprintf works on colums - data has to therefore be transformed 
        cell_write_all = cell_write_all';

        %- Write to file
        fprintf(fid,string_write,cell_write_all{:});      
    end
    
    %- Close file handle
    fclose(fid);
        
end

cd(current_dir)   
    
    
    
