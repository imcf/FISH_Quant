function enrich_quant = FISH_IF_enrich_v1(file_info,param)

flagDebug = 0;

%% Get files to be processed
folder_results = file_info.folder_results;
folder_images = file_info.folder_images;  
name_results = file_info.name_results;

txt_smFISH = file_info.txt_smFISH;
txt_protein = file_info.txt_protein;      

%% Get different quantification parameters

%- Size of cropping region around RNA
size_crop  = param.size_crop;
flag_quant = param.flag_quant;   % How crop should be analyze - median or max

%- Internal no-coloc control
pix_offset = param.pix_offset;

%- Restrict cells to specified expression level
nRNA_min = param.nRNA_min;
nRNA_max = param.nRNA_max;

%% Loop over files
img = FQ_img;
iCell_all = 1;

for iFile = 1:length(name_results)
    
    %- Load file and check if there are cells
    file_loop = fullfile(folder_results,name_results{iFile});
    disp(file_loop)
    img.load_results(file_loop,[]);
    if isempty(img.cell_prop); disp('No cells'); continue; end
    
    %- Open GFP file
    [img_GFP_struct, status_file] = img_load_stack_v1(fullfile(folder_images,strrep(img.file_names.raw,txt_smFISH,txt_protein)),'');
    if ~status_file; disp('No GFP image'); continue; end
    
    img_GFP = img_GFP_struct.data;
    dim.X   = img_GFP_struct.NX;
    dim.Y   = img_GFP_struct.NY;
    dim.Z   = img_GFP_struct.NZ;
    
    %- Loop over cells
    for iCell = 1:length(img.cell_prop)
        
        %==== Get all spots outside of the nucleus & peform quality checks
        thresh_in = logical(img.cell_prop(iCell).thresh.in);        
        spots_detected = img.cell_prop(iCell).spots_detected(thresh_in,1:3);
         spots_int = img.cell_prop(iCell).spots_detected(thresh_in,10);
         
        %- Not co-loc control
        spots_detected(:,1:2) = spots_detected(:,1:2) - pix_offset;

        %- Remove RNAs in the nucleus
        pos_Nuc        = img.cell_prop(iCell).pos_Nuc;
        if isempty(pos_Nuc); disp('No nuc'); continue; end
            
        pos_Cell.x  = img.cell_prop(iCell).x;
        pos_Cell.y  = img.cell_prop(iCell).y;
        ind_cyto    = ~inpolygon(spots_detected(:,1), spots_detected(:,2),pos_Nuc.y,pos_Nuc.x) ;

        %- Check if expression levels are within specified range
        if length(ind_cyto)<nRNA_min || length(ind_cyto)>nRNA_max 
            disp('Not enough or too many RNAs. Cell will be excluded.')
            disp(length(ind_cyto))
            continue; 
        end
        
        
        %==== Get GFP intensity in cytoplasm
        
        %- For MIP get detected z-range
        min_z = min(spots_detected(:,3));
        max_z = max(spots_detected(:,3));
        GFP_MIP = max(img_GFP(:,:,min_z:max_z),[],3);
        
        mask_cell     = poly2mask(pos_Cell.x, pos_Cell.y,  dim.Y, dim.X);
        mask_nuc      = poly2mask(pos_Nuc.x, pos_Nuc.y,  dim.Y, dim.X);
        mask_cyto     = mask_cell;
        mask_cyto(mask_nuc==1) = 0;
        
        if flagDebug
            figure, set(gcf,'color','w') 
            subplot(2,2,1), imshow(GFP_MIP,[])
            subplot(2,2,2), imshow(mask_cell,[])
            subplot(2,2,3), imshow(mask_nuc,[])
            subplot(2,2,4), imshow(mask_cyto,[])
        end
        
        %- Loop over all RNAs
        int_RNA = [];
        
        for iRNA = 1:size(spots_detected,1)
 
            %- Is RNA in nucleus?
            if ~ind_cyto(iRNA); continue; end
            
            %- Crop around
            y_min = spots_detected(iRNA,1)-size_crop.xy;
            y_max = spots_detected(iRNA,1)+size_crop.xy;
            
            x_min = spots_detected(iRNA,2)-size_crop.xy;
            x_max = spots_detected(iRNA,2)+size_crop.xy;
            
            z_min = spots_detected(iRNA,3)-size_crop.z;
            z_max = spots_detected(iRNA,3)+size_crop.z;
            
            if y_min < 1;     y_min = 1;     end
            if y_max > dim.Y; y_max = dim.Y; end
            
            if x_min < 1;     x_min = 1;     end
            if x_max > dim.X; x_max = dim.X; end
            
            if z_min < 1;     z_min = 1;     end
            if z_max > dim.Z; z_max = dim.Z; end
            
            %- For raw data
            img_crop = double(img_GFP(y_min:y_max,x_min:x_max,z_min:z_max));
            
            switch flag_quant
                
                case 'median'
                    int_RNA = [int_RNA;median(img_crop(:))];  
                    
                case 'max'
                    int_RNA = [int_RNA;max(img_crop(:))];  
            end
        end
        
        %- Save data
        int_RNA_cells{iCell_all}     = int_RNA;
        median_RNA_int(iCell_all,1)  = median(spots_int);
        
        GFP_cyto_median(iCell_all) = median(GFP_MIP(mask_cyto));
        
        N_RNA_cyto(iCell_all)      = sum(ind_cyto);
        N_RNA(iCell_all)           = size(spots_detected,1);
        
        iCell_all                  = iCell_all+1;
    end
end


%=== Post analysis
enrich_quant = [];
for iCellTotal = 1:length(int_RNA_cells)
    enrich_quant(iCellTotal,1) = N_RNA(iCellTotal);
    enrich_quant(iCellTotal,2) = N_RNA_cyto(iCellTotal);
    enrich_quant(iCellTotal,3) = median(int_RNA_cells{iCellTotal});
    enrich_quant(iCellTotal,4) = GFP_cyto_median(iCellTotal);
end

%- Calculate enrichment
enrich_quant(:,5) = enrich_quant(:,3) ./ enrich_quant(:,4);
