function pos_RNA = sim_cell_extension_v2(sim_prop,cell_prop)

verbose = 0;

%% Parameters for the pattern
pattern_prop  = sim_prop.pattern_prop;
pattern_level = sim_prop.pattern_level;

%- mRNA levels
n_RNA  = sim_prop.n_RNA;    % Total number of mRNAs
ratio_density      = pattern_prop.level.(pattern_level); % Percentage of localized mRNAs

%- Other parameters
dist_max = pattern_prop.dist_max;

%% Parameters of the cell
cell_mask         = cell_prop.cell_mask;
cell_mask_2D      =  cell_prop.cell_mask_2D;   %% ENABLE IN NEW VErSION

cell_mask_index   = cell_prop.cell_mask_index;
cell_mask_size    = cell_prop.cell_mask_size;
dist_nucleus_3D   = cell_prop.dist_nucleus_3D;


%%  Process extension

%- Select the cell extension furthest away from the center.
%[dum, ind_ext] = max([cell_prop.ext_prop.dis_geodesic]);

%- Select random extension
ind_ext = randsample(length(cell_prop.ext_prop),1);

%- Generate permissive region around cell extension
xext = cell_prop.ext_prop(ind_ext).pos_max_dist(1);  % Tip of the extrusion
yext = cell_prop.ext_prop(ind_ext).pos_max_dist(2);

x_circ = double(xext + dist_max*sin(0:0.1:2.1*pi));
y_circ = double(yext + dist_max*cos(0:0.1:2.1*pi));

mask_circle  = poly2mask(y_circ, x_circ, size(cell_mask_2D,1),size(cell_mask_2D,2));
mask_ext     = cell_mask_2D & mask_circle;
mask_ext_lin = find(mask_ext);


%% RNAs in extension

%= Calculate mRNA number in extension by considering density ratios
density   = n_RNA/length(find(cell_mask_2D == 1));
n_RNA_ext = round(ratio_density*density*length(find(mask_ext == 1)));

%=  XY positions in the extension
posXY_ext_lin = datasample(mask_ext_lin,n_RNA_ext);
[Y_ext, X_ext] = ind2sub(size(mask_ext),posXY_ext_lin);
   
%= Find random z-position
Z_ext = zeros(size(Y_ext));
for iPos = 1:length(Y_ext)
    Z_ext(iPos,1) = datasample(find(cell_mask(Y_ext(iPos),X_ext(iPos),:)),1);
end
 
%% Simulate random positions
pos_rand_lin = [];

%- Get linear index of random positions
if n_RNA > 0
    ind_sub       = find(dist_nucleus_3D>0);
    ind_dum       = datasample(ind_sub,n_RNA);
    pos_rand_lin  = cell_mask_index(ind_dum);
end

[pos_RNA_rand(:,1),pos_RNA_rand(:,2),pos_RNA_rand(:,3)] = ind2sub(cell_mask_size,pos_rand_lin);


%% Calculate positions in pixel 
pos_RNA = [];
pos_RNA(:,1) = [pos_RNA_rand(:,1);Y_ext];
pos_RNA(:,2) = [pos_RNA_rand(:,2);X_ext];
pos_RNA(:,3) = [pos_RNA_rand(:,3);Z_ext];


%% Plot for debugging
if verbose
    figure, set(gcf,'color','w')
    subplot(2,2,1)
    imshow(cell_mask_2D)
    hold on
    plot(y_circ,x_circ,'r')
    hold off

    set(gcf,'color','w')
    subplot(2,2,2)
    imshow(mask_circle)
    
    subplot(2,2,3)
    imshow(mask_ext)
        hold on
    plot(y_circ,x_circ,'r')
    hold off
    
    subplot(2,2,4)
    imshow(mask_ext)
        hold on
    plot(x_circ,y_circ,'r')
     plot(X_ext,Y_ext,'+g')
    hold off
    suptitle(cell_prop.name_img_BGD,'none')
    
    figure
    hold on
    plot3(pos_RNA_rand(:,1),pos_RNA_rand(:,2),pos_RNA_rand(:,3),'og')
    plot3(Y_ext,X_ext,Z_ext,'or')
    hold off
end