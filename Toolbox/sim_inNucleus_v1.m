function pos_RNA = sim_inNucleus_v1(sim_prop,cell_prop)
%% Simulate mRNA localization close to the cell membrane in 3D

%% Parameters of the localization pattern
pattern_prop     = sim_prop.pattern_prop;
pattern_level    = sim_prop.pattern_level;

p                = pattern_prop.level.(pattern_level);

n_RNA            = sim_prop.n_RNA;
n_loc  = floor(p*n_RNA) +1;
n_rand = n_RNA - n_loc;


%% Parameters of the cell
cell_mask_index        = cell_prop.cell_mask_index;
cell_mask_size         = cell_prop.cell_mask_size;
dist_nucleus_3D        = cell_prop.dist_nucleus_3D;

%% Simulate positions
pos_loc_lin = [];
pos_rand_lin = [];

%- Get linear index close to cell membrane
if n_loc > 0
    ind_sub = find(dist_nucleus_3D<0);  % Inside of the nucleus and within distance of cell membrane
    ind_dum     = datasample(ind_sub,n_loc);
    pos_loc_lin = cell_mask_index(ind_dum);
end

%- Get linear index of random positions
if n_rand > 0
    ind_sub      = find(dist_nucleus_3D>0);
    ind_dum      = datasample(ind_sub,n_rand);
    pos_rand_lin = cell_mask_index(ind_dum);
end

%- Get pixel positions
[pos_RNA(:,1),pos_RNA(:,2),pos_RNA(:,3)] = ind2sub(cell_mask_size,[pos_loc_lin;pos_rand_lin]);
