function [img_os_shift range_os dim_os] = PSF_3D_os_shift_v1(img_os,fact_os,pixel_size,par_shift)

%= Function to move image around and rescale it.

if isempty(par_shift)

    prompt(1) = {'Shift of center in X [+/- subpixels]'};
    prompt(2) = {'Shift of center in Y [+/- subpixels]'};
    prompt(3) = {'Shift of center in Z [+/- subpixels]'};

    defaultValue{1} = num2str(0);
    defaultValue{2} = num2str(0);
    defaultValue{3} = num2str(0);
    
    par_shift = inputdlg(prompt,dlgTitle,1,defaultValue);
    
    par_shift{1} =  str2double(par_shift{1});
    par_shift{2} =  str2double(par_shift{2});
    par_shift{3} =  str2double(par_shift{3});
end

if( ~ isempty(par_shift))
        
    
    % ==== Shift image according to defined shifts. 
    shift.x = par_shift{1};
    shift.y = par_shift{2};
    shift.z = par_shift{3}; 
        
    %- Correct if shifts are larger than one sub-pixel-resolution
    shift.x = rem(shift.x,fact_os.xy);
    shift.y = rem(shift.y,fact_os.xy);
    shift.z = rem(shift.z,fact_os.z);    
    
    %- Padding to allow movement
    pad_x = fact_os.xy;
    pad_y = fact_os.xy;
    pad_z = fact_os.z;
    
    img_os_pad   = padarray(img_os,[pad_y pad_x pad_z]); 
    
    img_os_shift = img_os_pad(fact_os.xy+1-shift.y : end-fact_os.xy-shift.y, ...
                              fact_os.xy+1-shift.x : end-fact_os.xy-shift.x,...
                              fact_os.z+1-shift.z  : end-fact_os.z-shift.z);      
    
       
    
    [dim_os.Y dim_os.X dim_os.Z] = size(img_os_shift);
    
    range_os.X_nm = (1:dim_os.X)*pixel_size.xy;
    range_os.Y_nm = (1:dim_os.Y)*pixel_size.xy;
    range_os.Z_nm = (1:dim_os.Z)*pixel_size.z;    
 

end