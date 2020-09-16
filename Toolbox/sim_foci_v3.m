function pos_RNA = sim_foci_v3(sim_prop,cell_prop, cell_library_info)


%% Parameters of the cell
cell_mask_size        = cell_prop.cell_mask_size;
dist_cell_membrane_3D = cell_prop.dist_cell_membrane_3D;
dist_nucleus_3D       = cell_prop.dist_nucleus_3D;
cell_mask_index       = cell_prop.cell_mask_index;

pixel_size_xy = cell_library_info.pixel_size_xy;
pixel_size_z  = cell_library_info.pixel_size_z;

%% Parameters of the localization pattern
pattern_prop     = sim_prop.pattern_prop;
pattern_level    = sim_prop.pattern_level;


%% Parameters of the localization pattern
n_rand       = sim_prop.n_RNA;

RNA_in_foci  = pattern_prop.RNA_in_foci;
n_foci       = pattern_prop.n_foci;
foci_diameter = pattern_prop.foci_diameter;


%== For different pattern strength, the following parameters are changes
%  1. Number of foci per cell. 
%  2. Number of mRNAs per foci.
%  3. Spatial extent of foci - adjusted to approximate the same density

%- Get modulating factor for pattern strength
patt_strength = pattern_prop.level.(pattern_level);

%-- Number of foci, number of mRNA, and spatial extent
n_foci_cell   = floor(pearsrnd(n_foci.mu,n_foci.sigma,n_foci.skew,n_foci.kurt));
n_foci_cell   = round(patt_strength*n_foci_cell);

%-- # mRNA per foc
n_RNA_in_foci = floor(pearsrnd(RNA_in_foci.mu,RNA_in_foci.sigma,RNA_in_foci.skew,RNA_in_foci.kurt,n_foci_cell,1));
n_RNA_in_foci = round(patt_strength*n_RNA_in_foci);


%- Change volumes to maintain same density
foci_diameter = round(patt_strength^(1/3) * foci_diameter);


%% Get all possible positions to place foci within the cells
th_dist_membrane = 1.5*max(foci_diameter);
ind_pos = find(dist_cell_membrane_3D<th_dist_membrane & dist_nucleus_3D>th_dist_membrane);  % Outside of nucleus and within distance of cell membrane
if isempty( ind_pos)
    disp([mfilename, ': No positioning of foci within specified distance range possible!'])
    return
end


%% Simulate the localized mRNA in foci
pos_loc = [];

for i_foci = 1:n_foci_cell
    
    % How many mRNAs per foci and what size
    n_RNA_loop =  n_RNA_in_foci(i_foci) ; 
    diameter   =  randi([foci_diameter(1) foci_diameter(2)]);     

    %- With current implementation foci are simulated as spheres, but an
    %  ellipse could also be simulated by changing the half-axis.
    pa_x_nm = diameter/2; 
    pa_y_nm = diameter/2; 
    pa_z_nm = diameter/2;

    phi   = 360*rand(1) -180;   % Rotation around X (in degrees); between -180 and +180
    theta = 180*rand(1) - 90;   % Rotation around Y (in degrees); between -90 and +90.
    psi   = 360*rand(1) -180;   % Rotation around Z (in degrees); between -180 and +180

    %- Convert 3D Euler angles to 3D rotation matrix
    rot  = eulerAnglesToRotation3d(phi, theta, psi);

   
    %===== Simulate mRNAs positions within the foci
    pos_RNA_foci_pix     = [];  
    
    for iRNA = 1:n_RNA_loop    
        
        %- Simulate coordiantes within the not-rotated ellipsoid
        dist      = 2;  
        while (dist > 1)
            pos_RNA.x_nm = (rand(1)*(2*pa_x_nm) - pa_x_nm);
            pos_RNA.y_nm = (rand(1)*(2*pa_y_nm) - pa_y_nm);
            pos_RNA.z_nm = (rand(1)*(2*pa_z_nm) - pa_z_nm);                 
            dist         = (pos_RNA.x_nm^2 / pa_x_nm^2) + (pos_RNA.y_nm^2 / pa_y_nm^2)  + (pos_RNA.z_nm^2 / pa_z_nm^2); 
        end 

        %- Rotate position
        dum                     = [pos_RNA.x_nm,pos_RNA.y_nm,pos_RNA.z_nm];
        dum2                    = transformPoint3d(dum, rot);
        pos_RNA_foci_pix(iRNA,:) = dum2 ./ [pixel_size_xy pixel_size_xy pixel_size_z];

    end

    %===== Simulate mRNA positions within the cell
    [pos_foci(1),pos_foci(2),pos_foci(3)]    = ind2sub(cell_mask_size,cell_mask_index(datasample(ind_pos,1)));      
    pos_RNA_cell = pos_RNA_foci_pix + repmat(pos_foci,n_RNA_loop,1)  ;   
    
    pos_loc  = [pos_loc ; pos_RNA_cell];
    
end


%% Linear index of random positions
if n_rand > 0
    ind_sub      = find(dist_nucleus_3D>0);
    ind_dum      = datasample(ind_sub,n_rand);
    pos_rand_lin = cell_mask_index(ind_dum);
end

[pos_random(:,1),pos_random(:,2),pos_random(:,3)] = ind2sub(cell_mask_size,pos_rand_lin);

%% Get pixel positions
pos_RNA   = [ pos_loc ; pos_random ];