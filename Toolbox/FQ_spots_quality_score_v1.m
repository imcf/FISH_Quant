function  spots_detected = FQ_spots_quality_score_v1(img,ind_cell)
%
%
% spots_detected(:,1:3) ... yxz position of detected local maximum in image
% spots_detected(:,4:9) ... xyz: min and max of subregion for fitting
%
% spots_detected(:,10)   ... Quality score;
% spots_detected(:,11)   ... Quality score normalized with maximum
% spots_detected(:,12)   ... Thresholded or not (based on quality score) 


%- Number of spots
spots_detected = img.cell_prop(ind_cell).spots_detected;
sub_spots_filt = img.cell_prop(ind_cell).sub_spots_filt;
N_Spots         = size(spots_detected,1);    % Number of candidates 

%= Extract all options
score         = img.settings.detect.score;
flags         = img.settings.detect.flags;
PSF           = img.PSF_theo;

%= Some parameters
quality_score  = zeros(N_Spots,1);

%= Loop over spots (if any are detected)
if N_Spots
    
    % ==== Score computation for each spot - parallel loop
    %      Scores are calculated either
    %      - Based on the curvuture of the curve (smallest eigenvalues of Hessian matrix) 
    %      - Based on standard deviation of spot 


    %===== SCORE COMPUTATION
    
    disp('... Score Computation...');

    switch score
    
        case 'Curvature'
            
            if(flags.parallel)
                parfor k = 1:N_Spots
                    quality_score(k) = - min(eig(hessian_finite_differences_v1(sub_spots_filt{k},round(PSF.xy_pix+1),round(PSF.z_pix))));
                end
            else
                for k = 1:N_Spots
                    quality_score(k) = - min(eig(hessian_finite_differences_v1(sub_spots_filt{k},round(PSF.xy_pix+1),round(PSF.z_pix))));
                end       
            end

        case 'Standard deviation'

        if(flags.parallel)
            parfor k = 1:N_Spots
                quality_score(k) = std(sub_spots_filt{k}(:));
            end
        else
            for k = 1:N_Spots
                quality_score(k) = std(sub_spots_filt{k}(:));
            end
        end
    end

    %= Metric for tresholding    
    quality_score_norm = (quality_score')/max(quality_score);  % Relative score based on curvature - normalized with max score           

    spots_detected(:,12)   = quality_score;
    spots_detected(:,13)   = quality_score_norm;
    spots_detected(:,14)   = 0;                      %- Thresholded or not (based on quality score)   

end      
