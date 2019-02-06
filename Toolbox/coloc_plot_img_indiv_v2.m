function coloc_plot_img_indiv_v2(par)

ind_close_ch1 = par.ind_close_ch1;
ind_close_ch2 = par.ind_close_ch2;

distance_spots = par.distance_spots;
data_ch1_th   = par.data_ch1_th;
data_ch2_th   = par.data_ch2_th;
pixel_size    = par.pixel_size;
d_plot        = par.d_plot;
dim           = par.dim;
img_ch1       = par.img_ch1;
img_ch2       = par.img_ch2;
file_ch1_open = par.file_ch1_open;
file_ch2_open = par.file_ch2_open;
cell_prop_ch1 = par.cell_prop_ch1;
cell_prop_ch2 = par.cell_prop_ch2;
folder_img_indiv_coloc = par.folder_img_indiv_coloc;
folder_img_indiv_not_coloc = par.folder_img_indiv_not_coloc;
N_ch1 =  par.N_ch1;
N_ch2 =  par.N_ch2;



%% === PLOT colocalized spots
for i = 1:length(ind_close_ch1)

    %- Get spots and their distance
    spot_ch1 = data_ch1_th(ind_close_ch1(i),:);
    spot_ch2 = data_ch2_th(ind_close_ch2(i),:);
    
    
    %- Calculate distance (raw data and corrected for shift)
    dist_loop_corr = round(distance_spots(i));
    dist_loop_raw  = round(sqrt(sum((spot_ch1-spot_ch2).^2)));

    %- Crop image
    pos_y_mean = round(mean([spot_ch1(1),spot_ch2(1)]) /  pixel_size.xy) +1;
    pos_x_mean = round(mean([spot_ch1(2),spot_ch2(2)]) /  pixel_size.xy) +1;
    pos_z_mean = round(mean([spot_ch1(3),spot_ch2(3)]) /  pixel_size.z)  +1;

    x_min = pos_x_mean - d_plot.x;
    x_max = pos_x_mean + d_plot.x;

    y_min = pos_y_mean - d_plot.y;
    y_max = pos_y_mean + d_plot.y;

    z_min = pos_z_mean - d_plot.z;
    z_max = pos_z_mean + d_plot.z;

    if x_min < 1;  x_min = 1; end
    if y_min < 1;  y_min = 1; end
    if z_min < 1;  z_min = 1; end
    if z_min > dim.Z; z_min = dim.Z; end  % Fitting in z can yields spots far outside
    
    if x_max > dim.X; x_max = dim.X; end
    if y_max > dim.Y; y_max = dim.Y; end
    if z_max > dim.Z; z_max = dim.Z; end        
    if z_max < 1;     z_max = 1; end      % Fitting in z can yields spots far outside
   
    ch1_crop = img_ch1(y_min:y_max,x_min:x_max,z_min:z_max);
    ch2_crop = img_ch2(y_min:y_max,x_min:x_max,z_min:z_max);

    % - Calculate spot position in cropped image
    spot_ch1_x = spot_ch1(2) - (x_min-1.0)*pixel_size.xy;
    spot_ch1_y = spot_ch1(1) - (y_min-1.0)*pixel_size.xy;
    spot_ch1_z = spot_ch1(3) - (z_min-1.0)*pixel_size.z;

    spot_ch2_x = spot_ch2(2) - (x_min-1.0)*pixel_size.xy;
    spot_ch2_y = spot_ch2(1) - (y_min-1.0)*pixel_size.xy;
    spot_ch2_z = spot_ch2(3) - (z_min-1.0)*pixel_size.z;

 
    %- Plot figure
    try
        figure, set(gcf,'color','w'), set(gcf,'visible','off')

        subplot(2,3,1)
        im_disp = max(ch1_crop,[],3);
        imshow(im_disp,[],'XData',[0 (size(im_disp,2)-1)*pixel_size.xy],'YData',[0 (size(im_disp,1)-1)*pixel_size.xy]) 
        colormap('hot'); colorbar;
        title('CH1 - XY [green]')

         hold on
            plot(spot_ch1_x,spot_ch1_y,'+g','LineWidth',2)
            plot(spot_ch2_x,spot_ch2_y,'+b','LineWidth',2)
        hold off

        subplot(2,3,2)
        imshow(max(ch2_crop,[],3),[],'XData',[0 (size(im_disp,2)-1)*pixel_size.xy],'YData',[0 (size(im_disp,1)-1)*pixel_size.xy])
        colormap('hot'); colorbar;
        title('CH2 - XY [blue]')

        hold on
            plot(spot_ch1_x,spot_ch1_y,'+g','LineWidth',2)
            plot(spot_ch2_x,spot_ch2_y,'+b','LineWidth',2)
        hold off


        subplot(2,3,4)
        im_disp = squeeze(max(ch1_crop,[],1))';
        imshow(im_disp,[],'XData',[0 (size(im_disp,2)-1)*pixel_size.xy],'YData',[0 (size(im_disp,1)-1)*pixel_size.z])
        colormap('hot'); colorbar;
        title('CH1 - XZ')

        hold on
            plot(spot_ch1_x,spot_ch1_z,'+g','LineWidth',2)
            plot(spot_ch2_x,spot_ch2_z,'+b','LineWidth',2)
        hold off

         subplot(2,3,5)
        im_disp = squeeze(max(ch2_crop,[],1))'; 
        imshow(im_disp,[],'XData',[0 (size(im_disp,2)-1)*pixel_size.xy],'YData',[0 (size(im_disp,1)-1)*pixel_size.z])
        colormap('hot'); colorbar;
        title('CH2 - XZ')

         hold on
            plot(spot_ch1_x,spot_ch1_z,'+g','LineWidth',2)
            plot(spot_ch2_x,spot_ch2_z,'+b','LineWidth',2)
        hold off           

        subplot(2,3,3)
        axis off
        text(0,0.8,['Dist-corrected: ',num2str(dist_loop_corr),' nm'],'Interpreter','none');
        text(0,0.7,['Dist-raw: ',num2str(dist_loop_raw),' nm'],'Interpreter','none');
        text(0,0.6,['IMG: ',file_ch1_open],'Interpreter','none');
        text(0,0.5,['Cell: ',cell_prop_ch1.label],'Interpreter','none');
        text(0,0.4,['Index-CH1: ',num2str(ind_close_ch1(i))],'Interpreter','none');
        text(0,0.3,['Index-CH2: ',num2str(ind_close_ch2(i))],'Interpreter','none');

        %-- Save figure and close
        [dum, img_name_only] = fileparts(file_ch1_open);
        name = [img_name_only,'___',cell_prop_ch1.label,'___CH1-ID_',num2str(ind_close_ch1(i)),'___CH2-ID_',num2str(ind_close_ch2(i)),'.png'];
        saveas(gcf,fullfile(folder_img_indiv_coloc,name));
        close(gcf);
    catch err
        disp(err)
    end
end


%% === PLOT NOT colocalized spots (for the the channel with fewer spots)
ind_not_ch1 = setdiff(1:N_ch1,ind_close_ch1);
ind_not_ch2 = setdiff(1:N_ch2,ind_close_ch2);

if N_ch1 <= N_ch2
   
    flag.which_ch = 1;
    img_text      = file_ch1_open;
    
    ind_plot      = ind_not_ch1;
    pos_plot      = data_ch1_th(ind_not_ch1,1:3);
    data_other_ch = data_ch2_th(ind_not_ch2,1:3);

else

   flag.which_ch = 2;
   img_text      = file_ch2_open;

   ind_plot      = ind_not_ch2;
   pos_plot      = data_ch2_th(ind_not_ch2,1:3);
   data_other_ch = data_ch1_th(ind_not_ch1,1:3);

end

for i = 1:size(pos_plot,1)

   %- Index of spot
   ind_spot_loop = ind_plot(i);

   %- Find close spots within the shown pixel grid
   diff_pos_nm = abs(data_other_ch(:,1:3) - repmat(pos_plot(i,:),size(data_other_ch,1),1));

   clearvars diff_pos_pix
   diff_pos_pix(:,1:2) = diff_pos_nm(:,1:2)/pixel_size.xy;
   diff_pos_pix(:,3)   = diff_pos_nm(:,3)/pixel_size.z;

   ind_close      = find(diff_pos_pix(:,1) <= d_plot.y & diff_pos_pix(:,2) <= d_plot.x & diff_pos_pix(:,3) <= d_plot.z);    
   pos_plot_close = data_other_ch(ind_close,1:3);

   %- Find closest spots
    dist_3d                   = sqrt(sum(diff_pos_nm(ind_close,:).^2,2));
    [dist_3d_min,ind_min_dum] = min(dist_3d);
    ind_min                   = ind_close(ind_min_dum);
    
    %- Crop image
    pos_y_mean = round(pos_plot(i,1) /  pixel_size.xy) +1;
    pos_x_mean = round(pos_plot(i,2) /  pixel_size.xy) +1;
    pos_z_mean = round(pos_plot(i,3) /  pixel_size.z)  +1;
    
    x_min = pos_x_mean - d_plot.x;
    x_max = pos_x_mean + d_plot.x;

    y_min = pos_y_mean - d_plot.y;
    y_max = pos_y_mean + d_plot.y;

    z_min = pos_z_mean - d_plot.z;
    z_max = pos_z_mean + d_plot.z;

    if x_min < 1;  x_min = 1; end
    if y_min < 1;  y_min = 1; end
    if z_min < 1;  z_min = 1; end
    if z_min > dim.Z; z_min = dim.Z; end  % Fitting in z can yields spots far outside

    if x_max > dim.X; x_max = dim.X; end
    if y_max > dim.Y; y_max = dim.Y; end
    if z_max > dim.Z; z_max = dim.Z; end
    if z_max < 1;     z_max = 1; end      % Fitting in z can yields spots far outside
     
    ch1_crop = img_ch1(y_min:y_max,x_min:x_max,z_min:z_max);
    ch2_crop = img_ch2(y_min:y_max,x_min:x_max,z_min:z_max);

    %- Calculate spot position in cropped image
    spot_x = pos_plot(i,2) - (x_min-1)*pixel_size.xy;
    spot_y = pos_plot(i,1) - (y_min-1)*pixel_size.xy;
    spot_z = pos_plot(i,3) - (z_min-1)*pixel_size.z;

    spot_x_close = pos_plot_close(:,2) - (x_min-1)*pixel_size.xy;
    spot_y_close = pos_plot_close(:,1) - (y_min-1)*pixel_size.xy;
    spot_z_close = pos_plot_close(:,3) - (z_min-1)*pixel_size.z;

    %- Plot figure
try
    figure, set(gcf,'color','w'), set(gcf,'visible','off')

    subplot(2,3,1)
    im_disp = max(ch1_crop,[],3);
    imshow(im_disp,[],'XData',[0 (size(im_disp,2)-1)*pixel_size.xy],'YData',[0 (size(im_disp,1)-1)*pixel_size.xy]) 
    colormap('hot'); colorbar;
    title('CH1 - XY [green]')
    
    % Decide what to plot & save handles to copy later
    hold on
    if flag.which_ch == 1
        h_spots = plot(spot_x,spot_y,'+g','LineWidth',2);  
        h_close = plot(spot_x_close,spot_y_close,'ob','LineWidth',2);

    elseif flag.which_ch == 2
        h_spots = plot(spot_x,spot_y,'+b','LineWidth',2);  
        h_close = plot(spot_x_close,spot_y_close,'og','LineWidth',4);
    else
         h_close = [];
         h_spots = [];
    end
    hold off

    subplot(2,3,2);
    imshow(max(ch2_crop,[],3),[],'XData',[0 (size(im_disp,2)-1)*pixel_size.xy],'YData',[0 (size(im_disp,1)-1)*pixel_size.xy])
    colormap('hot'); colorbar;
    title('CH2 - XY [blue]')

    if ~isempty(h_close) || ~isempty(h_spots)
        copyobj(h_close,gca);              
        copyobj(h_spots,gca); 
    end
    
    subplot(2,3,4)
    im_disp = squeeze(max(ch1_crop,[],1))';
    imshow(im_disp,[],'XData',[0 (size(im_disp,2)-1)*pixel_size.xy],'YData',[0 (size(im_disp,1)-1)*pixel_size.z])
    colormap('hot'); colorbar;
    title('CH1 - XZ')

    % Decide what to plot & save handles to copy later
    hold on
    if flag.which_ch == 1
        h_spots = plot(spot_x,spot_z,'+g','LineWidth',2);
        h_close = plot(spot_x_close,spot_z_close,'ob','LineWidth',2);
       
    elseif flag.which_ch == 2
        h_spots = plot(spot_x,spot_z,'+b','LineWidth',2); 
        h_close = plot(spot_x_close,spot_z_close,'+g','LineWidth',2);     
   else
         h_close = [];
         h_spots = [];          
    end
    hold off

    subplot(2,3,5)
    im_disp = squeeze(max(ch2_crop,[],1))'; 
    imshow(im_disp,[],'XData',[0 (size(im_disp,2)-1)*pixel_size.xy],'YData',[0 (size(im_disp,1)-1)*pixel_size.z])
    colormap('hot'); colorbar;
    title('CH2 - XZ')

    if ~isempty(h_close) || ~isempty(h_spots)
        copyobj(h_close,gca);              
        copyobj(h_spots,gca);    
    end

    subplot(2,3,3)
    axis off
    
 catch err
    disp(err)
end   
    
    text(0,0.8,['Dist to closest: ',num2str(round(dist_3d_min)),' nm'],'Interpreter','none');
    text(0,0.7,['IMG: ',img_text],'Interpreter','none');
    text(0,0.6,['Cell: ',cell_prop_ch1.label],'Interpreter','none');

    if flag.which_ch == 1
        text(0,0.5,['Index-CH1: ',num2str(ind_spot_loop)],'Interpreter','none');
        text(0,0.4,['Closest-CH2: ',num2str(ind_min)],'Interpreter','none');
    elseif flag.which_ch == 2
	    text(0,0.5,['Closest-CH1: ',num2str(ind_min)],'Interpreter','none');
        text(0,0.4,['Index-CH2: ',num2str(ind_spot_loop)],'Interpreter','none');
    end

    %-- Save figure and close
    [dum, img_name_only] = fileparts(img_text);      


    if flag.which_ch == 1                   
        name = [img_name_only,'___',cell_prop_ch1.label,'___CH1-ID_',num2str(ind_spot_loop),'.png'];
    elseif flag.which_ch == 2
        name = [img_name_only,'___',cell_prop_ch2.label,'___CH2-ID_',num2str(ind_spot_loop),'.png'];
    end

    saveas(gcf,fullfile(folder_img_indiv_not_coloc,name));
    close(gcf);               
end