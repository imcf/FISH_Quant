function [cell_library_v2, cell_library_info ] = cell_library_create_v1(cell_library_info)


%% Some parameters for simulations

%- Number of data-points that will be placed at lower limit of cell and
%  nucleus to guarantee closed polygon. More values usually guarantee that 
%  finer outlines are respected.
n_Z0  = 2000;
n_Nuc = 2000;

%- Shrink factor - for Matlab function boundary.
%  Value between 0 and 1. Smaller values lead to a less compact boundary
shrink_cell = 0.5;
shrink_nuc  = 0.1;


%% Get all relevant parameters

%- FQ result files, and folders for results and images
FQ_files = cell_library_info.FQ_files;
path_FQ_files = cell_library_info.path_FQ_files;
folder_images = cell_library_info.folder_images;
folder_crop_save = cell_library_info.folder_crop_save;

%- Pixel-size in nano-meter
pixel_size_xy = cell_library_info.pixel_size_xy;
pixel_size_z = cell_library_info.pixel_size_z;

%- Image dimensions in X and Y
dim_X = cell_library_info.dim_X;
dim_Y = cell_library_info.dim_Y;

%- Text identifiers of smFISH (GAPHD), and all other channels
file_ident = cell_library_info.file_ident;

%- Should other channels be cropped (1) or not (0)
flag_crop_bgd = cell_library_info.flag_crop_bgd;

%- Padding around each cell in XY before cropping to avoid filter artifacts
pad_xy = cell_library_info.pad_xy;

%- NUCLEUS: position in the cell
% Lower and upper limit expressed as percentage of maximum cell height
nuc_z_min_rel = cell_library_info.nuc_z_min_rel;   % Lower position of nucleus
nuc_z_max_rel = cell_library_info.nuc_z_max_rel;   % Upper position of nucleus

%- Show more results (for debugging)
verbose = cell_library_info.verbose;


%% Create parameters needed for the script
FQ_obj = FQ_img;  %- FQ object

i_cell_tot   = 1;
cell_library = [] ;

%- Loop over all file
h = waitbar(0,'Please wait...');
startTime = tic; 

%- Loop over all detection files
for i_file = 1:length(FQ_files)
    
    
    %- Update progress bar for for loop
    dT_s         = toc(startTime);
    dT_remain    = (dT_s / i_file) * (length(FQ_files)-i_file);
    txt_waitbar  = ['File ', num2str(i_file),' of ' ,num2str(length(FQ_files)), ...
                     '; elapsed: ',num2str(round(dT_s/60)), ' min', ...
                     ', remaining: ',num2str(round(dT_remain/60)), ' min'];
    waitbar(i_file / length(FQ_files),h,txt_waitbar)

    
    %======================================================================
    % SOME HOUSE-KEEPING FOR THE LOADED FILE
    
    %- Reinitialized FQ object
    FQ_obj.reinit();
    
    %- Load detection results
    FQ_file_loop = FQ_files{i_file};
    
    fprintf('\n\n ***** Loading FQ results file:   %s\n',FQ_file_loop)
    disp('Loading GAPHD detection results .... this can take a while ...')
    
    FQ_obj.load_results(fullfile(path_FQ_files,FQ_file_loop),[],0);
    cell_prop = FQ_obj.cell_prop;
    N_cells   = length(cell_prop);
    
    fprintf('... results are loaded! \n **** %d cells in image >>> ',N_cells)
    
    %- Remove cells that touch the border (considers already the padding)
    ind_border = false(N_cells,1);
    for i_cell = 1:N_cells
        cell_x  = cell_prop(i_cell).x;
        cell_y  = cell_prop(i_cell).y;
        ind_border(i_cell)   = any(cell_x - pad_xy < 1) || ...
            any(cell_y - pad_xy < 1) || ...
            any(cell_x + pad_xy > dim_X) ||...
            any(cell_y + pad_xy > dim_Y);
    end
    
    cell_prop = cell_prop(~ind_border);
    N_cells = length(cell_prop);
    fprintf('  will keep %d cells, the others touch the image border.\n\n\n',N_cells)
    
    %======================================================================
    %  LOAD IMAGES OF OTHER CHANNELS
    if flag_crop_bgd
        
        %- Get channel identifiers
        names_channels = fieldnames(file_ident);
        ident_FISH = file_ident.smFISH;
        
        %- Loop over all channels
        ch_counter = 1;
        fprintf(' **** Loading  %d different channels.\n',length(names_channels))
        for iCH = 1:length(names_channels)
            
            channel_loop = names_channels{iCH};
            fprintf('\n ** Loading  channels: %s\n',channel_loop)
            
            if ~strcmp(channel_loop,'smFISH')
                
                %- Get file-name of other channels
                ident_channel = file_ident.(channel_loop);
                name_img  = strrep(FQ_obj.file_names.raw,ident_FISH,ident_channel);
                
                %- Load image
                channels(ch_counter).ident     = channel_loop;
                channels(ch_counter).file_name = name_img;
                channels(ch_counter).img = load_stack_data_v7(fullfile(folder_images,name_img));
                
                if isempty(channels(ch_counter).img)
                    disp(' COULD NOT LOAD CHANNEL. WILL SKIP THESE RESULTS!')
                    disp(name_img)
                end
                
                ch_counter = ch_counter +1 ;
            end
        end
    end
    
    %======================================================================
    % ===  Loop over alls cells
    fprintf('\n\n')
    
    for i_cell = 1:N_cells
          
        fprintf(' **** Processing cell %d out of %d for this image\n',i_cell,N_cells)
        
        %======================================================================
        % General properties of the cell: positions and crop
        
        %- Get mRNA detection: positions are in pixel & listed as YXZ
        cell_prop_loop = cell_prop(i_cell);
         
        %if  ~strcmp(cell_prop_loop.label,'Cell_CP_12'); continue; end
        pos_RNA        = cell_prop_loop.spots_detected(:,1:3); 
        
        %- Outliers are removed based closest next-neighbor distance
        D = pdist2(pos_RNA,pos_RNA);
        D(D == 0) = NaN;
        [D_min, ind_min] = min(D);
        ind_outlier = find(isoutlier(D_min));
        pos_RNA(ind_outlier,:) = [];
        
        
        % Get 2D positions of nucleus and cell: positions are listed as YXZ
        nuc_2D   = [(cell_prop_loop.pos_Nuc.y)', (cell_prop_loop.pos_Nuc.x)'] ;
        cell_2D  = [(cell_prop_loop.y)',  (cell_prop_loop.x)'];
        
        %- Create bounding boxes for cropping including padding
        cell_crop_xy = [];
        cell_crop_xy(1,:) = [min(cell_2D(:,1)), min(cell_2D(:,2))];
        cell_crop_xy(2,:) = [max(cell_2D(:,1)), max(cell_2D(:,2))];
        
        %- Positions within the cropped image
        pos_RNA_crop = [];
        pos_RNA_crop(:,1:2) = pos_RNA(:,1:2) - repmat(cell_crop_xy(1,:)-1,size(pos_RNA(:,1:2),1),1);
        pos_RNA_crop(:,3)   = pos_RNA(:,3);
        
        nuc_2D_crop   = nuc_2D  - repmat(cell_crop_xy(1,1:2)-1,size(nuc_2D,1),1);
        cell_2D_crop  = cell_2D - repmat(cell_crop_xy(1,1:2)-1,size(cell_2D,1),1);
 
        %==================================================================
        %  ====  Generate 3D CELL & summarize its properties
        
        %== Add additional points at the lower part of the cell
        %   Random XY positions to yield good sampling of lower part
        pos_low         = zeros(n_Z0,3);
        cell_bottom_pix = min(pos_RNA_crop(:,3));
        pos_low(:,3)    = cell_bottom_pix;
        
        %- Simulate positions within the 2D cell polygon
        for i_point = 1:n_Z0
            in_poly = 0;
            while in_poly == 0
                y_pos = randi([min(cell_2D_crop(:,1)) max(cell_2D_crop(:,1))]);
                x_pos = randi([min(cell_2D_crop(:,2)) max(cell_2D_crop(:,2))]);
                in_poly = inpolygon(x_pos,y_pos,cell_2D_crop(:,2),cell_2D_crop(:,1));
            end
            pos_low(i_point,1:2)  = [y_pos x_pos] ;
        end
        
        pos_RNA_crop    = [pos_RNA_crop ; pos_low];
        pos_RNA_crop_nm = pos_RNA_crop.*repmat([pixel_size_xy pixel_size_xy pixel_size_z],size(pos_RNA_crop,1),1);
        
        %== Show mRNAs
        if verbose
            figure, set(gcf,'color','w')
            
            subplot(1,2,1)
            hold on
            plot(cell_2D_crop(:,2),cell_2D_crop(:,1),'k')
            plot(nuc_2D_crop(:,2),nuc_2D_crop(:,1),'b')
            plot3(pos_RNA_crop(:,2),pos_RNA_crop(:,1),pos_RNA_crop(:,3),'or')
            plot3(pos_low(:,2),pos_low(:,1),pos_low(:,3),'og')
            hold off
            xlabel('X position [pixel]'); ylabel('Y position [pixel]')
            
            subplot(1,2,2)
            plot3(pos_RNA_crop(:,2),pos_RNA_crop(:,1),pos_RNA_crop(:,3),'.b')
            
        end
        
        %=== Calculate and analyze the conforming 3D boundary around the cell
        [K_cell, vol_cell] = boundary(pos_RNA_crop(:,1),pos_RNA_crop(:,2),pos_RNA_crop(:,3),shrink_cell);
        
        %== Show mRNAs
        if verbose
            figure, set(gcf,'color','w')
                       hold on
            trisurf(K_cell,pos_RNA_crop(:,2),pos_RNA_crop(:,1),pos_RNA_crop(:,3), ...
                'FaceColor','yellow','FaceAlpha', 0.2);
             
            hold on
            plot3(pos_RNA_crop(:,2),pos_RNA_crop(:,1),pos_RNA_crop(:,3),'or')
            hold off
        end
        
        
        %- Mesh coordinates: 3 axis and the 3 vertices of each of the triangular patches
        meshY = [pos_RNA_crop(K_cell(:,1),1), ...
            pos_RNA_crop(K_cell(:,2),1), ...
            pos_RNA_crop(K_cell(:,3),1)]';
        
        meshX = [pos_RNA_crop(K_cell(:,1),2), ...
            pos_RNA_crop(K_cell(:,2),2), ...
            pos_RNA_crop(K_cell(:,3),2)]';
        
        meshZ = [pos_RNA_crop(K_cell(:,1),3), ...
            pos_RNA_crop(K_cell(:,2),3), ...
            pos_RNA_crop(K_cell(:,3),3)]';
        
        
        %===  Calculate voxelized image
        %   TO SAVE STORAGE THIS IS NOT DONE FOR THE FULL SIZE IMAGE 
        %   including padding but a tight crop around the cell!!! 
        pos_RNA_min  = min(pos_RNA_crop);
        pos_RNA_max  = max(pos_RNA_crop);
        
        [cell_mask] = VOXELISE(pos_RNA_min(1):pos_RNA_max(1), ...
            pos_RNA_min(2):pos_RNA_max(2), ...
            pos_RNA_min(3):pos_RNA_max(3), ...
            meshY,meshX,meshZ);
        
        %- Filter to close some wholes
        cell_mask  = logical(round(smooth3(cell_mask)));        
        
        %==  3D distance transform to speed up distance calculations
        aspect    = [pixel_size_xy pixel_size_xy pixel_size_z];
        
        %- Distances should only be calculated from upper membrane. 
        %  This can be achieve by setting the first slice (which is usually
        %  background) to the outline present in the second slice. 
        cell_mask2 = cell_mask;
        cell_mask2(:,:,1) = cell_mask2(:,:,2);
        
        cell_dist_3D = bwdistsc(~cell_mask2,aspect);
        
        %== 2D distance transform
        cell_mask_2D = max(cell_mask,[],3);
        cell_dist_2D = bwdist(~cell_mask_2D)*cell_library_info.pixel_size_xy;
        
        %==  Maximum distance from cell centroid
        cell_centroid          = mean(cell_2D_crop);
        dist_cell_center       = sqrt(sum((repmat(cell_centroid, size(cell_2D_crop,1),1) - cell_2D_crop).^2,2));
        max_dist_cell2D_center = max(dist_cell_center);
        
        %== Fit cell with an ellipsoid
        cell2D_ellipse_fit = fit_ellipse(cell_2D_crop(:,2), cell_2D_crop(:,1));
        
        %== Redefine the cell outline - find outline based on mask
        B = bwboundaries(cell_mask_2D,8);
        N_poly = length(B);
        ind_largest = 1;
        
        %- Check if there are multiple polygons
        if N_poly > 1
            N_points  = 0; ind_largest = 0;
            
            %- Loop over polygon and find largests
            for i_poly = 1:N_poly

                poly_loop = B{i_poly};
                length(poly_loop(:,1));

                if length(poly_loop(:,1)) > N_points
                    ind_largest = i_poly;
                    N_points  = length(poly_loop(:,1));
                end
            end
        end
        
        %- Use largest as outline
        cell_2D_new = B{ind_largest};
        
        if verbose
            figure, set(gcf,'color','w')
            hold on
            plot(cell_2D_new(:,2),cell_2D_new(:,1),'r')
            plot3(pos_RNA_crop(:,2),pos_RNA_crop(:,1),pos_RNA_crop(:,3),'ok')
            plot(cell_2D_crop(:,2),cell_2D_crop(:,1),'g')
            
            figure
            imshow(cell_mask_2D,[])
  
        end
        %==================================================================
        %=== Create the NUCLEUS
        
        % 1. Fit 2D segmentation with an ellipse
        % 2. Create the 3D nucleus by filling a volume with points
        % 3. Calculate the conforming 3D boundary around these points.
        
        %- Fit nucleus with 2D ellipse
        %  Note: input arranged such that X is first
        nuc2D_ellipse_fit = fit_ellipse(nuc_2D_crop(:,2), nuc_2D_crop(:,1));
        
        %- Determine lower position and height of 3D nucleus
        
        %== Simulate points that fill the nucleus in 3D (semi-ellipse)
        % Points will first be simulated in a not rotated ellipse to get
        % the correct volume, and will then be rotated to be aligned with
        % the fitted ellipse of the nucleus
        
        %- Calculatee rotation matrix to lign up points with the ellipse
        phi   = - (180*nuc2D_ellipse_fit.phi)/pi;   % Rotation around X (in degrees); between -180 and +180
        theta = 0;   % Rotation around Y (in degrees); between -90 and +90.
        psi   = 0;   % Rotation around Z (in degrees); between -180 and +180
        rot   = eulerAnglesToRotation3d(phi, theta, psi);

        %- MAKE SURE THAT NUCLEUS IS IN THE CELL
        cell_height = max(pos_RNA_crop(:,3)) - min(pos_RNA_crop(:,3)) ;
        nuc_not_in_cell = 1;
        nuc_height_iter = nuc_z_max_rel;
        flag_ignore = 0;
        
        while nuc_not_in_cell
            
            %- Cell height
            nuc_height  = cell_height * (nuc_height_iter - nuc_z_min_rel);
            nuc_bottom  = ceil(cell_height * nuc_z_min_rel + cell_bottom_pix);
            
            %- Generate points in 3D ellipse
            pos_nuc_crop = zeros(n_Nuc,3);
            
            for i_pos = 1:n_Nuc
               
                %- Simulate coordiantes within the non-rotated ellipsoid
                dist = 2;
                while (dist > 1)
                    x_pix = rand(1)*(2*nuc2D_ellipse_fit.a) - nuc2D_ellipse_fit.a;
                    y_pix = rand(1)*(2*nuc2D_ellipse_fit.b) - nuc2D_ellipse_fit.b;
                    z_pix = rand(1)*nuc_height;
                    dist = ((x_pix)^2)/nuc2D_ellipse_fit.a^2 + ((y_pix)^2)/nuc2D_ellipse_fit.b^2 + ((z_pix)^2)/nuc_height^2;
                end
                
                %- Rotate positions to align with fitted ellipse of nucleus
                pos_nuc_crop(i_pos,:) = transformPoint3d([x_pix,y_pix,z_pix], rot);
            end
            
            %- Switch XY
            pos_nuc_crop     = pos_nuc_crop(:,[2 1 3]);
            
            %- Translation in XY and move up in Z
            pos_nuc_crop(:,1) = pos_nuc_crop(:,1)  + nuc2D_ellipse_fit.Y0_in;
            pos_nuc_crop(:,2) = pos_nuc_crop(:,2)  + nuc2D_ellipse_fit.X0_in;
            pos_nuc_crop(:,3) = pos_nuc_crop(:,3)  + nuc_bottom;
 
            %=====  Check if all points are within the cell
            pos_nuc_crop_dum = round(pos_nuc_crop);
            
            %- Remove cell height for test in distance matrix
            pos_nuc_crop_dum(:,3) = pos_nuc_crop_dum(:,3)-cell_bottom_pix;

            %- Remove outsize of the image
            [NY,NX,NZ] = size(cell_dist_3D);
            ind_rem =  find ((pos_nuc_crop_dum(:,1) < 1) | ...
                             (pos_nuc_crop_dum(:,2) < 1) | ...
                             (pos_nuc_crop_dum(:,3) < 1) | ...
                             (pos_nuc_crop_dum(:,1) > NY) | ...
                             (pos_nuc_crop_dum(:,2) > NX) | ...
                             (pos_nuc_crop_dum(:,3) > NZ));
                         
             pos_nuc_crop_dum(ind_rem,:) = [];
             pos_nuc_crop(ind_rem,:) = [];

             ind_lin = sub2ind(size(cell_dist_3D),pos_nuc_crop_dum(:,1),pos_nuc_crop_dum(:,2),pos_nuc_crop_dum(:,3));
             nuc_not_in_cell = any(cell_dist_3D(ind_lin) <= 0);

            %- Reduce size in case there is an iterative reduction
            nuc_height_iter = nuc_height_iter * 0.95;
            
            if nuc_height_iter < 0.5
                disp('Problems when trying to place nuclei in this cell. Cell will be dismissed!')
                flag_ignore = 1;
                break
            end   
        end
        
        %- Ignore cell since nucleus couldn't be placed
        if flag_ignore == 1; continue; end
        
        %- Convert into nm
        pos_nuc_crop_nm  = pos_nuc_crop.*repmat([pixel_size_xy pixel_size_xy pixel_size_z],size(pos_nuc_crop,1),1);
        
        %=== Calculate the conforming 3D boundary around the nucleus
        [K_nuc,vol_nuc] = boundary(pos_nuc_crop(:,1),pos_nuc_crop(:,2),pos_nuc_crop(:,3),shrink_nuc);
        
        %= Plot if in debug mode
        if verbose
            figure, set(gcf,'color','w')
            
            subplot(1,2,1)
            hold on
            plot(cell_2D_crop(:,2),cell_2D_crop(:,1),'r')
            plot(nuc_2D_crop(:,2),nuc_2D_crop(:,1),'b')
            plot3(pos_nuc_crop(:,2),pos_nuc_crop(:,1),pos_nuc_crop(:,3),'og')
            hold off
            box on
            axis image
            title('Simulated positions in nucleus')
            xlabel('X position [pixel]'); ylabel('Y position [pixel]')
            
            subplot(1,2,2)
            hold on
            trisurf(K_cell,pos_RNA_crop_nm(:,2),pos_RNA_crop_nm(:,1),pos_RNA_crop_nm(:,3), ...
                'FaceColor','yellow','FaceAlpha', 0.2);
            trisurf(K_nuc,pos_nuc_crop_nm(:,2),pos_nuc_crop_nm(:,1),pos_nuc_crop_nm(:,3))
            hold off
            axis equal
            title('3D polygons of cell and nucleus')
        end
        
        %=== Process the NUCLEAR polygon
        
        %- Mesh coordinates: 3 axis and the 3 vertices of each of the triangular patches
        meshY_nuc = [pos_nuc_crop(K_nuc(:,1),1), ...
            pos_nuc_crop(K_nuc(:,2),1), ...
            pos_nuc_crop(K_nuc(:,3),1)]';
        
        meshX_nuc = [pos_nuc_crop(K_nuc(:,1),2), ...
            pos_nuc_crop(K_nuc(:,2),2), ...
            pos_nuc_crop(K_nuc(:,3),2)]';
        
        meshZ_nuc = [pos_nuc_crop(K_nuc(:,1),3), ...
            pos_nuc_crop(K_nuc(:,2),3), ...
            pos_nuc_crop(K_nuc(:,3),3)]';
        
        %-  Calculate voxelized image
        %   TO SAVE STORAGE THIS IS NOT DONE FOR THE FULL SIZE IMAGE 
        %   including padding but a tight crop around the cell!!! 
        [nucleus_mask] = VOXELISE(pos_RNA_min(1):pos_RNA_max(1), ...
            pos_RNA_min(2):pos_RNA_max(2), ...
            pos_RNA_min(3):pos_RNA_max(3), ...
            meshY_nuc,meshX_nuc,meshZ_nuc);
         
        %- Filter nuclear mask
        nucleus_mask         = logical(round(smooth3(nucleus_mask)));
        
        %- Distance transform to speed up distance calculations
        [nucleus_dist_ext] = bwdistsc(nucleus_mask,aspect);
        [nucleus_dist_int] = bwdistsc(~nucleus_mask,aspect);
        nucleus_dist_3D = nucleus_dist_ext - nucleus_dist_int;
        
        %=== 2D distances
        nucleus_mask_2D = max(nucleus_mask,[],3);
        [nucleus_dist_2D_ext] = bwdist(nucleus_mask_2D);
        [nucleus_dist_2D_int] = bwdist(~nucleus_mask_2D);
        
        nucleus_dist_2D = nucleus_dist_2D_ext - nucleus_dist_2D_int;
        
        %- Fit 2D nucleus with an ellipsoid
        %nuc2D_ellipse_fit = fit_ellipse(nuc_2D_crop(:,1), nuc_2D_crop(:,2));

        if verbose
            figure
            subplot(1,2,1)
            imshow(squeeze(max(cell_mask,[],2)))
            
            subplot(1,2,2)
            imshow(squeeze(max(nucleus_mask,[],2)))
        end

        %%==================================================================
        %  ====  CROP other channels
        
        if flag_crop_bgd
            if verbose; figure, set(gcf,'color','w'); end
            
            for iCH = 1:length(channels)
                
                %- CROP image WITH PADDING
                img_crop = channels(iCH).img.data(cell_crop_xy(1,1)-pad_xy:cell_crop_xy(2,1)+pad_xy, ...
                                                  cell_crop_xy(1,2)-pad_xy:cell_crop_xy(2,2)+pad_xy,:);
                
                %- File-name
                [dum, name_base,ext] = fileparts( channels(iCH).file_name);
                name_save = [name_base,'__',cell_prop_loop.label,'.tif'];
                name_save_full = fullfile(folder_crop_save,name_save);
                
                for z=1:length(img_crop(1, 1, :))
                    imwrite(uint16(img_crop(:,:,z)), name_save_full, 'WriteMode', 'append','Compression','none');
                end
                
                %- Save file-name
                cell_library_v2(i_cell_tot).(['name_img_',channels(iCH).ident]) = name_save;
                
                %- Plot in verbose mode
                if verbose
                    subplot(1,length(channels),iCH)
                    imshow(max(img_crop,[],3),[])
                    hold on
                    plot(cell_2D_new(:,2)+pad_xy,cell_2D_new(:,1)+pad_xy,'r')
                    plot(nuc_2D_crop(:,2)+pad_xy,nuc_2D_crop(:,1)+pad_xy,'b')
                    hold off
                    box on
                    axis image
                    title(channels(iCH).ident)
                end
            end
        end
        
        
        %==================================================================
        %  ====  Save results
        
        %== Other important parameters
        cell_library_v2(i_cell_tot).name_cell = cell_prop_loop.label;   % Name of cell
     
        %== FOR CELLS
        cell_mask_index = find(cell_mask);

        cell_library_v2(i_cell_tot).cell_mask       = cell_mask;         % 3D LOGICAL. Mask for 3D cell outline.
        cell_library_v2(i_cell_tot).cell_mask_2D    = cell_mask_2D;      % 2D LOGICAL. Mask for 2D cell outline.
        cell_library_v2(i_cell_tot).cell_mask_size  = size(cell_mask);   % VECTOR. Size of logical 3D cell mask.
        cell_library_v2(i_cell_tot).cell_mask_index = uint32(cell_mask_index);   % VECTOR. Contains all indices of cell mask (used in combination with 3D membrane distance).
        cell_library_v2(i_cell_tot).cell_2D         = cell_2D_new;       % 2D coordinates of cell
        cell_library_v2(i_cell_tot).K_cell          = K_cell;            % Contains triangulation information from Boundary function
        cell_library_v2(i_cell_tot).pos_cell_pix    = uint16(pos_RNA_crop);
        
        cell_library_v2(i_cell_tot).dist_cell_membrane_3D = uint16(cell_dist_3D(cell_mask_index)); % VECTOR. Contains 3D distance to cell membrane for all voxel in the cell.
        cell_library_v2(i_cell_tot).dist_cell_membrane_2D = uint16(cell_dist_2D);                  % 2D ARRAY. Distances to cell membrane in 2D.
        
        cell_library_v2(i_cell_tot).cell_bottom_pix        = cell_bottom_pix;
        cell_library_v2(i_cell_tot).max_dist_cell2D_center = max_dist_cell2D_center;          % DOUBLE. max distance to cell centroid in 2D.
        cell_library_v2(i_cell_tot).cell2D_ellipse_fit     = cell2D_ellipse_fit;              % STRUCT. Contains results of fitting an ellipse to cellular outline in 2D (with fit_ellipse).
        cell_library_v2(i_cell_tot).vol_cell_nm  = vol_cell * pixel_size_xy * pixel_size_xy * pixel_size_z;
        
        %== FOR NUCLEI
        cell_library_v2(i_cell_tot).nucleus_mask       = nucleus_mask;              % 3D LOGICAL. Mask for 3D nucleus outline.
        cell_library_v2(i_cell_tot).nucleus_mask_2D    = nucleus_mask_2D;           % 2D LOGICAL. Mask for 2D cell outline.
        cell_library_v2(i_cell_tot).dist_nucleus_3D    = int16(nucleus_dist_3D(cell_mask_index));  % VECTOR. Contains 3D distance to nucleus. Positive for outside, negative for inside
        cell_library_v2(i_cell_tot).dist_nucleus_2D    = int16(nucleus_dist_2D);           % 2D ARRAY. Distance to nucleus. Positive for outside, negative for inside
        cell_library_v2(i_cell_tot).nuc_2D             = nuc_2D_crop;    % 2D coordinates of nucleus
        cell_library_v2(i_cell_tot).K_nuc              = uint16(K_nuc);
        cell_library_v2(i_cell_tot).pos_nuc_pix        = uint16(pos_nuc_crop);
        
        cell_library_v2(i_cell_tot).nuc_bottom_pix     = ceil(nuc_bottom);
        cell_library_v2(i_cell_tot).nuc2D_ellipse_fit  = nuc2D_ellipse_fit;  % STRUCT. Contains results of fitting an ellipse to nuclear outline in 2D (with fit_ellipse)
        cell_library_v2(i_cell_tot).vol_nuc_nm   = vol_nuc * pixel_size_xy * pixel_size_xy * pixel_size_z;
        
        %= Update counter
        i_cell_tot = i_cell_tot + 1;
    end
end

delete(h)