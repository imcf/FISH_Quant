function  [spots_detected, img_mask, CC_GOOD,prop_img_detect] = spots_predetect_v17(image_struct,options,flag_struct)
% Function returns pixel location of local maximum
%
% spots_detected(:,1:3)   ... xyz position of detected local maximum in image
% spots_detected(:,10:11) ... Intensity in raw image and filtered image
%
% v1 Feb 28, 2010
% - Original implementation
%
% v2 March 1, 2010
% - Restrict search on area of nucleus alone
%
% v3 March 2, 2010
% - Adjust to new definiton of outlines of cell and TS
%
% v4
%- Adjust to new defintion of cell_prop
%
% v5
% - new version which allow thresholding of the score parameter


%- Empty structures in case you don't use connected component
CC_best = {};
CC_GOOD = {};
prop_img_detect = [];

%= Options
size_detect = options.size_detect;
detect_th   = options.detect_th;
cell_prop   = options.cell_prop;
pixel_size  = options.pixel_size;


%= Dimension of the image
%image      = image_struct.data;
image_filt   = image_struct.data_filtered;
image        = image_struct.data; 
[dim.Y, dim.X, dim.Z] = size(image_filt);

%= Set image outside of nucleus to zero
image_filt_mask_full = image_filt;
image_filt_mask      = image_filt;

flag_cell_crop  = 0;


if not(isfield(flag_struct,'flag_detect_region'))
    flag_struct.flag_detect_region = 0;
end



if not(isempty(cell_prop))
    
    
    %=== Restrict analysis to a certain sub-region
    
    %- No field defined
    if not(isfield(cell_prop,'mask_cell_3D'))
        
        mask_cell_2D = poly2mask(cell_prop.x, cell_prop.y, dim.Y, dim.X);
        mask_cell_3D = repmat(mask_cell_2D,[1,1,dim.Z]);  

       if not(isempty(cell_prop.pos_Nuc))

            mask_nuc_2D     = poly2mask(cell_prop.pos_Nuc.x, cell_prop.pos_Nuc.y, dim.Y, dim.X);
            mask_nuc_3D     = repmat(mask_nuc_2D,[1,1,dim.Z]);      

            mask_cyto_3D              = mask_cell_3D;
            mask_cyto_3D(mask_nuc_3D) = 0;
            
        else
            mask_nuc_3D  = mask_cell_3D;
            mask_cyto_3D = mask_cell_3D;
       end

        
    %- Field defined but empty    
    else
        if isempty(cell_prop.mask_cell_3D)
            
            mask_cell_2D = poly2mask(cell_prop.x, cell_prop.y, dim.Y, dim.X);
            mask_cell_3D = repmat(mask_cell_2D,[1,1,dim.Z]);
            
            if not(isempty(cell_prop.pos_Nuc))

                mask_nuc_2D     = poly2mask(cell_prop.pos_Nuc.x, cell_prop.pos_Nuc.y, dim.Y, dim.X);             
                mask_nuc_3D     = repmat(mask_nuc_2D,[1,1,dim.Z]);      
             
                mask_cyto_3D              = mask_cell_3D;
                mask_cyto_3D(mask_nuc_3D) = 0;
                
            else
                mask_nuc_3D  = mask_cell_3D;
                mask_cyto_3D = mask_nuc_3D;
            end
        
                       
        else       
            mask_cell_3D = cell_prop.mask_cell_3D;
            mask_nuc_3D  = cell_prop.mask_nuc_3D;
            mask_cyto_3D = cell_prop.mask_cyto_3D;
        end
    end
    

    %- Set image outside of sub-region to zero
    switch flag_struct.flag_detect_region

        %- Entire cell
        case 0
            image_filt_mask_full(not(mask_cell_3D)) = 0;

        %- Only cyto
        case 1
            image_filt_mask_full(not(mask_cyto_3D)) = 0;

        %- Only nuc    
        case 2
           image_filt_mask_full(not(mask_nuc_3D)) = 0;
    end    
    
    
    %- Crop image to speed up calculatation
    cell_x_min = min(cell_prop.x);
    cell_x_max = max(cell_prop.x);
    
    cell_y_min = min(cell_prop.y);
    cell_y_max = max(cell_prop.y);
    
    flag_cell_crop = 1;
    
    [dim.Y dim.X dim.Z] = size(image_filt_mask_full);
    
    if cell_x_min < 1;     cell_x_min = 1;     end
    if cell_x_max > dim.X; cell_x_max = dim.X; end
    
    if cell_y_min < 1;     cell_y_min = 1;     end
    if cell_y_max > dim.Y; cell_y_max = dim.Y; end
    
    image_filt_mask = image_filt_mask_full(cell_y_min:cell_y_max,cell_x_min:cell_x_max,:);
    
    %- Save properties of cropped image
    prop_img_detect.cell_y_min = cell_y_min;
    prop_img_detect.cell_y_max = cell_y_max;
    prop_img_detect.cell_x_min = cell_x_min;
    prop_img_detect.cell_x_max = cell_x_max;
    prop_img_detect.img_size   = size(image_filt_mask);
    
end    


%===  Detect local maximum by nonmaximal suppression
% Comment: toolbox might have to be installed again if error message pop up.
% Give 3d coordinates of all identified non-suppressed point locations (n x d)
% Coordinates are integer - no sub-pixel information
% (1,1,1) is pixel in upper left corner on first focal plane

if isempty(detect_th)
    detect_th  = prctile(image_filt(:),99);
end


switch flag_struct.mode_predetect

    case 'nonMaxSupr'
        disp('... non maximum supression ...');
           
        if flag_struct.reg_pos_sep == 1     
            size_detect.xy = size_detect.xy_sep;
            size_detect.z  = size_detect.z_sep;      
        end
           
        rad_detect = [size_detect.xy size_detect.xy size_detect.z];
        pos_dum    = nonMaxSupr(double(image_filt_mask), rad_detect,detect_th);
        
        
        if size(pos_dum,1) > 1
        
            %- Remove spots that are within half the detection radius
            %  This can occur when small pixels are used
            pos_sort = sortrows(pos_dum);

            pos_diff = abs(diff(pos_sort));

            ind_x_0 = pos_diff(:,2) <= ceil(size_detect.xy);
            ind_y_0 = pos_diff(:,1) <= ceil(size_detect.xy);
            ind_z_0 = pos_diff(:,3) <= ceil(size_detect.z);

            pos_diff(ind_x_0,2) = 0;
            pos_diff(ind_y_0,1) = 0;
            pos_diff(ind_z_0,3) = 0;

            ind_remove = ismember(pos_diff,[0 0 0],'rows');

            pos_pre_detect = pos_sort;
            pos_pre_detect(ind_remove,:) = [];

        else
            pos_pre_detect = pos_dum;
        end

        clearvars pos_dum;

    case 'connectcomp'

        disp('... connected components ...');
        
        %- Connected components
        par_ccc.conn        = 26;   % Connectivity in 3D
        par_ccc.thresholds  = detect_th;
        [dum, dum, CC]      = multithreshstack_v4(image_filt_mask,par_ccc);
        
        %- Get centroid of each identified region
        CC_best = CC{1};
        S = regionprops(CC_best,'Centroid');
        N_spots = CC_best.NumObjects;

        centroid_linear  = [S.Centroid]';
        centroid_matrix  = round(reshape(centroid_linear,3,N_spots))';
        
        pos_pre_detect(:,1) = centroid_matrix(:,2);
        pos_pre_detect(:,2) = centroid_matrix(:,1);
        pos_pre_detect(:,3) = centroid_matrix(:,3);
        
end

%- Add coordinates if cropped    
if flag_cell_crop
    pos_pre_detect(:,1) = pos_pre_detect(:,1) + cell_y_min - 1;
    pos_pre_detect(:,2) = pos_pre_detect(:,2) + cell_x_min - 1;
end


%===  Remove spots which are close to edge of image and sort rows
disp('... remove spots close to the edge ...');

ind_x   = (pos_pre_detect(:,1) > size_detect.xy) & (pos_pre_detect(:,1) <= dim.Y-size_detect.xy);
ind_y   = (pos_pre_detect(:,2) > size_detect.xy) & (pos_pre_detect(:,2) <= dim.X-size_detect.xy);


if not(flag_struct.region_smaller)
    ind_z   = (pos_pre_detect(:,3) > size_detect.z)  & (pos_pre_detect(:,3) <= dim.Z-size_detect.z);    
    ind_in_cell = ind_x & ind_y & ind_z;

else
    ind_in_cell = ind_x & ind_y;
end    



%=== Remove spots which are within the transcription site(s)
%    Loop through the list of polynoms describing the transcription site   

N_TS = size(cell_prop.pos_TS,2);

ind_out_TS = [];

if not(isempty(pos_pre_detect))

    if N_TS > 0

        for k = 1:N_TS

            %- Find spots which are not in TS
            %  pos_dum will be update which each iteration to include the newly
            %  excluded spots.

            in_TS  = inpolygon(pos_pre_detect(:,2),pos_pre_detect(:,1),cell_prop.pos_TS(k).x,cell_prop.pos_TS(k).y); % Points defined in Positions inside the polygon
            ind_out_TS(:,k) = ~in_TS;
      
        end   
    else
        ind_out_TS = ones(size(pos_pre_detect,1),1);
    end
else
    ind_out_TS = ones(size(pos_pre_detect,1),1);
end

%- Get coordinates of spots that are outside of ALL TS
if N_TS > 0 
    ind_good_TS = sum(ind_out_TS,2) == N_TS;
else
    ind_good_TS = logical(ind_out_TS);
end

%- Get coordinates of good spots
ind_spots_GOOD_logic = ind_in_cell & ind_good_TS;

%- Get coordinates of good spots
pos_spots_GOOD     = pos_pre_detect(ind_spots_GOOD_logic,:);   
pos_spots_GOOD_lin = sub2ind(size(image_filt), pos_spots_GOOD(:,1),pos_spots_GOOD(:,2),pos_spots_GOOD(:,3));


%- Assign values
spots_detected(:,1:3)  = pos_spots_GOOD;
spots_detected(:,10)   = image(pos_spots_GOOD_lin);
spots_detected(:,11)   = image_filt(pos_spots_GOOD_lin);
      

%- Get CC only for good spots
if ~isempty(CC_best) && CC_best.NumObjects > 0
        
    %- Correct pixel-lists
    pixel_list_crop = CC_best.PixelIdxList(ind_spots_GOOD_logic);
    pixel_list_full = {};
    
    for i_list = 1:length(pixel_list_crop);
             
       %- Get list 
       list_loop =  pixel_list_crop{i_list};
       
       [y_sub,x_sub,z] = ind2sub(size(image_filt_mask),list_loop);
       
       %- Correct x & y      
       y_list = y_sub + cell_y_min - 1;
       x_list = x_sub + cell_x_min - 1;
       
       %- Make new list 
       pixel_list_full{i_list} = sub2ind(size(image_filt), y_list, x_list, z);
           
    end
    
    %- Get CC for best spots
    try 
        CC_GOOD                   = CC_best;
        CC_GOOD.NumObjects        = length(pixel_list_crop);
        CC_GOOD.PixelIdxList      = pixel_list_full;
        CC_GOOD.PixelIdxList_crop = pixel_list_crop;
    catch err
        disp('Error in spots_predetect_v17')
        err
    end
 
end


%=== Plot results of spot detection
%=   Subtract one from each value to center cross in pixel since we don't
%    have sub-pixel pointing accuracy (and the way matlab handles sub-pixel pointing)
%- Masked image for plot
img_mask.max_xy    = max(image_filt_mask_full,[],3);
img_mask.max_xz    = squeeze(max(image_filt_mask_full,[],1));
    
    
if flag_struct.output
       
    %==== Actual plot
    h_fig = figure;
    
    
    %- All spots
    h1 = subplot(3,2,1);
    imshow(img_mask.max_xy,[]); hold on           
    plot(pos_pre_detect(:,2),pos_pre_detect(:,1),'gx','MarkerSize',10)
    hold off
    title('All detected spots')

    h2 = subplot(3,2,2);
    imshow(img_mask.max_xz',[],'XData',[0 (dim.X-1)*pixel_size.xy],'YData',[0 (dim.Z-1)*pixel_size.z]); hold on           
    plot(pos_pre_detect(:,2)*pixel_size.xy-pixel_size.xy,pos_pre_detect(:,3)*pixel_size.z-pixel_size.z,'gx','MarkerSize',10)
    hold off
    title('All detected spots')

    
    %- Spots away from edge
    pos_in_img = pos_pre_detect(ind_in_cell,:);   
    
    h3 = subplot(3,2,3);
    imshow(img_mask.max_xy,[]); hold on           
    plot(pos_in_img(:,2),pos_in_img(:,1),'gx','MarkerSize',10)
    hold off
    title('Spots away from edge')

    h4 = subplot(3,2,4);
    imshow(img_mask.max_xz',[],'XData',[0 (dim.X-1)*pixel_size.xy],'YData',[0 (dim.Z-1)*pixel_size.z]); hold on            
    plot(pos_in_img(:,2)*pixel_size.xy-pixel_size.xy,pos_in_img(:,3)*pixel_size.z-pixel_size.z,'gx','MarkerSize',10)
    hold off
    title('Spots away from edge')

    %- Spots away from edge and TS
    h5 = subplot(3,2,5);
    imshow(img_mask.max_xy,[]); hold on           
    plot(pos_spots_GOOD(:,2),pos_spots_GOOD(:,1),'gx','MarkerSize',10)
    hold off
    title('In cell & outside TS')

    h6 = subplot(3,2,6);
    imshow(img_mask.max_xz',[],'XData',[0 (dim.X-1)*pixel_size.xy],'YData',[0 (dim.Z-1)*pixel_size.z]); hold on              
    plot(pos_spots_GOOD(:,2)*pixel_size.xy-pixel_size.xy,pos_spots_GOOD(:,3)*pixel_size.z-pixel_size.z,'gx','MarkerSize',10)
    hold off
    title('In cell & outside TS')
    colormap(hot)
    
    linkaxes([h1,h3,h5], 'xy');
    linkaxes([h2,h4,h6], 'xy');

    set(h_fig,'Color','w')
    
end

   