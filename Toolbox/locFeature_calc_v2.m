function [ locFeature, ripley_curves] = locFeature_calc_v2(pos_RNA,cell_prop,image_cell,param_feature)
% Function to calculate mRNA localization features
%
% === INPUT
%  pos_RNA  ... 2D/3D position of cell
%  pos_cell ... coordinates of cell and nucleus
%  param    ... structure containing parameters decribing the different
%               features
%
%  verbose ... cell array containing strings to indicate for which step
%               some debugging plots are shown.
%                   pre-proc, ripley, cell-ext, membrane

verbose     = param_feature.verbose;

%% Get position of cell border and the mRNAs

%- Cell border
pos_border.x = cell_prop.x - min(cell_prop.x);
pos_border.y = cell_prop.y - min(cell_prop.y);

%- RNA positions
pos_points.x = pos_RNA(:,2) -  min(cell_prop.x);
pos_points.y = pos_RNA(:,1) -  min(cell_prop.y);
pos_points.z = pos_RNA(:,3);

%% Some pre-processing for the mRNAs

%- Make sure that mRNAs are really in the 2D polygon
ind_cell_2D    = inpolygon(pos_points.x, pos_points.y, pos_border.x,pos_border.y) ;
pos_points.x   = pos_points.x(ind_cell_2D);
pos_points.y   = pos_points.y(ind_cell_2D);
pos_points.z   = pos_points.z(ind_cell_2D);

n_RNA = numel(pos_points.x);

%% Some general analysis of the cell and nucleus 
            
%- Get cropping coordinates  
[Ny, Nx, Nz] = size(image_cell);
min_y = min(cell_prop.y);
if min_y<1; min_y = 1; end

max_y = max(cell_prop.y);
if max_y>Ny; max_y = Ny; end

min_x = min(cell_prop.x);
if min_x<1; min_x = 1; end

max_x = max(cell_prop.x);
if max_x>Nx; max_x = Nx; end

%- Get mask of the cell and its centroid
%box_border     = [min(cell_prop.x) min(cell_prop.y) ; max(cell_prop.x) max(cell_prop.y)]; 
box_border     = [min_x min_y;max_x max_y];
size_mask      = [box_border(2,1) - box_border(1,1)+1 ; box_border(2,2) - box_border(1,2)+1 ];
mask_cell      = poly2mask(pos_border.y, pos_border.x, size_mask(1), size_mask(2));
area_cell      = length(find(mask_cell == 1));

pixel_cell                   = find(mask_cell == 1) ; 
[pixel_cell_x, pixel_cell_y] = ind2sub(size(mask_cell),pixel_cell);
cell_centroid                = [mean(pixel_cell_y) mean(pixel_cell_x)];

%- Polygon of nucleus
try
    mask_nuc                   = poly2mask( cell_prop.pos_Nuc.y - min(cell_prop.y),  cell_prop.pos_Nuc.x- min(cell_prop.x), size_mask(1), size_mask(2));
catch err
    disp('Error mean determining mask of nucleus. Is there a nucleus defined in this cell?')
    disp(err)
    return
end

pixel_nuc                  = find(mask_nuc == 1) ;
[pixel_nuc_x, pixel_nuc_y] = ind2sub(size(mask_cell),pixel_nuc);
nucleus_centroid           = [mean(pixel_nuc_y) mean(pixel_nuc_x)];


if any(strcmp(verbose,'pre-proc'))
    figure, set(gcf,'color','w'),clf
    
    imshow(max(image_cell,[],3))
    hold on
    plot(pos_border.x,pos_border.y,'b')
    plot(pos_points.x,pos_points.y,'og')
    axis image
    
end


%% Percentage of mRNAs in the nucleus 
ind_nuc    = inpolygon(pos_points.x, pos_points.y,cell_prop.pos_Nuc.x - min(cell_prop.x),cell_prop.pos_Nuc.y - min(cell_prop.y)) ;
locFeature.ratio_nuclear = sum(ind_nuc)/n_RNA;


%% CALCULATION OF RIPLEY-K BASED FEATURES 

%- Check if some results for debugging should be shown
if any(strcmp(verbose,'ripley'))
    param_feature.ripley.verbose = 1;
else
    param_feature.ripley.verbose = 0;
end

%- Assign some more parameters 
param_feature.ripley.area_cell = area_cell;
param_feature.ripley.n_RNA     = n_RNA;
param_feature.ripley.mask_cell = mask_cell;

%- Calculate the features based on the Ripley function
[ripley_features,  ripley_curves] = loc_feature_Ripley_v1(pos_points,pos_border,param_feature.ripley); 

%- Assign all features
fields = fieldnames(ripley_features);
for i = 1:numel(fields)
  locFeature.(fields{i}) = ripley_features.(fields{i});
end


%% Number and size of foci
locFeature.n_foci    = length(cell_prop.ind_GMM_accepted);

if locFeature.n_foci > 0
    locFeature.size_foci = size(cell_prop.position_GMM,1)/length(cell_prop.ind_GMM_accepted);
else
    locFeature.size_foci = 0;
end


%% Polarization and dispersion index 

centroid_mat       = repmat(cell_centroid, length(pixel_cell_x),1);
dist_cell_pix      = sum((centroid_mat - [pixel_cell_y pixel_cell_x]).^2,2); 
Rg_cell            = sqrt(mean(dist_cell_pix));

%- Analyze mRNAs
centroid_RNA       = [mean(pos_points.y) mean(pos_points.x)];
dist_cell_mRNA     = sqrt(sum((cell_centroid - centroid_RNA).^2));

%- Polarization index
locFeature.polarization_index = dist_cell_mRNA/Rg_cell; 

%- Dispersion index
Sigma_RNA          = sum((pos_points.y - centroid_RNA(1)).^2)/(length(pos_points.y)) + sum((pos_points.x - centroid_RNA(2)).^2)/(length(pos_points.x));
Sigma_cell         = sum((pixel_cell_y - centroid_RNA(1)).^2)/length(pixel_cell_y) + sum((pixel_cell_x - centroid_RNA(2)).^2)/length(pixel_cell_y);

locFeature.dispersion_index   = Sigma_RNA/Sigma_cell;


%% CALCULATION OF CELL-EXTENSION FEATURES

%- How many openings?
disk_size = param_feature.cell_ext.disk_size;

%- Plot for debugging
if any(strcmp(verbose,'cell-ext'))
    
    %- How many subplots?
    [p_subs]=numSubplots(length(disk_size)+1);

    %- Plot
    figure, set(gcf,'color','w')
    subplot(p_subs(1),p_subs(2),1)
    hold on
    plot(pos_border.x,pos_border.y,'b')
    plot(pos_points.x,pos_points.y,'og')
    axis image
    v=axis;
    box on
    title('Complete image')
end

%- Loop over all openings

for i_disk = 1:length(disk_size)
    
    %- Morphological opening with different disk-size
    structural_element = strel('disk',disk_size(i_disk),8);     
    mask_cell_reduced  = imopen(mask_cell, structural_element);  
    
    
    %- Check if cell is not completely removed
    if any(any(mask_cell_reduced == 1)==1)
    
        %- How many mRNAs are in the reduced cell?
        poly_cell_reduced     = cell2array(bwboundaries(mask_cell_reduced));
        ind_RNA_cut = inpolygon(pos_points.x, pos_points.y, poly_cell_reduced(:,1),poly_cell_reduced(:,2));
        N_RNA_cut   = length(find(ind_RNA_cut==1));
        
    else
        poly_cell_reduced = [0 0;0 0];
        N_RNA_cut = 0;
        ind_RNA_cut = false(n_RNA,1);
    end
       
    %- Save feature
    locFeature.(['morph_opening_',num2str(disk_size(i_disk)),'_ratio']) = (n_RNA-N_RNA_cut)/n_RNA;
    
    %- Plot debugging plot
    if any(strcmp(verbose,'cell-ext'))
        subplot(p_subs(1),p_subs(2),i_disk+1)
        hold on
        plot(poly_cell_reduced(:,1),poly_cell_reduced(:,2),'b')
        plot(pos_points.x,pos_points.y,'og')
        plot(pos_points.x(ind_RNA_cut),pos_points.y(ind_RNA_cut),'or')
        axis image
        axis(v)
        box on
        title(['Opening with disk (in/total) ',num2str(disk_size(i_disk)),' (',num2str(n_RNA-N_RNA_cut),'/',num2str(n_RNA),')'])
    end
    
end
    

%% CALCULATION OF 3D CELL MEMBRANE FEATURE

if ~ isempty(image_cell)

    if param_feature.morph_opening_in_2D
        
        %- Get mean projection of cell
        SE       = strel('ball', 25,1,0);
        img_crop =  image_cell(box_border(1,2) : box_border(2,2) , box_border(1,1)  : box_border(2,1),:);
        img_mean =  mean(img_crop(:,:,:),3);
        img_mean =  imopen(img_mean, SE);
    else
        
        %- Opening to remove spots
        SE       = strel('ball', 25,1,0);
        img_crop = image_cell(box_border(1,2) : box_border(2,2) , box_border(1,1)  : box_border(2,1),:);
        img_open =  imopen(img_crop, SE);
        
        %- Get mean projection of cell
        img_mean = mean(img_open(:,:,:),3);
    end
    
    
    %- Gaussian blurring of the image to remove background
    kernel_size.psf_xy = 0;
    kernel_size.psf_z  = 0;
    kernel_size.bgd_xy = 7;
    kernel_size.bgd_z  = 7;

    img_bgd  = gaussSmooth(img_mean, [kernel_size.bgd_xy kernel_size.bgd_xy kernel_size.bgd_z], 'same');
    img_norm = (img_bgd - min(min(img_bgd)))/max(max(img_bgd));

    %- Get intensity of processed image at different positions
    
    pos_points_pixel_y = round(pos_points.y);
    pos_points_pixel_x = round(pos_points.x);

    ind_zeros_y = pos_points_pixel_y <= 0; 
    ind_zeros_x = pos_points_pixel_x <= 0; 
    
    ind_max_y = pos_points_pixel_y  > size(img_mean,1); 
    ind_max_x = pos_points_pixel_x  > size(img_mean,2);     
    
    ind_exclude = (ind_zeros_y + ind_zeros_x + ind_max_y + ind_max_x) > 0; 
    
    pos_points_pixel_y = pos_points_pixel_y(~ind_exclude);
    pos_points_pixel_x = pos_points_pixel_x(~ind_exclude);
    pos_points_z_corr  = pos_points.z(~ind_exclude);
    
    lin_ind_RNA      = sub2ind(size(img_mean), pos_points_pixel_y,pos_points_pixel_x);
    img_int_pos_z    = img_norm(lin_ind_RNA);

    %- Calculate localization features
    locFeature.cell_heigth_Spearman = corr(img_int_pos_z, pos_points_z_corr,'type','Spearman');
    mdl                = fitlm(img_int_pos_z, pos_points_z_corr);
    locFeature.cell_heigth_rsquared = mdl.Rsquared.Ordinary;
    
    if any(strcmp(verbose,'membrane'))
        figure, set(gcf,'color','w')
        subplot(2,2,1)
        imshow(mean(img_crop(:,:,:),3),[])
        hold on
        plot(pos_border.x,pos_border.y,'b')
        hold off
        title('Mean of raw image')
        
        subplot(2,2,2)
        imshow(img_mean,[])
        hold on
        plot(pos_border.x,pos_border.y,'b')
        hold off
        title('Mean projection of image after opening')
        
        subplot(2,2,3)
        imshow(img_bgd,[])
        hold on
        plot(pos_border.x,pos_border.y,'b')
        hold off
        title('Filtered image')
        
        subplot(2,2,4)
        plot(img_int_pos_z,pos_points_z_corr,'ob')
        xlabel('Normalized image intensity')
        ylabel('z-position [pix]')       
    end  
end

%% CALCULATION OF DIFFERENT DISTANCE FEATURES
        
dist_membrane      = zeros(1,n_RNA) ;
dist_nucleus       = zeros(1,n_RNA) ;
dist_cell_centroid = zeros(1,n_RNA) ;
dist_nucleus_membrane = zeros(1,n_RNA) ;

%=== Loop over all spots to calculate different distances

% Remove duplicate positions in outlines ... 
nuc_pos = [];
nuc_pos(:,1) = cell_prop.pos_Nuc.y;
nuc_pos(:,2) = cell_prop.pos_Nuc.x;
nuc_pos = unique(nuc_pos, 'rows');

% Remove duplicate positions in outlines ... 
cell_pos = [];
cell_pos(:,1) = cell_prop.y;
cell_pos(:,2) = cell_prop.x;
cell_pos = unique(cell_pos, 'rows');

try
    for i_spot = 1:n_RNA
        dist_membrane(i_spot)           =  abs(p_poly_dist(pos_RNA(i_spot,2), pos_RNA(i_spot,1), cell_pos(:,2), cell_pos(:,1)));
        dist_nucleus_membrane(i_spot)   =  abs(p_poly_dist(pos_RNA(i_spot,2), pos_RNA(i_spot,1), nuc_pos(:,2), nuc_pos(:,1)));
        dist_nucleus(i_spot)            =  pdist([pos_RNA(i_spot,2) pos_RNA(i_spot,1); nucleus_centroid(2) + min(cell_prop.x), nucleus_centroid(1) + min(cell_prop.y)]);
        dist_cell_centroid(i_spot)      =  pdist([pos_RNA(i_spot,2) pos_RNA(i_spot,1); cell_centroid(:,2) +  min(cell_prop.x) cell_centroid(:,1)+ min(cell_prop.y)]);
    end

catch err
    disp(err)
end
     
%==== Calculate normalization factors for different distances

%- Normalization factor for distance to cellular border
disk_er     = strel('disk',1);
mask_border = mask_nuc - imerode(mask_nuc, disk_er);

mask_cell_inv    = ones(size(mask_cell)) - mask_cell;
Distance_mask    = bwdist(mask_cell_inv);
norm_cell_border = mean(Distance_mask(Distance_mask > 0));

locFeature.dist_cell_membrane_mean  = mean(dist_membrane)/norm_cell_border;
locFeature.dist_cell_membrane_stdev = std(dist_membrane)/norm_cell_border;

locFeature.dist_cell_membrane_q5  = quantile(dist_membrane,0.05)/norm_cell_border;
locFeature.dist_cell_membrane_q10 = quantile(dist_membrane,0.1)/norm_cell_border;
locFeature.dist_cell_membrane_q20 = quantile(dist_membrane,0.2)/norm_cell_border;
locFeature.dist_cell_membrane_q50 = quantile(dist_membrane,0.5)/norm_cell_border;


%- Normalization factor for distance to nuclear border
Distance_mask    = bwdist(mask_border).*mask_cell;
norm_nuc_border  = mean(Distance_mask(Distance_mask > 0));

locFeature.dist_nuc_membrane_mean = mean(dist_nucleus_membrane)/norm_nuc_border;
locFeature.dist_nuc_membrane_stdev  = std(dist_nucleus_membrane)/norm_nuc_border;


%- Normalization with distance to cellular center
mask_cell_centroid = zeros(size(mask_cell));
mask_cell_centroid(round(cell_centroid(2)), round(cell_centroid(1))) = 1;
Distance_mask_cell_center    = bwdist(mask_cell_centroid).*mask_cell;
norm_cell_center = mean(Distance_mask_cell_center(Distance_mask_cell_center > 0));

locFeature.dist_cell_centroid_mean = mean(dist_cell_centroid)/norm_cell_center;
locFeature.dist_cell_centroid_stdev   = std(dist_cell_centroid)/norm_cell_center;


%- Normalization with distance to nuclear  center
mask_nuc_centroid = zeros(size(mask_cell));
mask_nuc_centroid(round(nucleus_centroid(2)), round(nucleus_centroid(1))) = 1;
Distance_mask_nuc_center    = bwdist(mask_nuc_centroid).*mask_cell;
norm_nuc_center = mean(Distance_mask_nuc_center(Distance_mask_nuc_center > 0));

locFeature.dist_nucleus_centroid_mean    = mean(dist_nucleus)/norm_nuc_center;
locFeature.dist_nucleus_centroid_stdev   = std(dist_nucleus)/norm_nuc_center;

locFeature.nRNA   =  n_RNA ;
    