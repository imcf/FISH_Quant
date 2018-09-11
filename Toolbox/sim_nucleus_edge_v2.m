function pos_RNA = sim_nucleus_edge_v2(sim_prop,cell_prop,cell_library_info)

verbose = 0;  % Show plots for debugging

%% Parameters for the pattern
pattern_prop     = sim_prop.pattern_prop;
pattern_level    = sim_prop.pattern_level;

%- mRNA levels
n_RNA  = sim_prop.n_RNA;                     % Total number of mRNAs
p      = pattern_prop.level.(pattern_level); % Percentage of localized mRNAs
n_loc  = floor(p*n_RNA) +1;
n_rand = n_RNA - n_loc;

%- Other parameters
th_dist_nucleus = pattern_prop.th_dist_nucleus;

theta_sigma  = pattern_prop.theta_sigma;
phi_sigma    = pattern_prop.phi_sigma; 
phi_mean     = pattern_prop.phi_mean; 


%% Parameters of the cell
cell_mask_index   = cell_prop.cell_mask_index;
cell_mask         = cell_prop.cell_mask;
cell_mask_size    = cell_prop.cell_mask_size;
dist_nucleus_3D   = cell_prop.dist_nucleus_3D;

nuc2D_ellipse_fit  = cell_prop.nuc2D_ellipse_fit;        % STRUCT. Contains fitting results of fitting eli[se to cell outline in 2D (with fit_ellipse)
nuc_bottom_pix     = cell_prop.nuc_bottom_pix;
cell_bottom_pix    = cell_prop.cell_bottom_pix;
nuc_bottom_pix_rel = nuc_bottom_pix - cell_bottom_pix + 2 ;  % Relative coordinates of nucleus in CellMask (which is cropped in z), +2 to be on the save side and be in the nucleus.


%% Ellipse fit around nucleus in 2D
long_ax             = max(nuc2D_ellipse_fit.b, nuc2D_ellipse_fit.a);
th_dist_nucleus_pix = ceil(th_dist_nucleus / min([cell_library_info.pixel_size_xy cell_library_info.pixel_size_z])); % Transform distance from nucleus in max amount of pixels

%- Orientation angles of the larger and small axis of the ellipse
%  Could also be replaced by a random angle
angle_cor   = pi - nuc2D_ellipse_fit.phi;    % Corrected orientation angle (defined as tilt against y-axis)
axes_angle  = [angle_cor, angle_cor + pi/2];
polar_angle = datasample(axes_angle,1);


%% Simulate localized mRNA position (at one side of the edge of the nuclear membrane)
n_accepted      = 0;
pos_loc_lin     = zeros(n_loc,1) ; 

r_all          = [0:round(1.5*(long_ax+th_dist_nucleus_pix))]';
nuc_center_all = repmat([nuc2D_ellipse_fit.X0_in nuc2D_ellipse_fit.Y0_in nuc_bottom_pix_rel+1],length(r_all),1);  % DEFINED AS XYZ

%- Create masks to speed up simulations
pos_mask = zeros(cell_mask_size);
mask_dist_nuc3D = zeros(cell_mask_size);
mask_dist_nuc3D(cell_mask_index) = dist_nucleus_3D;

while n_accepted < n_loc
    
    %- Simulate positions in spherical coordinates
    theta      = normrnd(polar_angle, theta_sigma,1,1);  % Pick the polarization angle from a normal distribution
    phi        = normrnd(phi_mean, phi_sigma,1,1);       % Pick the POSITIVE elevation angle from a normal distribution
    if phi<0; continue; end
    
    %- Get trace vector 
    theta_all = repmat(theta,length(r_all),1);
    phi_all   = repmat(phi,length(r_all),1);
    
    [X_dum, Y_dum, Z_dum]   = sph2cart(theta_all,phi_all,r_all) ;
    Z_dum = Z_dum*cell_library_info.pixel_size_xy/cell_library_info.pixel_size_z; % Consider difference in pixel-size in different dimensions;
    
    pos_all_pix = floor([X_dum Y_dum Z_dum]  + nuc_center_all);
        
    %- Remove elements that are outside of image
    X = pos_all_pix(:,1);
    Y = pos_all_pix(:,2);
    Z = pos_all_pix(:,3);
    
    ind_use = not(X<1 | Y< 1 | Z <1 | X> cell_mask_size(2) | Y> cell_mask_size(1)  | Z> cell_mask_size(3));
    
    %- Create maks with trace vector
    pos_linear = sub2ind(cell_mask_size,Y(ind_use),X(ind_use),Z(ind_use));
    
    pos_mask_loop = pos_mask;
    pos_mask_loop(pos_linear) = 1;
    
    %- Find elements within the cell & specified distance from nucleus
    ind_cell    = find(pos_mask_loop & cell_mask);    
    ind_rel_nuc = mask_dist_nuc3D(ind_cell) > 0 & mask_dist_nuc3D(ind_cell) < th_dist_nucleus;  
    ind_good = ind_cell(ind_rel_nuc);
    
        
    %- Randomly select one of the elements
    if ~isempty(ind_good)
        n_accepted = n_accepted+1;            
        pos_loc_lin(n_accepted)    = datasample(ind_good,1);
    end
end


%% Simulate random positions
pos_rand_lin = [];

%- Get linear index of random positions
if n_rand > 0
    ind_sub       = find(dist_nucleus_3D>0);
    ind_dum       = datasample(ind_sub,n_rand);
    pos_rand_lin  = cell_mask_index(ind_dum);
end

%% Calculate positions in pixel 
pos_RNA = [];
[pos_RNA(:,1),pos_RNA(:,2),pos_RNA(:,3)] = ind2sub(cell_mask_size,[pos_loc_lin;pos_rand_lin]);


%% Debugging plots
if verbose
    
    %=== Plot all placed mRNAs
    figure, set(gcf,'color','w')
    drawnow
    
    subplot(1,2,1)
    hold on
    plot(cell_prop.cell_2D(:,2),cell_prop.cell_2D(:,1),'-b')
    plot(cell_prop.nuc_2D(:,2),cell_prop.nuc_2D(:,1),'-b')
    plot(nuc2D_ellipse_fit.Y0_in, nuc2D_ellipse_fit.X0_in,'+g')
    plot(pos_RNA(:,2),pos_RNA(:,1),'or')
    hold off
    axis image
    set(gca,'Ydir','reverse')
    
    %==== Plot distance matrix
    dist_3d = zeros(cell_mask_size);
    dist_3d(cell_mask_index)   = dist_nucleus_3D;
    
    subplot(1,2,2)
    imagesc(dist_3d(:,:,round(nuc_bottom_pix_rel)))
     hold on
     plot(cell_prop.nuc_2D(:,2),cell_prop.nuc_2D(:,1),'-w')
    colormap jet
    colorbar
    axis image
    
    %- Loop over all pixel and keep the ones that are within the threshold distance
    dist_loop = [];
    for ipos = 1:length(pos_all_pix)
        
        X = pos_all_pix(ipos,1);
        Y = pos_all_pix(ipos,2);
        Z = pos_all_pix(ipos,3);
        
        try
            pos_linear = sub2ind(cell_mask_size,Y,X,Z);
            [ind_cell] = find(cell_mask_index == pos_linear,1);
            
            if ~isempty(ind_cell)
                dum = dist_nucleus_3D(ind_cell);
                dist_loop = [dist_loop,dum];
                if dum < 0
                    plot(X,Y,'or')
                else
                    plot(X,Y,'og')
                end
            end
        catch
        end
    end
end