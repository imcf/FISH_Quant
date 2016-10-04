function [F] = fun_Gaussian_2D_double_integral_v1(x,y,par_mod)
% 3D-Gaussian - implementation for numeric intergration
%
%
%  SEE triplequad for more information: triplequad(fun,xmin,xmax,ymin,ymax,zmin,zmax)
%   triplequad(fun,xmin,xmax,ymin,ymax,zmin,zmax) evaluates the triple 
%   integral fun(x,y,z) over the three dimensional rectangular region 
%   xmin <= x <= xmax, ymin <= y <= ymax, zmin <= z <= zmax. 
%   fun is a function handle. fun(x,y,z) must accept a vector x and 
%   scalars y and z, and return a vector of values of the integrand
%

%- All parameters
sigma_X = par_mod(1);
sigma_Y = par_mod(2);

mu_X    = par_mod(3);
mu_Y    = par_mod(4);

psf_amp = par_mod(5);
psf_bgd = par_mod(6);

%- Calculate function
F = psf_amp * (  erf2(x.min,x.max,mu_X,sigma_X) .* ...
                 erf2(y.min,y.max,mu_Y,sigma_Y) ) / ... 
                 1 + psf_bgd;           
            
         