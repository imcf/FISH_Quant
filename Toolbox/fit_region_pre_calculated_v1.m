function [ FIT_RES ]  =  fit_region_pre_calculated_v1(fit_pos, xdata)

%- Get spacing
param            = xdata{4};
space_x          = param.spacing(1);
space_y          = param.spacing(2);
space_z          = param.spacing(3);
pixel_size       = param.pixel_size; 
 
%- Get positions of center coordiantes
mu_Y  = fit_pos(1:3:(length(fit_pos)-2));
mu_X  = fit_pos(2:3:(length(fit_pos)-1));
mu_Z  = fit_pos(3:3:length(fit_pos));


%- Loop over placed PSF
nPSF  = length(fit_pos)/3;
F     = zeros(length(xdata{5}),nPSF);
for i = 1:nPSF
    F(:,i) = param.amp .* (xdata{1}(2,round(abs(xdata{5}  - mu_Y(i))./space_y +1))  .*  ...
                          xdata{2}(2,round(abs(xdata{6}  - mu_X(i))./space_x +1))  .*  ...
                          xdata{3}(2,round(abs(xdata{7}  - mu_Z(i))./space_z +1))) ./  ...
                          (pixel_size.xy*pixel_size.xy*pixel_size.z);                     
end


%- Consider existing image
if isempty(xdata{15})
    FIT_RES  =  uint16(sum(F,2)); 
else
    FIT_RES  =  uint16(sum(F,2)) + xdata{15}; 
end






