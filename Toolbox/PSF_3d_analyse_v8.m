function [img_PSF_struct, PSF_fit, file_name_full] = PSF_3d_analyse_v8(file_name_full, parameters)
% Analyze PSF in 3D. Involves background subtraction, cropping, and fit
% with Gaussian function.


%== Parameters
pixel_size     = parameters.pixel_size;
par_microscope = parameters.par_microscope;
flags          = parameters.flags;
par_crop_quant = parameters.par_crop_quant;
par_crop_detect = parameters.par_crop_detect;
PSF_BGD        = parameters.PSF_BGD;


%== Get file-name if not defined
if isempty(file_name_full) || not(exist(file_name_full))
    [file_name_PSF,path_name_PSF] = uigetfile('.tif','Select averaged image of mRNA.','MultiSelect','off');
    file_name_full = fullfile(path_name_PSF,file_name_PSF);
else
    file_name_PSF = 1;
end

%== Read-in if specified
if file_name_PSF ~= 0
    
    %=== Read in file 
    img_PSF_struct = load_stack_data_v7(file_name_full);
    
    %=== Background subtraction    
    
    %- Scalar (can also be zero)    
    if  size(PSF_BGD,1)*size(PSF_BGD,2) == 1

        img_PSF_dum = double(img_PSF_struct.data) - PSF_BGD;

    %- Matrix (can also be zero)     
    elseif size(PSF_BGD,1) == size(img_PSF_struct.data,1)  && size(PSF_BGD,2) == size(img_PSF_struct.data,2)  && size(PSF_BGD,3) == size(img_PSF_struct.data,3)  

        img_PSF_dum = img_PSF_struct.data;

        for i = 1:size(img_PSF_struct.data,3)
           bgd_slice = PSF_BGD(:,:,i);
           bgd_mean = mean( bgd_slice(:));

           img_PSF_dum(:,:,i) = img_PSF_dum(:,:,i) - bgd_mean;
        end
        
    else
        warndlg('Background of PSF in invalid format')
        img_PSF_dum= double(img_PSF_rec.data);    
    end
    
    %- Assign and set negative values to zero
    img_PSF_struct.data_w_bgd   = img_PSF_struct.data;
    img_PSF_struct.data         = img_PSF_dum;            % Used to be: img_PSF_dum .* (img_PSF_dum>0) but setting to zero gives bias  
   
    %== Fit with Gaussian
    disp('======== FIT OF LOADED PSF WITH 3D GAUSSIAN')
    
    parameters_fit.pixel_size      = pixel_size;
    parameters_fit.par_microscope  = par_microscope;
    parameters_fit.flags           = flags;
    parameters_fit.flags.output    = 2;
    img_PSF_fit      = img_PSF_struct;
    img_PSF_fit.data = img_PSF_struct.data_w_bgd;
    
    
         
    %-- [1] Same cropping as used for detection
    parameters_fit.flags.output    = 0;
    disp('=== Same cropping range as for mRNA detection [no BGD subtraction]')
    parameters_fit.par_crop        = par_crop_detect;
    PSF_fit_crop_mature            = PSF_3D_Gauss_fit_v8(img_PSF_fit,parameters_fit);
    
    
    %-- [1] Same cropping as used for TS quantification
    disp('=== Same cropping range as for TS quantification [no BGD subtraction]')
    parameters_fit.flags.output    = 2;
    parameters_fit.par_crop        = par_crop_quant;
 
    sigma_xy_min = 0.5 * PSF_fit_crop_mature.sigma_xy;
    sigma_xy_max = 1.5 * PSF_fit_crop_mature.sigma_xy;
    
    sigma_z_min = 0.5 * PSF_fit_crop_mature.sigma_z;
    simga_z_max = 1.5 * PSF_fit_crop_mature.sigma_z;
    
    bound.lb = [sigma_xy_min sigma_z_min 0   0   0   0   0]; 
    bound.ub = [sigma_xy_max simga_z_max inf inf inf inf inf];
    
    parameters_fit.bound= bound;
    PSF_fit                        = PSF_3D_Gauss_fit_v8(img_PSF_fit,parameters_fit);
    
    img_PSF_struct.PSF_fit.sigma_xy = PSF_fit.sigma_xy ;
    img_PSF_struct.PSF_fit.sigma_z  = PSF_fit.sigma_z;
    img_PSF_struct.PSF_fit.amp      = PSF_fit.amp;
    img_PSF_struct.PSF_fit.bgd      = PSF_fit.bgd; 

    
%     %-- [3] Same cropping as used for detection
%     disp('=== Same cropping range as for mRNA detection [BGD subtraction]')
%     parameters_fit.par_crop        = par_crop_detect;
%     PSF_3D_Gauss_fit_v8(img_PSF_struct,parameters_fit);
    
    
    %- Show output if specified
    if flags.output
    
        %- Data for plot
        img_PSF_xy = max(img_PSF_struct.data,[],3);
        img_PSF_xz = squeeze(max(img_PSF_struct.data,[],1));
        img_PSF_yz = squeeze(max(img_PSF_struct.data,[],2)); 

        [dim.Y dim.X dim.Z] = size(img_PSF_struct.data);

        %- PSF
        h_fig = figure;
        subplot(1,3,1)
        imshow(img_PSF_xy,[ ],'XData',[0 dim.X]*pixel_size.xy,'YData',[0 dim.Y]*pixel_size.xy)
        title('PSF - XY')

        subplot(1,3,2)
        imshow(img_PSF_xz',[ ],'XData',[0 dim.X]*pixel_size.xy,'YData',[0 dim.Z]*pixel_size.z)
        title('PSF - XZ')

        subplot(1,3,3)
        imshow(img_PSF_yz',[ ],'XData',[0 dim.Y]*pixel_size.xy,'YData',[0 dim.Z]*pixel_size.z)
        title('PSF - YZ')

        colormap hot
        
        set(h_fig,'Color','w')
    end
   
else
    img_PSF_struct = [];
    PSF_fit        = [];
end





