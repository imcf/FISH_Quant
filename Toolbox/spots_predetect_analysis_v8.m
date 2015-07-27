function  [spots_detected_th spots_detected detect_threshold_score sub_spots sub_spots_filt] = spots_predetect_analysis_v8(image_struct,img_mask,spots_detected_pos,options,flag_struct)
% spots_detected_pos(:,1:3) ... xyz position of detected local maximum in image
% spots_detected_pos(:,4)   ... Quality score;
% spots_detected_pos(:,5)   ... Quality score normalized with maximum
% spots_detected_pos(:,6)   ... Thresholded or not (based on quality score) 
%
% v4 Consider size of stack
%
% v3, May
% - Consider case when no spots are detected
%
% v2 April 14, 2010
% - Move open and close Matlabpool for parrallel computing out of function. This way
%   pool will only be openend once when called in a loop - saves time!
%
% v1 March 28, 2010
% - Original implementation


%= Extract all options
detect_th_score  = options.detect_th_score;
PSF              = options.PSF;
size_detect      = options.size_detect;

%= Some parameters including default output
N_Spots        = size(spots_detected_pos,1);    % Number of candidates 
quality_score  = ones(N_Spots,1);
sub_spots      = cell(N_Spots,1);
sub_spots_filt = cell(N_Spots,1);  
spots_detected_th      = [];
spots_detected         = [];
detect_threshold_score = detect_th_score;

%= Image and its basic properties
image          = image_struct.data;
image_filt     = image_struct.data_filtered;
[dim.Y dim.X dim.Z] = size(image);

%= Loop over the spots
if N_Spots

    %===  Extract immediate environment for each spot in 3d
    disp('... sub-spot mosaicing...');    

    for i = 1:N_Spots    
        
        y_min = spots_detected_pos(i,1)-size_detect.xy;
        y_max = spots_detected_pos(i,1)+size_detect.xy;
        
        x_min = spots_detected_pos(i,2)-size_detect.xy;
        x_max = spots_detected_pos(i,2)+size_detect.xy;
        
        z_min = spots_detected_pos(i,3)-size_detect.z;
        z_max = spots_detected_pos(i,3)+size_detect.z;
        
        if z_min < 1;     z_min = 1;     end
        if z_max > dim.Z; z_max = dim.Z; end        
        
        
       %- For raw data
        sub_spots_all{i} = double(image(y_min:y_max,x_min:x_max,z_min:z_max));

        %- For filtered data                        
        sub_spots_filt_all{i} = double(image_filt(y_min:y_max,x_min:x_max,z_min:z_max));         
        
        y_min_spots(i) = y_min;
        y_max_spots(i) = y_max;     
        x_min_spots(i) = x_min;  
        x_max_spots(i) = x_max;
        z_min_spots(i) = z_min;
        z_max_spots(i) = z_max;
 
   
    end


    % ==== Score computation for each spot - parallel loop 
    %      Scores are calculated either
    %      - Based on the curvuture of the curve (smallest eigenvalues of Hessian matrix) 
    %          ??? Herve mentioned that they are multiplied by the maximum intensity of the region - can't find this. 
    %      - Based on standard deviation of spot 
 
    
    disp('... Score Computation...');


    if strcmp(flag_struct.score,'Curvature')

        if(flag_struct.parallel)
            parfor k = 1:N_Spots
                quality_score(k) = - min(eig(hessian_finite_differences_v1(sub_spots_filt_all{k},round(PSF.xy_pix+1),round(PSF.z_pix))));
            end
        else
            for k = 1:N_Spots
                quality_score(k) = - min(eig(hessian_finite_differences_v1(sub_spots_filt_all{k},round(PSF.xy_pix+1),round(PSF.z_pix))));
            end       
        end

    elseif strcmp(flag_struct.score,'Standard deviation')

        if(flag_struct.parallel)
            parfor k = 1:N_Spots
                quality_score(k) = std(sub_spots_filt_all{k}(:));
            end
        else
            for k = 1:N_Spots
                quality_score(k) = std(sub_spots_filt_all{k}(:));
            end
        end
    end

    %= Metric for tresholding    
    quality_score_norm = (quality_score')/max(quality_score);  % Relative score based on curvature - normalized with max score


    %= Apply threshold based on quality score
    if isempty(detect_th_score)
        [ind_th_out detect_threshold_score] = threshold_histogram_v3(quality_score,30);  
    else
        detect_threshold_score = detect_th_score;
        ind_th_out     = find ( quality_score(:) < detect_th_score);
    end

    ind_all     = (1:N_Spots);
    ind_th_in   = setdiff(ind_all,ind_th_out);



    %- Calculate projections for plot with montage function
    for k=1:length(ind_th_in)

        %- Get index in original list (before thresholding)
        ind_spot_rel = ind_th_in(k);

        sub_spots{k}      = sub_spots_all{ind_spot_rel};
        sub_spots_filt{k} = sub_spots_filt_all{ind_spot_rel};
    end
                
        
    %==== Prepare matrix to store results of geometric thresholding 
    spots_detected(:,1:3) = spots_detected_pos(:,1:3);
    spots_detected(:,4)   = y_min_spots;
    spots_detected(:,5)   = y_max_spots;
    spots_detected(:,6)   = x_min_spots;                      
    spots_detected(:,7)   = x_max_spots;
    spots_detected(:,8)   = z_min_spots;
    spots_detected(:,9)   = z_max_spots;                     
    spots_detected(:,10:11) = spots_detected_pos(:,10:11);
    spots_detected(:,12)   = quality_score;
    spots_detected(:,13)   = quality_score_norm;
    spots_detected(:,14)   = 1;                      %- Thresholded or not (based on quality score)    
     
    spots_detected_th           = spots_detected(ind_th_in,:);  
        
    %- Plot if defined    
    if flag_struct.output

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
