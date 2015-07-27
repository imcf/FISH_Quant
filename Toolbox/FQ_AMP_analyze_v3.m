function mRNA_prop = FQ_AMP_analyze_v3(spots_fit,spots_detected,thresh,parameters,mRNA_prop) 

%% == Parameters
h_plot  = parameters.h_plot;
col_par = parameters.col_par;


%% Consider only 'good' spots
int_th  = logical(thresh.in);

%% == Get averaged intensity value of pixel intensity
pix_int_th = spots_detected(int_th, col_par.int_raw);
bgd_th     = spots_fit(int_th,col_par.bgd);

pix_int_th_avg = mean(pix_int_th);
bgd_th_avg     = mean(bgd_th);

mRNA_prop.pix_brightest = round(pix_int_th_avg - bgd_th_avg);

%% == Analyze distributions

%-- Analyze distribution of amplitudes
amp_th  = spots_fit(int_th,col_par.amp);

%-- Mean value and standard deviation
mu3    = mean(amp_th); % Data mean
sigma3 = std(amp_th); % Data standard deviation

%- Remove outliers
outliers         = (amp_th - mu3) > 3*sigma3; 
amp_th(outliers) = []; 

%- Histogram
[count_amp bin_amp] = hist(amp_th,30);
count_amp_norm      = count_amp/max(count_amp);

%- Skewness and kurtosis
mRNA_prop.amp_skew = skewness(amp_th);
mRNA_prop.amp_kurt = kurtosis(amp_th);

%- Fit with normal distribution
[mRNA_prop.amp_mean,mRNA_prop.amp_sigma] = normfit(amp_th);
amp_fit          = normpdf(bin_amp,mRNA_prop.amp_mean,mRNA_prop.amp_sigma);
amp_fit_norm     = amp_fit/max(amp_fit);

%- Consider skewness of fit
[rand_n type]         = pearsrnd(mRNA_prop.amp_mean,mRNA_prop.amp_sigma,mRNA_prop.amp_skew ,mRNA_prop.amp_kurt,100000,1);
[count_rand bin_rand] = hist(rand_n,bin_amp);
count_rand_norm       = count_rand/max(count_rand);

%- Export parameters used for plot
mRNA_prop.bin_amp         = bin_amp;
mRNA_prop.count_amp_norm  = count_amp_norm;
mRNA_prop.amp_fit_norm    = amp_fit_norm;
mRNA_prop.bin_rand        = bin_rand;
mRNA_prop.count_rand_norm = count_rand_norm;

%- Plot results
axes(h_plot)
cla(h_plot,'reset')
hold on
bar(bin_amp,count_amp_norm,'FaceColor',[0.7 0.7 0.7])
plot(bin_amp,amp_fit_norm,'-b')
plot(bin_rand,count_rand_norm,'-r')
hold off

box on
legend('Experiment','Normal distribution','Skewed normal distribution')
xlabel('Amplitude')
ylabel('Normalized count')

disp(' '); disp('Fit with skewed normal distribution')
disp(['Mean:     ', num2str(round(mRNA_prop.amp_mean ))])
disp(['Sigma:    ', num2str(round(mRNA_prop.amp_sigma))])
disp(['Skewness: ', num2str(mRNA_prop.amp_skew)])
disp(['Kurtosis: ', num2str(mRNA_prop.amp_kurt)])
disp(' ');
