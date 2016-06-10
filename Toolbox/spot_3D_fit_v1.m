function [result, xdata] = spot_3D_fit_v1(img,xdata,options_fit,flag_struct)
% FUNCTION Fit a provided image with a 3D Gaussian

% par_start is a structure containing starting guesses for the fit. If a
% field is specified this value will be used. If the fit_mode is set in
% such a way that this value is not a free fitting parameter it will be
% used instead as an input parameter for the function call. Allowed fields
% are:
%   sigmax 
%   sigmay
%   sigmaz
%   bgd
%   amp
%   centerx
%   centery
%   centerz

%% Get parameters
pixel_size  = options_fit.pixel_size;
par_start   = options_fit.par_start;
fit_mode    = options_fit.fit_mode;
bound       = options_fit.bound;
options     = options_fit.options;
    

%% Dimension of image
[dim.Y, dim.X, dim.Z] = size(img);
N_pix                 = dim.X*dim.Y*dim.Z;

%- Generate vectors describing the image    (unless already provided)
if isempty(xdata) || N_pix ~=size(xdata,2)
      
    [Xs,Ys,Zs] = meshgrid(dim.Y:2*dim.Y-1,dim.X:2*dim.X-1,dim.Z:2*dim.Z-1);  % Pixel-grid has on offset from 0 to allow for negative values in center position

    xdata      = [];
    xdata(1,:) = double(reshape(Xs,1,N_pix))*pixel_size.xy;
    xdata(2,:) = double(reshape(Ys,1,N_pix))*pixel_size.xy;
    xdata(3,:) = double(reshape(Zs,1,N_pix))*pixel_size.z;
end

%- Reformating image to fit data-format of axis vectors
ydata          = double(reshape(img,1,N_pix));


%% Analyze image to get initial conditions

%- Determine center of mass - starting point for center
center_mass  = ait_centroid3d_v3(double(img),xdata);

if not(isfield(par_start,'centerx'));  par_start.centerx = center_mass(1); end
if not(isfield(par_start,'centery'));  par_start.centery = center_mass(2); end
if not(isfield(par_start,'centerz'));  par_start.centerz = center_mass(3); end

%- Min and Max of the image: starting point for amplitude and background
img_max   = max(img(:));
img_min   = (min(img(:))) * double((min(img(:))>0)) + (1*(min(img(:))<=0));

par_start.amp = img_max-img_min; 
par_start.bgd = img_min;        


%% Sigma as a fixed fitting parameter (to a user specified value)
if strcmp(fit_mode,'sigma_fixed')
   
    %- Initial conditions
    % Double is necessary - otherwise problems with fitting routine
    x_init = double([  par_start.centerx, par_start.centery, par_start.centerz,...
                par_start.amp,     par_start.bgd]);


    %- Model parameters        
    par_mod{1} = 3;     % Flag to indicate sigma's are fixed
    par_mod{2} = xdata;         
    par_mod{3} = pixel_size;
    par_mod{4} = par_start.sigmax;
    par_mod{5} = par_start.sigmay;
    par_mod{6} = par_start.sigmaz;
         
    %-  Least Squares Curve Fitting
    % 
    [x,resnorm,residual,exitflag,output] = lsqcurvefit(@fun_Gaussian_3D_v2,x_init, ...
        par_mod,ydata,bound.lb,bound.ub,options);

    %- Calculate best fit
    img_fit_lin = fun_Gaussian_3D_v2(x,par_mod);
    img_fit     = reshape(img_fit_lin, size(img));
    
    %- Resize residuals
    if( numel(img) == numel(residual))
        im_residual = reshape(residual, size(img));
    else
        im_residual = ones(size(img));
    end

    %- Save results  
    result.sigmaX      = par_start.sigmax;          % Sigma X
    result.sigmaY      = par_start.sigmay;          % Sigma Y
    result.sigmaZ      = par_start.sigmaz;          % Sigma Z
    result.muX         = x(1) - dim.X*pixel_size.xy;                      % Center X
    result.muY         = x(2) - dim.Y*pixel_size.xy;                      % Center Y
    result.muZ         = x(3) - dim.Z*pixel_size.z;                      % Center Z
    result.amp         = x(4);                      % Amplitude
    result.bgd         = x(5);                      % Background  

%= Sigma as a free fitting paramter in xy and z       
elseif strcmp(fit_mode,'sigma_free_xz')

    %- Initial conditions
    % Double is necessary - otherwise problems with fitting routine
     x_init = double([ par_start.sigmax,  par_start.sigmaz,  ...
                par_start.centerx, par_start.centery, par_start.centerz,...
                par_start.amp,     par_start.bgd]);

    %- Model parameters
    par_mod{1} = 2;     % Flag to indicate that sigma_x = sigma_y
    par_mod{2} = xdata;         
    par_mod{3} = pixel_size;
   
    %-  Least Squares Curve Fitting
    [x,resnorm,residual,exitflag,output] = lsqcurvefit(@fun_Gaussian_3D_v2,double(x_init), ...
        par_mod,ydata,bound.lb,bound.ub,options);

    %- Calculate best fit
    img_fit_lin = fun_Gaussian_3D_v2(x,par_mod);
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
    result.sigmaZ      = x(2);           % Sigma Z
    result.muX         = x(3) - dim.X*pixel_size.xy;           % Center X
    result.muY         = x(4) - dim.Y*pixel_size.xy;           % Center Y
    result.muZ         = x(5) - dim.Z*pixel_size.z;           % Center Z
    result.amp         = x(6);           % Amplitude
    result.bgd         = x(7);           % Background
    
    
 %= Sigma as a free fitting paramter in xy and z       
elseif strcmp(fit_mode,'sigma_free_BGD_fixed')

    %- Initial conditions
    % Double is necessary - otherwise problems with fitting routine
     x_init = double([ par_start.sigmax,  par_start.sigmaz,  ...
                par_start.centerx, par_start.centery, par_start.centerz,...
                par_start.amp]);

    %- Model parameters
    par_mod{1} = 4;     % Flag to indicate that sigma_x = sigma_y and BGD is fixed
    par_mod{2} = xdata;         
    par_mod{3} = pixel_size;
    par_mod{4} = options_fit.bgd;
   
    %-  Least Squares Curve Fitting
    [x,resnorm,residual,exitflag,output] = lsqcurvefit(@fun_Gaussian_3D_v2,double(x_init), ...
        par_mod,ydata,bound.lb,bound.ub,options);

    %- Calculate best fit
    img_fit_lin = fun_Gaussian_3D_v2(x,par_mod);
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
    result.sigmaZ      = x(2);           % Sigma Z
    result.muX         = x(3) - dim.X*pixel_size.xy;           % Center X
    result.muY         = x(4) - dim.Y*pixel_size.xy;           % Center Y
    result.muZ         = x(5) - dim.Z*pixel_size.z;           % Center Z
    result.amp         = x(6);           % Amplitude
    result.bgd         = options_fit.bgd;           % Background      
    
     
end

%= Save results
if isempty(resnorm)
    resnorm = 0;
end

result.resnorm     = resnorm;
result.exitflag    = exitflag;
result.centroidX   = center_mass(1)- dim.X*pixel_size.xy; % Center of mass X: starting point for fit of center
result.centroidY   = center_mass(2)- dim.X*pixel_size.xy; % Center of mass Y: starting point for fit of center
result.centroidZ   = center_mass(3)- dim.Z*pixel_size.z; % Center of mass Z: starting point for fit of center
result.output      = output;
result.maxI        = img_max;
result.im_residual = im_residual;
result.img_fit     = img_fit;

%== Show results
if flag_struct.output
        
    %== FITTING RESULTS
    disp(' ')
    disp('= FIT TO 3D GAUSSIAN ')
    disp(['Sigma (xy): ', num2str(round(result.sigmaX))])
    disp(['Sigma (z) : ', num2str(round(result.sigmaY))])
    disp(['Amplitude : ', num2str(round(result.amp))])
    disp(['Background: ', num2str(round(result.bgd))])
    disp(['Center (x): ', num2str(result.muX)])
    disp(['Center (y): ', num2str(result.muY)])
    disp(['Center (z): ', num2str(result.muZ)])
    disp(' ')
    
    
    %== IMAGE
    [dim_sub.Y, dim_sub.X, dim_sub.Z] = size(img);
    
    %- Create projections
    img_MIP_xy = max(img,[],3);
    img_MIP_xz = squeeze(max(img,[],1));
    img_MIP_yz = squeeze(max(img,[],2)); 

    img_fit_MIP_xy = max(img_fit,[],3);
    img_fit_MIP_xz = squeeze(max(img_fit,[],1));
    img_fit_MIP_yz = squeeze(max(img_fit,[],2));            

    resid_MIP_xy = max(im_residual,[],3);
    resid_MIP_xz = squeeze(max(im_residual,[],1));
    resid_MIP_yz = squeeze(max(im_residual,[],2));  

    %- Min and max of image
    img_min = min(img(:));
    img_max = max(img(:));
    
    res_min = min(im_residual(:));
    res_max = max(im_residual(:));


    %- Show fit
    figure, set(gcf, 'color','w')     
    
    subplot(3,3,1)
    imshow(img_MIP_xy,[img_min img_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Y-1)]*pixel_size.xy)
    title('Image - XY')    
    colorbar
    hold on
    plot(result.muX, result.muY,'og')
    hold off

    subplot(3,3,4)
    imshow(img_MIP_xz',[img_min img_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Z-1)]*pixel_size.z)
    title('Image - XZ')
    colorbar
    hold on
    plot(result.muX, result.muZ,'og')
    hold off
    
    subplot(3,3,7)
    imshow(img_MIP_yz',[img_min img_max],'XData',[0 (dim_sub.Y-1)]*pixel_size.xy,'YData',[0 (dim_sub.Z-1)]*pixel_size.z)
    title('Image - YZ')
    colorbar
    hold on
    plot(result.muY, result.muZ,'og')
    hold off
    
    %- Fit
    subplot(3,3,2)
    imshow(img_fit_MIP_xy,[img_min img_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Y-1)]*pixel_size.xy)
    title('FIT - XY')
    hold on
    plot(result.muX, result.muY,'og')
    hold off
    
    subplot(3,3,5)
    imshow(img_fit_MIP_xz',[img_min img_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Z-1)]*pixel_size.z)
    title('FIT - XZ')
    hold on
    plot(result.muX, result.muZ,'og')
    hold off
    
    subplot(3,3,8)
    imshow(img_fit_MIP_yz',[img_min img_max],'XData',[0 (dim_sub.Y-1)]*pixel_size.xy,'YData',[0 (dim_sub.Z-1)]*pixel_size.z)
    title('FIT - YZ')
    hold on
    plot(result.muY, result.muZ,'og')
    hold off
    
    %- Residuals
    subplot(3,3,3)
    imshow(resid_MIP_xy,[res_min res_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Y-1)]*pixel_size.xy)
    title('RESID - XY')
    colorbar
    subplot(3,3,6)
    imshow(resid_MIP_xz',[res_min res_max],'XData',[0 (dim_sub.X-1)]*pixel_size.xy,'YData',[0 (dim_sub.Z-1)]*pixel_size.z)
    title('RESID - XZ')

    subplot(3,3,9)
    imshow(resid_MIP_yz',[res_min res_max],'XData',[0 (dim_sub.Y-1)]*pixel_size.xy,'YData',[0 (dim_sub.Z-1)]*pixel_size.z)
    title('RESID - YZ')
    colormap hot

end
