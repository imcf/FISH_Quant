function [ind_th_out  X_th] = threshold_histogram_v3(X, nBins)

%- Calculate histogram and determine threshold
[counts, bin ] = hist(X,nBins);
counts_max     = max(counts);
X_th           = 1.5*bin((counts==counts_max));
X_th           = X_th(1);
ind_th_out     = find ( X(:,1) < X_th);

%- Show results of histrogram and threshold
figure, hold on
bar(bin,counts)
plot([X_th X_th], [0 counts_max],'r')
hold off
box on
xlabel('Relative score')
ylabel('Count')
title('Thresholding: selected spots > red line')

%- Check if threshold is ok
choice = questdlg('Thresholding ok?','Threshold pre-detected spots','Yes','No','Yes');


%- Ask user if threshold is ok
while (strcmp(choice,'No'))
    
    %- Ask user for new threshold
    prompt    = {'Value of threshold:'};
    dlg_title = 'Threshold histogram';
    num_lines = 1;
    def       = {num2str(X_th)};
    answer    = inputdlg(prompt,dlg_title,num_lines,def);
    X_th      = str2double(answer{1});  
    ind_th_out = find ( X(:,1) < X_th);

    %- Plot histogram with location of threshold
    figure, hold on
    bar(bin,counts)
    plot([X_th X_th], [0 counts_max],'r')
    hold off
    box on
    xlabel('Relative score')
    ylabel('Count')
    title('Thresholding detected spots > red line')

    %- Check if threshold is ok
    choice = questdlg('Thresholding ok?','Thresholding based on curvature','Yes','No','Yes');
end   





