function pos_RNA = sim_random_cell_v1(sim_prop,cell_prop)
% Simulate RNAs in entire cell (nucleus included)

verbose = 0; % For debugging

%% Parameters of the localization pattern
n_rand            = sim_prop.n_RNA;

%% Parameters of the cell
cell_mask_index    = cell_prop.cell_mask_index;
cell_mask_size     = cell_prop.cell_mask_size;

%% Simulate positions
pos_rand_lin = [];

%- Get linear index of random positions
if n_rand > 0
    ind_dum       = datasample((1:length(cell_mask_index)), n_rand);
    pos_rand_lin  = cell_mask_index(ind_dum);
end

%- Get pixel positions
[pos_RNA(:,1),pos_RNA(:,2),pos_RNA(:,3)] = ind2sub(cell_mask_size,pos_rand_lin);


%% Debugging
if verbose
    figure
    plot(pos_RNA(:,2),pos_RNA(:,1),'og')

    hold on
    plot(cell_prop.cell_2D(:,2),cell_prop.cell_2D(:,1),'r')
    plot(cell_prop.nuc_2D(:,2),cell_prop.nuc_2D(:,1),'b')
    
    figure
    plot3(pos_RNA(:,2),pos_RNA(:,1),pos_RNA(:,3),'og')
end
