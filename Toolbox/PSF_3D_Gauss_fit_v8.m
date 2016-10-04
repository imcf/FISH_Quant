function [PSF_fit, img_PSF] = PSF_3D_Gauss_fit_v8(img_PSF,parameters)
% Function to fit 3D image data to 3d Gaussian
%
% Florian Mueller, muef@gmx.net
%
% === INPUT PARAMETER
% img_PSF .... contains image of PSF as 3d array in img_PSF.data
%
% par_crop ... Specifies cropping area (see also flag_crop)
%       par_crop.xy  ... in xy (+/- pixel from center)
%       par_crop.z   ... in z (+/- pixel from center)
%
% pixel_size ... Pixel-size
%       pixel_size.xy  ... in xy 
%       pixel_size.z   ... in z 
%
% par_microscope - Parameters describing the microscope. Used to calculate
%                  a theoretical PSF (see sigma_PSF_BoZhang_v1)
%
% === FLAGS
%  flags.crop   ... Image will be cropped 
%  flags.output ... Output plots will be shown
%
% === OUTPUT PARAMETERS
%
% === VERSION HISTORY


%== Parameters
pixel_size     = parameters.pixel_size;
par_microscope = parameters.par_microscope;
flags          = parameters.flags;

%- Check if there are boundaries for fit
if isfield(parameters,'bound')
    bound = parameters.bound;
else
    bound = [];
end

%== Find center of PSF 
[img_PSF.max.val img_PSF.max.ind_lin]       = max(img_PSF.data(:));
[img_PSF.max.Y,img_PSF.max.X,img_PSF.max.Z] = ind2sub(size(img_PSF.data),img_PSF.max.ind_lin);


%== Calculate theoretical PSF
[sigma_xy,sigma_z] = sigma_PSF_BoZhang_v1(par_microscope);
     
PSF_theo.xy_nm  = sigma_xy;
PSF_theo.xy_pix = sigma_xy/pixel_size.xy;
PSF_theo.z_nm   = sigma_z;                      
PSF_theo.z_pix  = sigma_z/pixel_size.z;


%== CROP IMAGE if specified and calculate sub-image
if flags.crop
    
    %- Crop region
    par_crop       = parameters.par_crop;
    if isempty(par_crop)
        par_crop.xy = ceil(7*PSF_theo.xy_pix);
        par_crop.z  = ceil(7*PSF_theo.z_pix);                
    end
    
    lp = par_crop.xy;
    lz = par_crop.z;    
    
    [dim.Y dim.X dim.Z] = size(img_PSF.data);
                                          
    x_min = img_PSF.max.X-lp;   if x_min < 1,     x_min = 1;     end
    x_max = img_PSF.max.X+lp;   if x_max > dim.X, x_max = dim.X; end
    
    y_min = img_PSF.max.Y-lp;   if y_min < 1,     y_min = 1;     end
    y_max = img_PSF.max.Y+lp;   if y_max > dim.Y, y_max = dim.Y; end
                                      
    z_min = img_PSF.max.Z-lz;   if z_min < 1,     z_min = 1;     end
    z_max = img_PSF.max.Z+lz;   if z_max > dim.Z, z_max = dim.Z; end
    
    img_PSF.crop = double(img_PSF.data(y_min:y_max,x_min:x_max,z_min:z_max));     
                        
    %- Offset can be used to find center in original image
    PSF_fit.crop_off_x_pix = img_PSF.max.X-lp-1;
    PSF_fit.crop_off_y_pix = img_PSF.max.Y-lp-1;
    PSF_fit.crop_off_z_pix = img_PSF.max.Z-lz-1;
                                  
else
    img_PSF.crop = img_PSF.data;
    
    PSF_fit.crop_off_x_pix = 0;
    PSF_fit.crop_off_y_pix = 0;
    PSF_fit.crop_off_z_pix = 0;
    
end

%=== Prepare vectors describing sub-grid
[dim_sub.Y dim_sub.X dim_sub.Z] = size(img_PSF.crop);
N_pix                           = dim_sub.X*dim_sub.Y*dim_sub.Z;

[Xs,Ys,Zs] = meshgrid(1:dim_sub.X,1:dim_sub.Y,1:dim_sub.Z);
X1         = reshape(Xs,1,N_pix);
Y1         = reshape(Ys,1,N_pix);
Z1         = reshape(Zs,1,N_pix);

xdata = [];
xdata(1,:) = double(X1.*pixel_size.xy);
xdata(2,:) = double(Y1.*pixel_size.xy);
xdata(3,:) = double(Z1.*pixel_size.z);

range.X = 1:dim_sub.X;
range.Y = 1:dim_sub.Y;
range.Z = 1:dim_sub.Z;


%=== Fit with 3D Gaussian

%- Basic parameters
options_fit.pixel_size = pixel_size;
options_fit.PSF_theo   = PSF_theo;
options_fit.par_start  = [];
options_fit.bound      = bound;
flag_struct.output     = flags.output;

%- Define fit mode
if isfield(parameters,'fit_mode')
    options_fit.fit_mode   = parameters.fit_mode;
else
    options_fit.fit_mode   = 'sigma_free_xz';
end

%- Assign background if specified
if isfield(parameters,'bgd')
    options_fit.bgd   = parameters.bgd;
end

%- Perform fit
FIT_Result       = psf_fit_3d_v7(img_PSF.crop,xdata,options_fit,flag_struct);

PSF_fit.sigma_xy = FIT_Result.sigmaX;
PSF_fit.sigma_z  = FIT_Result.sigmaZ;
PSF_fit.amp      = FIT_Result.amp;
PSF_fit.bgd      = FIT_Result.bgd; 

PSF_fit.mu_x     = FIT_Result.muX;
PSF_fit.mu_y     = FIT_Result.muY; 
PSF_fit.mu_z     = FIT_Result.muZ;
 
PSF_fit.mu_x_pix = PSF_fit.mu_x / pixel_size.xy;
PSF_fit.mu_y_pix = PSF_fit.mu_y / pixel_size.xy;
PSF_fit.mu_z_pix = PSF_fit.mu_z / pixel_size.xy;

PSF_fit.bgd      = FIT_Result.bgd; 
PSF_fit.resid    = FIT_Result.im_residual; 

PSF_fit.img      = img_PSF.crop;
PSF_fit.xdata    = xdata;
PSF_fit.range    = range;


%=== Reproduce best fit 
par_mod{1} = 2;     % sigma_x = sigma_y
par_mod{2} = xdata;
par_mod{3} = pixel_size;
           
par_fit(1) = PSF_fit.sigma_xy;
par_fit(2) = PSF_fit.sigma_z;    
par_fit(3) = PSF_fit.mu_x;
par_fit(4) = PSF_fit.mu_y;
par_fit(5) = PSF_fit.mu_z;    
par_fit(6) = PSF_fit.amp ;
par_fit(7) = PSF_fit.bgd ;

PSF_fit.fit_lin = fun_Gaussian_3D_v2(par_fit,par_mod);
PSF_fit.fit     = reshape(PSF_fit.fit_lin,size(img_PSF.crop)); 

% 
% % === Show result of fit
% 
if flags.output
    
    disp(' ')
    disp('= FIT TO 3D GAUSSIAN ')
    disp(['Sigma (xy): ', num2str(round(PSF_fit.sigma_xy))])
    disp(['Sigma (z) : ', num2str(round(PSF_fit.sigma_z))])
    disp(['Amplitude : ', num2str(round(PSF_fit.amp))])
    disp(['Background: ', num2str(round(PSF_fit.bgd))])
    disp(['Center (x): ', num2str(PSF_fit.mu_x)])
    disp(['Center (y): ', num2str(PSF_fit.mu_y)])
    disp(['Center (z): ', num2str(PSF_fit.mu_z)])
    disp(' ')
end
%    if flags.output 
%     %- Create projections
%     img_PSF_xy = max(img_PSF.crop,[],3);
%     img_PSF_xz = squeeze(max(img_PSF.crop,[],1));
%     img_PSF_yz = squeeze(max(img_PSF.crop,[],2)); 
% 
%     img_PSF_fit_xy = max(PSF_fit.fit,[],3);
%     img_PSF_fit_xz = squeeze(max(PSF_fit.fit,[],1));
%     img_PSF_fit_yz = squeeze(max(PSF_fit.fit,[],2));            
% 
%     img_PSF_resid_xy = max(abs(PSF_fit.resid),[],3);
%     img_PSF_resid_xz = squeeze(max(abs(PSF_fit.resid),[],1));
%     img_PSF_resid_yz = squeeze(max(abs(PSF_fit.resid),[],2));  
% 
%     %- Min and max of image
%     img_min = min(img_PSF.crop(:));
%     img_max = max(img_PSF.crop(:));
%     
%     res_min = min(img_PSF_resid_xy(:));
%     res_max = max(img_PSF_resid_xy(:));
% end
%     
%     
% if flags.output == 2
%     
%     h_fig = figure;
%     
%     %- PSF
%     subplot(3,3,1)
%     imshow(img_PSF_xy,[img_min img_max],'XData',[0 dim_sub.X]*pixel_size.xy,'YData',[0 dim_sub.Y]*pixel_size.xy)
%     title('IMG - XY')
%     colorbar
% 
%     subplot(3,3,4)
%     imshow(img_PSF_xz',[img_min img_max],'XData',[0 dim_sub.X]*pixel_size.xy,'YData',[0 dim_sub.Z]*pixel_size.z)
%     title('IMG - XZ')
% 
%     subplot(3,3,7)
%     imshow(img_PSF_yz',[img_min img_max],'XData',[0 dim_sub.Y]*pixel_size.xy,'YData',[0 dim_sub.Z]*pixel_size.z)
%     title('IMG - YZ')
% 
%     %- Fit
%     subplot(3,3,2)
%     imshow(img_PSF_fit_xy,[img_min img_max],'XData',[0 dim_sub.X]*pixel_size.xy,'YData',[0 dim_sub.Y]*pixel_size.xy)
%     title('FIT - XY')
%     colorbar
%     
%     subplot(3,3,5)
%     imshow(img_PSF_fit_xz',[img_min img_max],'XData',[0 dim_sub.X]*pixel_size.xy,'YData',[0 dim_sub.Z]*pixel_size.z)
%     title('FIT - XZ')
% 
%     subplot(3,3,8)
%     imshow(img_PSF_fit_yz',[img_min img_max],'XData',[0 dim_sub.Y]*pixel_size.xy,'YData',[0 dim_sub.Z]*pixel_size.z)
%     title('FIT - YZ')
% 
%     %- Residuals
%     subplot(3,3,3)
%     imshow(img_PSF_resid_xy,[res_min res_max],'XData',[0 dim_sub.X]*pixel_size.xy,'YData',[0 dim_sub.Y]*pixel_size.xy)
%     title('RESID - XY')
%     colorbar
%     subplot(3,3,6)
%     imshow(img_PSF_resid_xz',[res_min res_max],'XData',[0 dim_sub.X]*pixel_size.xy,'YData',[0 dim_sub.Z]*pixel_size.z)
%     title('RESID - XZ')
% 
%     subplot(3,3,9)
%     imshow(img_PSF_resid_yz',[res_min res_max],'XData',[0 dim_sub.Y]*pixel_size.xy,'YData',[0 dim_sub.Z]*pixel_size.z)
%     title('RESID - YZ')
%     colormap hot
%     
%     set(h_fig,'Color','w')
% 
% end
% 
