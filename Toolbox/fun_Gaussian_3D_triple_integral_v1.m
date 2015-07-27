function [F] = fun_Gaussian_3D_triple_integral_v1(x,y,z,par_mod)
% 3D-Gaussian - implementation for numeric intergration

%- All parameters
sigma_X = par_mod(1);
sigma_Y = par_mod(2);
sigma_Z = par_mod(3);

mu_X    = par_mod(4);
mu_Y    = par_mod(5);
mu_Z    = par_mod(6);

psf_amp = par_mod(7);
psf_bgd = par_mod(8);

%- Volume
%V = (x.max-x.min)*(y.max-y.min)*(z.max-z.min);

%- Calculate function
F = psf_amp * ( ( erf2(x.min,x.max,mu_X,sigma_X) .* ...
                  erf2(y.min,y.max,mu_Y,sigma_Y) .* ...
                  erf2(z.min,z.max,mu_Z,sigma_Z)) ) / ...                   
                1 + psf_bgd;  
            
%- Divide by volume
%F = F/V;
            
         