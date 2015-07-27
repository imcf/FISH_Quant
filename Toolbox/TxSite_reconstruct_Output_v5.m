function  TxSite_reconstruct_Output_v5(TxSite_quant, REC_prop, parameters)


%- Get parameters
flags       = parameters.flags;
%factor_Q_ok = parameters.factor_Q_ok;
psname      = parameters.file_name_save_PLOTS_PS;

%- Images
img_res         = REC_prop.img_res;
img_fit         = REC_prop.img_fit;
img_TS_crop_xyz = REC_prop.img_TS;
img_bgd         = REC_prop.img_bgd;
coord           = REC_prop.coord;

%- Save properties of reconstruction
summary_Q_run_N_MRNA = REC_prop.summary_Q_run_N_MRNA;
summary_Q_run        = REC_prop.summary_Q_run;
mean_Q               = REC_prop.mean_Q;


if flags.output

    %=== Display results
    disp('  ')
    disp('  ')
    disp('==== SUMMARY OF TxSITE QUANTIFICATION ====')
    disp('  ')
    disp(['All REC: mean +/- stdev     : ' , num2str(TxSite_quant.N_mRNA_TS_mean_all), ' +/- ', num2str(TxSite_quant.N_mRNA_TS_std_all)]);  
    disp(['Best 10% of REC: mean +/- stdev     : ' , num2str(TxSite_quant.N_mRNA_TS_mean_10per), ' +/- ',num2str(TxSite_quant.N_mRNA_TS_std_10per)]);
    disp(' ')
    disp(['Number of mRNA at TS (ratio integrated INT): ' , num2str(TxSite_quant.N_mRNA_integrated_int)]);
    disp(['Number of mRNA at TS (sum of pixel)        : ' , num2str(TxSite_quant.N_mRNA_sum_pix)]); 
    disp(['Number of mRNA at TS (ratio max. int. )    : ' , num2str(TxSite_quant.N_mRNA_trad)]);   
    disp(['Number of mRNA at TS (ratio fitted AMP)    : ' , num2str(TxSite_quant.N_mRNA_fitted_amp)]);     
    
    disp(' ')
    disp('AVERAGED SIZE OF TRANSCRITPION SITE ')
    disp(['All mRNA                 : ', num2str(REC_prop.TS_size_all_mean,'%10.0f'),   ' +/- ',num2str(REC_prop.TS_size_all_std,'%10.0f') ,' nm'])
    disp(['mRNA within max distance : ', num2str(REC_prop.TS_dist_all_IN_mean,'%10.0f'),' +/- ',num2str(REC_prop.TS_dist_all_IN_std,'%10.0f') ,' nm'])
end 
    

if flags.output == 2 || not(isempty(psname))
   
    %- The initial checks to avoid plotting the results when only the
    % simplified methods were used. 
      
    %=== Show residuals
    if summary_Q_run ~= 0
    
        h1 = figure;
        subplot(2,1,1)
        plot(summary_Q_run_N_MRNA,summary_Q_run)
        xlabel('Number of placed mRNA')
        ylabel('Quality score')    

        subplot(2,1,2)
        plot(summary_Q_run_N_MRNA,mean_Q)
        xlabel('Number of placed mRNA')
        ylabel('Quality score') 

        if not(isempty(psname))
           print (h1,'-dpsc', psname, '-append');
           close(h1)   
        end
    end
    
    if img_TS_crop_xyz ~= 0
        
        
        %=== Plot histogram of residuals
        img_diff_bgd = img_TS_crop_xyz-img_bgd;
        img_diff_fit = img_TS_crop_xyz-img_fit;

        h1 = figure; 
        subplot(2,1,1)
        hist(img_diff_bgd(:),200)
        title(['Resid with only bgd subtraction: ', num2str(round(sum((img_diff_bgd(:)))))])

        subplot(2,1,2)
        hist(img_diff_fit(:),200)
        title(['Resid with FIT: ', num2str(round(sum((img_diff_fit(:)))))])


        if not(isempty(psname))
           print (h1,'-dpsc', psname, '-append');
           close(h1)   
        end
    
        % === Images of TxSite, reconstruction, and residuals

        %- Prepare plots
        img_proj_max_xy  = max(img_TS_crop_xyz,[],3);
        img_proj_max_yz  = squeeze(max(img_TS_crop_xyz,[],2))';  
        img_proj_max_xz  = squeeze(max(img_TS_crop_xyz,[],1))';


        img_fit_proj_max_xy  = max(img_fit,[],3);
        img_fit_proj_max_yz  = squeeze(max(img_fit,[],2))';  
        img_fit_proj_max_xz  = squeeze(max(img_fit,[],1))';

        res_proj_max_xy  = max(img_res,[],3);
        res_proj_max_yz  = squeeze(max(img_res,[],2))';  
        res_proj_max_xz  = squeeze(max(img_res,[],1))';

        img_res_neg = abs(img_res .* (img_res<0));

        res_neg_proj_max_xy  = max(img_res_neg,[],3);
        res_neg_proj_max_yz  = squeeze(max(img_res_neg,[],2))';  
        res_neg_proj_max_xz  = squeeze(max(img_res_neg,[],1))';

        % Min & max of image
        TS_max  = max(img_TS_crop_xyz(:));
        FIT_max = max(img_fit(:));

        if TS_max >= FIT_max
            img_max = TS_max;
        else
            img_max = FIT_max;
        end


        TS_min  = min(img_TS_crop_xyz(:));
        FIT_min = min(img_fit(:));

        if TS_min <= FIT_min
            img_min = TS_min;
        else
            img_min = FIT_min;
        end

        %-- Plot images
        h1 = figure;    

        %- TxSite    
        subplot(3,5,1)
        imshow(img_proj_max_xy,[img_min img_max],'XData',coord.X_nm,'YData',coord.Y_nm)
        title('TS - XY')
        colorbar
        axis image

        subplot(3,5,6)
        imshow(img_proj_max_yz,[ img_min img_max],'XData',coord.Y_nm,'YData',coord.Z_nm);
        title('TS - YZ')
        colorbar
        axis image

        subplot(3,5,11)
        imshow(img_proj_max_xz,[ img_min img_max],'XData',coord.X_nm,'YData',coord.Z_nm);
        title('TS - XZ')
        colorbar
        axis image

        %- Fit
        subplot(3,5,2)
        hold on
        imshow(img_fit_proj_max_xy,[img_min img_max ],'XData',coord.X_nm,'YData',coord.Y_nm)
        plot(REC_prop.pos_best_IN(:,2),REC_prop.pos_best_IN(:,1),'g+','LineWidth',2)
        plot(REC_prop.pos_best_OUT(:,2),REC_prop.pos_best_OUT(:,1),'b+','LineWidth',2)
        hold off
        title('Fit - XY')
        colorbar
        axis image

        subplot(3,5,7)
        hold on
        imshow(img_fit_proj_max_yz,[ img_min img_max],'XData',coord.X_nm,'YData',coord.Z_nm);
        plot(REC_prop.pos_best_IN(:,1),REC_prop.pos_best_IN(:,3),'g+','LineWidth',2)
        plot(REC_prop.pos_best_OUT(:,1),REC_prop.pos_best_OUT(:,3),'b+','LineWidth',2)
        hold off
        title('Fit - YZ')
        colorbar
        axis image

        subplot(3,5,12)
        hold on
        imshow(img_fit_proj_max_xz,[ img_min img_max],'XData',coord.X_nm,'YData',coord.Z_nm);
        plot(REC_prop.pos_best_IN(:,2),REC_prop.pos_best_IN(:,3),'g+','LineWidth',2)
        plot(REC_prop.pos_best_OUT(:,2),REC_prop.pos_best_OUT(:,3),'b+','LineWidth',2)
        hold off
        title('Fit - XZ')
        colorbar
        axis image

        %- Residuals
        subplot(3,5,3)
        imshow(res_proj_max_xy,[ 0 1*img_max],'XData',coord.X_nm,'YData',coord.Y_nm)
        title('RES - XY')
        colorbar
        axis image

        subplot(3,5,8)
        imshow(res_proj_max_yz,[ 0 1*img_max],'XData',coord.Y_nm,'YData',coord.Z_nm);
        title('RES - YZ')
        colorbar
        axis image

        subplot(3,5,13)
        imshow(res_proj_max_xz,[ 0 1*img_max],'XData',coord.X_nm,'YData',coord.Z_nm);
        title('RES - XZ')
        colorbar
        axis image

        %- Residuals [POS]
        subplot(3,5,4)
        imshow(res_proj_max_xy,[ ],'XData',coord.X_nm,'YData',coord.Y_nm)
        title('RES [pos] - XY')
        colorbar
        axis image

        subplot(3,5,9)
        imshow(res_proj_max_yz,[ ],'XData',coord.Y_nm,'YData',coord.Z_nm);
        title('RES [pos] - YZ')
        colorbar
        axis image

        subplot(3,5,14)
        imshow(res_proj_max_xz,[ ],'XData',coord.X_nm,'YData',coord.Z_nm);
        title('RES [pos] - XZ')
        colorbar
        axis image

        %- Residuals [NEG]
        subplot(3,5,5)
        imshow(res_neg_proj_max_xy,[ ],'XData',coord.X_nm,'YData',coord.Y_nm)
        title('RES [neg] - XY')
        colorbar
        axis image

        subplot(3,5,10)
        imshow(res_neg_proj_max_yz,[ ],'XData',coord.Y_nm,'YData',coord.Z_nm);
        title('RES [neg] - YZ')
        colorbar
        axis image

        subplot(3,5,15)
        imshow(res_neg_proj_max_xz,[ ],'XData',coord.X_nm,'YData',coord.Z_nm);
        title('RES [neg] - XZ')
        colorbar
        axis image

        colormap Hot

        if not(isempty(psname))
           print (h1,'-dpsc', psname, '-append');
           close(h1)   
        end
    end
end