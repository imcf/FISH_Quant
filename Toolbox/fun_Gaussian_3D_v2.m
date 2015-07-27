function [F] = fun_Gaussian_3D_v2(par_fit,par_mod)
% FUNCTION 3D-Gaussian
%
% function_flag == 1 .... all parameter are free (sigma_x,sigma_y, ...)
% function_flag == 2 .... all parameter are free but sigma_x = sigma_y
% function_flag == 3 .... Sigma's are fixed
%
% X0 - PARAMETERS DESCRIBING THE 3D GAUSSIAN
%
%  X0(1) ... Center in X (MuX)
%  X0(2) ... Center in Y (MuY)
%  X0(3) ... Center in Z (MuZ)
%  X0(4) ... Amplitude
%  X0(7) ... Background
%
% deltaX ... pixel-size in xy
% deltaZ ... pixel-size in z
%
% Version history
%
% v1 Feb 2011
% - Initial implementation
%
% v2 March 2, 2011
% - Additional flag added, parameters renamed and slighlty changed

flag_function = par_mod{1};
grid_data     = par_mod{2};
pixel_size    = par_mod{3};


if flag_function == 1
    sigma_X = par_fit(1);
    sigma_Y = par_fit(2);
    sigma_Z = par_fit(3);
    
    mu_X = par_fit(4);
    mu_Y = par_fit(5);
    mu_Z = par_fit(6);
    
    psf_amp = par_fit(7);
    psf_bgd = par_fit(8);
    
elseif flag_function == 2
    sigma_X = par_fit(1);
    sigma_Y = par_fit(1);
    sigma_Z = par_fit(2);
    
    mu_X = par_fit(3);
    mu_Y = par_fit(4);
    mu_Z = par_fit(5);
    
    psf_amp = par_fit(6);
    psf_bgd = par_fit(7);
    
elseif flag_function == 3
    sigma_X = par_mod{4};
    sigma_Y = par_mod{5};
    sigma_Z = par_mod{6};
    
    mu_X = par_fit(1);
    mu_Y = par_fit(2);
    mu_Z = par_fit(3);
    
    psf_amp = par_fit(4);
    psf_bgd = par_fit(5);
    
    
    
%- BGD is fixed parameters    
elseif flag_function == 4

    sigma_X = par_fit(1);
    sigma_Y = par_fit(1);
    sigma_Z = par_fit(2);
    
    mu_X = par_fit(3);
    mu_Y = par_fit(4);
    mu_Z = par_fit(5);
    
    psf_amp = par_fit(6);
    
    psf_bgd = par_mod{4};    
    
end


%- Extract vectors that are needed for computation
x = grid_data(1,:);
y = grid_data(2,:);
z = grid_data(3,:);


%- Calculate function
%  Division by the volume to get the average intensity for each voxel

F = psf_amp * ( ( erf2( x-pixel_size.xy/2, x+pixel_size.xy/2, mu_X, sigma_X ) .* ...
                  erf2( y-pixel_size.xy/2, y+pixel_size.xy/2, mu_Y, sigma_Y) .* ...
                  erf2( z-pixel_size.z/2,  z+pixel_size.z/2,  mu_Z,sigma_Z)) ) / ... 
                  (pixel_size.xy^2*pixel_size.z) + psf_bgd;



