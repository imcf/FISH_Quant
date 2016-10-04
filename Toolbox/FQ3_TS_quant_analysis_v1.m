function [results, img_PSF_all] = FQ3_TS_quant_analysis_v1(img,pos_TS,img_PSF_all,parameters)

%== Some parameters
flags               = parameters.flags;
pixel_size          = parameters.pixel_size;
par_microscope      = parameters.par_microscope;
range_int           = parameters.range_int;
psname              = parameters.file_name_save_PLOTS_PS;

%=== Extract image of transcription site
min_x = round(min(pos_TS.x));
max_x = round(max(pos_TS.x));
min_y = round(min(pos_TS.y));
max_y = round(max(pos_TS.y));

%- Make sure cropping is within image
dim = img.dim;

[dim.Y dim.X dim.Z] = size(img.raw);

if min_x < 1; min_x = 1; end
if max_x > dim.X; max_x = dim.X; end

if min_y < 1; min_y = 1; end
if max_y > dim.Y; max_y = dim.Y; end

%- Generate image zero everywhere except at transcription site
img_TS_large                            = zeros(size(img.raw));
img_TS_large(min_y:max_y,min_x:max_x,:) = img.raw(min_y:max_y,min_x:max_x,:); 

[img_TS_large_max.val img_TS_large_max.ind_lin]            = max(img_TS_large(:));
[img_TS_large_max.Y,img_TS_large_max.X,img_TS_large_max.Z] = ind2sub(size(img_TS_large),img_TS_large_max.ind_lin(1));


%=== Cropping region
crop_xy_pix = parameters.crop_image.xy_pix;
crop_z_pix  = parameters.crop_image.z_pix;

xmin_crop = round(img_TS_large_max.X - crop_xy_pix);
xmax_crop = round(img_TS_large_max.X + crop_xy_pix);

ymin_crop = round(img_TS_large_max.Y - crop_xy_pix);
ymax_crop = round(img_TS_large_max.Y + crop_xy_pix);

zmin_crop = round(img_TS_large_max.Z - crop_z_pix);
zmax_crop = round(img_TS_large_max.Z + crop_z_pix);

if ymin_crop<1;     ymin_crop = 1;     end
if ymax_crop>dim.Y; ymax_crop = dim.Y; end

if xmin_crop<1;     xmin_crop = 1;     end
if xmax_crop>dim.X; xmax_crop = dim.X; end

if zmin_crop<1;     zmin_crop = 1;     end
if zmax_crop>dim.Z; zmax_crop = dim.Z; end


img_TS_crop_xyz = img.raw(ymin_crop:ymax_crop,xmin_crop:xmax_crop,zmin_crop:zmax_crop);

        

%% Calculate assignment table for linear indices to matrix coordinates
%  Used for intensity based random placement of PSF

%==  Vectors with dimensions
[dim_TS_crop.Y,dim_TS_crop.X,dim_TS_crop.Z] = size(img_TS_crop_xyz);
X_nm_crop = []; Y_nm_crop = []; Z_nm_crop = []; 
X_nm_crop(:,1) = (1:dim_TS_crop.X)*pixel_size.xy;
Y_nm_crop(:,1) = (1:dim_TS_crop.Y)*pixel_size.xy;
Z_nm_crop(:,1) = (1:dim_TS_crop.Z)*pixel_size.z;

coord.X_nm = X_nm_crop;
coord.Y_nm = Y_nm_crop;
coord.Z_nm = Z_nm_crop;

%== List of intensity values for intensity based selection of position
index_table = zeros(dim_TS_crop.Z*dim_TS_crop.X*dim_TS_crop.Y,3);
ind_loop    = 1;

%- Loop through in the same way than linear indexing and assign index
for iZ=1:dim_TS_crop.Z
    for iX=1:dim_TS_crop.X
        for iY =1:dim_TS_crop.Y        
            index_table(ind_loop,:) = [iY, iX, iZ];
            ind_loop = ind_loop+1;
        end
    end
end



%% Show results of crop
if flags.output == 2 || not(isempty(psname))
    
    %== Visualize site in projections
    img_TS_crop_proj_xy = max(img_TS_crop_xyz,[],3);
    img_TS_crop_proj_xz = squeeze(max(img_TS_crop_xyz,[],1));
    img_TS_crop_proj_yz = squeeze(max(img_TS_crop_xyz,[],2));

    h1 = figure;
    subplot(2,2,4)
    imshow(img_TS_crop_proj_xy,[],'XData',X_nm_crop,'YData',Y_nm_crop);
    title('TxSite MIP XY - cropped')
    
    subplot(2,2,2)
    imshow(img_TS_crop_proj_xz',[],'XData',X_nm_crop,'YData',Z_nm_crop);
    title('TxSite MIP XZ - cropped')
    
    subplot(2,2,3)
    imshow(img_TS_crop_proj_yz,[],'XData',Z_nm_crop,'YData',Y_nm_crop);
    title('TxSite MIP ZY - cropped')
    colormap hot
    set(h1,'Color','w')
    
    if not(isempty(psname))
       print (h1,'-dpsc', psname, '-append');
       close(h1)   
    end
end

%% Estimate background - on not cropped image!

%- Based on averaging a certain percentage of the cropped image
if flags.bgd_local == 1
        
    nBins = parameters.nBins;

    %- Calculate histogram and determine threshold
    [counts, bin ] = hist(img_TS_crop_xyz(:),nBins);
    counts_max     = max(counts);
    int_row_sort   = sort(img_TS_crop_xyz(:),'ascend');
    N_vox          = length(int_row_sort);
    bgd_avg        = mean(int_row_sort(1:round(per_avg_bgd*N_vox)));

    %- Manual correct threshold
    if flags.bgd_local == 2
        
        %- Show results of histogram and threshold
        figure, hold on
        bar(bin,counts)
        plot([bgd_avg bgd_avg], [0 counts_max],'r')
        hold off
        xlabel('Intensity value')
        ylabel('Count')
        title('Thresholding of background > red line')

        %- Check if threshold is ok
        choice = questdlg('Background ok?','Estimation of background','Yes','No','Yes');


        %- Ask user if threshold is ok
        while (strcmp(choice,'No'))

            %- Ask user for new threshold
            prompt    = {'Value of threshold:'};
            dlg_title = 'Threshold histogram';
            num_lines = 1;
            def       = {num2str(bgd_avg)};
            answer    = inputdlg(prompt,dlg_title,num_lines,def);
            bgd_avg      = str2double(answer{1}); 
            
            bgd_median = bgd_avg;
            bgd_stdev  = 0;

            %- Plot histogram with location of threshold
            figure, hold on
            bar(bin,counts)
            plot([bgd_avg bgd_avg], [0 counts_max],'r')
            hold off
            xlabel('Intensity value')
            ylabel('Count')
            title('Thresholding based on curvature threshold > red line')

            %- Check if threshold is ok
            choice = questdlg('Background ok?','Estimation of background','Yes','No','Yes');
        end
    end  

%- Define range based on averaged intensity of entire cell or nucleus
elseif flags.bgd_local == 2
    
    
    if not(isempty(parameters.nuc_bw))
        bgd_bw = parameters.nuc_bw;
    else
        bgd_bw = parameters.cell_bw;
    end
    
    int_all = [];
    for z_ind = zmin_crop:1:zmax_crop
        img_loop = img.raw(:,:,zmin_crop:zmax_crop);
        int_loop  = img_loop(bgd_bw);
        int_all   = [int_all;int_loop(:)];
    end
    
    bgd_median = round(median(double(int_all)));
    bgd_std    = round(std(double(int_all)));
    
    fact_min = parameters.bgd_fact_min;
    fact_max = parameters.bgd_fact_max;
    N_bins   = parameters.bgd_N_bins;
    
    %- Generate background values and remove values <0
    bgd_avg =  round(linspace(bgd_median-fact_min*bgd_std,bgd_median+fact_max*bgd_std,N_bins));
    bgd_avg(bgd_avg<0) = [];
    
    bgd_median = bgd_median;
    bgd_stdev  = bgd_std;
    
    if flags.output == 1
        disp(' ')
        disp('=== ANALYSIS of cellular intensity ')
        disp(['Median of cell intensity: ', num2str(bgd_median)]);
        disp(['Stdev of cell intensity : ', num2str(bgd_std)]);
    end
    
    if parameters.fid ~= -1
        fprintf(parameters.fid, '\n= ANALYSIS of cellular intensity for TxSite background\n');
        fprintf(parameters.fid, 'Median of cell intensity:  %g \n', bgd_median);
        fprintf(parameters.fid, 'Stdev of cell intensity :  %g \n', bgd_std);
        fprintf(parameters.fid, 'Intensities to be tested:  %s \n \n', num2str(bgd_avg));
    end
    
else
    bgd_avg    = parameters.BGD.amp;
    bgd_median = parameters.BGD.amp;
    bgd_stdev  = 0;
end


%% Add padding to different PSF's  to avoid too large shifts

N_PSF = size(img_PSF_all,1)*size(img_PSF_all,2);

for i_PSF = 1:N_PSF

    img_PSF = img_PSF_all(i_PSF);

    img_PSF_all(i_PSF).pad = padarray(img_PSF.data,[dim_TS_crop.Y dim_TS_crop.X dim_TS_crop.Z]);

    img_PSF_all(i_PSF).max.X_pad = img_PSF.max.X + dim_TS_crop.X;
    img_PSF_all(i_PSF).max.Y_pad = img_PSF.max.Y + dim_TS_crop.Y;
    img_PSF_all(i_PSF).max.Z_pad = img_PSF.max.Z + dim_TS_crop.Z;
end


%% ========================================================================
%=  Fit with Gaussian

%- Basic parameters of the fit
parameters_fit.pixel_size     = pixel_size;
parameters_fit.par_microscope = par_microscope;
parameters_fit.flags.output   = flags.output;
parameters_fit.flags.crop     = 0;

%- Fix background to median value if defined
if flags.IntegInt_bgd_free
    parameters_fit.fit_mode   = 'sigma_free_xz';
else
    if bgd_median
        parameters_fit.bgd        = bgd_median;
        parameters_fit.fit_mode   = 'sigma_free_BGD_fixed';
    else
        parameters_fit.fit_mode   = 'sigma_free_xz';
    end
end

%- Boundaries for fit
if flags.bound == 1

    simga_xy_max = dim_TS_crop.Y*pixel_size.xy;
    simga_z_max  = dim_TS_crop.Z*pixel_size.z;

    bound.lb = [0               0 0   0   0   0   0]; 
    bound.ub = [simga_xy_max simga_z_max inf inf inf inf inf];
    
else
    bound = [];
    
end

%- Fit
parameters_fit.bound = bound;
dum.data      = img_TS_crop_xyz;
TS_Fit_Result = PSF_3D_Gauss_fit_v8(dum,parameters_fit);  


%== Integrated intensity under fitted curve

%- Integration range
x_int = range_int.x_int;
y_int = range_int.y_int;
z_int = range_int.z_int;

%- 3D
if z_int.max-z_int.min > 0

    par_mod_int(1)  = TS_Fit_Result.sigma_xy;
    par_mod_int(2)  = TS_Fit_Result.sigma_xy;
    par_mod_int(3)  = TS_Fit_Result.sigma_z;
    par_mod_int(7)  = TS_Fit_Result.amp ;

    par_mod_int(4)  = 0;
    par_mod_int(5)  = 0;
    par_mod_int(6)  = 0;
    par_mod_int(8)  = 0;

    %- Calculate intensity
    TS_Fit_Result.integ_int = fun_Gaussian_3D_triple_integral_v1(x_int,y_int,z_int,par_mod_int);
    
else
    par_mod_int(1)  = TS_Fit_Result.sigma_xy;
    par_mod_int(2)  = TS_Fit_Result.sigma_xy;

    par_mod_int(3)  = 0;
    par_mod_int(4)  = 0;

    par_mod_int(5)  = TS_Fit_Result.amp;
    par_mod_int(6)  = 0 ;

    TS_Fit_Result.integ_int = fun_Gaussian_2D_double_integral_v1(x_int,y_int,par_mod_int);
    
end
    


TS_Fit_Result.x_int = x_int;
TS_Fit_Result.y_int = y_int;
TS_Fit_Result.z_int = z_int;


%% Save results
results.img_TS_crop_xyz  = img_TS_crop_xyz;
results.coord            = coord;
results.index_table      = index_table;
results.TS_Fit_Result    = TS_Fit_Result;
results.bgd_amp          = bgd_avg;

results.bgd_median = bgd_median;
results.bgd_stdev  = bgd_stdev;


