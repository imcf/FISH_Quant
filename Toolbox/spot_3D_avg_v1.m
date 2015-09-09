function [spot_avg, spot_avg_os, pixel_size_os,img_sum] = spot_3D_avg_v1(img,ind_cell,img_sum)
% Florian Mueller, muellerf.research@gmail.com
%
% === INPUT PARAMETER
% img      ... FISH-quant image structure
%
% par_spots ... Defines properties of spots 
%       1st col  ... y-coordinates
%       2nd col  ... x-coordinates
%       3rd col  ... z-coordinates
%       4th col  ... BGD intensity
%
% par_crop ... Specifies cropping area (see also flag_crop)
%       par_crop.xy  ... in xy (+/- pixel from center)
%       par_crop.z   ... in z (+/- pixel from center)
%
% pixel_size ... Pixel-size
%       pixel_size.xy  ... in xy 
%       pixel_size.z   ... in z 
%
% fact_os ... Specifies oversampling in xy and z
%       fact_os.xy  ... in xy 
%       fact_os.z   ... in z 
%
%
% offset  ... offset in X and Y which brings the averaging area away from
%             the actual center and can be used to determine background images.
%
% === FLAGS
%  flag_os     ... Oversampling will be performed  
%  flag_output ... Output plots will be shown
%  flags.bgd    ... Indicates if background should be subtracted from each
%                  spot before averaging.


    %=== If only one index is specified - average indicated cell
    if ~isempty(ind_cell)

        img.settings.avg_spots.flags.output = 1;              
        [spot_avg, spot_avg_os,pixel_size_os,img_sum] = avg_spots_cell(img,ind_cell,img_sum);
        
     
    %=== Average all cells   
    else
        img.settings.avg_spots.flags.output = 0; 
        N_cell  = length(img.cell_prop);
        
        for i=1:N_cell

           %=== Average images
           [dum,dum,pixel_size_os,img_sum] = avg_spots_cell(img,i,img_sum);

        end

            %- Calculate averaged image
            if not(isempty(img_sum))

                spot_avg       = round(img_sum.spot_sum     /img_sum.N_sum);
                spot_avg_os    = round(img_sum.spot_os_sum /img_sum.N_sum); 
                img.par_microscope.pixel_size_os = pixel_size_os;

                %- Extract area without buffer zone
                if img.settings.avg_spots.fact_os.xy > 1 || img.settings.avg_spots.fact_os.z > 1
                    fact_os          = img.settings.avg_spots.fact_os;
                    spot_avg_os      = spot_avg_os(2*fact_os.xy:end-2*fact_os.xy,2*fact_os.xy:end-2*fact_os.xy,2*fact_os.z+1:end-2*fact_os.z);
                end

            else
                disp('!!! NO spot was considered in averaging !!!!')
                img.spot_avg     = [];
                img.spot_os_avg  = [];

            end


    end


end



%% FUNCTION TO AVERAGE SPOTS IN A CELL
function [spot_avg, spot_os_avg,pixel_size_os,img_sum] = avg_spots_cell(img,ind_cell,img_sum)

    %=== Parameters for averaging
    par_crop   = img.settings.avg_spots.crop;
    fact_os    = img.settings.avg_spots.fact_os;
    flags      = img.settings.avg_spots.flags;

    %- Pixel size
    pixel_size       = img.par_microscope.pixel_size;
    pixel_size_os.xy = pixel_size.xy / img.settings.avg_spots.fact_os.xy;
    pixel_size_os.z  = pixel_size.z  / img.settings.avg_spots.fact_os.z;

    
    %=== Check if there are any spots to average
    if sum(img.cell_prop(ind_cell).thresh.in) == 0   
        spot_os_avg = [];
        spot_avg    = [];
        return
    end
    
    %==== Decide which positions to use 

    %- Fit
    if img.settings.avg_spots.fact_os.xy > 1 || img.settings.avg_spots.fact_os.z > 1

        status_os = 1;
        spots_pos = img.cell_prop(ind_cell).spots_fit(img.cell_prop(ind_cell).thresh.in,[img.col_par.pos_y img.col_par.pos_x img.col_par.pos_z]);

        spots_pos(:,1) = spots_pos(:,1) + img.par_microscope.pixel_size.xy;
        spots_pos(:,2) = spots_pos(:,2) +  img.par_microscope.pixel_size.xy;
        spots_pos(:,3) = spots_pos(:,3) +  img.par_microscope.pixel_size.z;

    %- Detection    
    else
        
        status_os = 0;
        spots_pos(:,1) = (img.cell_prop(ind_cell).spots_detected(img.cell_prop(ind_cell).thresh.in,img.col_par.pos_y_det) -1) * img.par_microscope.pixel_size.xy;
        spots_pos(:,2) = (img.cell_prop(ind_cell).spots_detected(img.cell_prop(ind_cell).thresh.in,img.col_par.pos_x_det) -1) * img.par_microscope.pixel_size.xy;
        spots_pos(:,3) = (img.cell_prop(ind_cell).spots_detected(img.cell_prop(ind_cell).thresh.in,img.col_par.pos_z_det) -1) * img.par_microscope.pixel_size.z;

    end

    N_spots   = size(spots_pos,1);
    
 
    %- Get background only if bgd subtraction option is specified
    if img.settings.avg_spots.flags.bgd
        spots_bgd = img.cell_prop(ind_cell).spots_fit(:,img.col_par.bgd);
    else
        spots_bgd = zeros(size(spots_pos,1),1);
    end
    
    par_spots = [spots_pos,spots_bgd];
    



    %=== Make sure that image is DOUBLE!!!! Otherwise you run into troubles when
    %  adding up to many images and unit16 maxes out at 65K
    img_data = double(img.raw);    

    lp = par_crop.xy;                   % Size of detection zone in xy 
    lz = par_crop.z;                    % Size of detection zone in z 

    dim_crop.X = 2*lp+1;
    dim_crop.Y = 2*lp+1;
    dim_crop.Z = 2*lz+1;


    %== Structure for oversampling including buffer zones
    %   Consider if results from ealier loop are shown
    if isempty(img_sum)
        spot_sum            = zeros(2*lp+1,2*lp+1,2*lz+1);   
        if status_os
            spot_os_sum = zeros(fact_os.xy*(dim_crop.Y) + 2*fact_os.xy, ...
                                fact_os.xy*(dim_crop.X) + 2*fact_os.xy,...
                                fact_os.z *(dim_crop.Z) + 2*fact_os.z);
            spot_os_temp = spot_os_sum;
        else
            spot_os_sum  = spot_sum;
            spot_os_temp = spot_sum;
        end

        N_sum    = 0;
    else
        spot_sum     = img_sum.spot_sum;
        spot_os_sum  = img_sum.spot_os_sum;
        spot_os_temp = zeros(size(spot_os_sum));
        N_sum        = img_sum.N_sum;
    end


    %===== Loop over all spots
    if flags.output
        fprintf('Averaging spot (of %d):      1',N_spots);
    end

    N_ignore = 0;

    for i=1:N_spots

        if flags.output 
            fprintf('\b\b\b\b\b%5i',i);
        end

        %- Determine offset by which each sub-image will be moved 
        %  + 1 is necessary since first pixel has index 1 (and not 0)

        x_pix.val           = par_spots(i,2)/pixel_size.xy +1 ;
        x_pix.floor         = floor(x_pix.val) ;
        x_pix.rem           = x_pix.val-x_pix.floor;
        x_pix.subpix        = ceil(x_pix.rem*fact_os.xy);
        x_pix.subpix_offset = floor(fact_os.xy/2)+1-x_pix.subpix ; 

        y_pix.val           = par_spots(i,1)/pixel_size.xy +1;
        y_pix.floor         = floor(y_pix.val) ;
        y_pix.rem           = y_pix.val-y_pix.floor;
        y_pix.subpix        = ceil(y_pix.rem*fact_os.xy);
        y_pix.subpix_offset = floor(fact_os.xy/2)+1-y_pix.subpix ; 

        z_pix.val           = par_spots(i,3)/pixel_size.z  +1;  
        z_pix.floor         = floor(z_pix.val);
        z_pix.rem           = z_pix.val-z_pix.floor;
        z_pix.subpix        = ceil(z_pix.rem*fact_os.z);
        z_pix.subpix_offset = floor(fact_os.z/2)+1-z_pix.subpix ; 

        % Make sure that region arround pixel is within image
        if  x_pix.floor-lp >= 1 && x_pix.floor+lp <= img.dim.X && ...
            y_pix.floor-lp >= 1 && y_pix.floor+lp <= img.dim.Y && ...
            z_pix.floor-lz >= 1 && z_pix.floor+lz <= img.dim.Z

           img_crop = img_data(y_pix.floor-lp:y_pix.floor+lp,...
                          x_pix.floor-lp:x_pix.floor+lp,...
                          z_pix.floor-lz:z_pix.floor+lz);

           if status_os

               % Generate over-sampled image
               spot_os = spot_os_temp;
               for iY=1:dim_crop.Y 
                   for iX=1:dim_crop.X
                       for iZ=1:dim_crop.Z

                           X.start = iX*fact_os.xy + 1 + x_pix.subpix_offset;
                           X.end   = (iX+1)*fact_os.xy + x_pix.subpix_offset;
                           Y.start = iY*fact_os.xy+ 1  + y_pix.subpix_offset;
                           Y.end   = (iY+1)*fact_os.xy + y_pix.subpix_offset;
                           Z.start = iZ*fact_os.z + 1  + z_pix.subpix_offset;
                           Z.end   = (iZ+1)*fact_os.z  + z_pix.subpix_offset;

                           spot_os(Y.start:Y.end,X.start:X.end,Z.start:Z.end) = img_crop(iY,iX,iZ); 
                       end
                   end
               end
           else
               spot_os = img_crop;
           end

           if img.settings.avg_spots.flags.bgd
               bgd = par_spots(i,4);
               spot_os  = spot_os  - bgd;
               img_crop = img_crop - bgd;
           end

           spot_os_sum = spot_os_sum + spot_os;
           spot_sum    = spot_sum    + img_crop;

           N_sum = N_sum+1;
        else
            N_ignore = N_ignore+1;

        end


    end

    if flags.output
        fprintf('\n');
        disp(['Number averaged spots (rest too close to image border for averaging): ' , num2str(N_spots-N_ignore)])
        disp(['Total number of averaged spots: ' , num2str(N_sum)])
    end


    %- Continue if spots were averaged
    if N_sum

        %- Calculate averaged spots
        spot_avg       = round(spot_sum/N_sum);
        spot_os_avg    = round(spot_os_sum /N_sum);  

        %- Save status for averaging in batch mode
        img_sum.spot_sum    = spot_sum;
        img_sum.spot_os_sum = spot_os_sum;
        img_sum.N_sum       = N_sum;

        %- Extract area without buffer zone
        if status_os
            spot_os_avg    = spot_os_avg(2*fact_os.xy:end-2*fact_os.xy,2*fact_os.xy:end-2*fact_os.xy,2*fact_os.z+1:end-2*fact_os.z);
        end

    else
        spot_avg    = [];
        spot_os_avg = [];
        img_sum     = {};
        if flags.output
            disp('!!! NO spot was considered in averaging !!!!')
        end
    end

    if flags.output
        disp(' ')
    end

end