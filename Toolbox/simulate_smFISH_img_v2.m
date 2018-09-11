function [im_final, im_no_bgd, prop_cell] = simulate_smFISH_img_v2(sim_prop,cell_prop,cell_library_info)
% Function to simulate images from specified mRNA positions.

%% Get parameters 
factor_binning = sim_prop.factor_binning;

path_save    = sim_prop.path_save;
if ~exist(path_save); mkdir(path_save); end

folder_img_lib = sim_prop.folder_img_lib;

pixel_size_xy = cell_library_info.pixel_size_xy;
pixel_size_z  = cell_library_info.pixel_size_z;
pad_xy        = cell_library_info.pad_xy;

%% Load background image
if ~isfield(cell_prop,'img_bgd') || isempty(cell_prop.img_bgd)
    
    if sim_prop.flag_use_tiff_class
        img_bgd = load_tif_3D(fullfile(folder_img_lib,cell_prop.name_img_bgd_cell));
    else
        img_bgd_struct = load_stack_data_v7(fullfile(folder_img_lib,cell_prop.name_img_bgd_cell));
        img_bgd = img_bgd_struct.data;
    end
    
else
    img_bgd = cell_prop.img_bgd;
end

if ~isempty(img_bgd)
    
    %- Load mRNA coordinates
    pos_RNA          = sim_prop.RNA_pos;
    pos_RNA(:,[1,2]) = pos_RNA(:,[1,2])   + pad_xy;             % Consider padding in XY
    pos_RNA(:,3)     = pos_RNA(:,3)       + cell_prop.cell_bottom_pix;  % Bring z-coordiantes to lower limit of cell in z
    pos_RNA_scaled   = round(factor_binning * pos_RNA);             % Consider binning and round
    
    %- Creating the actual image - on larger pixel grid
    size_img               = size(img_bgd);
    size_large             = factor_binning*size_img;
    img_support            = uint16(zeros(size_large));
    [img_large,  RNA_int]  = PSF_add_v2(img_support,pos_RNA_scaled,sim_prop);
    
    %- Perform binning
    img_6D     = reshape(img_large,[factor_binning size_img(1) factor_binning size_img(2) factor_binning size_img(3)]);
    img_fish   = round(reshape(sum(sum(sum(img_6D,1),3),5),size_img)./(factor_binning^3));
    
    im_final   = uint16(img_fish) + uint16(img_bgd) ;
    im_no_bgd  = uint16(img_fish) ;
    
    %cell_prop.RNA_int  = RNA_int;
    
    clear img_support img_large img_6D img_fish img_bgd
    
    %=== Save image
    
    %- Find file-name and update counter if file already exists.
    ind_file  = 1;
    file_exist = 1;
    
    [dum, name_bgd_base] = fileparts(cell_prop.name_img_BGD);
    
    while file_exist == 1
        
        outputNameBase = [name_bgd_base,'__',sim_prop.pattern_name,'__',num2str(ind_file)];
        outputFileName = fullfile(path_save,[outputNameBase,'.tif']);
        
        %- Update index
        if exist(outputFileName, 'file') == 2
            ind_file = ind_file + 1 ;
        else
            file_exist = 0;
        end
    end
    
    %- Write z-stack to file
    for z_plane=1:length(im_final(1, 1, :))
        imwrite(uint16(im_final(:, :, z_plane)), outputFileName, 'WriteMode', 'append','Compression','none');
    end
    
    %==== Save MIPs to file
    im_final_MIP   = uint16(max(uint16(im_final),[],3));
    proj_name = fullfile(path_save,['MAX_',outputNameBase,'.tif']);
    imwrite((im_final_MIP), proj_name);
    
    %=== Save FQ results file containing the positions and outline
    FQ_obj = FQ_img;
    
    FQ_obj.par_microscope.pixel_size.xy = pixel_size_xy;
    FQ_obj.par_microscope.pixel_size.z = pixel_size_z;
    
    FQ_obj.file_names.raw = [outputNameBase,'.tif'];
    FQ_obj.cell_prop(1).label     = cell_prop.name_cell;
    FQ_obj.cell_prop(1).x         = cell_prop.cell_2D(:,2)+ pad_xy;
    FQ_obj.cell_prop(1).y         = cell_prop.cell_2D(:,1) + pad_xy;
    
    FQ_obj.cell_prop(1).pos_Nuc(1).label = 'Nucleus';
    FQ_obj.cell_prop(1).pos_Nuc(1).x = cell_prop.nuc_2D(:,2) + pad_xy;
    FQ_obj.cell_prop(1).pos_Nuc(1).y = cell_prop.nuc_2D(:,1) + pad_xy;
    
    FQ_obj.cell_prop(1).spots_detected(:,1)  = round(pixel_size_xy*(pos_RNA(:,1)-1));
    FQ_obj.cell_prop(1).spots_detected(:,2)  = round(pixel_size_xy*(pos_RNA(:,2)-1));
    FQ_obj.cell_prop(1).spots_detected(:,3)  = round(pixel_size_z*(pos_RNA(:,3)-1));
    
    %- General parameters
    comment = ['Simulation:::Pattern::',sim_prop.pattern_name,'::',sim_prop.pattern_level,':::RNAlevel::',num2str(sim_prop.mRNA_level_avg),':::'];
    par_save.comment             = comment;
    par_save.path_save           = [];
    par_save.path_name_image     = [];
    
    par_save.version             = 'v3';
    par_save.flag_type           = 'FISH_sim';
    par_save.flag_th_only        = 0;
    
    FQ_obj.save_results(fullfile(path_save,[outputNameBase,'.txt']),par_save);
    
else
    im_final = [] ;
    disp('Bgd image not found')
    disp(cell_prop.cell_struct.name_img_bgd_cell)
    disp(folder_img_lib)
end
