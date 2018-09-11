function [ GMM_RESULTS ] = GMM_NO_fit_v1(region_struct, param_GMM)
%====  Gaussian Mixture Model 

%= Get various parameters
pixel_size         = param_GMM.pixel_size;
PSF_space_sampling = param_GMM.PSF_space_sampling;
flags              = param_GMM.flags;

verbose = 0;

%% Pre-calculating of the erf function 

%=== Defining a fine grid with user-defined sampling for a 200x200x200 region 
% This has to be big in order to be able to fill up the entire cropped image
X_erf = 0:PSF_space_sampling:200*pixel_size.xy;
Y_erf = 0:PSF_space_sampling:200*pixel_size.xy;
Z_erf = 0:PSF_space_sampling:200*pixel_size.z;

%===ERF is calculated from the center 0,0,0, we directly get distance of
%   the grid that are difference between center and positon.             
mu_X = 0; mu_Y = 0; mu_Z = 0;

% PARAMETERS FROM  SINGLE MRNA DETECTION 
sigmax     = param_GMM.sigma_x;
sigmay     = param_GMM.sigma_y;
sigmaz     = param_GMM.sigma_z;

%- Calculate erf
erf_x =   erf2( X_erf-pixel_size.xy/2, X_erf+pixel_size.xy/2, mu_X, sigmax);
erf_y =   erf2( Y_erf-pixel_size.xy/2, Y_erf+pixel_size.xy/2, mu_Y, sigmay);
erf_z =   erf2( Z_erf-pixel_size.z/2,  Z_erf+pixel_size.z/2, mu_Z,  sigmaz);
            
%%%% Reshape the grid and creation of the lookup table 
erf_table_x      = [ X_erf ;  erf_x] ; 
erf_table_y      = [ Y_erf ;  erf_y] ;
erf_table_z      = [ Z_erf ;  erf_z] ;


%% Prepare image to be fit with GMM

img_crop  = region_struct.img_crop;

%- Prepare image to be fit
switch flags.fit_region

    %- Entire image is fit
    case 'entire'
        
        %- Find all pixels
        [ind_pixel_y, ind_pixel_x, ind_pixel_z] = ind2sub(size(img_crop), find(img_crop >=0));
        
        %- Image as vector
        N_pix    = numel(img_crop);
        img_vect = double(reshape(img_crop,N_pix, 1));
        
    %- Only pixels identified from connected components are fit
    case 'CC'
        ind_pixel_y = region_struct.CC_coord_crop.sub(:,1);
        ind_pixel_x = region_struct.CC_coord_crop.sub(:,2);
        ind_pixel_z = region_struct.CC_coord_crop.sub(:,3);
        
        img_vect   = squeeze(img_crop(region_struct.CC_coord_crop.lin));
        
        % Make sure this is a row vector
        if size(img_vect,2)>1
            img_vect = img_vect';
        end
end

%- CREATION OF GRID describing image that should be fit
grid.x = ind_pixel_x.*pixel_size.xy;
grid.y = ind_pixel_y.*pixel_size.xy;
grid.z = ind_pixel_z.*pixel_size.z;


%% PARAMETERS FOR THE FITTING
param.amp        = param_GMM.amp;
param.spacing    = [ PSF_space_sampling PSF_space_sampling PSF_space_sampling] ;  % CORRESPOND TO THE THICKNESS OF THE GRID OF THE PRE CALCULATION OF THE ERF FUNCTION
param.pixel_size = pixel_size;
xdata{4} = param;

xdata{1} = erf_table_y;
xdata{2} = erf_table_x;
xdata{3} = erf_table_z;

xdata{5} = grid.y;
xdata{6} = grid.x;
xdata{7} = grid.z;

xdata{9} = size(img_crop); 


%% Actual GMM fitting
% INITIALISATION OF STRUCTURE

tic; 

%- Find location of maximum
[dum, pos_max.lin] =  max(double(img_vect));   
x_init             = [grid.y(pos_max.lin); grid.x(pos_max.lin); grid.z(pos_max.lin)];

%- First iteration
i = 1; 
im_seq    = {}; 
ssr       = [];
xdata{15} = []; %- Stores the image
diff_ssr  = -1; %- Keep track of the changes in the residuals

im_reconstructed = fit_region_pre_calculated_v1(x_init, xdata);      

%- Save results
im_seq{i}   = im_reconstructed;   
fit_pos     = x_init;
im_residual = double(img_vect) - double(im_reconstructed);   

ssr(i)      = sum(im_residual.^2);

%- Loop until difference in residuals will go up again (overfitted)
i=2;

while diff_ssr < 0 
    
    %- Save fitted positions and image
    xdata{15}    = im_reconstructed ;
    
    %- Find location of maximum
    [dum, pos_max.lin]                =  max(double(im_residual));                
    x_init             = [grid.y(pos_max.lin); grid.x(pos_max.lin); grid.z(pos_max.lin)];

    %- Get new positions

    %- Fit image
    im_reconstructed = uint16(fit_region_pre_calculated_v1(x_init, xdata));    
    im_residual      = double(img_vect) - double(im_reconstructed); 
        
    %- Save results
    fit_pos   = [fit_pos x_init];
    im_seq{i} = im_reconstructed;   
    ssr(i)    = sum(im_residual.^2); 
    
    %- Prepare next iteration
    diff_ssr    = ssr(i) - ssr(i-1); 
    i           = i+1;
    
end

TIME = toc;

GMM_RESULTS.FIT  = fit_pos(:,1:i-2);
GMM_RESULTS.IM   = im_seq{i-2};
GMM_RESULTS.TIME = TIME;


%% Debugging code
if verbose
    
    pos_y = fit_pos(1,:) / pixel_size.xy;
    pos_x = fit_pos(2,:) / pixel_size.xy;
    
    
    %- Crop image
    img_crop_mip = max(img_crop,[],3);
   
    %- Prepare other images
    switch flags.fit_region
        
        %- Entire image is fit
        case 'entire'
            
            img_crop_mip    = max(img_crop,[],3);
            im_PSF          = reshape(im_seq{1},size(img_crop));
            im_GMM          = reshape(im_seq{i-2},size(img_crop));
            im_GMM_too_many = reshape(im_seq{i-1},size(img_crop));
            im_res          = reshape(im_residual,size(img_crop));
            
        case 'CC'
            
            img_empty    = zeros(size(img_crop));
            
            im_fit = img_empty;
            im_fit(region_struct.CC_coord_crop.lin) = img_vect;
            img_crop_mip    = max(im_fit,[],3);
       
            im_PSF = img_empty;
            im_PSF(region_struct.CC_coord_crop.lin) = im_seq{1};
            
            im_GMM = img_empty;
            im_GMM(region_struct.CC_coord_crop.lin) = im_seq{i-2};
            
            im_GMM_too_many = img_empty;
            im_GMM_too_many(region_struct.CC_coord_crop.lin) = im_seq{i-1};
            
            im_res = img_empty;
            im_res(region_struct.CC_coord_crop.lin) = im_residual;
            
    end
    
    im_min = min(img_crop_mip(:));
    im_max = max(img_crop_mip(:));
    
    %- Actual figure
    figure,
    subplot(3,2,1)
    imshow(img_crop_mip,[im_min im_max])
    title('data')
    colorbar
    
    subplot(3,2,2)
    imshow(max(im_PSF,[],3),[])
    
    title('psf - first placed')
    colorbar
    
    subplot(3,2,3)
    hold on
    imshow(max(im_GMM,[],3),[im_min im_max])
    plot(pos_x,pos_y,'+r')
    hold off
    title('GMM')
    v=axis;
    
     if size(fit_pos,2) > 5
        
        ax = subplot(3,2,4);
        ndhist(pos_x,pos_y);
        
        set(gca,'YDir','Reverse')
        colorbar
        axis equal
        title('Histgram of placed PSF')
        colormap(ax,'parula') 
   end
    
    subplot(3,2,5)
    imshow(max(im_res,[],3),[])
    title('resid')       
    colorbar
    
    ax = subplot(3,2,6)
    hist(im_residual)
    title('resid')
    colormap(ax,'parula') 
    
   %- Set color-map of rest back to gray
   colormap('gray')
end


