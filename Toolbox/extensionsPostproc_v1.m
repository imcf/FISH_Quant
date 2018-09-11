function cell_library = extensionsPostproc_v1(cell_library)

%- Analyze annotated cell-protrusion. Exclude small ones, determine the
%  distance of the remaining ones from the center of the cell.

min_area = 150; % Minimum area an extension must have (in pixel)
verbose  = 0;   % Show summary figures 

%% Analyze protrusions
struct_elem  = strel('disk',1);

%- Loop over all cells
for ind_cell =1:length(cell_library);
    
    cell_struct = cell_library(ind_cell);
    
    %- Analyze position and size of cell
    pos_cell   = double(cell_struct.cell_2D); 
    y_max_cell = max(pos_cell(:,1));    
    x_max_cell = max(pos_cell(:,2));
   
    %- Generate mask of cell
    mask_cell = poly2mask(pos_cell(:,1), pos_cell(:,2), x_max_cell,y_max_cell);
    
    %- Some image processing to get distance of contour from center of cell
    cell_mask_dilution = imdilate(mask_cell,struct_elem);
    cell_mask_erosion  = imerode(mask_cell,struct_elem);
    
    contour           = (mask_cell - cell_mask_erosion);     
    mask_dist         = bwdistgeodesic(logical(mask_cell),logical(contour),'quasi-euclidean');
    max_dist          = max(max(max(mask_dist)));
    center_cell       = find(mask_dist == max_dist) ; 
    [x_cent, y_cent ] = ind2sub(size(mask_cell), center_cell) ;
    center_cell       = round(mean([x_cent y_cent],1)) ;    
    dist_center       = bwdistgeodesic(logical(cell_mask_dilution),center_cell(2), center_cell(1),'quasi-euclidean');
    dist_center(isnan(dist_center)) = 0;
    
    %- Plot output if specified
    if verbose
        
        figure, set(gcf,'color','w')  
        suptitle(cell_struct.name_img_bgd_cell,'none')
        
        subplot(1,3,1)
        imshow(mask_cell)
        hold on
            plot(pos_cell(:,1), pos_cell(:,2),'r')
            plot(center_cell(2), center_cell(1),'+r')
        hold off
        
        subplot(1,3,2)
        imshow(uint16(dist_center),[])
        hold on
            plot(center_cell(2), center_cell(1),'+r')
        hold off
        title('distance from center')
        
        subplot(1,3,3)
        plot(pos_cell(:,1), pos_cell(:,2),'b')
        hold on
        set(gca,'Ydir','reverse')
        axis image
        
        
    end
    
    %- Loop over all extensions
    n_extension = size(cell_struct.pos_extension,2);
    i_ext_accept = 1;
    ext_prop      = {};
    
    for i_prot = 1:n_extension
        
       %- Generate mask of extension
       mask_prot = poly2mask(cell_struct.pos_extension(i_prot).x, cell_struct.pos_extension(i_prot).y,x_max_cell ,y_max_cell);
       
       %- Find pixels shared by both masks
       mask_overlap          = (mask_cell+mask_prot) == 2;
       [y_overlap, x_overlap] = ind2sub(size(mask_overlap),find(mask_overlap));
        
       %- Consider extension only if larger than specified size limit
       if length(x_overlap) > min_area
       
           ext_prop(i_ext_accept).y_area = y_overlap;
           ext_prop(i_ext_accept).x_area = x_overlap;

           %- Area of protrusion 
           ext_prop(i_ext_accept).area = length(x_overlap) ; 

           %- Get boundary around extension
           poly_temp                     = boundary(x_overlap,y_overlap) ; 
           ext_prop(i_ext_accept).poly = [x_overlap(poly_temp) y_overlap(poly_temp)];

           %- Assign distance from center
           [ext_prop(i_ext_accept).dis_geodesic, ind_max] = max(dist_center(sub2ind(size(dist_center),y_overlap,x_overlap)));
           ext_prop(i_ext_accept).pos_max_dist           = [x_overlap(ind_max) y_overlap(ind_max)];
           
           %- Update plot
           if verbose
                subplot(1,3,3)
                hold on
                    plot(x_overlap, y_overlap,'.g')
                    plot(ext_prop(i_ext_accept).poly(:,1), ext_prop(i_ext_accept).poly(:,2),'-m')
                    text(ext_prop(i_ext_accept).pos_max_dist(1),ext_prop(i_ext_accept).pos_max_dist(2),num2str(round(ext_prop(i_ext_accept).dis_geodesic)))
                hold off
           end
           
           %- Update counter
           i_ext_accept = i_ext_accept +1;
           
       else
            if verbose
                subplot(1,3,3)
                hold on
                plot(x_overlap, y_overlap,'.r')
                hold off
            end
       end
    end
    
    %- Assign analyzed cell protrusions back to cell library
    cell_library(ind_cell).ext_prop = ext_prop;
end
