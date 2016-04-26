function [result, xdata] = spot_2D_fit_v1(img,xdata,options_fit,flag_struct)
% FUNCTION Fit a provided image with a 3D Gaussian

% par_start is a structure containing starting guesses for the fit. If a
% field is specified this value will be used. If the fit_mode is set in
% such a way that this value is not a free fitting parameter it will be
% used instead as an input parameter for the function call. Allowed fields
% are:
%   sigmax 
%   sigmay
%   bgd
%   amp
%   centerx
%   centery

%% Get parameters
pixel_size  = options_fit.pixel_size;
par_start   = options_fit.par_start;
fit_mode    = options_fit.fit_mode;
bound       = options_fit.bound;
options     = options_fit.options;
    

%% Dimension of image
[dim.Y, dim.X, dim.Z] = size(img);
N_pix                 = dim.X*dim.Y;

%- Generate vectors describing the image    (unless already provided)
if isempty(xdata) || N_pix ~=size(xdata,2)
      
    [Xs,Ys,Zs] = meshgrid(dim.Y:2*dim.Y-1,dim.X:2*dim.X-1);  % Pixel-grid has on offset from 0 to allow for negative values in center position

    xdata      = [];
    xdata(1,:) = double(reshape(Xs,1,N_pix))*pixel_size.xy;
    xdata(2,:) = double(reshape(Ys,1,N_pix))*pixel_size.xy;

end

%- Reformating image to fit data-format of axis vectors
ydata          = double(reshape(img,1,N_pix));


%% Analyze image to get initial conditions

%- Determine center of mass - starting point for center
center_mass  = ait_centroid3d_v3(double(img),xdata);

if not(isfield(par_start,'centerx'));  par_start.centerx = center_mass(1); end
if not(isfield(par_start,'centery'));  par_start.centery = center_mass(2); end

%- Min and Max of the image: starting point for amplitude and background
img_max   = max(img(:));
img_min   = (min(img(:))) * double((min(img(:))>0)) + (1*(min(img(:))<=0));

par_start.amp = img_max-img_min; 
par_start.bgd = img_min;        


%% Sigma as a fixed fitting parameter (to a user specified value)
if strcmp(fit_mode,'sigma_free_xz')

    %- Initial conditions
    % Double is necessary - otherwise problems with fitting routine
     x_init = double([ par_start.sigmax,  ....
                par_start.centerx, par_start.centery, ...
                par_start.amp,     par_start.bgd]);

    %- Model parameters
    par_mod{1} = 2;     % Flag to indicate that sigma_x = sigma_y
    par_mod{2} = xdata;         
    par_mod{3} = pixel_size;
   
    %-  Least Squares Curve Fitting
    [x,resnorm,residual,exitflag,output] = lsqcurvefit(@fun_Gaussian_2D_v1,double(x_init), ...
        par_mod,ydata,bound.lb,bound.ub,options);

    %- Calculate best fit
    img_fit_lin = fun_Gaussian_2D_v1(x,par_mod);
    img_fit     = reshape(img_fit_lin, size(img));
    
    %- Resize residuals
    if( numel(img) == numel(residual))
        im_residual = reshape(residual, size(img));
    else
        im_residual = ones(size(img));
    end

    %- Save results  
    result.sigmaX      = x(1);           % Sigma X
    result.sigmaY      = x(1);           % Sigma Y
    result.sigmaZ      = -1;           
    result.muX         = x(2) - dim.X*pixel_size.xy;           % Center X
    result.muY         = x(3) - dim.Y*pixel_size.xy;           % Center Y
    result.muZ         = -1;             % Center Z
    result.amp         = x(4);           % Amplitude
    result.bgd         = x(5);           % Background
    
end

%= Save results
if isempty(resnorm)
    resnorm = 0;
end

result.resnorm     = resnorm;
result.exitflag    = exitflag;
result.centroidX   = center_mass(1)- dim.X*pixel_size.xy; % Center of mass X: starting point for fit of center
result.centroidY   = center_mass(2)- dim.X*pixel_size.xy; % Center of mass Y: starting point for fit of center
result.centroidZ   = -1; % Center of mass Z: starting point for fit of center
result.output      = output;
result.maxI        = img_max;
result.im_residual = im_residual;
result.img_fit     = img_fit;

%== Show results
if flag_struct.output
        
    %== FITTING RESULTS
    disp(' ')
    disp('= FIT TO 3D GAUSSIAN ')
    disp(['Sigma (xy): ', num2str((result.sigmaX))])
    disp(['Sigma (z) : ', num2str((result.sigmaY))])
    disp(['Amplitude : ', num2str(round(result.amp))])
    disp(['Background: ', num2str(round(result.bgd))])
    disp(['Center (x): ', num2str(result.muX)])
    disp(['Center (y): ', num2str(result.muY)])
    disp(['Center (z): ', num2str(result.muZ)])
    disp(' ')
    
    
    %== IMAGE
    [dim_sub.Y, dim_sub.X] = size(img);
    
    %- Create projections
    img_MIP_xy = img;
    img_fit_MIP_xy = img_fit;
    resid_MIP_xy = im_residual;


    %- Min and max of image
    img_min = min(img(:));
    img_max = max(img(:));
    
    res_min = min(im_residual(:));
    res_max = max(im_residual(:));


    %- Show fit
    figure, set(gcf, 'color','w')     
    
    subplot(3,1,1)
    imshow(img_MIP_xy,[img_min img_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Y-1)]*pixel_size.xy)
    title('Image - XY')    
    colorbar
    hold on
    plot(result.muX, result.muY,'og')
    hold off

    %- Fit
    subplot(3,1,2)
    imshow(img_fit_MIP_xy,[img_min img_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Y-1)]*pixel_size.xy)
    title('FIT - XY')
    hold on
    plot(result.muX, result.muY,'og')
    hold off
   
    %- Residuals
    subplot(3,1,3)
    imshow(resid_MIP_xy,[res_min res_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Y-1)]*pixel_size.xy)
    title('RESID - XY')
    colorbar
  
end
