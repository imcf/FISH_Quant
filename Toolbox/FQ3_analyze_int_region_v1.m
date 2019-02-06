function file_save_full = FQ3_analyze_int_region_v1(parameters )


%% Get parameters
name_str = parameters.name_str;


results_list = parameters.results_list;
folder_results = parameters.folder_results;
folder_image = parameters.folder_image;


%% Make cell out of list of filenames if only one is defined
if ~iscell(results_list)
    dum =results_list; 
    results_list = {dum};
end
N_files = length(results_list);


flags          = parameters.flags;
file_name_save = parameters.file_name_save;
proj_type      = parameters.proj_type;
filename_save  = parameters.filename_save;


%% Loop over all files
name_outline_all      = {};
name_cell_all      = {};
summary_quant  = [];

i_cell_total = 1;

img = FQ_img;

%- Loop over all files
for i_file =  1:N_files
    
    
    file_name      = results_list{i_file};
    file_name_full = fullfile(folder_results,file_name);

    disp(' ') 
    disp(['=== Analyze file ',num2str(i_file),' of ', num2str(N_files)]) 
    disp(['Name: ', file_name])
    disp(['Folder: ', folder_results])
    
    
    %== Load region file and extract outlines of cells
    flag_load = img.load_results(file_name_full,[]); 

    if flag_load.outline == 0
        warndlg('File cannot be opened',mfilename); 
    else
        
        %- New name for image
        name_image_old = img.file_names.raw;
        name_image_new = strrep(name_image_old, name_str.ch1, name_str.ch2);
        disp(['ORIGNAL name of image:    ', name_image_old])
        disp(['Name of image to ANALYZE: ', name_image_new])
        
        
        %- Which file name to save
        switch filename_save
        
            case 'Image-name [IF]'
                name_save = name_image_new;
                
            case 'Image-name [FISH]'
                name_save = name_image_old;    
                
            case 'Name of results file'
                name_save = file_name;                  
        end
        
        %- Load image
        disp('Loading image')
        [image_struct, status_file] =  img_load_stack_v1(fullfile(folder_image,name_image_new));
        
        if status_file == 0
            disp('FILE COULD NOT BE OPENED')
            disp(fullfile(folder_image,name_image_new))
            return
        end
        
        %- Choose appropriate projection
        disp('Perform Z-projection')
        switch proj_type

            case 'Median'
                img_proj      = median(image_struct.data,3);
       
            case 'Maximum'
                img_proj      = max(image_struct.data,[],3);              
            
            case 'Sum'
                img_proj      = sum(image_struct.data,3);
        end
        
        %- Basic information about image   
        [dim.Y, dim.X, dim.Z] = size(image_struct.data);              
         

        %=== Loop over cells
        cell_prop = img.cell_prop;
        
        for i_cell = 1:length(cell_prop)
          
            disp(['  == CELL ', num2str(i_cell), ' of ', num2str(length(cell_prop))]);
                 
            %- Get RNA counts
            N_total = size(cell_prop(i_cell).spots_fit,1);
            N_nuc   = sum(cell_prop(i_cell).in_Nuc);
            
            %- Cell label
            cell_label = cell_prop(i_cell).label;
            
            %- Get coordinates of cell
            cell_X = cell_prop(i_cell).x;
            cell_Y = cell_prop(i_cell).y;

           %- Generate mask 
           mask_cell_2D = poly2mask(cell_X, cell_Y, dim.Y, dim.X);     % Mask is defined by dim.Y x dim.X !!!
            
           %- Find perimeter
           perim_cell_2D = bwperim(mask_cell_2D);
            
            %- Get coordinates of nucleus (if defined)
            if isfield(cell_prop(i_cell),'pos_Nuc')
                if not(isempty(cell_prop(i_cell).pos_Nuc))
                    nux_X = cell_prop(i_cell).pos_Nuc.x;
                    nux_Y = cell_prop(i_cell).pos_Nuc.y;
 
                     %- Generate mask of nucleus
                     mask_nuc_2D = poly2mask(nux_X, nux_Y, dim.Y, dim.X);   % Mask is defined by dim.Y x dim.X !!!
                     
                    %- Find perimeter
                    perim_nuc_2D = bwperim(mask_nuc_2D);
                     
                     %- Generate mask of cytoplasm
                     mask_cyto_2D              = mask_cell_2D;
                     mask_cyto_2D(mask_nuc_2D) = 0;
                    
                    flag_nuc = 1;
                    
                else
                    flag_nuc = 0;
                    
                end
            else
                flag_nuc = 0;
            end
                
            %==== GET PROPERTIES OF DIFFERENT REGIONS
            
            %- CELL
            img_MIP_cell = img_proj;
            img_MIP_cell(not(mask_cell_2D)) = 0;

            int_cell_img     = double(img_MIP_cell(img_MIP_cell>0));
            int_cell.mean    = mean(int_cell_img);
            int_cell.median  = median(int_cell_img);
            int_cell.stdev   = std(int_cell_img);
            int_cell.size    = length(int_cell_img);
            int_cell.perim   = numel(find(perim_cell_2D==1));
            int_cell.sum     = sum(int_cell_img);
            
            %- Only if nucleus is defined
            if flag_nuc
                            
                %- NUCLEUS
                img_MIP_nuc = img_proj;
                img_MIP_nuc(not(mask_nuc_2D)) = 0;
                
                int_nuc_img     = double(img_MIP_nuc(img_MIP_nuc>0));
                int_nuc.mean    = mean(int_nuc_img);
                int_nuc.median  = median(int_nuc_img);
                int_nuc.stdev   = std(int_nuc_img);
                int_nuc.size    = length(int_nuc_img);
                int_nuc.perim  = numel(find(perim_nuc_2D==1));
                int_nuc.sum     = sum(int_nuc_img);
                
 
                %- CYTOPLASM
                img_MIP_cyto = img_proj;
                img_MIP_cyto(not(mask_cyto_2D)) = 0;
                
                int_cyto_img     = double(img_MIP_cyto(img_MIP_cyto>0));
                int_cyto.mean    = mean(int_cyto_img);
                int_cyto.median  = median(int_cyto_img);
                int_cyto.stdev   = std(int_cyto_img);
                int_cyto.size    = length(int_cyto_img);                
                int_cyto.sum     = sum(int_cyto_img);

            else
                disp('No nucleus defined') 
              
                int_nuc.mean    = 0;
                int_nuc.median  = 0;
                int_nuc.stdev   = 0;
                int_nuc.size    = 0;
                int_nuc.perim   = 0;
                int_nuc.sum    = 0;
                
                int_cyto.mean    = 0;
                int_cyto.median  = 0;
                int_cyto.stdev   = 0;
                int_cyto.size    = 0;
                int_cyto.sum    = 0;
            end
            
            
            if flags.output
                
                h = figure;
                subplot(2,2,1)
                imshow(img_proj,[])
                plot([cell_X,cell_X(1)],[cell_Y,cell_Y(1)],'r','Linewidth', 2)
                if flag_nuc
                    hold on
                    plot([nux_X,nux_X(1)],[nux_Y,nux_Y(1)],'y','Linewidth', 2)
                    hold off
                end
                axis off
                legend('Cell','Nucleus')
                title('Image with outlines')
                
                subplot(2,2,2)
                imshow(img_MIP_cell,[])
                axis off
                title('Entire cell')
                
                if flag_nuc
                    
                    subplot(2,2,3)
                    imshow(img_MIP_nuc,[])
                    axis off
                    title('Nucleus')
                    
                    subplot(2,2,4)
                    imshow(img_MIP_cyto,[])
                    axis off
                    title('Cytoplasm')                    
                    
                    
                end

                set(h,'Color','w')
                
            end
            
            %- Save summary of cell
            summary_quant(i_cell_total,:)  = [N_total N_nuc, ...
                                              int_cell.size int_cell.perim int_cell.sum int_cell.mean int_cell.median  int_cell.stdev , ...
                                              int_nuc.size  int_nuc.perim  int_nuc.sum  int_nuc.mean  int_nuc.median   int_nuc.stdev  , ... 
                                              int_cyto.size                int_cyto.sum  int_cyto.mean int_cyto.median  int_cyto.stdev ];
               
            name_outline_all{i_cell_total,1} = name_save;
            name_cell_all{i_cell_total,1}    = cell_label;
             
            i_cell_total = i_cell_total +1;
 
        end
    end
end


        
%% === Save summary file to same folder: ALL SPOTS
file_save_full = fullfile(folder_results,file_name_save);

%- Summarize all outputs
cell_data    = num2cell(summary_quant);   

cell_write_all  = [name_outline_all,name_cell_all,cell_data];
cell_write_FILE = cell_write_all';

N_col = size(cell_data,2); 
string_write = ['%s\t%s',repmat('\t%g',1,N_col), '\n'];

    
%- Write file    
fid = fopen(file_save_full,'w');
fprintf(fid,'FISH-QUANT\n');
fprintf(fid,'Analysis of intensity distribution in %s-projection of %s images  %s \n',proj_type,name_str.ch2, date);
fprintf(fid,'Name_File\tName_Cell\tN_RNA_total\tN_RNA_nuc\tCELL_area\tCELL_perimeter\tCELL_sum\tCELL_mean\tCELL_median\tCELL_std\tNUC_area\tNUC_perimeter\tNUC_sum\tNUC_mean\tNUC_median\tNUC_std\tCYTO_area\tCYTO_sum\tCYTO_mean\tCYTO_median\tCYTO_std\n');        
fprintf(fid,string_write, cell_write_FILE{:});
fclose(fid);

%- Display file name
disp(' ')
disp('===== RESULTS SAVED')
disp(file_save_full)

