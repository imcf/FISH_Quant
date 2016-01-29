function img = FQ_calc_intint_v1(img)


%% Integration range - region used for detection / fit

range_int.x_int.min =  - img.settings.detect.reg_size.xy * img.par_microscope.pixel_size.xy; 
range_int.x_int.max =  + img.settings.detect.reg_size.xy * img.par_microscope.pixel_size.xy;

range_int.y_int.min =  range_int.x_int.min ;
range_int.y_int.max =  range_int.x_int.max;

range_int.z_int.min =  - img.settings.detect.reg_size.z * img.par_microscope.pixel_size.z;
range_int.z_int.max =  + img.settings.detect.reg_size.z * img.par_microscope.pixel_size.z;

x_int = range_int.x_int;
y_int = range_int.y_int;
z_int = range_int.z_int;

%- Constant parameters for integrated intensity
par_mod_int(4)  = 0;
par_mod_int(5)  = 0;
par_mod_int(6)  = 0;        
par_mod_int(8)  = 0 ;

par_fit.x_int = x_int;
par_fit.y_int = y_int;
par_fit.z_int = z_int;
par_fit.col_par = img.col_par;

%% Loop over all cells
N_cell = length(img.cell_prop);

%- Loop over cells
for i_cell=1:N_cell

    %- Calculate integrated intensity
    [img.cell_prop(i_cell).intint] = calc_intint(img.cell_prop(i_cell),par_mod_int,par_fit);
end


 
%% Actual function that calculates the features

function [intint]= calc_intint(cell_prop,par_mod_int,par_fit)


intint = [];
%====  Get estimates from Gaussian fit

%- Loop over all spots
for i_spot = 1:size(cell_prop.spots_detected,1)

    %= Integrated intensity of mRNA 
    par_mod_int(1)  = cell_prop.spots_fit(i_spot,par_fit.col_par.sigmax); % SIGMA-XY
    par_mod_int(2)  = cell_prop.spots_fit(i_spot,par_fit.col_par.sigmax); % SIGMA-XY
    par_mod_int(3)  = cell_prop.spots_fit(i_spot,par_fit.col_par.sigmaz); % SIGMA-Z
    par_mod_int(7)  = cell_prop.spots_fit(i_spot,par_fit.col_par.amp); % AMP
    intint(i_spot)  = fun_Gaussian_3D_triple_integral_v1(par_fit.x_int,par_fit.y_int,par_fit.z_int,par_mod_int) / 10^9;
end


