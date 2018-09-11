function table_feat_all = analyze_smFISH_v2(file_info,param,table_feat_all)
% Script to analyze a specified FQ outline file, performs spot detection,

%- Initiate FQ object
FQ_obj         = FQ_img;
table_feat_img = table;   %- Table to store all features

%- Take settings and experimental parameters from loaded setting file
FQ_obj.settings       = param.settings_loaded;
FQ_obj.par_microscope = param.par_microscope_loaded;

%% Load outline file and corresponding image file
flags.load_settings = 0;
flags.use_tiffread  = 1; % Use tiffread to avoid java error "Too many files open"
status_open = FQ_obj.load_results(file_info.outline_name,file_info.path_image,flags);

%- Outline file can't be opened
if status_open.outline ~= 1
    disp('>>> Outline could not be opened');
    disp(file_info.outline_name)
    return
end

%- Image can't be opened
if status_open.img ~= 1
    disp('>>> Image could not be opened');
    disp(['Folder: ',file_info.path_image])
    disp(['File  : ',FQ_obj.file_names.raw])
    return
end

%% Some housekeeping for either simulated or experimental data

%- Simulated data
if param.flags.is_simulation
    
    %=== For simulations more information is extracted
    info_sim = get_info_sim_v1(FQ_obj,file_info);
    file_info.path_results =  info_sim.path_results;
    file_info.path_results_localization =  info_sim.path_results_localization;
    
    cell_label    = info_sim.cell_label;
    name_MIP_full = info_sim.name_MIP_full;

    gene_name = 'simulated';
    
else
    
    %- This could be the name of the gene
    cell_label    = 'NR';
    name_MIP_full = 'NR'; % Full file name to the MIP
    
    %- Get positions of file-separators    
    idcs   = strfind(file_info.path_image,filesep);
    
    %- File-separator at the end
    if idcs(end) == length(file_info.path_image)
        gene_name = file_info.path_image(idcs(end-1)+1:idcs(end)-1);
        
    %- Not at the end
    else
       gene_name = file_info.path_image(idcs(end)+1:end); 
    end
    
    %- Folder to save localization table
    if ~isempty(param.features)
        folder_locFeatures = fullfile(file_info.path_results, 'locFeatures');
        if ~exist(folder_locFeatures); mkdir(folder_locFeatures); end
        file_info.path_results_localization = folder_locFeatures;
    end
end


%% ==================================================================
%===== Filtering of image

%- Filter - save also background image if DualGaussian filter is used.
[status_filter, img_bgd]      = FQ_obj.filter;

FQ_obj.dim.X = size(FQ_obj.raw,2) ;
FQ_obj.dim.Y = size(FQ_obj.raw,1) ;
FQ_obj.dim.Z = size(FQ_obj.raw,3) ;

%- Create background image for GMM if not the same settings for the
%spot-detection filter were used
if ~(strcmp(FQ_obj.settings.filter,'3D_2xGauss') && ...
    (FQ_obj.settings.filter.kernel_size.bgd_xy ==  param.GMM.kernel_size.bgd_xy) && ...
    (FQ_obj.settings.filter.kernel_size.bgd_z ==  param.GMM.kernel_size.bgd_z))

    %- Assign settings
    FQ_obj.settings.filter.kernel_size = param.GMM.kernel_size;
    FQ_obj.settings.filter.method      = '3D_2xGauss';

    %- Perform filtering
    img_filtered             = FQ_obj.filt;  %- Save filtered image
    [status_filter, img_bgd] = FQ_obj.filter;
    FQ_obj.filt              = img_filtered;

end

%- Fit will be done on BACKGROUND subtracted image, and not on raw
%  image as done for the older version of FISH-quant. This allows
%  to obtain the fitting estimates for individual mRNA molecules in
%  the same image as will be used for the GMM.

im_bgd_substracted = FQ_obj.raw - img_bgd ;
FISH_img_raw       = FQ_obj.raw; % Used for feature calculation
FQ_obj.raw         = im_bgd_substracted ;

%- Make sure that the old settings are still there
FQ_obj.settings = param.settings_loaded;


%% ==================================================================
% === Prepare folders to save GMM

%- Get extension of image
[d, d2, img_ext] = fileparts(FQ_obj.file_names.raw);

%- Save standard spot detection
name_save_no_GMM = strrep(FQ_obj.file_names.raw,img_ext,'_res_NO_GMM.txt');
name_save_no_GMM = fullfile(file_info.path_results, 'results_noGMM',name_save_no_GMM);
folder_result_no_GMM = fileparts(name_save_no_GMM);
if ~exist(folder_result_no_GMM); mkdir(folder_result_no_GMM); end

%- Save standard spot detection after GMM
name_save_GMM = strrep(FQ_obj.file_names.raw,img_ext,'_res_GMM.txt');
name_save_GMM = fullfile(file_info.path_results, 'results_GMM',name_save_GMM);
folder_result_GMM = fileparts(name_save_GMM);
if ~exist(folder_result_GMM); mkdir(folder_result_GMM); end



%% ==================================================================
% === Loop over all cells to perform detection and spot fitting
for i_cell = 1:numel(FQ_obj.cell_prop)

    %- Pre-detection
    [spots_detected, sub_spots, sub_spots_filt, img_mask, CC_GOOD, prop_img_detect,in_Nuc] = FQ_obj.spots_predect(i_cell);
    FQ_obj.cell_prop(i_cell).CC_results = CC_GOOD;  %- Results of connected components - empty if LocalMax detection was performed

    %- Calculate quality score only if it will be used for thresholding
    if FQ_obj.settings.detect.thresh_score > 0
        FQ_obj.spots_quality_score(i_cell);
        FQ_obj.spots_quality_score_apply(i_cell,1);
    end

    %- Remove spots where cropped region contains only zeroes  
    n_spots    = length(FQ_obj.cell_prop(i_cell).sub_spots);
    ind_remove = [] ;
    
    for i = 1 : n_spots
        ind_remove(i) = max(max(max(FQ_obj.cell_prop(i_cell).sub_spots{i}))) == 0;
    end
    
    ind_remove = logical(ind_remove) ; 
    
    FQ_obj.cell_prop(i_cell).sub_spots(ind_remove) = [] ;  
    FQ_obj.cell_prop(i_cell).spots_detected(ind_remove,:) = [] ; 
    FQ_obj.cell_prop(i_cell).sub_spots_filt(ind_remove) = [] ;  
    FQ_obj.cell_prop(i_cell).in_Nuc(ind_remove) = [] ;   

    %- Fit spots in 3D
    FQ_obj.spots_fit_3D(i_cell);

end

%% ==================================================================
% === Perform GMM for all cells
param.GMM.pixel_size = FQ_obj.par_microscope.pixel_size;
param.GMM.folder_result_GMM = folder_result_GMM;
FQ_obj = GMM_apply_v1(FQ_obj,im_bgd_substracted,param.GMM);


%% ==================================================================
% === Save results of spot detection 

%- Save standard spot detection
par_save.flag_type           = 'spots';
FQ_obj.save_results(name_save_no_GMM,par_save);

%- Save settings
folder_GMM = fileparts(name_save_no_GMM);
savejson('',param.settings_loaded,fullfile(folder_GMM,'FQ_settings.json'));


%=== Save spot detection after GMM
par_save.flag_type  = 'spots_GMM';
FQ_obj.save_results(name_save_GMM,par_save);

%- Save settings
folder_GMM = fileparts(name_save_GMM);
savejson('',param.GMM,fullfile(folder_GMM,'GMM_settings.json'));
savejson('',param.settings_loaded,fullfile(folder_GMM,'FQ_settings.json'));


%% === Assemble results for summary plots
if param.flags.analyze_summary
    for i_cell = 1:size(img.cell_prop,2)

        %- Get spots
        spots_simple = img.cell_prop(i_cell).spots_fit;
        spots_GMM    = img.cell_prop(i_cell).spots_fit_GMM;

        %- Get mask?
        mask2D       = poly2mask(img.cell_prop(i_cell).x, img.cell_prop(i_cell).y, img.dim.Y, img.dim.X);
        int_cell_raw = double(img.raw_proj_z(mask2D)); 

        %- Summarize information
        summary_image.image_name{i_cell_tot}       = file_loop;
        summary_image.cell_label{i_cell_tot}       = img.cell_prop(i_cell).label;
        summary_image.N_spots_simple(i_cell_tot,1) = size(spots_simple,1);
        summary_image.N_spots_GMM(i_cell_tot,1)    = size(spots_GMM,1);
        summary_image.cell_area(i_cell_tot,1)      = numel(find(mask2D(:)));
        summary_image.cell_int_median(i_cell_tot,1)= median(int_cell_raw);
        summary_image.cell_int_mean(i_cell_tot,1)  = mean(int_cell_raw);
        summary_image.cell_int_std(i_cell_tot,1)   = std(int_cell_raw);

        %- Update counter
        i_cell_tot = i_cell_tot+1;
    end
end

%% ==================================================================
% === Calculate localization features for all cells

if ~isempty(param.features)


    for i_cell = 1:numel(FQ_obj.cell_prop)

        %- Cell geometry
        cell_prop = FQ_obj.cell_prop(i_cell);

        %- Save cropped MIP around cells
        if ~param.flags.is_simulation

            %- Folder for MIP
            path_MIP = fullfile(file_info.path_results, '..','cell_crop_MIP');
            if ~exist(path_MIP, 'dir'); mkdir(path_MIP); end

            %- Name of MIP
            [dum, name_base] = fileparts(FQ_obj.file_names.raw);
            name_MIP = [name_base,'_', FQ_obj.cell_prop(i_cell).label,'.png'];
            name_MIP_full = fullfile(path_MIP,name_MIP);


            %- Save MIP if not already existing
            if ~exist(name_MIP_full, 'file')   

                [Ny, Nx] = size( FQ_obj.raw_proj_z);

                %- Get cropping coordinates            
                min_y = min(FQ_obj.cell_prop(i_cell).y);
                if min_y<1; min_y = 1; end

                max_y = max(FQ_obj.cell_prop(i_cell).y);
                if max_y>Ny; max_y = Ny; end

                min_x = min(FQ_obj.cell_prop(i_cell).x);
                if min_x<1; min_x = 1; end

                max_x = max(FQ_obj.cell_prop(i_cell).x);
                if max_x>Nx; max_x = Nx; end

                im_temp_crop       = FQ_obj.raw_proj_z(min_y:max_y,min_x:max_x);
                imwrite(im_temp_crop,name_MIP_full);
            end
        end

        %- Calculate features if GMM analysis results are present
        if ~isempty(cell_prop.spots_fit_GMM)

            %- RNA positions in pixel
            pos_RNA      = cell_prop.spots_fit_GMM;
            pos_RNA(:,1) = pos_RNA(:,1) / FQ_obj.par_microscope.pixel_size.xy;
            pos_RNA(:,2) = pos_RNA(:,2) / FQ_obj.par_microscope.pixel_size.xy;
            pos_RNA(:,3) = pos_RNA(:,3) / FQ_obj.par_microscope.pixel_size.z;

            %- Exclude mRNA in the nucleus that belongs to a blob (possible TS)
            if ~isempty(cell_prop.pos_Nuc)
                in_nucleus  = inpolygon(pos_RNA(:,1)  ,pos_RNA(:,2),cell_prop.pos_Nuc.y,cell_prop.pos_Nuc.x);
            else
                in_nucleus  = false(size(pos_RNA,1),1);
            end
            ind_GMM     = logical(sum([floor(cell_prop.spots_fit_GMM(:,1))==cell_prop.spots_fit_GMM(:,1) floor(cell_prop.spots_fit_GMM(:,2))==cell_prop.spots_fit_GMM(:,2) floor(cell_prop.spots_fit_GMM(:,3))==cell_prop.spots_fit_GMM(:,3)],2) == 3);
            ind_exclude = logical(in_nucleus.*ind_GMM);
            pos_RNA     = pos_RNA(~ind_exclude,:);

            %- Calculate features and write to a table
            [locFeature, ripley_curve] = locFeature_calc_v2(pos_RNA,cell_prop,FISH_img_raw,param.features);
            FQ_obj.cell_prop(i_cell).locFeature = locFeature;

            %===  Add cell label and other infos about file
            %  Adding as simple string is not possible - have to have same
            %  number of characters otherwise
            locFeature.cell_name  = {FQ_obj.cell_prop(i_cell).label};
            locFeature.cell_label = {cell_label};
            locFeature.name_img = {FQ_obj.file_names.raw};
            locFeature.name_img_MIP = {name_MIP_full};
            locFeature.results_GMM = {name_save_GMM};
            locFeature.results     = {name_save_no_GMM};
            locFeature.gene_name   = {gene_name};

            %-- Save additional information if cell is simulated
            if param.flags.is_simulation
                locFeature.pattern_strength = {info_sim.pattern_strength};
                if ~isempty(info_sim.RNAdensity)
                    locFeature.RNAdensity = {info_sim.RNAdensity}; 
                end
                if ~isempty(info_sim.RNAlevel)
                    locFeature.RNAlevel = {info_sim.RNAlevel};  
                end
            end

            %- Save features as tables (1) for image, (2) for all data
            table_cell      = struct2table(locFeature);
            table_feat_img = [table_feat_img;table_cell];
            table_feat_all = [table_feat_all;table_cell];
        end
    end

    %=== Save the localization features for this file
    name_table = strrep(FQ_obj.file_names.raw,img_ext,'__locFeature.csv');
    name_table = fullfile(file_info.path_results_localization, name_table);
    writetable(table_feat_img, name_table,'Delimiter',';');

end

