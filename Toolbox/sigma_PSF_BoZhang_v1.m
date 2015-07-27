function [sigma_xy,sigma_z] = sigma_PSF_BoZhang_v1(par_microscope)
% Compute the sigmas of the bi-Gaussian approximation of the PSF
% Using equations of Bo Zhang et al., Gaussian approximations of 
% fluorescence microscope point-spread function models (SPIE 2006)


% lambda_em = emission wavelength
% lambda_ex = excitation wavelength
% NA = numerical aperture of the objective lens
% n = refractive index of the sample medium
% microscope = string that determines microscope type: 'widefield',
% 'confocal' or 'nipkow'
%
% Ch. Zimmer


%- Extract relevant parameters
lambda_em  = par_microscope.Em;
lambda_ex  = par_microscope.Ex;
NA         = par_microscope.NA;
RI         = par_microscope.RI;
microscope = par_microscope.type;


if isempty(lambda_ex)
    lambda_ex = lambda_em;
end

switch microscope
    case 'widefield'    % Widefield Microscope
        sigma_xy = 0.225 * lambda_em / NA ;
        sigma_z  = 0.78 * RI * lambda_em / (NA*NA) ;

    case {'confocal', 'nipkow'}   % Laser Scanning Confocal Microscope and Spinning Disc Confocal Microscope
        sigma_xy = 0.225 / NA * lambda_ex * lambda_em / sqrt( lambda_ex^2 + lambda_em^2 ) ;
        sigma_z =  0.78 * RI / (NA^2) *  lambda_ex * lambda_em / sqrt( lambda_ex^2 + lambda_em^2 ) ;

    otherwise
        error(['microscope = ',microscope,' is not a valid option !']);
end

