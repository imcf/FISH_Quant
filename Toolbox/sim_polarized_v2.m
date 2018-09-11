function pos_RNA = sim_polarized_v2(sim_prop,cell_prop)
%% Simulate polarized mRNA localization

verbose = 0; % Show plots for debugging

%% Parameters for the pattern
pattern_prop     = sim_prop.pattern_prop;
pattern_level    = sim_prop.pattern_level;

sigma  = pattern_prop.level.(pattern_level); % SD of the polarization angle

%- mRNA levels
n_RNA  = sim_prop.n_RNA;   % Total number of mRNAs
p      = sim_prop.pattern_prop.p; % Percentage of localized mRNAs
n_loc  = floor(p*n_RNA) +1;
n_rand = n_RNA - n_loc;

%% Parameters of the cell
cell_mask_index    = cell_prop.cell_mask_index;
dist_nucleus_3D    = cell_prop.dist_nucleus_3D;
cell_mask_size     = cell_prop.cell_mask_size;
cell_2D            = double(cell_prop.cell_2D);
nuc_2D             = double(cell_prop.nuc_2D);
max_dist_cell2D_center = cell_prop.max_dist_cell2D_center;    % DOUBLE. max distance to cell centroid in 2D 
cell2D_ellipse_fit = cell_prop.cell2D_ellipse_fit;            % STRUCT. Contains fitting results of fitting eli[se to cell outline in 2D (with fit_ellipse)


%% == DETERMINE ORIENTATION ANGLE for polarization
% Cell outline was fit with an ellipse, mRNAs are polarized along one of
% the two major axis. Lastly, we check on which side is more "space" in the
% cytoplasm to avoid situations where nuclei touch the cell membrane and
% all mRNAs are squeezed into this very small space. 

%== Select one of the major axis of the fitted ellipse
%   Could also be replaced by a random angle
angle_axis  = pi - [cell2D_ellipse_fit.phi,cell2D_ellipse_fit.phi + pi/2];  % Orientation angles of ellipsoid. Phi majored as tilt from y-axis. Transform to measurement from x-axis.
angle_sim   = datasample(angle_axis,1);       % Select one of the polarization angle

%- Calculate intersect between cell and selected semi-axis through its center
x_ax(1) = cell2D_ellipse_fit.X0_in - 2*max_dist_cell2D_center*cos(angle_sim);
x_ax(2) = cell2D_ellipse_fit.X0_in + 2*max_dist_cell2D_center*cos(angle_sim);
y_ax(1) = cell2D_ellipse_fit.Y0_in - 2*max_dist_cell2D_center*sin(angle_sim);
y_ax(2) = cell2D_ellipse_fit.Y0_in + 2*max_dist_cell2D_center*sin(angle_sim);

coord_intersect = InterX([cell_2D(:,2)'; cell_2D(:,1)'],[x_ax(1) x_ax(2) ; y_ax(1) y_ax(2)]);

%- Calculate distance between intersect and nuclear envelope 
d1 = p_poly_dist(coord_intersect(1,1), coord_intersect(2,1), nuc_2D(:,1),  nuc_2D(:,2));
d2 = p_poly_dist(coord_intersect(1,2), coord_intersect(2,2), nuc_2D(:,1),  nuc_2D(:,2));

%- Select the side with more space
[ind, v ] = max([d1 d2]);
if v == 1; angle_sim = angle_sim + pi; end 


%% Simulate polarized positions 
pos_loc_lin = zeros(n_loc,1) ; 
n_accepted  = 0 ; 

while n_accepted < n_loc
    
    theta = normrnd( angle_sim, sigma,1,1);
    r     = round(max_dist_cell2D_center)*sqrt(rand(1));
    
    Z     =  uint16(randi([1 cell_mask_size(3)]));
    X     =  uint16(cell2D_ellipse_fit.X0_in + r*cos(theta));
    Y     =  uint16(cell2D_ellipse_fit.Y0_in + r*sin(theta));
    
    %- Reject all positions outside of image
    if X<1 || Y< 1 || Z <1 || Y> cell_mask_size(1) || X> cell_mask_size(2)  || Z> cell_mask_size(3)  ; continue; end
    
    %- Test if within the cell
    pos_linear = sub2ind(cell_mask_size,Y,X,Z);
    [ind_cell] = find(cell_mask_index == pos_linear,1);
    
    if ~isempty(ind_cell)
        if dist_nucleus_3D(ind_cell) > 0      
            n_accepted = n_accepted+1;
            pos_loc_lin(n_accepted) = pos_linear;
        end 
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


%% Plot if verbose
if verbose
    
    figure
    subplot(1,2,1)
    hold on
    plot(cell_2D(:,2), cell_2D(:,1),'b')
    plot(nuc_2D(:,2), nuc_2D(:,1),':b')
    plot(cell2D_ellipse_fit.X0_in, cell2D_ellipse_fit.Y0_in,'or')
    plot([x_ax(1) x_ax(2)], [y_ax(1) y_ax(2)],'-g')
    
    for i_test=1:size(coord_intersect,2)
        plot(coord_intersect(1,i_test), coord_intersect(2,i_test),'+r')
    end
    
    %- RNA positions
    plot(pos_RNA(:,2),pos_RNA(:,1),'x')
    
    axis image
    set(gca,'Ydir','reverse')
    
    hold off
    box on
    axis equal
    
    subplot(1,2,2)
    imshow(max(cell_prop.cell_mask,[],3),[])
    hold on
    plot(cell_2D(:,2), cell_2D(:,1),'-r')
    hold off
end