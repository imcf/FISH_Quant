function cell_label_to_FQ_v2(parameters)
% Florian Mueller, Institut Pasteur
% email: muellerf.research@gmail.com

    %= Get parameters
    names_struct   = parameters.names_struct;
    file_names     = parameters.file_names;
    path_name      = parameters.path_name;

    % Flag to determine which region is background
    options.flag_bgd = parameters.flag_bgd;
    
    %% Prepare loop parameters
    if ~iscell(file_names)
        dum=file_names;
        file_names={dum};
    end

    N_files = length(file_names);

 
    %% Loop over files
    for i_file = 1:N_files

        %- Update info and get file-name
        fprintf('\n=== ANALYZE file %g of %g\n',i_file,N_files)

        name_analyze = file_names{i_file};
        fprintf('Name: %s\n',name_analyze);

        %- Analyze file-name
        % Contains path when coming from a recursive directory scan
        [path_loop, name, ext] = fileparts(name_analyze);
        if isempty(path_loop)
            path_loop = path_name;
        end
        name_img_loop = [name ext];
        
        %- Check if suffix for cell mask is present
        pos_string_cell = strfind(name_img_loop,names_struct.suffix.cell);

        if isempty(pos_string_cell)
           disp('Not a mask for cells!') 
        else

            %= Conversion for cells
            disp('RUNNING CONVERSION for cells ...') 
            [reg_CELLS,img_size] = label_to_region(fullfile(path_loop,name_img_loop),options);

            %== Name for cel
            name_cell = name_img_loop(1:pos_string_cell-1);
            
            %== Infer name of nuclear outline and check if it exists
            name_dum      = [name_img_loop(1:pos_string_cell-1),names_struct.suffix.nuc];
            name_mask_nuc = strrep(name_dum, names_struct.suffix.FISH, names_struct.suffix.DAPI);               
            name_mask_nuc_full  = fullfile(path_loop,name_mask_nuc);

            if exist(name_mask_nuc_full,'file')
                fprintf('Name (nucleus): %s\n',name_mask_nuc);
                disp('RUNNING CONVERSION for nuclei ...') 
                reg_NUC  = label_to_region(fullfile(path_loop,name_mask_nuc),options);
                name_nuc = strrep(name_cell, names_struct.suffix.FISH, names_struct.suffix.DAPI);
            else
                fprintf('Name (nucleus): %s DOES NOT EXIST!\n',name_mask_nuc);
                reg_NUC = {};
                name_nuc = [];
            end

            %== Generate cell_prop to save outline file
            cell_prop = make_cell_prop(reg_CELLS,reg_NUC,img_size);
 
            %== Save outlines
            parameters.names_struct.cell = name_cell;
            parameters.names_struct.nuc  = name_nuc;
            parameters.names_struct.path = path_loop;
            parameters.cell_prop         = cell_prop;  
            
            %- First color: either if no second color or if second color
            %               and saving of first color enabled
            if ~parameters.save_2nd.status || (parameters.save_2nd.status && ~parameters.save_2nd.status_not_1st)
                
                file_name_outline            = save_outline(parameters,0);
                fprintf('Outline saved: %s\n',file_name_outline);
            end
            
            %- Second color 
            if parameters.save_2nd.status            
                file_name_outline            = save_outline(parameters,1);
                fprintf('Outline saved: %s\n',file_name_outline);
            end 
                

        end   
    end
end

% =========================================================================
% == Convert cell label to FQ region
% =========================================================================

function [reg_prop,img] = label_to_region(file_name_full,options)
    % Function that opens mask with segmentation results and provides bounding
    % polygon for each region.
    %
    % ==== INPUT
    %   file_name_full   ... File name of segmentation mask
    %   options.flag_bgd ... specifies what is background
    %      index_0   ... remove region with index 0
    %      largest   .... Remove largest region
    %      none      .... Don't remove any region
    %
    % ==== OUTPUT
    %   reg_prop    ... Structure containing polygon of each region
    %   img         ... Loaded image of mask (with function img_load_stack_v1)

    flag_debug = 0;  % Enables certain output for debugging

    %% Initiate parameters
    reg_prop = {};
    img      = {};

    %% Open image
    [img, status_file] = load_stack_data_v7(file_name_full);
    img.NZ = size(img.data,3);
    
    %- Check if file was loaded
    if status_file == 0
        disp([mfilename ': could not load cell mask.'])
        disp(['File: ', file_name_full])
        return
    end

    %- Check if image is 2D
    if img.NZ ~= 1
        disp([mfilename ': works only with 2D images. Provided image is 3D'])
        disp(['File: ', file_name_full])
        return
    end


    %% Remove background
    index_unique = unique(img.data(:));

    switch options.flag_bgd 

        %- Remove region with index 0
        case 'index_0'
            index_unique(find(index_unique == 0)) = [];

        %- Remove largest region    
        case 'largest'

            % Loop to determine size of each region
            for i_loop = 1:length(index_unique)

                %- Get index of region
                N_pix_all(i_loop,1) = length(find(img.data == index_unique(i_loop)));    
            end

            [dum, ind_max]        = max(N_pix_all);
            index_unique(ind_max) = [];


        %- Do nothing    
        case 'none'

        %- Invalid option    
        otherwise
            disp([mfilenam ': invalid selection for background removal'])
            return
    end


    %% Loop over region
    mask_0   = zeros(size(img.data));
    ind_good = 1;

    if length(index_unique) == 0
        disp('NO CELLS FOUND') 
    end
    
    for i_ind = 1:length(index_unique)

        %- Get index of region
        ind_loop           = index_unique(i_ind);
        ind_loop_pixel     = img.data == ind_loop;    

        %- Generate binary mask and convert to polygon
        mask_loop                 = mask_0;
        mask_loop(ind_loop_pixel) = 1;       

        B = bwboundaries(mask_loop,'noholes');

        N_poly = length(B);

        %- Check if there are multiple polygons
        if N_poly == 1
            poly_loop = B{1};   
            reg_prop(ind_good,1).x =  poly_loop(:,2);
            reg_prop(ind_good,1).y =  poly_loop(:,1);
            ind_good= ind_good+1;
        else
            disp('MORE THAN ONE POLYGON FOUND. Will choose largest.')

            N_points  = 0;
            ind_large = 0;

            if flag_debug
                colors = distinguishable_colors(N_poly);
                figure; imshow(mask_loop,[]); hold on;
                axis image
            end

            %- Loop over polygon and find largests
            for i_poly = 1:N_poly

                poly_loop = B{i_poly};
                length(poly_loop(:,1));

                if flag_debug
                    plot(poly_loop(:,2),poly_loop(:,1),'Color',colors(i_poly,:),'LineWidth',2)
                end

                if length(poly_loop(:,1)) > N_points

                    ind_large = i_poly;
                    N_points  = length(poly_loop(:,1));
                end
            end

            poly_loop = B{ind_large};

            reg_prop(ind_good,1).x =  poly_loop(:,2);
            reg_prop(ind_good,1).y =  poly_loop(:,1);
            ind_good = ind_good+1;

        end  
    end
end

% =========================================================================
% == Put together information that will be saved in FQ outline
% =========================================================================
function cell_prop = make_cell_prop(reg_CELLS,reg_NUC,img_size)

    flag_debug = 0;

    %== [1] Generate cell_prop structure based on outlined cells
    cell_prop = struct('label', {}, 'x', {}, 'y', {}, 'pos_Nuc', {}, 'pos_TS', {});

    N_cells = size(reg_CELLS,1);
    for i_cell = 1:N_cells

        %- Get coordinates
        cell_prop(i_cell).x = reg_CELLS(i_cell).x;
        cell_prop(i_cell).y = reg_CELLS(i_cell).y;   

        %- Assign name
        cell_prop(i_cell).label = ['Cell_CP_', num2str(i_cell)];

    end

    % == [2] Loop over all nuclei and try to assign them
    N_Nuc = size(reg_NUC,1);

    for i_nuc = 1:N_Nuc

        %- Get coordinates of nucleus
        Nuc_Y = reg_NUC(i_nuc).y;
        Nuc_X = reg_NUC(i_nuc).x;   

        %- Loop over all cells to find the one that contains the nucleus
        ind_cell_Nuc = [];

        for i_cell = 1:N_cells

            %- Get coordinates
            cell_X = cell_prop(i_cell).x;
            cell_Y = cell_prop(i_cell).y;   

            %- Check if nuc is within or on the polygon for the cells
            [in_cell, on_cell] = inpolygon(Nuc_X,Nuc_Y,cell_X,cell_Y);
            cell_tot = in_cell | on_cell;

            if flag_debug
                if sum(cell_tot) > 1

                    figure; set(gcf,'Color','white')
                    subplot(2,2,1)
                    fill(Nuc_X,Nuc_Y,'r')
                    title('Nucleus')
                    axis image

                    subplot(2,2,2)
                    fill(cell_X,cell_Y,'r')
                    title('Cell')
                    axis image

                    subplot(2,2,3)
                    hold on
                    fill(cell_X,cell_Y,'g')
                    fill(Nuc_X,Nuc_Y,'r')
                    axis([1 img_size.x 1 img_size.y])
                    axis square                
                    box on

                end
            end

            if sum(cell_tot) >= 0.9*length(Nuc_X)   % Allow somewhat larger nuclei than cells - can help with imprecise conversion from segmentation masks to outlines
                ind_cell_Nuc = i_cell; 
            end


           %- Plots to debug 
           if flag_debug

               if sum(cell_tot) > 1
                    in = cell_tot;

                    subplot(2,2,4)
                    hold on
                        plot(Nuc_X(in),Nuc_Y(in),'+g')
                        plot(Nuc_X(~in),Nuc_Y(~in),'+r')
                    hold off
                     axis square                
                    box on

                    axis([1 img_size.x 1 img_size.y])
               end
            end      
        end


        %- Assign to cell
        if not(isempty(ind_cell_Nuc))

            %- If nucleus is already defined ask if old one should be deleted
            if not(isempty(cell_prop(ind_cell_Nuc).pos_Nuc))         
                disp('Cell already has a nucleus - new one will not be assigned'); 
                disp(['Index cell:', num2str(ind_cell_Nuc)]);
                disp(['Index nuc :', num2str(i_nuc)]);

            else

                %- Save position
                pos_Nuc.x        = Nuc_X;  
                pos_Nuc.y        = Nuc_Y;  
                pos_Nuc.label    = 'Nuc_CP';     

                %- Update information of this cell
                cell_prop(ind_cell_Nuc).pos_Nuc = pos_Nuc;    
            end  

        else
            disp('Nucleus could not be assigned to any cell. Must be ENTIRELY within the cell.')
            disp(['Index nuc :', num2str(i_nuc)]);

        end    
    end
end

% =========================================================================
% == SAVE OUTLINE
% =========================================================================
function [file_name_outline, file_name_outline_full]  = save_outline(parameters,flag_second)

    %= Get relevant paramters
    ext_orig         = parameters.ext_orig;
    names_struct     = parameters.names_struct;
    par_microscope   = parameters.par_microscope;
    version          = parameters.version;
    cell_prop        = parameters.cell_prop;
    path_name        = parameters.names_struct.path;

    %- Suffix and extension
    suffix    = names_struct.suffix;

    %- Depending on how directories were scanned path_name might be empty
    %  (recursive dir) or not (regular dir). If scanned by rdir, pathname
    %  is contained in file-name
    name_FISH_no_ext = names_struct.cell;
    name_FISH        = [names_struct.cell,ext_orig];
    name_DAPI        = [ names_struct.nuc,ext_orig];

    %- Remove parts of the file-name
    name_FISH_no_ext = strrep(name_FISH_no_ext, parameters.names_struct.name_remove, '');
    name_FISH        = strrep(name_FISH, parameters.names_struct.name_remove, '');
    name_DAPI        = strrep(name_DAPI, parameters.names_struct.name_remove, '');

    
    %- Create outline for second color
    if flag_second
        name_FISH        = strrep(name_FISH, suffix.FISH, parameters.save_2nd.suffix);
        name_FISH_no_ext = strrep(name_FISH_no_ext, suffix.FISH, parameters.save_2nd.suffix);
    end
    
    %- Save file-names
    file_names.raw      = name_FISH;
    file_names.DAPI     = name_DAPI;
    file_names.filtered = [];
    file_names.TS_label = [];
    file_names.settings = [];
    

    %- Get folder name
    switch parameters.save.flag_folder
        
        case 'replace'
            folder_save = strrep(path_name, parameters.save.string_orig, parameters.save.string_new);
            if strcmp(folder_save,path_name)
                disp('== COULD NOT FIND STRING TO REPLACE IN FOLDER NAME')
                disp(['Folder: ',path_name])
                disp(['String to replace: ',parameters.save.string_orig])
                file_name_outline = 'NOT SAVED!!! '; file_name_outline_full =[];                
                return
            end

        case 'sub'
            folder_save = fullfile(path_name,parameters.save.name_sub );

        case 'same'
            folder_save = path_name;

    end

   %- Make folder if it doesn't exist already & generate file-name
   if ~exist(folder_save,'dir'); mkdir(folder_save); end
    
   %= Parameters to save results
   par_outline.path_save           = path_name;
   par_outline.cell_prop           = cell_prop;
   par_outline.file_names          = file_names;
   par_outline.version             = version;
   par_outline.flag_type           = 'outline';  
   
   if ~flag_second
        par_outline.par_microscope  = par_microscope;
   else
       par_outline.par_microscope = parameters.save_2nd.par_microscope_c2;
       folder_save = fullfile(folder_save,['_FQ_outline_',parameters.save_2nd.suffix]);
   end
 
   %- Make folder if it doesn't exist already & generate file-name
   if ~exist(folder_save,'dir'); mkdir(folder_save); end
  
   file_name_outline = [name_FISH_no_ext,'_outline.txt'];
   file_name_outline_full = fullfile(folder_save,file_name_outline);
   
   FQ_save_results_v1(file_name_outline_full,par_outline);
end