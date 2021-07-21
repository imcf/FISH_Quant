function [spots_fit, FIT_Result,thresh] = FQ_spots_fit_2D_v1(img,ind_cell)
% FUNCTION Fitt all detected spots to 3D Gaussian

%- Empty default output
spots_fit      = [];
FIT_Result     = {};
thresh         = {};

%- Get predected spots
spots_detected = img.cell_prop(ind_cell).spots_detected;
N_Spots        = size(spots_detected,1);
sub_spots      = img.cell_prop(ind_cell).sub_spots;
pixel_size     = img.par_microscope.pixel_size;

%-- Fitting limits sigmaxy - centerx - centery - amp - bgd
fit_limits = img.settings.fit.limits;
bound.lb   = [fit_limits.sigma_xy_min  -inf -inf  0   0  ]; 
bound.ub   = [fit_limits.sigma_xy_max  inf  inf   inf inf];

%- Parameters
options_fit.pixel_size = pixel_size;
options_fit.PSF_theo   = img.PSF_theo;
options_fit.par_start  = [];
options_fit.bound      = bound;
options_fit.fit_mode   = 'sigma_free_xz';
flag_struct.output     = 0;
N_spots_fit_max        = img.settings.fit.N_spots_fit_max;
    
%=== Prepare some of the parameters needed for fitting

%-- Dimension of default image
dim.X = img.settings.detect.reg_size.xy*2 +1;
dim.Y = img.settings.detect.reg_size.xy*2 +1;
N_pix = dim.X*dim.Y;

%- Generate vectors describing the image    
[Xs,Ys] = meshgrid(dim.Y:2*dim.Y-1,dim.X:2*dim.X-1);  % Pixel-grid has on offset from 0 to allow for negative values in center position

xdata(1,:) = double(reshape(Xs,1,N_pix))*pixel_size.xy;
xdata(2,:) = double(reshape(Ys,1,N_pix))*pixel_size.xy;

%== Options for fitting routine
%- Starting points for sigma
options_fit.par_start.sigmax = img.PSF_theo.xy_nm; 
options_fit.par_start.sigmay = img.PSF_theo.xy_nm; 

options_fit.options = optimset('Jacobian','off','Display','off','MaxIter',100,'UseParallel','always');

%- Check if cell has more than the allowed number of spots
if (N_spots_fit_max < 0)  ||  (N_Spots < N_spots_fit_max) 

    if N_Spots
        
        %- Fit all thresholded spots
        fprintf('\n= Fit detected spots with 2D Gaussian\n');
        disp(['N spots = ' num2str(N_Spots)]);

        parfor k = 1:N_Spots
            FIT_Result{k} = spot_2D_fit_v1(sub_spots{k},xdata,options_fit,flag_struct);
        end

        %- Summarize result of all fits
        %  Column 1-7 are from spot detection, rest of the columns are from fitting
        for k=1:N_Spots  

            shift_y =  spots_detected(k,4);
            shift_x =  spots_detected(k,6);
            shift_z =  spots_detected(k,8);        

            spots_fit(k,:) =  [FIT_Result{k}.muY + (shift_y-1) * pixel_size.xy, ...
                               FIT_Result{k}.muX + (shift_x-1) * pixel_size.xy, ...
                               -1, ...
                               FIT_Result{k}.amp        FIT_Result{k}.bgd       FIT_Result{k}.resnorm , ...   
                               FIT_Result{k}.sigmaX     FIT_Result{k}.sigmaY    FIT_Result{k}.sigmaZ  , ...
                               FIT_Result{k}.centroidY  FIT_Result{k}.centroidX FIT_Result{k}.centroidZ  , ... 
                               FIT_Result{k}.muY        FIT_Result{k}.muX       FIT_Result{k}.muZ , ...
                               FIT_Result{k}.output.iterations];
        end
    end
    
else
    
	spots_fit = zeros(N_Spots,16);
    spots_fit(:,:) = NaN;
    
	spots_fit(:,1:2) = (spots_detected(:,1:2) * pixel_size.xy) - pixel_size.xy;   % Fitted distances start at 0 nm.
	spots_fit(:,3)   = -1 ;

    spots_fit(:,13) = ((spots_detected(:,5) - spots_detected(:,4)) / 2)   * pixel_size.xy;
    spots_fit(:,14) = ((spots_detected(:,7) - spots_detected(:,6)) / 2)   * pixel_size.xy;
    spots_fit(:,15) = -1;
    
    
	FIT_Result  = {};         
    
end


%- Thresholding status
thresh.all  = ones(N_Spots,1);
thresh.in   = ones(N_Spots,1);