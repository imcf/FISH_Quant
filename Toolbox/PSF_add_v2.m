function [img_SIM, mRNA_intensity ] = PSF_add_v2(image,pos,param )

%% Extract the parameters
nPSF           = size(pos,1);

%- Get PSF and analyse it
PSF            = param.PSF;
sizePSF        = size(PSF);
max_PSF        = double(max(PSF(:)));
psf_x          = floor(size(PSF,1)/2)+1;
psf_y          = floor(size(PSF,2)/2)+1;
psf_z          = floor(size(PSF,3)/2)+1;
position_cor   = pos + repmat([psf_x psf_y psf_z],size(pos,1),1);


%% Extend the image support
img_support = padarray(image,[psf_y psf_x psf_z]);
img_zeros   = uint16(zeros(size(img_support)));

%% Normalize PSF
PSF_norm = double(PSF)./max_PSF;

%% Generate the normalisation number 
amp = param.amp;
mRNA_intensity = pearsrnd(amp.mu, amp.sigma,amp.skew,amp.kurt,nPSF,1);

    
%% Generate the image    
   
for i_PSF = 1:nPSF

    %- Renormalize PSF
    PSF_temp = uint16(PSF_norm.*mRNA_intensity(i_PSF)) ; 

    X = position_cor(i_PSF,1);
    Y = position_cor(i_PSF,2);
    Z = position_cor(i_PSF,3);

    %-- FASTER VERSION to place mRNAs
    x_range = X - (round(sizePSF(1)/2)-1) : X + (round(sizePSF(1)/2)-1);
    y_range = Y - (round(sizePSF(2)/2)-1) : Y + (round(sizePSF(2)/2)-1);
    z_range = Z - (round(sizePSF(3)/2)-1) : Z + (round(sizePSF(3)/2)-1);
      
    img_support( x_range,y_range,z_range) = img_support( x_range,y_range,z_range) + PSF_temp;
     
end
       
%- Remove padding          
ind_x1 = psf_x+1;
ind_x2 = psf_x+size(image,1);
ind_y1 = psf_y+1;
ind_y2 = psf_y+size(image,2);
ind_z1 = psf_z+1;
ind_z2 = psf_z+size(image,3);

img_SIM = img_support(ind_x1:ind_x2, ind_y1:ind_y2, ind_z1:ind_z2);
        
        
        