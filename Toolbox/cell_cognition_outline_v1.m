function cell_cognition_outline_v1(parameter)


%- Get parameters
DAPI_identifier        = parameter.DAPI_identifier;
cell_identifier        = parameter.cell_identifier;
method_nucleus         = parameter.method_nucleus;
method_cell            = parameter.method_cell;
par_microscope         = parameter.par_microscope;
path_plate             = parameter.path_plate;
outline_folder_name    = parameter.outline_folder_name;
options.flag_bgd       = 'index_0';
extension              = parameter.extension;
flag_second            = 0;


%- Loop over folders
for i_plate = 1:length(path_plate)
      
   %- List folder content and get only subfolders
   fold = dir(path_plate{i_plate});
   isub = [fold(:).isdir]; % returns logical vector
   fold = {fold(isub).name}';
   
   %- Find well subfolders
   is_well     = cellfun(@(x) ~isempty(regexp(x,'^w+[0-9]_*')), fold);    % String starts (^) with a w, followed by one or more (+) numbers ([0-9], followed by a _
   well_folder = fold(is_well);
   
   for i_well = 1:size(well_folder,1)
       
       well_split            = strsplit(well_folder{i_well},'_');
       ind_well              = well_split{1}(2:end);
       well_folder{i_well,2} = str2num(ind_well);
       
   end
     
   
   %- 
   file = dir(strcat(path_plate{i_plate},'/analyzed/images/_labels/',cell_identifier,'/',method_cell));
   file = file(arrayfun(@(x) x.name(1), file) ~= '.');
   isub = [file(:).isdir]; % returns logical vector
   file = {file(~isub).name}';
   


   %- Loop over all masks
   for i_mask = 1:length(file) 
       
       
       
       %%%% Get the name of the segmentation mask
       
       
      parameter.path_name = strcat(path_plate{i_plate},'/analyzed/images/_labels/',cell_identifier,'/',method_cell);      
      
      mask_path{1} = strcat(path_plate{i_plate},'/analyzed/images/_labels/',cell_identifier,'/',method_cell,'/',file{i_mask}); % FISH channel
      mask_path{2} = strcat(path_plate{i_plate},'/analyzed/images/_labels/',DAPI_identifier,'/',method_nucleus,'/',file{i_mask}); % DAPI channel
      
      
      %%% Get the info separetely ( position, well ) 
      mask_split   = strsplit(file{i_mask}, '_');    
      position     = mask_split{2};
      well         = str2num(mask_split{1}(2:end));
      
      %%% Get the name of the gene identfier which is present in image
      %%% original title but not in the well folder title. We go into the
      %%% projection folder ZPROJ
       
      % We get all the files inside the ZPROJ file
      
      
      well_pointer = find([[well_folder{:,2}] == well ] == 1); 
     
      ZPROJ_path            = fullfile(path_plate{i_plate},well_folder{well_pointer},'ZPROJ');
      file_gene_identifier  = dir(ZPROJ_path); 
      file_gene_identifier  = {file_gene_identifier.name}';

      
      %%% We keep the files that correspond to our well
      ind_well_str          = strcat('^w+',num2str(well),'_*');
      is_file               = cellfun(@(x) ~isempty(regexp(x,ind_well_str)), file_gene_identifier);    % String starts (^) with a w, followed by one or more (+) numbers ([0-9], followed by a _
      file_gene_identifier  = file_gene_identifier(is_file); 
      
      % we get from the title the gene identiier corresponding to the mask
      file_gene             = file_gene_identifier(1);
      file_split            = strsplit(file_gene{1},'_');
      gene_identifier       = file_split(4); 
      
      
      % Now we build the outline name ( same as the original image ) 
      
      channel   = strsplit(file_split{6},'.');
      channel   = channel(1);
      file_name = strcat('w',num2str(well),'_',file_split(2),'_',file_split(3),'_',gene_identifier,'_p',position,'_');
      
      
      outline_name = strcat(path_plate{i_plate},'/',well_folder{well_pointer},'/',outline_folder_name,'/', file_name,cell_identifier,'_outline.txt');
      
      parameter.outline_name = outline_name{1};
       
      if  exist(strcat(path_plate{i_plate},'/',well_folder{well_pointer},'/',outline_folder_name)) ~= 7
          mkdir(strcat(path_plate{i_plate},'/',well_folder{well_pointer},'/',outline_folder_name))
      end
 
      
      [reg_nuc img ]  = label_to_region(mask_path{2}, options); 
       reg_cell       = label_to_region(mask_path{1}, options); 
      
      img_size = img.size;
      
      cell_prop            = make_cell_prop(reg_cell,reg_nuc,img_size);
      parameter.cell_prop  = cell_prop;

      name_FISH = strcat(file_name,cell_identifier,extension)  ;  %strcat(well_folder{well},'_p',position,'_',cell_identifier,extension);     
      name_DAPI = strcat(file_name,DAPI_identifier,extension) ;  %strcat(well_folder{well},'_p',position,'_',DAPI_identifier,extension);

      parameter.name_FISH = name_FISH{1};
      parameter.name_DAPI = name_DAPI{1};
      

      save_outline(parameter, flag_second) 
      
      
   end
   
end  
    
      
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
    [image] = imread(file_name_full);
    img.NZ = size(image,3);
    img.data = image; 
    img.size = size(image); 
    
  

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

    for i_ind = 1:length(index_unique)

        %- Get index of region
        ind_loop           = index_unique(i_ind);
        ind_loop_pixel     = img.data == ind_loop;    

        %- Generate binary mask and convert to polygon
        mask_loop                 = mask_0;
        mask_loop(ind_loop_pixel) = 1;       

        B = bwboundaries(mask_loop,8);

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
      
      
      
      
     
function cell_prop = make_cell_prop(reg_cell,reg_nuc,img_size)

    flag_debug = 0;

    %== [1] Generate cell_prop structure based on outlined cells
    cell_prop = struct('label', {}, 'x', {}, 'y', {}, 'pos_Nuc', {}, 'pos_TS', {});

    N_cells = size(reg_cell,1);
    for i_cell = 1:N_cells

        %- Get coordinates
        cell_prop(i_cell).x = reg_cell(i_cell).x;
        cell_prop(i_cell).y = reg_cell(i_cell).y;   

        %- Assign name
        cell_prop(i_cell).label = ['Cell_CP_', num2str(i_cell)];

    end

    % == [2] Loop over all nuclei and try to assign them
    N_Nuc = size(reg_nuc,1);

    for i_nuc = 1:N_Nuc

        %- Get coordinates of nucleus
        Nuc_Y = reg_nuc(i_nuc).y;
        Nuc_X = reg_nuc(i_nuc).x;   

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

            if sum(cell_tot) >= 0.5*length(Nuc_X)   % Allow somewhat larger nuclei than cells - can help with imprecise conversion from segmentation masks to outlines
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
      
      
      
      
      
       
    

function [file_name_outline, file_name_outline_full]  = save_outline(parameter,flag_second)

    %= Get relevant paramters
    
    par_microscope         = parameter.par_microscope;
    version                = 'v2e';
    cell_prop              = parameter.cell_prop;
    path_name              = parameter.path_name;
    file_name_outline_full = parameter.outline_name;
    name_FISH              = parameter.name_FISH; 
    name_DAPI              = parameter.name_DAPI;
    
     %- Save file-names
    file_names.raw      = name_FISH;
    file_names.DAPI     = name_DAPI;
    file_names.filtered = [];
    file_names.TS_label = [];
    file_names.settings = [];
    
    
    
    
    %= Parameters to save results
   par_outline.path_save           = path_name;
   par_outline.cell_prop           = cell_prop;
   par_outline.file_names          = file_names;
   par_outline.version             = version;
   par_outline.flag_type           = 'outline';  

    

  
   if ~flag_second
        par_outline.par_microscope      = par_microscope;
   else
       par_outline.par_microscope = parameter.save_2nd.par_microscope_c2;
   end
   FQ_save_results_v1(file_name_outline_full,par_outline);
 end
 
      
end
      
 