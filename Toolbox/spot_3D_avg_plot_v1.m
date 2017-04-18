function spot_3D_avg_plot_v1(img)

    spot_avg    = img.spot_avg;
    spot_avg_os = img.spot_avg_os;

    %- Make projections
    spot_xy  = max(spot_avg,[],3);                      
    spot_xz  = squeeze(max(spot_avg,[],2));                          
    spot_yz  = squeeze(max(spot_avg,[],1)); 

    spot_os_xy  = max(spot_avg_os,[],3);                      
    spot_os_xz  = squeeze(max(spot_avg_os,[],2));  
    spot_os_yz  = squeeze(max(spot_avg_os,[],1)); 

    %- Size of image
    [dim_crop.Y, dim_crop.X, dim_crop.Z] = size(spot_avg);
    pixel_size       = img.par_microscope.pixel_size;

    %- If not oversampling was performed
    if img.settings.avg_spots.fact_os.xy == 1 && img.settings.avg_spots.fact_os.z == 1

        h1 = figure; set(gcf,'color','w')
        subplot(1,3,1)
        imshow(spot_xy ,[],'XData', [0 dim_crop.X*pixel_size.xy],'YData',[0 dim_crop.Y*pixel_size.xy])
        title('Normal sampling - XY')

        subplot(1,3,2)
        imshow(spot_xz',[],'XData', [0 dim_crop.X*pixel_size.xy],'YData',[0 dim_crop.Z*pixel_size.z])
        title('Normal sampling - XZ')

        subplot(1,3,3)
        imshow(spot_yz',[],'XData', [0 dim_crop.Y*pixel_size.xy],'YData',[0 dim_crop.Z*pixel_size.z])
        title('Normal sampling - YZ')
        colormap hot 
        set(h1, 'Color', 'w')

    else

        %- All projections
        h1 = figure;
        subplot(3,2,1)
        imshow(spot_xy ,[],'XData', [0 dim_crop.X*pixel_size.xy],'YData',[0 dim_crop.Y*pixel_size.xy])
        title('Normal sampling - XY')

        subplot(3,2,3)
        imshow(spot_xz',[],'XData', [0 dim_crop.X*pixel_size.xy],'YData',[0 dim_crop.Z*pixel_size.z])
        title('Normal sampling - XZ')

        subplot(3,2,5)
        imshow(spot_yz',[],'XData', [0 dim_crop.Y*pixel_size.xy],'YData',[0 dim_crop.Z*pixel_size.z])
        title('Normal sampling - YZ')

        subplot(3,2,2)
        imshow(spot_os_xy ,[],'XData', [0 dim_crop.X*pixel_size.xy],'YData',[0 dim_crop.Y*pixel_size.xy])
        title('Over-sampling - XY')

        subplot(3,2,4)
        imshow(spot_os_xz',[], 'XData', [0 dim_crop.X*pixel_size.xy],'YData',[0 dim_crop.Z*pixel_size.z])
        title('Over-sampling - XZ')

        subplot(3,2,6)
        imshow(spot_os_yz',[], 'XData', [0 dim_crop.Y*pixel_size.xy],'YData',[0 dim_crop.Z*pixel_size.z])
        title('Over-sampling - YZ')
        colormap hot    
        set(h1, 'Color', 'w')

    end
end
