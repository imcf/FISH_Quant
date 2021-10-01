function [name_save, path_save] = FQ_save_results_v1(file_name_full,parameters)

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
    
    [name_save,path_save] = uiputfile(file_name_default,'Save outline / results of spot detection');
    file_name_full        = fullfile(path_save,name_save);
    [path_full_file,name_save_spots,ext_spots] = fileparts(file_name_full);
    file_name_spots_full  = fullfile(path_save,strcat(name_save_spots,'_spots.txt'));
    
    if name_save ~= 0
        
        %- Ask user to specify comment
        prompt = {'Comment (cancel for no comment):'};
        dlg_title = 'User comment for file';
        num_lines = 1;
        def = {''};
        comment = inputdlg(prompt,dlg_title,num_lines,def);
    end
    
else   
    
%     disp('There');
    [path_save, name_save,ext] = fileparts(file_name_full); 
    name_save = [name_save,ext];
    spots_name_save = [strcat(name_save, '_spots'),ext];

    if isempty(comment)
        comment = 'Automated outline definition (batch or quick-save)';
    end
end


% Only write if FileName specified
if name_save ~= 0
    
    fid = fopen(file_name_full,'w');
    fids = fopen(file_name_spots_full,'w');
    
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
        
        fprintf(fids, 'Cell_name\tPOS_X\tPOS_Y\tPOS_Z\tAMPNormRounded\n');
   
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

            %- Spots - standard spot detection
            
            % NOTE: fprintf works on columns - transformation is therefore needed
            if strcmp(flag_type,'spots')

                %- Are spots detected
                if isfield(cell_prop(i_cell),'spots_fit') && not(isempty(cell_prop(i_cell).spots_fit));
                    
                 
                    %- Is field with spots in nucleus defined
                    if isfield(cell_prop(i_cell),'in_Nuc') && not(isempty(cell_prop(i_cell).in_Nuc))
                        in_Nuc = double(cell_prop(i_cell).in_Nuc);
                    else 
                        N_spots = size(cell_prop(i_cell).spots_fit,1);
                        in_Nuc  = -ones(N_spots,1);
                    end

                    %- Save spots
                    % Get spots number and calculate the quantity of mRNA
                    spots_output   = [cell_prop(i_cell).spots_fit,cell_prop(i_cell).spots_detected,cell_prop(i_cell).thresh.in,in_Nuc];
                    [nrow,ncol]    = size(spots_output);
                    AMPNorm        = zeros(nrow,2);
                    AMPNorm(:,1)   = (spots_output(:,4))/(parameters.manual_value);
                    AMPNorm(:,2)   = round(AMPNorm(:,1));
                    spots_output2  = cat(2,spots_output(:,1:4),AMPNorm,spots_output(:,min(4+1,ncol):end));
                                        

                    if flag_th_only
                        th_out = not(cell_prop(i_cell).thresh.in);       
                        spots_output(th_out,:) = [];     
                    end

                    if not(isempty(spots_output))
                        N_par = size(spots_output2,2);            
                        string_output = [repmat('%g\t',1,N_par-1),'%g\n'];

                        fprintf(fid,'%s\n', 'SPOTS_START');          
                        fprintf(fid,'Pos_Y\tPos_X\tPos_Z\tAMP\tAMPNorm\tAMPNormRounded\tBGD\tRES\tSigmaX\tSigmaY\tSigmaZ\tCent_Y\tCent_X\tCent_Z\tMuY\tMuX\tMuZ\tITERY_det\tY_det\tX_det\tZ_det\tY_min\tY_max\tX_min\tX_max\tZ_min\tZ_max\tINT_raw\tINT_filt\tSC_det\tSC_det_norm\tTH_det\tTH_fit\tIN_nuc\n');
                        
                        
                        % print(spots_output');
                        fprintf(fid, string_output,spots_output2');  
                        fprintf(fid,'%s\n', 'SPOTS_END'); 
                        
                        row_number = size(spots_output2,1);
                        cell_names = repmat({cell_prop(i_cell).label},row_number,1);
                        cell_names_array = string(cell_names);  
                        str_mat = [cell_names_array(:,1) spots_output2(:,1) spots_output2(:,2) spots_output2(:,3) spots_output2(:,6)];
                        fprintf(fids,'%s\t%s\t%s\t%s\t%s\n',str_mat');                   
                    end
                end 
            end

      % NOTE: fprintf works on columns - transformation is therefore needed
            if strcmp(flag_type,'spots_GMM')

                %- Are spots detected
                if isfield(cell_prop(i_cell),'spots_fit_GMM') && not(isempty(cell_prop(i_cell).spots_fit_GMM));
                    
                    %- Save spots
                    spots_output   = [cell_prop(i_cell).spots_fit_GMM];


                    if not(isempty(spots_output))
                        N_par = size(spots_output,2);            
                        string_output = [repmat('%g\t',1,N_par-1),'%g\n'];

                        fprintf(fid,'%s\n', 'SPOTS_START');          
                        fprintf(fid,'Pos_Y\tPos_X\tPos_Z\n');

                        fprintf(fid, string_output,spots_output');  
                        fprintf(fid,'%s\n', 'SPOTS_END'); 
                        
                    end
                end 
            end          
        end           
    end
    
    fclose(fid);  
    fclose(fids);
else
    name_save = [];
end

assignin('base','cell_prop',cell_prop);
assignin('base','spots_output2',spots_output2);


%% -- Saves different CSV for the different amount of mRNA
%% Also get the number of mRNA depending on the quantity
%% And the fraction that it represents.


% [pathstr,name,ext] = fileparts(file_name_full);
% 
% totalNumber = size(spots_output2,1);
% maxRNA      = max(spots_output2(:,6));
% 
% disp(max(spots_output2(:,6)));
% 
% fractionRNA = zeros(maxRNA+1,3);
% 
% for i = 0:maxRNA
% %     disp(i)
%     fileName        = strcat(name,'mRNA',num2str(i),'.txt');
%     file_name_full  = fullfile(path_save,fileName);
%     
% %     disp(file_name_full);
%     
%    
%    
%     fid = fopen(file_name_full,'w');
%     
%     fprintf(fid,'Pos_Y\tPos_X\tPos_Z\n'); 
%     foundSpots = spots_output2(spots_output2(:,6)==i,1:3);
%     
%     disp(foundSpots);   
%  
%     N_par = size(foundSpots,2);            
%      string_output = [repmat('%g\t',1,N_par-1),'%g\n'];
%        
%     fprintf(fid, string_output,foundSpots');
%     fclose(fid);
%     
%     fractionRNA(i+1,1) = i;
%     fractionRNA(i+1,2) = size(foundSpots,1);
%     fractionRNA(i+1,3) = (size(foundSpots,1))/totalNumber;
%     
%     
% 
% end
% 
% fileName        = strcat(name,'fractionsRNA','.txt');
% file_name_full  = fullfile(path_save,fileName);
% 
% fid             = fopen(file_name_full,'w');
% 
% fprintf(fid,'RNAQuantity\tRNANumber\tRNAFraction\n');
% N_par = size(fractionRNA,2);            
% string_output = [repmat('%g\t',1,N_par-1),'%g\n'];
% 
% fprintf(fid,string_output,fractionRNA);
% 
% fclose(fid);

%% -- Goes to current dir
cd(current_dir)
