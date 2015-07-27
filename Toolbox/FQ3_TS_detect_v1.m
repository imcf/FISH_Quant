function cell_prop = FQ3_TS_detect_v1(image,parameters)

%== Function to detect transcription sites

%= Extract parameters
int_th             = parameters.int_th;
conn               = parameters.conn;
min_dist           = parameters.min_dist;
size_detect         = parameters.size_detect;
pixel_size         = parameters.pixel_size;
cell_prop          = parameters.cell_prop;
status_only_in_nuc = parameters.status_only_in_nuc;
img_DAPI           = parameters.img_DAPI;
th_min_TS_DAPI     = parameters.th_min_TS_DAPI; 
N_max_TS_total     = parameters.N_max_TS_total;
N_max_TS_cell      = parameters.N_max_TS_cell;

%- Parameters for offset considereation (lacI)
dist_max_offset    = parameters.dist_max_offset;
dist_max_offset_FISH_min_int = parameters.dist_max_offset_FISH_min_int;
img_2nd            = parameters.img_2nd;


%- Analyze number of cells
N_cells = length(cell_prop);
cell_TS_summary(N_cells).int = [];

%== Image
[dim_Y dim_X dim_Z]= size(image);
size_detect_xy_pix = ceil(size_detect.xy_nm / pixel_size.xy);
size_detect_z_pix  = ceil(size_detect.z_nm / pixel_size.z);


%== Delete all saved TxSites
for i_cell = 1:N_cells
    cell_prop(i_cell).pos_TS = {};
end


%== Connected components
img_xyz  = image;
img_bin  = img_xyz>int_th;
CC       = bwconncomp(img_bin,conn);
CC_STATS = regionprops(CC,'Centroid','Area');

%- Proceed only if less than N_max_TS_total TS were found
if CC.NumObjects < N_max_TS_total

    %img_det = zeros(size(img_bin));

    %= Position of sites
    for i_site = 1: CC.NumObjects

        status_good = 1;

        ind_lin = CC.PixelIdxList{i_site};


        [coord(i_site).Y coord(i_site).X coord(i_site).Z] = ind2sub(size(img_bin),ind_lin);
  
        coord(i_site).X_center = round(CC_STATS(i_site).Centroid(1));
        coord(i_site).Y_center = round(CC_STATS(i_site).Centroid(2));
        coord(i_site).Z_center = round(CC_STATS(i_site).Centroid(3));

        coord_center(i_site,:) = [coord(i_site).X_center coord(i_site).Y_center coord(i_site).Z_center];
        site_summary(i_site,:) = [i_site,img_xyz(coord(i_site).Y_center, coord(i_site).X_center, coord(i_site).Z_center)];

    end

    %== ONLY IF SITES ARE DETECTED
    if CC.NumObjects
     %== Calculate pairwise distance
            dist_center = pdist(coord_center,'euclidean');
            dist_center = squareform(dist_center);

            %- Matrix is symmeric - select only upper triangle
            dist_center = triu(dist_center,1);

            %- Distance > 0 (self-distance & lower trianlge) and smaller than certain threshold
            [ind_row,ind_col] = find(dist_center < min_dist & dist_center > 0 );
            
            %== Compare pairwise distance
            ind_good = (1:CC.NumObjects)';

            for i = 1:length(ind_row)

               %- Get intensity of respective site  
               INT_1st = site_summary(ind_row(i),2);
               INT_2nd = site_summary(ind_col(i),2);

               %- Delete site with smaller intensity from list 
               %  Find is necessary because elements will be deleted
               if INT_1st > INT_2nd       
                   ind_delete = find(ind_good == ind_col(i));
               else
                   ind_delete = find(ind_good == ind_row(i));
               end

               if not(isempty(ind_delete))
                   ind_good(ind_delete) = [];
               end

        end

        %== Get if brighter spot is found in second image
        if  not(isempty(img_2nd))
            
            dist_max_offset_x = ceil(dist_max_offset/pixel_size.xy);
            dist_max_offset_z = ceil(dist_max_offset/pixel_size.z);
            
            %- Go over 2nd stack and check if where is the brightest spot
            for i = 1: length(ind_good)     
             
                i_site = ind_good(i);
                
                X_center = round(coord(i_site).X_center);
                Y_center = round(coord(i_site).Y_center);
                Z_center = round(coord(i_site).Z_center);
                
                x_min = round(X_center - dist_max_offset_x);
                x_max = round(X_center + dist_max_offset_x);

                y_min = round(Y_center - dist_max_offset_x);
                y_max = round(Y_center + dist_max_offset_x);    

                z_min = round(Z_center - dist_max_offset_z);
                z_max = round(Z_center + dist_max_offset_z);
                
                if y_min<1;     y_min = 1;     end
                if y_max>dim_Y; y_max = dim_Y; end

                if x_min<1;     x_min = 1;     end
                if x_max>dim_X; x_max = dim_X; end

                if z_min<1;     z_min = 1;     end
                if z_max>dim_Z; z_max = dim_Z; end
                
                %- Generate of a second image only in detected area
                img_2nd_mask = zeros(size(img_2nd));
                img_2nd_mask(y_min:y_max,x_min:x_max,z_min:z_max) = ...
                            img_2nd(y_min:y_max,x_min:x_max,z_min:z_max);
                
                [max_val max_ind_lin]           = max(img_2nd_mask(:));
                
                if max_val > dist_max_offset_FISH_min_int
                
                    [Y_max_2nd X_max_2nd Z_max_2nd] = ind2sub(size(img_2nd_mask),max_ind_lin);

                    %- Calculate offsets and correct locations
                    dX = X_max_2nd - X_center;
                    dY = Y_max_2nd - Y_center;
                    dZ = Z_max_2nd - Z_center;

                    X_new = coord(i_site).X_center + dX;
                    Y_new = coord(i_site).Y_center + dY;
                    Z_new = coord(i_site).Z_center + dZ;

                    if X_new<1;     X_new = 1;     end
                    if X_new>dim_X; X_new = dim_X; end

                    if Y_new<1;     X_new = 1;     end
                    if Y_new>dim_Y; Y_new = dim_Y; end

                    if Z_new<1;     Z_new = 1;     end
                    if Z_new>dim_Z; Z_new = dim_Z; end


                    coord(i_site).X_center = X_new;
                    coord(i_site).Y_center = Y_new;
                    coord(i_site).Z_center = Z_new;
                end
                
                
                
            end
        end

        %== See to which cell site belongs
        i_site_good = 1;
        for i = 1: length(ind_good)    

            i_site = ind_good(i);

            x_min = round(coord(i_site).X_center - size_detect_xy_pix);
            x_max = round(coord(i_site).X_center + size_detect_xy_pix);

            y_min = round(coord(i_site).Y_center - size_detect_xy_pix);
            y_max = round(coord(i_site).Y_center + size_detect_xy_pix);    

            z_min = round(coord(i_site).Z_center - size_detect_z_pix);
            z_max = round(coord(i_site).Z_center + size_detect_z_pix);

            if z_max > 3 && z_min < dim_Z -2   % Make sure that site is away from edge (can be bright due to filtering).

                if y_min<1;     y_min = 1;     end
                if y_max>dim_Y; y_max = dim_Y; end

                if x_min<1;     x_min = 1;     end
                if x_max>dim_X; x_max = dim_X; end

                if z_min<1;     z_min = 1;     end
                if z_max>dim_Z; z_max = dim_Z; end
                
                %- Find cell to which TxSite belongs
                ind_cell_TS = [];
                for i_cell = 1:N_cells
                    cell_X = cell_prop(i_cell).x;
                    cell_Y = cell_prop(i_cell).y;   

                    in_cell = inpolygon(coord(i_site).X_center,coord(i_site).Y_center,cell_X,cell_Y);

                    if in_cell
                        ind_cell_TS = i_cell; 

                        %- Check if there is a nucleus and if yes if inside
                        if status_only_in_nuc
                            if isfield(cell_prop(i_cell),'pos_Nuc');
                                if not(isempty(cell_prop(i_cell).pos_Nuc))
                                    nuc_X = cell_prop(i_cell).pos_Nuc.x;
                                    nuc_Y = cell_prop(i_cell).pos_Nuc.y; 

                                    in_nuc = inpolygon(coord(i_site).X_center,coord(i_site).Y_center,nuc_X,nuc_Y); 

                                    if not(in_nuc)
                                        ind_cell_TS = [];
                                    end
                               end
                            end
                        end
                    end
                end

                
                %- Threshold based on DAPI signal if DAPI image is present
                if not(isempty(img_DAPI))
                    int_DAPI = img_DAPI(round(coord(i_site).Y_center), (coord(i_site).X_center), (coord(i_site).Z_center));                       
                   
                    if int_DAPI < th_min_TS_DAPI
                        ind_cell_TS = [];
                    end
                        
                else
                    int_DAPI = 0;
                end
    
                %- Assign TS that are left
                if not(isempty(ind_cell_TS))

                    if isfield(cell_prop(ind_cell_TS),'pos_TS')
                        N_TS = length(cell_prop(ind_cell_TS).pos_TS);
                    else
                        N_TS = 0;
                    end

                       
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).coord        = coord(i_site);
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).label        = ['TxS_auto_', num2str(i_site)];
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).status_QUANT = 0;
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).auto         = 1;

                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).x_min = x_min;
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).y_min = y_min;
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).z_min = z_min;

                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).x_max = x_max;
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).y_max = y_max;
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).z_max = z_max;

                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).x = [x_min x_max x_max x_min];
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).y = [y_min y_min y_max y_max];

                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).ind_cell = ind_cell_TS;

                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).DAPI_int = int_DAPI;
                    
                    int_max = img_xyz(round(coord(i_site).Y_center), (coord(i_site).X_center), (coord(i_site).Z_center)); 
                    cell_prop(ind_cell_TS).pos_TS(N_TS+1).int_max = int_max;

                    TxSite(i_site_good).coord = coord;
                    i_site_good = i_site_good + 1;
                    
                    
                    %- Save
                    cell_TS_summary(ind_cell_TS).int = [cell_TS_summary(ind_cell_TS).int int_max];
                    
                end

            end

        end
        
        
        % ==== Limit number of transcription sites per cell
        N_TS_cell = arrayfun(@(x) numel(x.int), cell_TS_summary);
        ind_cell_too_many = find(N_TS_cell > N_max_TS_cell);

        %- Loop over cells with too many sites
        for i_loop = 1:length(ind_cell_too_many)

            i_cell = ind_cell_too_many(i_loop);

            [B,IX] = sort(cell_TS_summary(i_cell).int,'descend');
            ind_delete = sort(IX(N_max_TS_cell+1:end),'descend'); %- Delete from the end
            for j_loop = 1:length(ind_delete)
                ind_TS_delete = ind_delete(j_loop);
                cell_prop(i_cell).pos_TS(ind_TS_delete) = [];
            end

        end
        
       
    end
        
    
else
   warndlg(['Too many spots found: ', num2str(CC.NumObjects),'. Define higher threshold.'],mfilename); 
   disp(['Too many spots found: ', num2str(CC.NumObjects)]); 
end