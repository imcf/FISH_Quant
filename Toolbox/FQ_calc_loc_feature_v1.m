function img = FQ_calc_loc_feature_v1(img)
%- Called for cell_prop of an individual cell

param.N_min      = 20;  % How many RNA we need to calculate features
param.pixel_size = img.par_microscope.pixel_size;


%% Loop over all cells
N_cell = length(img.cell_prop);

%- Loop over cells
for i_cell=1:N_cell

    %- Calculate localization features
    [img.cell_prop(i_cell).loc_features, img.cell_prop(i_cell).dist_all] = calc_features(img.cell_prop(i_cell),param);
end


 
%% Actual function that calculates the features

function [feature, dist_all]= calc_features(cell_prop,param)

pixel_size = param.pixel_size;

%- Continue only if enough mRNAs per cell
if size(cell_prop.spots_detected,1) >= param.N_min 
    
  
    %%% CALCULATION OF FEATURE FOR DISTANCE BETWEEN SPOT AND CELL STRUCTURE       
    cell_poly  = transpose([ cell_prop.x ; cell_prop.y ]) * pixel_size.xy; % Get the cell polygon in nm
    
    is_nuc       = ~isempty(cell_prop.pos_Nuc);  % Is a nucleus present?
    if is_nuc
        nucleus_poly  = transpose([ cell_prop.pos_Nuc.x ; cell_prop.pos_Nuc.y ]) * pixel_size.xy; 
     end
        
    dist_membrane      = [] ;
    dist_nucleus       = [] ;
       
    %- Loop over all spots
    for i_spot = 1:size(cell_prop.spots_fit,1)
        
        spot_pos               = cell_prop.spots_fit(i_spot,1:2);  % For detected positions: cell_prop.spots_detected(i_spot,1:2)*pixel_size.xy; 
        dist_membrane(i_spot)  =  p_poly_dist(spot_pos(2), spot_pos(1), cell_poly(:,1), cell_poly(:,2));
         
        if is_nuc
            dist_nucleus(i_spot) =  p_poly_dist(spot_pos(2), spot_pos(1), nucleus_poly(:,1), nucleus_poly(:,2));
        else
            dist_nucleus(i_spot) = 0;
        end
               
    end
    
    %- All distances
    dist_all(:,1) = dist_membrane;
    dist_all(:,2) = dist_nucleus;
    dist_all      = dist_all;
    
    %- Summary of cells  
    feature.mean.dist_membrane    = mean(dist_membrane);
    feature.median.dist_membrane  = median(dist_membrane);
    feature.std.dist_membrane     = std(dist_membrane);

    if is_nuc
        feature.mean.dist_nucleus   = mean(dist_nucleus);
        feature.median.dist_nucleus = mean(dist_nucleus);
        feature.std.dist_nucleus     = std(dist_nucleus);
    else 
        feature.mean.dist_nucleus   = 'NA';
        feature.median.dist_nucleus = 'NA';
        feature.std.dist_nucleus    = 'NA';  
    end
 
else
    feature = [];
    dist_all = [];
end

