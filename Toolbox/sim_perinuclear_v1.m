function pos_RNA = sim_perinuclear_v1(sim_prop,cell_prop)
%% Simulate mRNA localization close to the nuclear membrane in 3D

verbose = false;

%% Parameters of the localization pattern
pattern_level    = sim_prop.pattern_level;
prob_power       = sim_prop.pattern_prop.level.(pattern_level);

n_RNA            = sim_prop.n_RNA;

%% Parameters of the cell
dist_nucleus_2D = cell_prop.dist_nucleus_2D;
cell_mask_2D = cell_prop.cell_mask_2D;

%% Get 3D cell mask
cell_mask_index = cell_prop.cell_mask_index;
cell_mask_size  = cell_prop.cell_mask_size;
cell_mask_3D    = zeros(cell_mask_size);
cell_mask_3D(cell_mask_index) = 1;

%% Calculate localization probability

% Renormalize such that close to nucleus is 0
dist_nucleus_2D(not(cell_mask_2D)) = 0;  % Set outside of cell to 0
dist_dum = dist_nucleus_2D;
dist_dum(dist_nucleus_2D<0) = 0;      % Set inside of nucleus to 0 

dist_max = double(max(dist_dum(:)));  % Get max distance for renormalization
dist_dum = (dist_max - double(dist_dum));

dist_dum(not(cell_mask_2D)) = 0;   % Set outside of cell to 0  
dist_dum(dist_nucleus_2D<0) = 0;% prob_mean;

% Power law for probabilities
dist_dum = dist_dum.^prob_power;
dist_dum(not(cell_mask_2D)) = 0;
dist_dum(dist_nucleus_2D<0) = 0;

% Set inside of nucleus to mean dist
prob_mean = mean(dist_dum(dist_dum>0));
dist_dum(dist_nucleus_2D<0) = prob_mean;

% Renormalize to get probability
loc_prob = dist_dum ./ sum(dist_dum(:));
loc_prob_vector = loc_prob(:);
index_rna_loc_sel = mnrnd(n_RNA,loc_prob_vector);
index_all = 1:length(index_rna_loc_sel);

%ind_lin = find(index_rna_loc_sel);

% Get all index (including when same index is assigned multiple times)
ind_lin = rude(index_rna_loc_sel,index_all);

%- Select random Z-positions within the cell 
[rows,cols] = ind2sub(size(cell_mask_2D),ind_lin);
pos_RNA(:,1) = rows;
pos_RNA(:,2) = cols;
pos_RNA(:,3) = 0;

try
    for i=1:n_RNA
        pos_Z_possible = squeeze(cell_mask_3D(pos_RNA(i,1),pos_RNA(i,2),:));
        pos_z = datasample(find(pos_Z_possible),1);
        pos_RNA(i,3) = pos_z;
    end
catch
    2+2
end


%% Plot pattern for debugging
if verbose
    figure
    subplot(1,2,1)
    imshow(loc_prob,[])
    
    subplot(1,2,2)
    imshow(cell_prop.cell_mask_2D + 2*cell_prop.nucleus_mask_2D,[])
    hold on
    plot(pos_RNA(:,2),pos_RNA(:,1),'r.')
end








