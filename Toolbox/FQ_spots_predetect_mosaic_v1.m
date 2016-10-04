function  [sub_spots, sub_spots_filt] = FQ_spots_predetect_mosaic_v1(img,img_mask,ind_cell,flags)


spots_detected = img.cell_prop(ind_cell).spots_detected;
N_Spots        = size(spots_detected,1);    % Number of candidates 

%= Some parameters
image_raw          = img.raw;
image_filt     = img.filt;
sub_spots      = cell(N_Spots,1);
sub_spots_filt = cell(N_Spots,1);  

%- Continue only if limits are defined (and not set as NaN)
if any(isnan(spots_detected(:,4)))
    return
end

%- Loop over spots
if N_Spots

    %===  Extract immediate environment for each spot in 3d
    disp('... sub-spot mosaicing...');    

    for i = 1:N_Spots            
        
        y_min = spots_detected(i,4);
        y_max = spots_detected(i,5);
        
        x_min = spots_detected(i,6);
        x_max = spots_detected(i,7);
        
        z_min = spots_detected(i,8);
        z_max = spots_detected(i,9);        
        
        %- For raw data
        sub_spots{i} = double(image_raw(y_min:y_max,x_min:x_max,z_min:z_max));

        %- For filtered data                        
        sub_spots_filt{i} = double(image_filt(y_min:y_max,x_min:x_max,z_min:z_max));         
        
 
    end
       
    %- Plot if defined    
    if flags.output

        if isempty(img_mask)           
            img_mask.max_xy    = max(image_struct.data_filtered,[],3);
            img_mask.max_xz    = squeeze(max(image_struct.data_filtered,[],1));
        end

        figure
        subplot(3,1,1)
        imshow(img_mask.max_xy,[]); hold on 
        plot(spots_detected(:,2),spots_detected(:,1),'b+','MarkerSize',10)
        hold off
        title('All detected spots')

        subplot(3,1,2)
        imshow(img_mask.max_xy,[]); hold on 
        plot(spots_detected(ind_th_in,2),spots_detected(ind_th_in,1),'g+','MarkerSize',10) 
        hold off
        title('Remaining spots')  

        subplot(3,1,3)
        imshow(img_mask.max_xy,[]); hold on 
        plot(spots_detected(ind_th_out,2),spots_detected(ind_th_out,1),'r+','MarkerSize',10) 
        hold off
        title('Removed spots')
        colormap(hot)

    end
end      
