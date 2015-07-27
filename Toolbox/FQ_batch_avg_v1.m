function [spot_avg, spot_avg_os, pixel_size_os,img_sum]  = FQ_batch_avg_v1(handles)




cell_summary    = handles.cell_summary;
file_summary    = handles.file_summary;

img_loop = handles.img;
img_sum  = [];

for i_file = 1:length(file_summary)

    if file_summary(i_file).status_file_ok

        par_microscope      = handles.par_microscope;
        file_names          = file_summary(i_file).file_names;
        file_name_list      = file_summary(i_file).file_name_list;
        file_names.settings = handles.file_name_settings_new;

        i_start = file_summary(i_file).cells.start;
        i_end = file_summary(i_file).cells.end;

        cell_prop = {};
        for i_abs = i_start:i_end

            i_rel = i_abs-i_start +1;  

            %- Save only thresholded spots
            spots_fit      = cell_summary(i_abs,1).spots_fit;
            spots_detected = cell_summary(i_abs,1).spots_detected;
            thresh.in      = cell_summary(i_abs,1).thresh.in;
            ind_save       = (thresh.in == 1);            

            cell_prop(i_rel).spots_fit      = spots_fit(ind_save,:); 
            cell_prop(i_rel).spots_detected = spots_detected(ind_save,:); 
            cell_prop(i_rel).thresh.in      = thresh.in(ind_save);

            %- Other properties of the cell
            cell_prop(i_rel).x         = cell_summary(i_abs,1).x; 
            cell_prop(i_rel).y         = cell_summary(i_abs,1).y;
            cell_prop(i_rel).pos_TS    = cell_summary(i_abs,1).pos_TS;
            cell_prop(i_rel).pos_Nuc   = cell_summary(i_abs,1).pos_Nuc;
            cell_prop(i_rel).label     = cell_summary(i_abs,1).label; 

        end

        %- Make img structure
        img_loop.cell_prop           = cell_prop;
        img_loop.file_names          = file_names;
        
        %- Load file-name
        img_loop.load_img(fullfile(img_loop.path_names.img, img_loop.file_names.raw),'raw');
        
        %- Average spots from ALL cells
        [dum, dum, pixel_size_os,img_sum]  = img_loop.avg_spots([],img_sum);


    end
end


%- Averaging
spot_avg       = round(img_sum.spot_sum     /img_sum.N_sum);
spot_avg_os    = round(img_sum.spot_os_sum /img_sum.N_sum); 

%- Extract area without buffer zone
if img_loop.settings.avg_spots.fact_os.xy > 1 || img_loop.settings.avg_spots.fact_os.z > 1
    fact_os          = img_loop.settings.avg_spots.fact_os;
    spot_avg_os      = spot_avg_os(2*fact_os.xy:end-2*fact_os.xy,2*fact_os.xy:end-2*fact_os.xy,2*fact_os.z+1:end-2*fact_os.z);
end

disp(' ')
disp(['Number of averaged spots: ', num2str(img_sum.N_sum)])



% 
% 
%   %=== Average first image
%     ind_cell     = 1;
%     file_name    = cell_summary(ind_cell,1).name_image;
%     image_struct = load_stack_data_v7(fullfile(path_name,file_name));
%     image        = image_struct.data;
%     spots_fit    = cell_summary(ind_cell,1).spots_fit;
%     spots_det    = cell_summary(ind_cell,1).spots_detected;
%     ind_spots    = cell_summary(ind_cell,1).thresh.in;
% 
% 
% 
% %- Average spots from ALL cells
% handles.img.avg_spots([],[]);
% handles.status_avg_calc     = 1;  % Average calculated
% 
% %- Save handles, enable controls
% guidata(hObject, handles);
% FQ_enable_controls_v1(handles)
% 
% 
% 
% 
% 
% %- Continue if paramters are defined
% if( ~ isempty(userValue))
%     
%     %- Extract parameters used for averaging
%     average.crop.xy    = str2double(userValue{1});
%     average.crop.z     = str2double(userValue{2}); 
%     average.fact_os.xy = str2double(userValue{3});
%     average.fact_os.z  = str2double(userValue{4});     
%     flag_bgd           = str2double(userValue{5});
%     average.bgd_sub    = flag_bgd;
%     offset             = 0; 
%     
%     %- Decide which position to use 
%     if average.fact_os.xy > 1 || average.fact_os.z > 1
%         flag_which_pos = 0; %- Position based on fit
%     else
%         flag_which_pos = 1; %- Position based on detection
%     end
%     
%     %- Pixel size and other stuff
%     pixel_size_os.xy             = pixel_size.xy / handles.average.fact_os.xy;
%     pixel_size_os.z              = pixel_size.z  / handles.average.fact_os.z;
%     par_microscope.pixel_size_os = pixel_size_os;
% 
%     %- Get information about image and summary of spot fitting
%     path_name    = handles.path_name_image;
%     cell_summary = handles.cell_summary;
% 
%     %- Assign parameters for averaging
%     parameters.pixel_size  = pixel_size;
%     
%     parameters.par_crop    = average.crop;
%     parameters.fact_os     = average.fact_os;
%     parameters.offset      = offset;
%     parameters.flag_os     = flag_os;
%     parameters.flag_output = 0;
%     parameters.flag_bgd    = flag_bgd;
%     
%     
%     %=== Average first image
%     ind_cell     = 1;
%     file_name    = cell_summary(ind_cell,1).name_image;
%     image_struct = load_stack_data_v7(fullfile(path_name,file_name));
%     image        = image_struct.data;
%     spots_fit    = cell_summary(ind_cell,1).spots_fit;
%     spots_det    = cell_summary(ind_cell,1).spots_detected;
%     ind_spots    = cell_summary(ind_cell,1).thresh.in;
%     
%     
%     if not(isempty(spots_fit))
%         
%         %- Detected spots and their position
%         spots_fit    = spots_fit(ind_spots == 1,:);
%         spots_bgd    = spots_fit(:,col_par.bgd);
%         
%         if flag_which_pos == 1
%             spots_det = spots_det(ind_spots == 1,:);
% 
%             spots_pos(:,1) = (spots_det(:,col_par.pos_y_det) -1) * pixel_size.xy;
%             spots_pos(:,2) = (spots_det(:,col_par.pos_x_det) -1) * pixel_size.xy;
%             spots_pos(:,3) = (spots_det(:,col_par.pos_z_det) -1) * pixel_size.z;
%  
%         else  
%             spots_pos    = spots_fit(:,[col_par.pos_y col_par.pos_x col_par.pos_z]);
%         end
%         
%         par_spots = [spots_pos,spots_bgd];     
%         parameters.par_spots   = par_spots; 
%         
%         %- Parameters needed for function call
%         disp(['Processing ', num2str(ind_cell), ', of ' , num2str(size(cell_summary,1))]) 
%         [aux1 aux2 img_sum] = PSF_3D_average_spots_v10(image,[],parameters);
% 
%         
%     else
%         img_sum = [];
%     end
% 
%     %- Average the rest
%     for ind_cell = 2:size(cell_summary,1)
%         disp(['Processing ', num2str(ind_cell), ', of ' , num2str(size(cell_summary,1))]) 
% 
%         file_name    = cell_summary(ind_cell,1).name_image;
%         image_struct = load_stack_data_v7(fullfile(path_name,file_name));
%         image        = image_struct.data;
%         ind_spots    = cell_summary(ind_cell,1).thresh.in;
%         spots_fit    = cell_summary(ind_cell,1).spots_fit;
%         spots_det    = cell_summary(ind_cell,1).spots_detected;
%         
%         %- If spots are defined
%         if not(isempty(spots_fit))
%             
%             %- Detected spots and their position
%             spots_fit    = spots_fit(ind_spots == 1,:);
%             spots_bgd    = spots_fit(:,col_par.bgd);
%             spots_pos    = [];
%             
%             if flag_which_pos == 1
%                 spots_det = spots_det(ind_spots == 1,:);
%                 spots_pos(:,1) = (spots_det(:,col_par.pos_y_det) -1) * pixel_size.xy;
%                 spots_pos(:,2) = (spots_det(:,col_par.pos_x_det) -1) * pixel_size.xy;
%                 spots_pos(:,3) = (spots_det(:,col_par.pos_z_det) -1) * pixel_size.z;
%                 
%              else
% 
%                 spots_pos    = spots_fit(:,[col_par.pos_y col_par.pos_x col_par.pos_z]);
%             end
% 
%             par_spots = [spots_pos,spots_bgd];     
%             parameters.par_spots   = par_spots;       
%   
%             %- Parameters needed for function call
%             [aux1 aux2 img_sum] = PSF_3D_average_spots_v10(image,img_sum,parameters);
%             
%         end
%         
%     end
% 
% 
%     %- Calculate averaged image
%     if not(isempty(img_sum))
%     
%         spot_avg       = round(img_sum.spot_sum/img_sum.N_sum);
%         spot_os_avg    = round(img_sum.spot_os_sum /img_sum.N_sum); 
% 
% 
%         %- Extract area without buffer zone
%         if flag_os
%             fact_os = average.fact_os;
%             spot_os_avg  = spot_os_avg(2*fact_os.xy:end-2*fact_os.xy,2*fact_os.xy:end-2*fact_os.xy,2*fact_os.z+1:end-2*fact_os.z);
%         end
% 
% 
%         spot_xy  = max(spot_avg,[],3);                      
%         spot_xz  = squeeze(max(spot_avg,[],2));                          
%         spot_yz  = squeeze(max(spot_avg,[],1)); 
% 
%         spot_us_xy  = max(spot_os_avg,[],3);                      
%         spot_us_xz  = squeeze(max(spot_os_avg,[],2));  
%         spot_us_yz  = squeeze(max(spot_os_avg,[],1)); 
% 
% 
%         [dim.Y dim.X dim.Z] = size(spot_os_avg);
% 
%         %- All projections
%         if average.fact_os.xy == 1 && average.fact_os.z == 1
% 
%             h1 = figure;
%             subplot(1,3,1)
%             imshow(spot_xy ,[],'XData', [0 dim.X*pixel_size.xy],'YData',[0 dim.Y*pixel_size.xy])
%             title('Avg.ed spot - XY')
% 
%             subplot(1,3,2)
%             imshow(spot_xz',[],'XData', [0 dim.X*pixel_size.xy],'YData',[0 dim.Z*pixel_size.z])
%             title('Avg.ed spot - XZ')
% 
%             subplot(1,3,3)
%             imshow(spot_yz',[],'XData', [0 dim.Y*pixel_size.xy],'YData',[0 dim.Z*pixel_size.z])
%             title('Avg.ed spot - YZ')
%             colormap hot
%             set(h1, 'Color', 'w')
% 
%         else
% 
%             h1 = figure;
%             subplot(3,2,1)
%             imshow(spot_xy ,[],'XData', [0 dim.X*pixel_size.xy],'YData',[0 dim.Y*pixel_size.xy])
%             title('Normal sampling - XY')
% 
%             subplot(3,2,3)
%             imshow(spot_xz',[],'XData', [0 dim.X*pixel_size.xy],'YData',[0 dim.Z*pixel_size.z])
%             title('Normal sampling - XZ')
% 
%             subplot(3,2,5)
%             imshow(spot_yz',[],'XData', [0 dim.Y*pixel_size.xy],'YData',[0 dim.Z*pixel_size.z])
%             title('Normal sampling - YZ')
% 
%             subplot(3,2,2)
%             imshow(spot_us_xy ,[],'XData', [0 dim.X*pixel_size.xy],'YData',[0 dim.Y*pixel_size.xy])
%             title('Over-sampling - XY')
% 
%             subplot(3,2,4)
%             imshow(spot_us_xz',[], 'XData', [0 dim.X*pixel_size.xy],'YData',[0 dim.Z*pixel_size.z])
%             title('Over-sampling - XZ')
% 
%             subplot(3,2,6)
%             imshow(spot_us_yz',[], 'XData', [0 dim.Y*pixel_size.xy],'YData',[0 dim.Z*pixel_size.z])
%             title('Over-sampling - YZ')
%             colormap hot
%             set(h1, 'Color', 'w')
%         end
%     else
%         disp('!!! NO spot was considered in averaging !!!!')
%         spot_avg     = [];
%         spot_os_avg  = [];
%         
%     end
%     
% else
%     spot_avg     = [];
%     spot_os_avg  = [];
% end