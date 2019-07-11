function [ripley_features, ripley_curves] = loc_feature_Ripley_v1(pos_points,pos_border, param) 
%- Function to calculated localization features based on the L-function.


%==== Calculate L-function for one position - 1/4 of maximum size of the cell
a               = distmat([transpose(pos_border.x) transpose(pos_border.y)]);
size_cell       = max(max(a));
R_mid_cell      = ripley_k_function_edge_corr_v1(pos_points,pos_border,round(size_cell/4),param);
L_mid_cell      = sqrt(R_mid_cell/pi) - transpose(size_cell/4);


%==== Calculate R and L functions for aggregates
dist_interest    = param.dist_interest; 
space            = param.space; 

t      = linspace(1,dist_interest,round(dist_interest/space));
R_fun  = ripley_k_function_edge_corr_v1(pos_points,pos_border,t,param);
L_fun  = sqrt(R_fun/pi) - transpose(t);

%- Smooth tL-function to calculate features
L_smooth  = movingmean(L_fun,4);

%- Get max value of curve & its gradient
[max_L, I]            = max(L_smooth);
L_smooth_gradient_asc = gradient(L_smooth,1);

%- Calculate the different features
ripley_features.Ripley_max           = max_L;
ripley_features.Ripley_gradient_max  = max(L_smooth_gradient_asc(1:I));
ripley_features.Ripley_gradient_min  = min(L_smooth_gradient_asc(I:length(L_smooth_gradient_asc)));
ripley_features.Ripley_mid_cell      = L_mid_cell;
ripley_features.Ripley_corr          = corr(transpose(t), L_fun, 'type', 'Spearman');
ripley_features.Ripley_dist_max      = I;

ripley_curves.L_stat_cor_edge      = L_fun;
ripley_curves.Ripley_smoothed      = L_smooth;
ripley_curves.Ripley_smoothed_gradient_asc  = L_smooth_gradient_asc;

%- Some plots
if param.verbose
   figure, set(gcf,'color','w')
   
   subplot(1,2,1)
   plot(t,R_fun)
   xlabel('Distance [pix]')
   ylabel('Ripley K-function')
   
   subplot(1,2,2)
   hold on
   plot(t,L_fun,'-b')
   plot(t,L_smooth,'-r')
   hold off
   box on
   xlabel('Distance [pix]')
   ylabel('L-function')
   legend('Raw curve','Smoothed curve')
   
end
    