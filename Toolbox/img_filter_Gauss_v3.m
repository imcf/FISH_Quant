function img_filt = img_filter_Gauss_v3(image_struct,kernel_size,flag)


%== 1. Pad array with Matlab function padarray
filter.pad = ceil(3*kernel_size.bgd_xy);
img_pad    = double(padarray(image_struct.data,[filter.pad filter.pad filter.pad],'symmetric','both'));

%== 2. Background: apply Gaussian smoothing to images.
kernel_xy = kernel_size.bgd_xy;
kernel_z  = kernel_size.bgd_z;
    
if flag.output    
    disp(' ')
    disp('== Filtering [bgd] 1/2')
    disp(['Kernel-xy [pix]: ',  num2str(kernel_xy)])
    disp(['Kernel-z [pix]: ',  num2str(kernel_z)])
end
           
%- Filter unless kernel-size is 0
if kernel_xy
    img_bgd   = gaussSmooth(img_pad, [kernel_xy kernel_xy kernel_z], 'same');
else
    img_bgd = zeros(size(img_pad));
    
end

%- Background subtracted image
img_diff = img_pad-img_bgd;


%== 3. Convolution with the Theoretical gaussian Kernel
kernel_xy = kernel_size.psf_xy;
kernel_z  = kernel_size.psf_z;
    
if flag.output     
	disp('== Filtering [spot enhancement)')
    disp(['Kernel-xy [pix]: ',  num2str(kernel_xy)])
    disp(['Kernel-z [pix]: ',  num2str(kernel_z)])
end
    
%- Filter unless kernel-size is 0
if kernel_xy
        
    %- Filter image to enhance SNR    
    img_filt  = gaussSmooth( img_diff, [kernel_xy kernel_xy kernel_z], 'same');        
    img_filt  = img_filt.*(img_filt>0); 
else
    img_filt = img_diff;
end
       
img_filt = uint16(img_filt(filter.pad+1:end-filter.pad,filter.pad+1:end-filter.pad,filter.pad+1:end-filter.pad));


%- Show results of filtering
if flag.output
    h_fig = figure;
    set(h_fig,'Color','w')

    subplot(1,3,1)
    img_dum = img_bgd(filter.pad+1:end-filter.pad,filter.pad+1:end-filter.pad,filter.pad+1:end-filter.pad);
    imshow(max(img_dum,[],3),[])
    title(['Background. Kernel-xy: ', num2str(kernel_size.bgd_xy ), '; kernel-z: ', num2str(kernel_size.bgd_z )])
    colormap(hot), axis off
    
    subplot(1,3,2)
    img_dum = img_diff(filter.pad+1:end-filter.pad,filter.pad+1:end-filter.pad,filter.pad+1:end-filter.pad);
    imshow(max(img_dum,[],3),[])
    title('Background subtracted')
    colormap(hot), axis off
    
    subplot(1,3,3)
    imshow(max(img_filt,[],3),[])
    title(['Enhanced image. Kernel-xy: ', num2str(kernel_size.psf_xy), '; kernel-z: ', num2str(kernel_size.psf_z )])
    colormap(hot), axis off
end