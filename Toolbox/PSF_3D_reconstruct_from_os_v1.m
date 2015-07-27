function psf_rec = PSF_3D_reconstruct_from_os_v1(spot_os,range_rec,fact_os,flag_output)
%
% Function to reconstruct xyz PSF by down-sampling from over-sampled PSF


%% Some parameters
dim_rec.Y = length(range_rec.Y_nm);
dim_rec.X = length(range_rec.X_nm);
dim_rec.Z = length(range_rec.Z_nm);

psf_rec = zeros(dim_rec.Y,dim_rec.X,dim_rec.Z);

% Generate constructed PSF
for iY=1:dim_rec.Y 
   for iX=1:dim_rec.X
       for iZ=1:dim_rec.Z

           X.start  = (iX-1)*fact_os.xy + 1;
           X.end    = (iX)*fact_os.xy;
           Y.start  = (iY-1)*fact_os.xy+ 1;
           Y.end    = (iY)*fact_os.xy;
           Z.start  = (iZ-1)*fact_os.z + 1;
           Z.end    = (iZ)*fact_os.z;     
           
           try
                spot_sub          = spot_os(Y.start:Y.end,X.start:X.end,Z.start:Z.end);
                psf_rec(iY,iX,iZ) = mean(spot_sub(:));
           catch
               disp('PSF_3D_reconstruct_from_os_v1: array index too large');
           end
           
       end
   end
end


%% Show results
if flag_output
    spot_xy  = max(spot_os,[],3);                      
    spot_xz  = squeeze(max(spot_os,[],1));                          
    spot_yz  = squeeze(max(spot_os,[],2)); 
    
    img_PSF_xy  = max(psf_rec,[],3);                      
    img_PSF_xz  = squeeze(max(psf_rec,[],1));  
    img_PSF_yz  = squeeze(max(psf_rec,[],2)); 

    %- All projections
    figure(flag_output); set(gcf,'color','w')
    subplot(3,2,1)
    imshow(spot_xy ,[],'XData', [range_rec.X_nm(1) range_rec.X_nm(end)],'YData',[range_rec.Y_nm(1) range_rec.Y_nm(end)])
    title('Over-sampling - XY')

    subplot(3,2,3)
    imshow(spot_xz',[],'XData', [range_rec.X_nm(1) range_rec.X_nm(end)],'YData',[range_rec.Z_nm(1) range_rec.Z_nm(end)])
    title('Over-sampling - XZ')
    
    subplot(3,2,5)
    imshow(spot_yz',[],'XData', [range_rec.Y_nm(1) range_rec.Y_nm(end)],'YData',[range_rec.Z_nm(1) range_rec.Z_nm(end)])
    title('Over-sampling - YZ')
    
    subplot(3,2,2)
    imshow(img_PSF_xy ,[],'XData', [range_rec.X_nm(1) range_rec.X_nm(end)],'YData',[range_rec.Y_nm(1) range_rec.Y_nm(end)])
    title('Reconstructed - XY')

    subplot(3,2,4)
    imshow(img_PSF_xz',[],'XData', [range_rec.X_nm(1) range_rec.X_nm(end)],'YData',[range_rec.Z_nm(1) range_rec.Z_nm(end)])
    title('Reconstructed - XZ')
    
    subplot(3,2,6)
    imshow(img_PSF_yz',[],'XData', [range_rec.Y_nm(1) range_rec.Y_nm(end)],'YData',[range_rec.Z_nm(1) range_rec.Z_nm(end)])
    title('Reconstructed - YZ')
    colormap hot
end



