function FQ_obj = GMM_apply_v1(FQ_obj,img,param_GMM)

%- Get base-name 
[dum, name_base] = fileparts(FQ_obj.file_names.raw);

%- Function to apply a GMM model to alrady analyze smFISH data.
flags = param_GMM.flags;

n_spots_GMM_min = param_GMM.n_spots_GMM_min;
GMM_thresh_size = param_GMM.GMM_thresh_size;  %  Indicate the minimum number of mRNAs an aggregate must contain such that the results of the GMM are considered.
z_score_th      = param_GMM.z_score_th;       %  Maximum (modified) z-score to select fitting estimates
th_fact_intensity  = param_GMM.th_fact_intensity;

%==== Get median values for sigma & amp
% Will be used to determine if a detected spots will be analyzed by the GMM or not.

%- For each cell individually
for i_cell = 1:numel(FQ_obj.cell_prop)
    if ~isempty(FQ_obj.cell_prop(i_cell).spots_fit)
   
        sx               = (FQ_obj.cell_prop(i_cell).spots_fit(:,7));
        z_mod            = (sx-median(sx)) / mad(sx,1);
        sigma_xy(i_cell) = median(sx(z_mod< z_score_th));
        
        sz               = (FQ_obj.cell_prop(i_cell).spots_fit(:,9));
        z_mod            = (sz-median(sz)) / mad(sz,1);
        sigma_z(i_cell) = median(sz(z_mod<z_score_th));
        
        a               = (FQ_obj.cell_prop(i_cell).spots_fit(:,4));
        z_mod           = (a-median(a)) / mad(a,1);
        amp(i_cell)     = median(a(z_mod<z_score_th));     
    end
end

%- For pooled cells
param_fit_GMM_data   = vertcat(FQ_obj.cell_prop(:).spots_fit);

sigma_xy_ALL = (param_fit_GMM_data(:,7));
z_mod        = (sigma_xy_ALL-median(sigma_xy_ALL)) / mad(sigma_xy_ALL,1);
sigma_xy_ALL = median(sigma_xy_ALL(z_mod<z_score_th));

sigma_z_ALL = (param_fit_GMM_data(:,9));
z_mod        = (sigma_z_ALL-median(sigma_z_ALL)) / mad(sigma_z_ALL,1);
sigma_z_ALL = median(sigma_z_ALL(z_mod<z_score_th));

amp_ALL = (param_fit_GMM_data(:,4));
z_mod   = (amp_ALL-median(amp_ALL)) / mad(amp_ALL,1);
amp_ALL = median(amp_ALL(z_mod<z_score_th));


%%%-  Loop over all cells to perform GMM
for i_cell = 1:numel(FQ_obj.cell_prop)
    
    %=== Empty GMM results in case it will not be applied
    FQ_obj.cell_prop(i_cell).RESULT_GMM = [];
    FQ_obj.cell_prop(i_cell).spots_fit_GMM = [];    
    
    %=== Perform connected components (if not already done)
    if isempty(FQ_obj.cell_prop(i_cell).CC_results)
        
        %- Save old predection (local max)
        temp_predetect = FQ_obj.cell_prop(i_cell).spots_detected ;
        in_Nuc_temp    = FQ_obj.cell_prop(i_cell).in_Nuc ;
        
        %- Perform connected components
        FQ_obj.settings.detect.method                            = 'connectcomp';
        [spots_detected, sub_spots, sub_spots_filt, img_mask, CC_GOOD] = FQ_obj.spots_predect(i_cell);
        FQ_obj.cell_prop(i_cell).CC_results                      = CC_GOOD;
        
        %- Re-assign old detection (local max)
        FQ_obj.cell_prop(i_cell).spots_detected                  = temp_predetect ;
        FQ_obj.cell_prop(i_cell).in_Nuc                          = in_Nuc_temp ;
    end
    
    FQ_obj.cell_prop(i_cell).CC_results.ImageSize = [FQ_obj.dim.Y, FQ_obj.dim.X, FQ_obj.dim.Z];
    
    
    %===  Continue only if connected components were detected --> regions to be analyzed
    n_spot_fit = size(FQ_obj.cell_prop(i_cell).spots_fit,1);
    
    if isfield(FQ_obj.cell_prop(i_cell).CC_results, 'NumObjects')
        
        %=== Positions of connected components
        n_spot                                = FQ_obj.cell_prop(i_cell).CC_results.NumObjects;
        FQ_obj.cell_prop(i_cell).spots(:,1:3) = transpose(reshape(struct2array(regionprops(FQ_obj.cell_prop(i_cell).CC_results, 'Centroid')),3,n_spot));
        [Y_reg_all, X_reg_all, Z_reg_all]     = cellfun(@(x) ind2sub([FQ_obj.dim.Y FQ_obj.dim.X FQ_obj.dim.Y],x), FQ_obj.cell_prop(i_cell).CC_results.PixelIdxList, 'UniformOutput', 0);
        
        %== Which positions should be analyzed?
        
        %- ALL
        if flags.fit_all
            ind_GMM = transpose(1:1:n_spot);
            
            %- Only selected ones - requires connected comp and local max
        else
            
            %- Get local maximum detection
            detection_local_max = FQ_obj.cell_prop(i_cell).spots_detected(:,1:3);
            
            %- Check if two or more local max per connected component
            number_LM  = [] ;
            for i_spot = 1:n_spot        
                temp              = ismember([detection_local_max(:,1) detection_local_max(:,2) detection_local_max(:,3)] ,[Y_reg_all{i_spot} X_reg_all{i_spot} Z_reg_all{i_spot} ], 'rows');
                number_LM(i_spot) = sum(double(temp));  
            end
  
            ind_max_local        = transpose(double(number_LM > 1)) ;
            
            %- Check if brighter or larger than median mRNA
            intensity            = regionprops(FQ_obj.cell_prop(i_cell).CC_results,img,'MaxIntensity');
            intensity            = transpose(struct2array(intensity));
            ind_intensity        = double([intensity] > th_fact_intensity*median(intensity));
            
            AREA                 = regionprops(FQ_obj.cell_prop(i_cell).CC_results,img,'Area');
            ind_size             = transpose(double([AREA.Area] > 2)) ;  %- This avoids that very bright isolated pixels are considered
            
            ind_GMM_bin          = double((ind_max_local + ind_intensity).*ind_size > 0);
            ind_GMM              = find(ind_GMM_bin == 1) ;  
        end
        
        FQ_obj.cell_prop(i_cell).ind_GMM = ind_GMM ;
        
        %=== Perform the GMM
        
        %- Get parameters of mRNAs from current cell
        if ~flags.GMM_parameter &&  n_spot_fit>n_spots_GMM_min         
            param_GMM.sigma_x    = sigma_xy(i_cell);
            param_GMM.sigma_y    = sigma_xy(i_cell);
            param_GMM.sigma_z    = sigma_z(i_cell);
            param_GMM.amp        = amp(i_cell);
            
        %- Get parameters of mRNAs of the entire image
        else  
            param_GMM.sigma_x    = sigma_xy_ALL;
            param_GMM.sigma_y    = sigma_xy_ALL;
            param_GMM.sigma_z    = sigma_z_ALL;
            param_GMM.amp        = amp_ALL;
        end
        
        %- Store settings for GMM in label of cell
        FQ_obj.cell_prop(i_cell).label_GMM = [FQ_obj.cell_prop(i_cell).label, ['__GMM_','Amp-',num2str(round(param_GMM.amp)),'_Sxy-',num2str(round(param_GMM.sigma_x)),'_Sz-',num2str(round(param_GMM.sigma_z))]];
            
        %- Loop over all regions that should be analyzed
        for i_GMM  = 1:length(ind_GMM)
            
            %- Crop image
            region            = [Y_reg_all{ind_GMM(i_GMM)} X_reg_all{ind_GMM(i_GMM)} Z_reg_all{ind_GMM(i_GMM)}];
            coord_box         = [min(region,[],1) ; max(region,[],1)];
            
            x_good = coord_box(1,2)-1 > 0  && coord_box(2,2)+1 < FQ_obj.dim.X;
            y_good = coord_box(1,1)-1 > 0  && coord_box(2,1)+1 < FQ_obj.dim.Y;
            z_good = coord_box(1,3)-1 > 0  && coord_box(2,3)+1 < FQ_obj.dim.Z;
            
            %- Continue only if crop can be performed
            if x_good && y_good &&  z_good
                
                img_crop      = img(coord_box(1,1):coord_box(2,1),coord_box(1,2):coord_box(2,2), coord_box(1,3):coord_box(2,3));
                
                %- Get position of CC in cropped image
                CC_coord_crop.sub = [];
                CC_coord_crop.sub(:,1)  = uint16((region(:,1) - coord_box(1,1))+1);
                CC_coord_crop.sub(:,2)  = uint16((region(:,2) - coord_box(1,2))+1);
                CC_coord_crop.sub(:,3)  = uint16((region(:,3) - coord_box(1,3))+1);
                
                CC_coord_crop.lin       = sub2ind(size(img_crop), CC_coord_crop.sub(:,1), CC_coord_crop.sub(:,2), CC_coord_crop.sub(:,3));
                CC_coord_crop.arraySize = size(img_crop);
                
                %- Assign everything
                region_struct.img_crop        = img_crop;
                region_struct.CC_coord_crop   = CC_coord_crop;
                GMM_RESULT                =  GMM_NO_fit_v1(region_struct, param_GMM); 
                GMM_POS =  transpose(GMM_RESULT.FIT) ;
                
                %- GMM coordinates are relative to cropped image (in nm) - bring them back to the entire image
                offset_y = (coord_box(1,1) -2)*FQ_obj.par_microscope.pixel_size.xy;
                offset_x = (coord_box(1,2) -2)*FQ_obj.par_microscope.pixel_size.xy;
                offset_z = (coord_box(1,3) -2)*FQ_obj.par_microscope.pixel_size.z;
                
                GMM_POS_img = [];
                GMM_POS_img(:,1) = GMM_POS(:,1) + offset_y;
                GMM_POS_img(:,2) = GMM_POS(:,2) + offset_x;
                GMM_POS_img(:,3) = GMM_POS(:,3) + offset_z;
                
                %- Store results
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).position    = GMM_POS_img;
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).coord_box   = coord_box;
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).centroid    = mean(coord_box);
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).size        = length(region);
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).nspot       = size(GMM_RESULT.FIT,2);
                
                %- Verify if in nucleus (if nucleus is defined)
                if ~isempty(FQ_obj.cell_prop(i_cell).pos_Nuc)
                    FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).in_Nuc = inpolygon(FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).centroid(1), FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).centroid(2),FQ_obj.cell_prop(i_cell).pos_Nuc.y,FQ_obj.cell_prop(i_cell).pos_Nuc.x);
                else
                    FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).in_Nuc = false(size(GMM_RESULT.FIT,2),1);
                end
           else
                
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).position    =  mean(coord_box) .* [FQ_obj.par_microscope.pixel_size.xy FQ_obj.par_microscope.pixel_size.xy FQ_obj.par_microscope.pixel_size.z];
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).coord_box   =  coord_box;
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).centroid    =  mean(coord_box);
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).size        =  0;
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).nspot       =  0;
                FQ_obj.cell_prop(i_cell).RESULT_GMM(i_GMM).in_Nuc      =  false;
            end
        end
        
       %=== Replace detected region that went into GMM with GMM results
        %- GMM was performed
        if (n_spot>0)  && ~isempty(ind_GMM)
            
            %- Find GMM results with more than the defined minmum number ofspots
            ind_GMM_accepted_log  =  [FQ_obj.cell_prop(i_cell).RESULT_GMM(:).nspot] > GMM_thresh_size ;
            ind_GMM_accepted      = ind_GMM(ind_GMM_accepted_log);
              
            %- Find pre-detected spots that correspond to pixels that were analyzed with the GMM
            pixels_GMM_accepted   = vertcat(FQ_obj.cell_prop(i_cell).CC_results.PixelIdxList{ind_GMM_accepted});
            spot_predetect_lin    = sub2ind(size(FQ_obj.raw), FQ_obj.cell_prop(i_cell).spots_detected(:,1), FQ_obj.cell_prop(i_cell).spots_detected(:,2), FQ_obj.cell_prop(i_cell).spots_detected(:,3));
            [dum1, ind_pixels_intersect, dum2]     = intersect(spot_predetect_lin, pixels_GMM_accepted);
            
            %- Delete spots that were analyzed with GMM
            spots_single_fit                              = FQ_obj.cell_prop(i_cell).spots_fit;
            spots_single_fit(ind_pixels_intersect,:)      = [] ;
            spot_single_predetect                         = FQ_obj.cell_prop(i_cell).spots_detected ;
            spot_single_predetect(ind_pixels_intersect,:) = [] ;
            
        %- GMM was not performed
        else
            ind_GMM_accepted_log  = [];
            ind_GMM_accepted      = [];
            spots_single_fit      = FQ_obj.cell_prop(i_cell).spots_fit ;
            spot_single_predetect = FQ_obj.cell_prop(i_cell).spots_detected ;
        end
        
        %- Assign values
        FQ_obj.cell_prop(i_cell).ind_GMM_accepted = ind_GMM_accepted ;
        
        %- Assign list of spots that were NOT treated by GMM
        FQ_obj.cell_prop(i_cell).spots_single          = spot_single_predetect;
        
        if ~isempty(FQ_obj.cell_prop(i_cell).RESULT_GMM(ind_GMM_accepted_log))
            position_GMM  =  vertcat(FQ_obj.cell_prop(i_cell).RESULT_GMM(ind_GMM_accepted_log).position);
        else
            position_GMM = [] ;
        end
        
        %- Fuse individual spots and GMM results
        if ~isempty(spots_single_fit)
            spot_GMM_final                  = [spots_single_fit(:,1:3) ; position_GMM] ;
        else
            spot_GMM_final                  =  position_GMM ;
        end

        %- Assign to FQ object
        FQ_obj.cell_prop(i_cell).spots_fit_GMM = spot_GMM_final ;
        FQ_obj.cell_prop(i_cell).position_GMM  = position_GMM ;
    end
end

%- Show data
if (flags.save_plot || flags.show_GMM)
    
    %- Better scaling of image
    img_vector  = reshape(FQ_obj.raw,size(FQ_obj.raw,1)*size(FQ_obj.raw,2)*size(FQ_obj.raw,3),1);
    quantile_im = quantile(img_vector, 0.9999) ;
    
    %-- New image, invisible when plots will be saved
    fig = figure; set(gcf,'color','w')
    if flags.save_plot; set(gcf,'visible','off'); end
    axes('Units', 'normalized', 'Position', [0 0 1 1])
    imshow(max(FQ_obj.raw,[],3),[0 quantile_im]);
    hold on
    
    for i_cell = 1:size(FQ_obj.cell_prop,2)
        
        %- Plot individual mRNAs
        if ~isempty(FQ_obj.cell_prop(i_cell).spots_single)
            plot(FQ_obj.cell_prop(i_cell).spots_single(:,2), FQ_obj.cell_prop(i_cell).spots_single(:,1), '+', 'col', 'blue', 'MarkerSize',2)
        end
        
        %- For GMM - don't plot crosses but how many mRNAs per aggregate
        if ~isempty(FQ_obj.cell_prop(i_cell).RESULT_GMM)
            ind_accepted = find(vertcat(FQ_obj.cell_prop(i_cell).RESULT_GMM.nspot) > GMM_thresh_size == 1);
            
            for i_GMM = 1:length(ind_accepted)
                text(FQ_obj.cell_prop(i_cell).RESULT_GMM(ind_accepted(i_GMM)).centroid(2)-2, FQ_obj.cell_prop(i_cell).RESULT_GMM(ind_accepted(i_GMM)).centroid(1)-2, num2str(size(FQ_obj.cell_prop(i_cell).RESULT_GMM(ind_accepted(i_GMM)).position,1)),'col','green','FontSize',9)
            end
        end
        
        %- Plot outline of cell
        plot(FQ_obj.cell_prop(i_cell).x ,FQ_obj.cell_prop(i_cell).y, '-y')
        
        %- Draw nuclear outline if present
        if ~isempty(FQ_obj.cell_prop(i_cell).pos_Nuc)
            plot(FQ_obj.cell_prop(i_cell).pos_Nuc.x ,FQ_obj.cell_prop(i_cell).pos_Nuc.y, '--y')
        end
    end
    hold off
    
    if flags.save_plot
    
        folder_save_img = fullfile(param_GMM.folder_result_GMM,'#plots');
        if ~exist(folder_save_img); mkdir(folder_save_img); end

        save_name = fullfile(folder_save_img,[name_base,'_GMM-7.pdf']);
        try
            %export_fig(save_name)
            set(gcf,'Units','Inches');
            pos = get(gcf,'Position');
            set(gcf,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
            print(gcf,save_name,'-dpdf','-opengl');

        catch
%            disp('=== Error when saving image with results of GMM (using function export_fig)')
%            disp('This is likely due to missing ghostscript.') 
%            disp('Either install (links below) or disable saving of GMM results (param.GMM.flags.save_plot).')
%            disp('For Windows/Linux: http://www.ghostscript.com')
%            disp('For Mac: http://pages.uoregon.edu/koch/')
%            status_GMM_GS = 0;
            disp('=== Could not save PDF with detection results')
            disp(mfilename)
        end
        delete(fig)
    end
end
