function pos_RNA = sim_cell_edge_v2(sim_prop,cell_prop)
%% Simulate mRNA localization close to the cell edge.

%% Parameters of the localization pattern
pattern_prop     = sim_prop.pattern_prop;
pattern_level    = sim_prop.pattern_level;

th_dist_membrane = pattern_prop.th_dist_membrane;
p                = pattern_prop.level.(pattern_level);

n_RNA  = sim_prop.n_RNA;
n_loc  = floor(p*n_RNA) +1;
n_rand = n_RNA - n_loc;


%% Parameters of the cell
cell_mask_index    = cell_prop.cell_mask_index;
cell_mask_size      = cell_prop.cell_mask_size;
dist_nucleus_3D    = cell_prop.dist_nucleus_3D;
cell_dist_2D       = cell_prop.dist_cell_membrane_2D;

%% Get 3D cell mask
cell_mask          = zeros(cell_mask_size);
cell_mask(cell_mask_index) = 1;


%% Simulate positions close to cell membrane in 2D

%- Get mRNA positions that are close to the cell membrane in XY
ind_close_membrane_2D_all = find(cell_dist_2D >0 & cell_dist_2D < th_dist_membrane);
ind_close_membrane_2D     = datasample(ind_close_membrane_2D_all,n_loc);

%- Select random Z-positions within the cell 
[pos_RNA_2D(:,1),pos_RNA_2D(:,2)] = ind2sub(size(cell_dist_2D),ind_close_membrane_2D);

pos_RNA_loc = pos_RNA_2D;
for i=1:n_loc
    pos_Z_possible = squeeze(cell_mask(pos_RNA_2D(i,1),pos_RNA_2D(i,2),:));
    pos_z = datasample(find(pos_Z_possible),1);
    pos_RNA_loc(i,3) = pos_z;
end


%% Simulate random positions
if n_rand > 0
    ind_sub       = find(dist_nucleus_3D>0);
    ind_dum       = datasample(ind_sub,n_rand);
    pos_rand_lin  = cell_mask_index(ind_dum);
    
    %- Get pixel positions
    [pos_RNA_rand(:,1),pos_RNA_rand(:,2),pos_RNA_rand(:,3)] = ind2sub(cell_mask_size,pos_rand_lin);
else
    pos_RNA_rand = [];
end


%% Create output
pos_RNA = [pos_RNA_loc;pos_RNA_rand];
