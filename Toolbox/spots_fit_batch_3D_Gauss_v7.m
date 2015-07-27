function [spots_fit, FIT_Result] = spots_fit_batch_3D_Gauss_v7(spots_detected,sub_spots,parameters)
% FUNCTION Fitt all detected spots to 3D Gaussian
%
%
% v1 Feb 28, 2011
%  - Initial implementation
%
% v2 Feb 28, 2011
%  - New input parameter for starting guess
%
% v3 March new implementation for big property file for spot detection
%
% v4 April 14, 2010
% - Move open and close Matlabpool for parrallel computing out of function. This way
%   pool will only be openend once when called in a loop - saves time!
%
% v5  May, 2010
% - Consider case with no detected spots

%- Index of thresholded spots
N_Spots            = size(spots_detected,1);
spots_fit          = [];
FIT_Result         = {};

%- Parameters
pixel_size  = parameters.pixel_size;
PSF_theo    = parameters.PSF_theo;
par_start   = parameters.par_start;
flag_struct = parameters.flag_struct;
mode_fit    = parameters.mode_fit;
bound       = parameters.bound;

%- Parameters
options_fit.pixel_size = pixel_size;
options_fit.PSF_theo   = PSF_theo;
options_fit.par_start  = par_start;
options_fit.fit_mode   = mode_fit;
options_fit.bound      = bound;

flag_struct.output = 0;

if N_Spots
    %- Fit all thresholded spots
    disp('Fit detected spots with 3D Gaussian...');
    disp(['N spots = ' num2str(N_Spots)]);

    if (flag_struct.parallel)
        parfor k = 1:N_Spots
            FIT_Result{k} = psf_fit_3d_v7(sub_spots{k},[],options_fit,flag_struct);
        end

    else
        for k=1:N_Spots
            if (round(k/10) == k/100)
                disp('...');
                disp(['Progress: ', num2str(k*100/N_Spots), '%'])
            end

            FIT_Result{k} = psf_fit_3d_v7(sub_spots{k},[],options_fit,flag_struct);
            

        end
    end



    %- Summarize result of all fits
    %  Column 1-7 are from spot detection, rest of the columns are from fitting
    for k=1:N_Spots  
                
        shift_y =  spots_detected(k,4);
        shift_x =  spots_detected(k,6);
        shift_z =  spots_detected(k,8);        
        
        spots_fit(k,:) =  [FIT_Result{k}.muY + (shift_y-1) * pixel_size.xy, ...
                           FIT_Result{k}.muX + (shift_x-1) * pixel_size.xy, ...
                           FIT_Result{k}.muZ + (shift_z-1) * pixel_size.z, ...
                           FIT_Result{k}.amp        FIT_Result{k}.bgd       FIT_Result{k}.resnorm , ...   
                           FIT_Result{k}.sigmaX     FIT_Result{k}.sigmaY    FIT_Result{k}.sigmaZ  , ...
                           FIT_Result{k}.centroidY  FIT_Result{k}.centroidX FIT_Result{k}.centroidZ  , ... 
                           FIT_Result{k}.muY        FIT_Result{k}.muX       FIT_Result{k}.muZ , ...
                           FIT_Result{k}.output.iterations];
    end

    %spots_detected_new = [spots_detected,spots_fit] ;
end