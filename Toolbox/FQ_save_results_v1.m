function [file_save, path_save] = FQ_save_results_v1(file_name_full,parameters)

%== Extract parameters
path_save                = parameters.path_save; 
cell_prop                = parameters.cell_prop;
par_microscope           = parameters.par_microscope;
file_names               = parameters.file_names;
version                  = parameters.version;
flag_type                = parameters.flag_type;


%- Comment
if isfield(parameters,'comment')
    comment = parameters.comment;
else
    comment = '';    
end



%- Flag to indicate if only thresholded spots should be saved
if isfield(parameters,'flag_th_only')
    flag_th_only = parameters.flag_th_only;
else
    flag_th_only = 0;
end

%- Check if image size has been be specified as a parameter
if isfield(parameters,'size_img')
    size_img = parameters.size_img;
else
    size_img = [];
end


%- Change directory
current_dir = pwd;

%- Ask for file-name if it's not specified
if isempty(file_name_full)
    cd(path_save);

    %- Ask user for file-name for spot results
    [dum, name_file] = fileparts(file_names.raw); 
    file_name_default = [name_file,'__',flag_type,'.txt'];
    
    [file_save,path_save] = uiputfile(file_name_default,'Save outline / results of spot detection');
    file_name_full = fullfile(path_save,file_save);
    
    if file_save ~= 0
        
        %- Ask user to specify comment
        prompt = {'Comment (cancel for no comment):'};
        dlg_title = 'User comment for file';
        num_lines = 1;
        def = {''};
        comment = inputdlg(prompt,dlg_title,num_lines,def);
    end
else   
    file_save = 1;
    path_save = fileparts(file_name_full); 
    if isempty(comment)
        comment = 'Automated outline definition (batch or quick-save)';
    end
end


% Only write if FileName specified
if file_save ~= 0
    
    fid = fopen(file_name_full,'w');
    
    if fid < 0
       disp('OUTLINE FILE COULD NOT BE SAVED')
       disp(file_name_full)
    else
    
        %- Header    
        fprintf(fid,'FISH-QUANT\t%s\n', version );
        fprintf(fid,'File-version\t%s\n', '3D_v1' );
        fprintf(fid,'RESULTS OF SPOT DETECTION PERFORMED ON %s \n', date);
        fprintf(fid,'%s\t%s\n','COMMENT',char(comment));     

        %- File Name
        fprintf(fid,'%s\t%s\n','IMG_Raw',file_names.raw);    
        fprintf(fid,'%s\t%s\n','IMG_Filtered',file_names.filtered); 
        fprintf(fid,'%s\t%s\n','IMG_DAPI',file_names.DAPI); 
        fprintf(fid,'%s\t%s\n','IMG_TS_label',file_names.TS_label); 
        fprintf(fid,'%s\t%s\n','FILE_settings',file_names.settings); 

        %- Experimental parameters and analysis settings
        fprintf(fid,'PARAMETERS\n');
        fprintf(fid,'Pix-XY\tPix-Z\tRI\tEx\tEm\tNA\tType\n');
        fprintf(fid,'%g\t%g\t%g\t%g\t%g\t%g\t%s\n', par_microscope.pixel_size.xy, par_microscope.pixel_size.z, par_microscope.RI, par_microscope.Ex, par_microscope.Em,par_microscope.NA, par_microscope.type );

        if ~isempty(size_img)
            fprintf(fid,'%s\t%g\t%g\t%g\n','IMG_size',size_img(1),size_img(2),size_img(3)); 
        end


        %fprintf(fid,'ANALYSIS-SETTINGS \t%s\n', file_name_settings);   

        %- Outline of cell and detected spots
        for i_cell = 1:size(cell_prop,2)

            %- Outline of cell
            fprintf(fid,'%s\t%s\n', 'CELL_START', cell_prop(i_cell).label);

            fprintf(fid,'X_POS\t');
            fprintf(fid,'%g\t',cell_prop(i_cell).x);
            fprintf(fid,'\n');

            fprintf(fid,'Y_POS\t');
            fprintf(fid,'%g\t',cell_prop(i_cell).y);
            fprintf(fid,'\n');

            fprintf(fid,'Z_POS\t');
            if isfield(cell_prop(i_cell),'z')
                fprintf(fid,'%g\t',cell_prop(i_cell).z);
            end
            fprintf(fid,'\n');      

            fprintf(fid,'%s\n', 'CELL_END'); 

            %- Nucleus
            if isfield(cell_prop(i_cell),'pos_Nuc')
                for i_nuc = 1:size(cell_prop(i_cell).pos_Nuc,2)
                    fprintf(fid,'%s\t%s\n', 'Nucleus_START', cell_prop(i_cell).pos_Nuc(i_nuc).label);

                    fprintf(fid,'X_POS\t');
                    fprintf(fid,'%g\t',cell_prop(i_cell).pos_Nuc(i_nuc).x);
                    fprintf(fid,'\n');

                    fprintf(fid,'Y_POS\t');
                    fprintf(fid,'%g\t',cell_prop(i_cell).pos_Nuc(i_nuc).y);
                    fprintf(fid,'\n');  

                    fprintf(fid,'Z_POS\t');
                    if isfield(cell_prop(i_cell).pos_Nuc(i_nuc),'z')
                        fprintf(fid,'%g\t',cell_prop(i_cell).pos_Nuc(i_nuc).z);
                    end
                    fprintf(fid,'\n'); 

                    fprintf(fid,'%s\n', 'Nucleus_END'); 
                end
            end

            %- TS
            for i_TS = 1:size(cell_prop(i_cell).pos_TS,2)
                fprintf(fid,'%s\t%s\n', 'TxSite_START', cell_prop(i_cell).pos_TS(i_TS).label);

                fprintf(fid,'X_POS\t');
                fprintf(fid,'%g\t',cell_prop(i_cell).pos_TS(i_TS).x);
                fprintf(fid,'END\n');

                fprintf(fid,'Y_POS\t');
                fprintf(fid,'%g\t',cell_prop(i_cell).pos_TS(i_TS).y);
                fprintf(fid,'END\n');    

                fprintf(fid,'Z_POS\t');
                if isfield(cell_prop(i_cell).pos_TS(i_nuc),'z')
                    fprintf(fid,'%g\t',cell_prop(i_cell).pos_TS(i_nuc).z);
                end
                fprintf(fid,'\n');

                fprintf(fid,'%s\n', 'TxSite_END'); 
            end

            %- Spots
            % NOTE: fprintf works on columns - transformation is therefore needed
            if strcmp(flag_type,'spots')

                if isfield(cell_prop(i_cell),'spots_fit')
                    if not(isempty(cell_prop(i_cell).spots_fit));
                        spots_output   = [cell_prop(i_cell).spots_fit,cell_prop(i_cell).spots_detected,cell_prop(i_cell).thresh.in];

                        if flag_th_only
                            th_out = not(cell_prop(i_cell).thresh.in);       
                            spots_output(th_out,:) = [];     
                        end

                        if not(isempty(spots_output))
                            N_par = size(spots_output,2);            
                            string_output = [repmat('%g\t',1,N_par-1),'%g\n'];

                            fprintf(fid,'%s\n', 'SPOTS_START');          
                            fprintf(fid,'Pos_Y\tPos_X\tPos_Z\tAMP\tBGD\tRES\tSigmaX\tSigmaY\tSigmaZ\tCent_Y\tCent_X\tCent_Z\tMuY\tMuX\tMuZ\tITERY_det\tY_det\tX_det\tZ_det\tY_min\tY_max\tX_min\tX_max\tZ_min\tZ_max\tINT_raw\tINT_filt\tSC_det\tSC_det_norm\tTH_det\tTH_fit\n');

                            fprintf(fid, string_output,spots_output');  
                            fprintf(fid,'%s\n', 'SPOTS_END'); 
                        end
                    end
                end
            end


            %- Clusters
            if isfield(cell_prop(i_cell),'cluster_prop')            
                for i_c = 1:length(cell_prop(i_cell).cluster_prop)              
                    fprintf(fid,'%s\t%s\n', 'CLUSTER_START', cell_prop(i_cell).cluster_prop(i_c).label);

                    fprintf(fid,'Area\t%g\n',cell_prop(i_cell).cluster_prop(i_c).area);
                    fprintf(fid,'Intensity\t');

                    fprintf(fid,'%g\t',cell_prop(i_cell).cluster_prop(i_c).int);               
                    fprintf(fid,'\nX_POS\t');
                    fprintf(fid,'%g\t',cell_prop(i_cell).cluster_prop(i_c).x);
                    fprintf(fid,'\nY_POS\t');
                    fprintf(fid,'%g\t',cell_prop(i_cell).cluster_prop(i_c).y); 
                    fprintf(fid,'\nZ_POS\t');
                    fprintf(fid,'%g\t',cell_prop(i_cell).cluster_prop(i_c).z'); 

                    fprintf(fid,'Pos_Y\tPos_X\tPos_Z\tAMP\tBGD\tRES\tSigmaX\tSigmaY\tSigmaZ\tCent_Y\tCent_X\tCent_Z\tMuY\tMuX\tMuZ\tITERY_det\tY_det\tX_det\tZ_det\tY_min\tY_max\tX_min\tX_max\tZ_min\tZ_max\tINT_raw\tINT_filt\tSC_det\tSC_det_norm\tTH_det\tTH_fit\n');
                    %fprintf(fid,'\nPAR_Fit\t');
                    fprintf(fid,'%g\t',cell_prop(i_cell).cluster_prop(i_c).par_fit); 

                    fprintf(fid,'\nCLUSTER_END\n');

                end
            end
        end           
    end
    
    fclose(fid);    
end

cd(current_dir)
