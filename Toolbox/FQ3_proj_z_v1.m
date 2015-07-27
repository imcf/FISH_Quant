function proj_struct = FQ3_proj_z_v1(files_proc,param)
%% FUNCTION to generate z-projections for 3D stacks

    proj_struct = {};

    %% Parameters
    slice_select.operator = param.slice_select.operator;
    slice_select.perc     = param.slice_select.perc;

    %% Get input files

    switch files_proc.input_type

        %- Scan directories
        case 'dir'

            %- Get parameters
            path_scan = files_proc.path_scan;
            img_ext    = files_proc.img_ext;

            %- Make sure that there is a dot in front of the file extension
            if ~strcmp(img_ext(1),'.')
                img_ext = ['.',img_ext];
            end

            %- Scan directory
            if files_proc.flag_folder_rec
                string_search = fullfile(path_scan,'**',['*',img_ext]);
                file_list     = rdir(string_search);
                path_name     = '';   % Will be empty - path included in file-name!
            else

                string_search = fullfile(path_scan,['*',img_ext]);
                file_list     = dir(string_search);   
                path_name     = path_scan;
            end

            %- Return if no files were found
            if isempty(file_list)
                disp('== NO files found when searching directory')
                disp('File extensions are CASE sensitive')
                disp(['Search string: ', string_search])
                return

            else

                %- Convert output of dir/rdir to a cells
                file_list_short = struct('name',{file_list.name});
                file_name_all   = squeeze(struct2cell(file_list_short));
            end

        case 'file'

            file_name_all = files_proc.file_name_all;
            path_name     = files_proc.path_name;

    end

    %- Make sure that file-identifier that should be ignored are cell format
    if files_proc.flag_ignore
        if isfield(files_proc,'name_ignore') && ~iscell(files_proc.name_ignore)
            dum = files_proc.name_ignore;
            files_proc.name_ignore = {}; 
            files_proc.name_ignore{1} = dum;
        end
    end

    %% Loop over files
    if param.flags.show
        figure, set(gcf,'color','w')
    end


    N_files = length(file_name_all);


    for i_file = 1:N_files

        if param.flags.show
            figure, set(gcf,'color','w')
        end

        disp(' ')
        disp(['==== Processing ',num2str(i_file),'/',num2str(N_files)]);

        %== Load image file
        disp('==   Load image')
        file_name = file_name_all{i_file};

        %- Check if file-name contains string that should be ignored	
        if files_proc.flag_ignore

            if (sum(cellfun(@(x)~isempty(strfind(file_name,x)),files_proc.name_ignore)))
                disp(['Image ignored: ', file_name])
                continue
            end
        end

        %- Load image
        img = FQ_img;
        img.load_img(fullfile(path_name,file_name),'raw');
        img_loop  = uint16(img.raw);
        clear img;

        %- Check if image is already a projection
        NZ = size(img_loop,3);
        if NZ <= 3 
            disp('Fewer than 3 Z slices - no projection will be performed')
            continue
        end

        %- Make regular MIP
        MIP       = max(img_loop,[],3);  

        %== Slice selection
        disp(' ')
        disp('==   Slice selection')

        %- Perform only if slices should be removed
        if slice_select.perc < 1
            FM = zeros(size(img_loop,3),1);
            op = slice_select.operator;
            parfor i = 1:size(img_loop,3);
                FM(i) = fmeasure(double(img_loop(:,:,i)),op ,[]);
            end
            ind_sel = (FM >= quantile(FM,1-slice_select.perc ));    
            img_loop = img_loop(:,:,ind_sel);
        end


        %- Show results
        if param.flags.show
            subplot(1,2,1)
            z_ind = 1:length(FM);
            hold on
                plot(z_ind,FM,'k')
                plot(z_ind(ind_sel),FM(ind_sel),'or')
            hold off
            xlabel('z-slice'); ylabel('Focus')        
            title('Focus measurement per z-slice')
            legend('All','Selected for projection')
        end

        %== Projection
        disp(' ')
        disp('==   Z-Projection')
        %- Select image that will be projected
        switch param.project.type

            %--- Standard projection
            case 'standard'
                img_proj_3D = img_loop;
                clear img_loop

            %--- Local projection
            case 'local'

                img_focus = focusmeasure(double(img_loop), param.project.operator, param.project.windows_size);

                %- Get images with best slices
                N_slice     = param.project.N_slice;
                img_proj_3D = zeros(size(img_loop,1), size(img_loop,2),N_slice);

                [I1, I2]    = ndgrid(1:size(img_loop,1),1:size(img_loop,2));

                %- Loop to get best slices
                for i=1:N_slice

                    %- Get for each Z the best focus
                    [focus, slice]     = max(img_focus,[],3);
                    img_proj_3D(:,:,i) = img_loop(sub2ind(size(img_loop),I1,I2,slice));

                    %- Set the best values to zero to prepare for next iteration
                    img_focus(sub2ind(size(img_loop),I1,I2,slice)) = 0;
                end
        end

        %- Select projection method
        switch param.project.method

            case 'median'
            img_proj = median(img_proj_3D,3);

            case 'mean'
            img_proj = mean(img_proj_3D,3);

            case 'maximum'
            img_proj = max(img_proj_3D,[],3);

        end

        %- Show results
       if param.flags.show
            subplot(1,2,2)
            imshow(img_proj,[])
            axis image
            axis off
       end 

       %== Store results for inspection
       if param.flags.store
           proj_struct(i_file).MIP        =  MIP;
           proj_struct(i_file).proj_focus =  img_proj;
       end

       %=== Save image
       if param.flags.save


           %- Get file-name
           [path_img, name_save] = fileparts(fullfile(path_name,file_name));
           name_save = [name_save,'.tif'];
            if param.save.flag_prefix
                name_save = [param.save.prefix,name_save];
            end

            %- Get folder name
            switch param.save.flag_folder
                
                case 'replace'
                    folder_save = strrep(path_img, param.save.string_orig, param.save.string_new);
                    if strcmp(folder_save,path_img)
                        disp('== COULD NOT FIND STRING TO REPLACE IN FOLDER NAME')
                        disp(['Folder: ',path_img])
                        disp(['String to replace: ',param.save.string_orig])
                        return
                    end

                case {'same','sub'}
                    % Note for subfolder - will be generated next
                    folder_save = path_img;

            end

           %- Make subfolder
           if param.save.stats_folder_sub
                folder_save = fullfile(folder_save,param.save.name_sub );
           end


           %- Make folder if it doesn't exist already
           if ~exist(folder_save,'dir'); mkdir(folder_save); end

           %- Save  
           if ~exist(fullfile(folder_save,name_save),'file')
               imwrite(uint16(img_proj),fullfile(folder_save,name_save),'Compression', 'none');

               %- Save settings file
               file_settings = ['_FQ_Zproj_settings__',param.project.type,'.txt'];
               save_settings(fullfile(folder_save,file_settings),param);
           else
               disp('!!! FILE ALREADY EXISTS! Will not override. Please delete manually.')
           end
       end

    end

    disp('   ')            
    disp('=====   FINISHED')           
end

%% Function to save settings

function save_settings(file_name_full,par)

    fid = fopen(fullfile(file_name_full),'w');
    
    if fid < 0
        disp('= Settings file for Z-proj can not be saved')
        disp(file_name_full)
    else
    
        %- Header 
        fprintf(fid,'## FQ Z_projection %s \n\n', date);  

        %- Experimental parameters    
        fprintf(fid,'\n## Slice selection\n');
        fprintf(fid,'slice_sel_op=%s\n',    par.slice_select.operator);
        fprintf(fid,'slice_sel_perc=%g\n',  par.slice_select.perc);

        fprintf(fid,'\n## Z-projection\n');
        fprintf(fid,'proj_type=%s\n',  par.project.type);
        fprintf(fid,'proj_method=%s\n', par.project.method);

        if strcmp(par.project.type, 'local')
            fprintf(fid,'proj_op=%s\n',  par.project.operator);
            fprintf(fid,'proj_window=%g\n',  par.project.windows_size);
        end
    end
end
            
       