function [TxSite_quant, REC_prop, TS_rec] = FQ_TS_analyze_results_v8(TS_rec,Q_all,TS_analysis, parameters)


%% Check if there are FQ results with the PSF superposition approach
if isempty(TS_rec)
    status_FQ = 0;
else
    status_FQ = 1;
end


%% Parameters
N_pix_sum       = parameters.N_pix_sum;
dist_max        = parameters.dist_max;

flags           = parameters.flags;
N_reconstruct   = parameters.N_reconstruct;
mRNA_prop       = parameters.mRNA_prop;
range_int       = parameters.range_int;
psname          = parameters.file_name_save_PLOTS_PS;

img_TS_crop_xyz = double(TS_analysis.img_TS_crop_xyz);

bgd_median      = TS_analysis.bgd_median;


%% ONLY IF PSF superposition approach was used

if status_FQ

    %=== Get data from quantification
    coord       = TS_analysis.coord;
    img_bgd     = TS_analysis.img_bgd;
    
    
    %=== Check which mRNA are within the specified distance
    for iRun = 1 : N_reconstruct 

        dist_3D = TS_rec(iRun).dist_3D_shift;

        %- Get indices of in and out spots
        ind_pos_IN   = find(dist_3D<dist_max);
        ind_pos_ALL  = (1:length(dist_3D));
        ind_pos_OUT  = setdiff(ind_pos_ALL,ind_pos_IN);

        %- Get the corresponding positions
        pos_ALL      = TS_rec(iRun).pos;
        pos_IN       = pos_ALL(ind_pos_IN,:);
        pos_OUT      = pos_ALL(ind_pos_OUT,:);

        %- Assign
        TS_rec(iRun).ind_pos_IN     = ind_pos_IN;
        TS_rec(iRun).ind_pos_OUT    = ind_pos_OUT;
        TS_rec(iRun).N_mRNA_pos_good = length(ind_pos_IN);

        TS_rec(iRun).pos_IN  = pos_IN;
        TS_rec(iRun).pos_OUT = pos_OUT;

        %- Save distance
        TS_size_all(iRun)    = mean(dist_3D);
        TS_dist_all_IN(iRun) = mean(dist_3D(ind_pos_IN));

    end

    TS_size_all_mean    = round(mean(TS_size_all));
    TS_size_all_std     = round(std(TS_size_all));
    TS_dist_all_IN_mean = round(mean(TS_dist_all_IN));
    TS_dist_all_IN_std  = round(std(TS_dist_all_IN));

    
    % ==== Analyse results
    Q_min_loop = zeros(N_reconstruct,2);

    for iRun = 1 : N_reconstruct     
        Q_min_loop(iRun,:)    = [TS_rec(iRun).N_mRNA_pos_good TS_rec(iRun).Q_min];      
        summary_Q_run(:,iRun) = Q_all(iRun).data(:,2);    
    end

    summary_Q_run_N_MRNA = Q_all(iRun).data(:,1);
    mean_Q               = mean(summary_Q_run,2);

    %- Extract best fit for each run and sort
    [Q_min_run_sorted ind_Q_min_sorted] = sortrows(Q_min_loop,2);

    %== Extract best fit for image
    ind_best          = ind_Q_min_sorted(1);
    img_fit           = double(TS_rec(ind_best).data);
    img_res           = img_TS_crop_xyz - img_fit;

    %== Estimate number of transcripts with different metrics

    %- Use over-all best fit 
    N_mRNA_TS_global = Q_min_run_sorted(1,1);
    Q_min_global     = Q_min_run_sorted(1,2);

    %- Determine average of best 10%
    N_avg                = round(0.1*size(Q_min_run_sorted,1));
    N_mRNA_TS_mean_10per = round(mean(Q_min_run_sorted(1:N_avg,1)));
    N_mRNA_TS_std_10per  = ceil(std(Q_min_run_sorted(1:N_avg,1)));
    Q_avg_10per          = mean(Q_min_run_sorted(1:N_avg,2));

    %- Determine average of all fits
    N_mRNA_TS_mean = round( mean(Q_min_loop(:,1)));
    N_mRNA_TS_std  = round(std(Q_min_loop(:,1)));
    Q_avg          = mean(Q_min_loop(:,2));
end


%% === QUANTIFY WITH OTHER METHODS


%====  Analyze TS: Sum of pixel intensity around center

[dim.Y dim.X dim.Z]         = size(img_TS_crop_xyz);
[TS_max_int TS_max_int_IND] = max(img_TS_crop_xyz(:));
[ind_Y ind_X ind_Z]         = ind2sub(size(img_TS_crop_xyz), TS_max_int_IND);

min_Y = ind_Y - N_pix_sum.xy;
min_X = ind_X - N_pix_sum.xy;
min_Z = ind_Z - N_pix_sum.z;

max_Y = ind_Y + N_pix_sum.xy;
max_X = ind_X + N_pix_sum.xy;
max_Z = ind_Z + N_pix_sum.z;

flag_OK = 1;

if min_Y < 1 || min_X < 1 || min_Z < 1 || ...
   max_Y > dim.Y || max_X > dim.X || max_Z > dim.Z 
    flag_OK  = 0;
end

if flag_OK
    TS_sub = img_TS_crop_xyz(min_Y:max_Y,min_X:max_X,min_Z:max_Z);
    TS_sum = sum(TS_sub(:));
else
    TS_sum = 0;
    TS_sub = [];
end

N_pix  = length(TS_sub(:));
TS_bgd =  N_pix*mRNA_prop.bgd_value;


%== Ratio of maximum intensity
max_TS      = max(img_TS_crop_xyz(:)) - bgd_median;
if isfield(mRNA_prop,'pix_brightest')
    N_mRNA_trad = round(max_TS/mRNA_prop.pix_brightest);
else
    N_mRNA_trad = 0;
end


%== Ratio of estimated amplitude
if isfield(mRNA_prop,'amp_mean_fit_QUANT')
    mRNA_amp = mRNA_prop.amp_mean_fit_QUANT;  
else
    mRNA_amp = mRNA_prop.amp_mean;  
end


%== Automated CHECK IF TxSite IS BACKGROUND
%   This can occur when sites are detected automatically, e.g. with LacI.
%   Here sites can be detected that actually don't have a signal. They
%   usually have a clear signature: low AMP, and high sigma's. Two different
%   criteria will be used
%   [1] ONLY SIZE: Both sigma's (TS) > 3 * sigma's  (mRNA)
%
%   [2] SIZE AND SHAPE: sigma-xy (TS) >  2*simga-xy (mRNA)  AND
%                       amp (TS)      <  2*amp (mRNA)     

crit_1 = TS_analysis.TS_Fit_Result.sigma_xy > 3*mRNA_prop.sigma_xy && ...
         TS_analysis.TS_Fit_Result.sigma_z  > 3*mRNA_prop.sigma_z;

crit_2 = TS_analysis.TS_Fit_Result.amp      < 2*mRNA_amp && ...
         TS_analysis.TS_Fit_Result.sigma_xy > 2*mRNA_prop.sigma_xy;
     
if  crit_1 || crit_2
    flag_TS_only_background = 1;
else
    flag_TS_only_background = 0; 
end
    
if ~flag_TS_only_background

    %== Ratio of amplitude
    N_mRNA_fitted_amp = (TS_analysis.TS_Fit_Result.amp / mRNA_amp);

    %=== Integrated intensity of mRNA
    
    
    %- Integration range
    x_int = range_int.x_int;
    y_int = range_int.y_int;
    z_int = range_int.z_int;
    
    
    %- 3D
    if z_int.max-z_int.min > 0
        par_mod_int(1)  = mRNA_prop.sigma_xy;
        par_mod_int(2)  = mRNA_prop.sigma_xy;
        par_mod_int(3)  = mRNA_prop.sigma_z;

        par_mod_int(4)  = 0;
        par_mod_int(5)  = 0;
        par_mod_int(6)  = 0;

        par_mod_int(7)  = mRNA_amp;
        par_mod_int(8)  = 0 ;
   
        integrated_int        = fun_Gaussian_3D_triple_integral_v1(x_int,y_int,z_int,par_mod_int);
    
    %- 2D
    else
        
        par_mod_int(1)  = mRNA_prop.sigma_xy;
        par_mod_int(2)  = mRNA_prop.sigma_xy;

        par_mod_int(3)  = 0;
        par_mod_int(4)  = 0;

        par_mod_int(5)  = mRNA_amp;
        par_mod_int(6)  = 0 ;
                
        integrated_int  = fun_Gaussian_2D_double_integral_v1(x_int,y_int,par_mod_int);
    end
    
    N_mRNA_integrated_int = (TS_analysis.TS_Fit_Result.integ_int / integrated_int);
    N_mRNA_sum_pix = ((TS_sum-TS_bgd)/mRNA_prop.sum_pix);

else
    disp('TxSite has signature of only background: quantifications set to 0')
    N_mRNA_fitted_amp     = 0;
    N_mRNA_integrated_int = 0;
    N_mRNA_sum_pix        = 0;
end


%% == Analyse histogram of amplitudes
if status_FQ

    %- All
    amp_all = [];
    for iRun = 1 : N_reconstruct
        amp_all = [amp_all,TS_rec(iRun).amp];
    end

    [hist_all_counts hist_bin] = hist(amp_all,30);
    hist_all_counts_norm = hist_all_counts/max(hist_all_counts);

    %- Best 10%
    amp_best_10 = [];
    for iRun = 1 : N_avg
        i_loop = ind_Q_min_sorted(iRun);
        amp_best_10 = [amp_best_10,TS_rec(i_loop).amp];
    end
    [hist_top10_counts] = hist(amp_best_10,hist_bin);
    hist_top10_counts_norm = hist_top10_counts/max(hist_top10_counts);

    %- Best reconstruction
    ind_best = ind_Q_min_sorted(1);
    [hist_best_counts] = hist(TS_rec(ind_best).amp,hist_bin);
    hist_best_counts_norm = hist_best_counts/max(hist_best_counts);
end


%% Save output

%- Save properties of reconstruction
if status_FQ
    REC_prop.TS_size_all_mean    = TS_size_all_mean;
    REC_prop.TS_dist_all_IN_mean = TS_dist_all_IN_mean;
    REC_prop.TS_size_all_std    = TS_size_all_std;
    REC_prop.TS_dist_all_IN_std = TS_dist_all_IN_std;

    REC_prop.img_TS   = img_TS_crop_xyz;
    REC_prop.img_res  = img_res;
    REC_prop.img_fit  = img_fit;
    REC_prop.img_bgd  = img_bgd;
    REC_prop.coord    = coord;
    REC_prop.bgd_amp  = mean(img_bgd(:));

    REC_prop.pos_best    = TS_rec(ind_Q_min_sorted(1)).pos;
    REC_prop.pos_best_IN = TS_rec(ind_Q_min_sorted(1)).pos_IN;
    REC_prop.pos_best_OUT = TS_rec(ind_Q_min_sorted(1)).pos_OUT;

    [REC_prop.pos_all(1:N_reconstruct).coord] = deal(TS_rec(ind_Q_min_sorted).pos);

    REC_prop.summary_Q_run_N_MRNA = summary_Q_run_N_MRNA;
    REC_prop.summary_Q_run        = summary_Q_run;
    REC_prop.mean_Q               = mean_Q;
    
else
    REC_prop.TS_size_all_mean    = 0;
    REC_prop.TS_dist_all_IN_mean = 0;
    REC_prop.TS_size_all_std    = 0;
    REC_prop.TS_dist_all_IN_std = 0;

    REC_prop.img_TS   = 0;
    REC_prop.img_res  = 0;
    REC_prop.img_fit  = 0;
    REC_prop.img_bgd  = 0;
    REC_prop.coord    = 0;
    REC_prop.bgd_amp  = 0;

    REC_prop.pos_best    = 0;
    REC_prop.pos_best_IN = 0;
    REC_prop.pos_best_OUT = 0;

    REC_prop.pos_all = 0;

    REC_prop.summary_Q_run_N_MRNA = 0;
    REC_prop.summary_Q_run        = 0;
    REC_prop.mean_Q               = 0;
end

%- TxSite quantification
if status_FQ
    TxSite_quant.N_mRNA_TS_global      = N_mRNA_TS_global;
    TxSite_quant.Q_min_global          = Q_min_global;

    TxSite_quant.N_mRNA_TS_mean_10per  = N_mRNA_TS_mean_10per;
    TxSite_quant.N_mRNA_TS_std_10per   = N_mRNA_TS_std_10per;
    TxSite_quant.Q_avg_10per           = Q_avg_10per;

    TxSite_quant.N_mRNA_TS_mean_all    = N_mRNA_TS_mean;
    TxSite_quant.N_mRNA_TS_std_all     = N_mRNA_TS_std;
    TxSite_quant.Q_avg_all             = Q_avg;

else
    TxSite_quant.N_mRNA_TS_global  = 0;
    TxSite_quant.Q_min_global          = 0;

    TxSite_quant.N_mRNA_TS_mean_10per  = 0;
    TxSite_quant.N_mRNA_TS_std_10per   = 0;
    TxSite_quant.Q_avg_10per           = 0;

    TxSite_quant.N_mRNA_TS_mean_all    = 0;
    TxSite_quant.N_mRNA_TS_std_all     = 0;
    TxSite_quant.Q_avg_all             = 0;
end
   
TxSite_quant.N_mRNA_trad           = N_mRNA_trad;
TxSite_quant.N_mRNA_fitted_amp     = N_mRNA_fitted_amp;
TxSite_quant.N_mRNA_integrated_int = N_mRNA_integrated_int;
TxSite_quant.N_mRNA_sum_pix        = N_mRNA_sum_pix;

TxSite_quant.TS_max_int            = TS_max_int;
TxSite_quant.TS_max_bgd            = bgd_median;

TxSite_quant.TS_sum                = TS_sum;
TxSite_quant.TS_bgd                = TS_bgd;
TxSite_quant.N_pix_sub             = N_pix;


%% Show result
TxSite_reconstruct_Output_v5(TxSite_quant, REC_prop, parameters);


%% Save results
TxSite_save_output_v3(TxSite_quant, REC_prop,parameters)



%% PLOTS
if flags.output == 2 || not(isempty(psname))   
    
    if status_FQ
        %= Histogram of used amplitudes
        h1 = figure; hold on
        plot(hist_bin,hist_all_counts_norm,'r')
        plot(hist_bin,hist_top10_counts_norm,'b')
        plot(hist_bin,hist_best_counts_norm,'g')
        hold off
        box on 
        legend('All','Top 10','Best reconstruction')
        title('Histogram of used amplitudes in reconstructions')

        if not(isempty(psname))
           print (h1,'-dpsc', psname, '-append');
           close(h1)   
        end
    end
end