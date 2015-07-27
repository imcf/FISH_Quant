function results = PSF_place_image_v5(data_images,parameters)


%== PARAMETERS
flags       = parameters.flags;
mRNA_prop   = parameters.mRNA_prop;
index_table = parameters.index_table;


%== Image data
img_TS_lin  = data_images.img_TS_lin;
dim_TS      = data_images.dim_TS;
coord       = data_images.coord;
img_PSF_all = data_images.img_PSF;
img_Fit_lin = data_images.img_Fit_lin;


%== Generate position matrix based on intensity values
if flags.posWeight

    %- Generate vector with ssr
    res_lin           = img_TS_lin-img_Fit_lin;          
    img_pos_weight    = (res_lin).^flags.posWeight;      

    % Set weight vector to zero where reconstruction is already brighter than image
    img_pos_weight    = img_pos_weight.*(res_lin>0); 
    img_pos_weight_cs = cumsum(img_pos_weight);
    weight_max        = img_pos_weight_cs(end);   
end


%=== Determine position where PSF will be placed

%-- Linear index
if  flags.placement == 1

    %- Generate random number
    rand_aux = rand(1)*weight_max;

    %- Find corresponding index to this random number
    ind_rand = find(img_pos_weight_cs < rand_aux,1,'last'); 

    %- Catch rare case that number is too small
    if isempty(ind_rand)
        ind_rand = 1;
    end

elseif  flags.placement == 2
    [max_int ind_rand] = max(img_pos_weight);
end

if isempty(ind_rand)
    ind_rand=1;

end

%-- Find corresponding coordinates
ind.y = index_table(ind_rand,1);
ind.x = index_table(ind_rand,2);
ind.z = index_table(ind_rand,3);

center.x_nm = coord.X_nm(ind.x);
center.y_nm = coord.Y_nm(ind.y);
center.z_nm = coord.Z_nm(ind.z);


%% === Calculate PSF 
%- Determine scaling factor for PSF
amp_loop = pearsrnd(mRNA_prop.amp_mean,mRNA_prop.amp_sigma,mRNA_prop.amp_skew,mRNA_prop.amp_kurt,1,1);
        
%- From model
if flags.psf == 1
    aux_x = exp((1/2) * ( - ( X_nm - center.x_nm).^2/(mRNA_prop.sigma_xy^2)));
    aux_y = exp((1/2) * ( - ( Y_nm - center.y_nm).^2/(mRNA_prop.sigma_xy^2)));
    aux_z = exp((1/2) * ( - ( Z_nm - center.z_nm).^2/(mRNA_prop.sigma_z^2)));

    aux_xy  = aux_y * aux_x';   
    aux_xy3d = repmat(aux_xy,[1 1 nZ]);

    aux_zz       = reshape(aux_z,1,1,length(aux_z));
    aux_z3d      = repmat(aux_zz,[ nY nX 1]);          
    psf_loop     = aux_xy3d .* aux_z3d;   

    factor_scale = amp_loop/img_PSF_all(1).PSF_fit_detect.amp;    
    
    psf_new      = factor_scale*psf_loop; 

    %== Add image of PSF to reconstruction and calculate residuals 
    img_Fit_loop_lin  = img_Fit_lin + psf_new(:);


    %== Different quality scores
    resid  = img_TS_lin-img_Fit_loop_lin;    
    if     flags.quality == 1
        Q_It  = sum(resid.^2);  
        Q_img = resid.^2;

    elseif flags.quality == 2
        Q_It = sum(abs(resid));
        Q_img = abs(resid);
    end
    
    
    %- Save parameters
    Q_min                            = Q_It; 
    summary_loop(1).img_Fit_loop_lin = img_Fit_loop_lin;
    summary_loop(1).psf_new          = psf_new;
    summary_loop(1).Q_img_lin        = Q_img;
    summary_loop(1).amp_loop         = amp_loop;
    summary_loop(1).factor_scale     = factor_scale;     
    
    
%- From image
elseif flags.psf == 2

    if flags.shift
        N_PSF = size(img_PSF_all,1)*size(img_PSF_all,2);
    else
        N_PSF = 1;
    end
    
    for i_PSF = 1:N_PSF
    
        img_PSF = img_PSF_all(i_PSF);

        %== Shift PSF accordingly
        
        %- Calculate relative shift between image of PSF and image of TS
        %  and extract relevant part of PSF image
        Y0 = img_PSF.max.Y_pad - dim_TS.Y + 1;
        dY = dim_TS.Y - ind.y;

        X0 = img_PSF.max.X_pad - dim_TS.X + 1;
        dX = dim_TS.X - ind.x;

        Z0 = img_PSF.max.Z_pad - dim_TS.Z + 1;
        dZ = dim_TS.Z - ind.z;    


        %- Calc offset for X
        xmin.PSF = X0+dX;
        xmax.PSF = xmin.PSF+dim_TS.X-1;

        xmin.Rec  = 1;
        xmax.Rec  = dim_TS.X;


        %- Calc offset for Y        
        ymin.PSF = Y0+dY;
        ymax.PSF = ymin.PSF+dim_TS.Y-1;

        ymin.Rec  = 1;
        ymax.Rec  = dim_TS.Y;

        %- Calc offset for Z 

        zmin.PSF = Z0+dZ;
        zmax.PSF = zmin.PSF+dim_TS.Z-1;        

        zmin.Rec  = 1;
        zmax.Rec  = dim_TS.Z;

        %- Assign corresponding PSF
        psf_loop = zeros(dim_TS.Y,dim_TS.X,dim_TS.Z);
        psf_loop(ymin.Rec:ymax.Rec,xmin.Rec:xmax.Rec,zmin.Rec:zmax.Rec) = ...
            img_PSF.pad(ymin.PSF:ymax.PSF,xmin.PSF:xmax.PSF,zmin.PSF:zmax.PSF);  

        factor_scale = amp_loop/img_PSF.PSF_fit_detect.amp;
        
        %factor_scale = amp_loop/img_PSF.PSF_fit.amp;
        psf_new      = factor_scale*psf_loop; 
                    
        %== Add image of PSF to reconstruction and calculate residuals 
        img_Fit_loop_lin  = img_Fit_lin + psf_new(:);


        %== Different quality scores
        resid  = img_TS_lin-img_Fit_loop_lin;
        
        %- Squared SR
        if     flags.quality == 1
            Q_It  = sum(resid.^2);  
            Q_img = resid.^2;
            
        %- Absolute SR
        elseif flags.quality == 2
            Q_It = sum(abs(resid));
            Q_img = abs(resid);
        end
       

        %- Save parameters
        Q_all(i_PSF,1)                       = Q_It; 
        summary_loop(i_PSF).img_Fit_loop_lin = img_Fit_loop_lin;
        summary_loop(i_PSF).psf_new          = psf_new;
        summary_loop(i_PSF).Q_img_lin        = Q_img;
        summary_loop(i_PSF).amp_loop         = amp_loop;
        summary_loop(i_PSF).factor_scale     = factor_scale;
        summary_loop(i_PSF).fit_amp          = img_PSF.PSF_fit_OS.amp;
        summary_loop(i_PSF).int_max_psf      = max(psf_loop(:));
    end
    
   %- Find minimum 
   [Q_min ind_min] = min(Q_all);
   ind_min         = ind_min(1);      
   par_shift_best  = img_PSF_all(ind_min).par_shift; % Was i_PSF but shouldn' it really be ind_min?
   
end


%=== Assign ouput
results.Q_min            = Q_min;
results.Q_min_ind        = ind_min;
results.img_Fit_lin      = summary_loop(ind_min).img_Fit_loop_lin;
results.psf_new          = summary_loop(ind_min).psf_new;
results.Q_img_lin        = summary_loop(ind_min).Q_img_lin;
results.amp_loop         = summary_loop(ind_min).amp_loop;
results.factor_scale     = summary_loop(ind_min).factor_scale;
results.fit_amp          = summary_loop(ind_min).fit_amp ;
results.int_max_psf      = summary_loop(ind_min).int_max_psf ;
results.par_shift        = par_shift_best;

results.center = center;
results.ind    = ind;






