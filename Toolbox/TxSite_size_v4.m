function TxSite_SIZE  = TxSite_size_v4(pos_mRNA,coord,parameters)

% coord is usually retrieved from TS_analysis_results.coord
% pos_mRNA is usally retrieved from TS_rec.pos or from REC_prop.pos_best

flags               = parameters.flags;
psname              = parameters.file_name_save_PLOTS_PS;

%% Analyze size of transcription site

%- Center of coordinate grid describing transcription site
%X_center = coord.X_nm(ceil(length(coord.X_nm)/2));
%Y_center = coord.Y_nm(ceil(length(coord.Y_nm)/2));
%Z_center = coord.Z_nm(ceil(length(coord.Z_nm)/2));

X_center = mean(pos_mRNA(:,2));
Y_center = mean(pos_mRNA(:,1));
Z_center = mean(pos_mRNA(:,3));

%- Correct positions with respect to center of coordinate grid
pos_TS_best_shift = [];
pos_TS_best_shift(:,1) = pos_mRNA(:,1) - Y_center;
pos_TS_best_shift(:,2) = pos_mRNA(:,2) - X_center;
pos_TS_best_shift(:,3) = pos_mRNA(:,3) - Z_center;

TxSite_SIZE.pos            = pos_TS_best_shift;
TxSite_SIZE.pos_avg        = mean(TxSite_SIZE.pos ,1);
TxSite_SIZE.pos_shift      = (TxSite_SIZE.pos  - repmat(TxSite_SIZE.pos_avg,size(TxSite_SIZE.pos ,1),1));
TxSite_SIZE.dist_3D        = sqrt((TxSite_SIZE.pos(:,1).^2 + TxSite_SIZE.pos(:,2).^2  + TxSite_SIZE.pos(:,3).^2));
TxSite_SIZE.dist_avg       = round(mean(TxSite_SIZE.dist_3D));
TxSite_SIZE.dist_3D_shift  = sqrt((TxSite_SIZE.pos_shift(:,1).^2 + TxSite_SIZE.pos_shift(:,2).^2  + TxSite_SIZE.pos_shift(:,3).^2));
TxSite_SIZE.dist_avg_shift = round(mean(TxSite_SIZE.dist_3D_shift));

%- Calc histogram of positions
[TxSite_SIZE.dist_counts       TxSite_SIZE.dist_bins]       = hist(TxSite_SIZE.dist_3D);
[TxSite_SIZE.dist_counts_shift TxSite_SIZE.dist_bins_shift] = hist(TxSite_SIZE.dist_3D_shift);

%% OUTPUT

if parameters.fid ~= -1
   fprintf(parameters.fid, 'Dist AVG [CENTERED DATA]     : %g nm \n',TxSite_SIZE.dist_avg_shift);  
   fprintf(parameters.fid, 'DIST AVG [NOT CENTERED DATA] : %g nm \n\n',TxSite_SIZE.dist_avg);  
end


if flags.output
    disp(' ')
    disp(['Dist AVG [CENTERED DATA]     : ', num2str(TxSite_SIZE.dist_avg_shift,'%10.0f'),' nm'])
    disp(['DIST AVG [NOT CENTERED DATA] : ', num2str(TxSite_SIZE.dist_avg,'%10.0f'),' nm'])
end

if flags.output == 2 || not(isempty(psname))        
   
    h1 = figure ;
    subplot(2,1,1)
    bar(TxSite_SIZE.dist_bins,TxSite_SIZE.dist_counts)
    legend(['Dist AVG=', num2str(TxSite_SIZE.dist_avg,'%10.0f'),' nm'])
    xlabel('Distance from center in nm')
    ylabel('# of mRNA')
    title('Not centered data')

    subplot(2,1,2)
    bar(TxSite_SIZE.dist_bins_shift,TxSite_SIZE.dist_counts_shift)
    legend(['Dist AVG=', num2str(TxSite_SIZE.dist_avg_shift,'%10.0f'),' nm'])
    title('Centered data')
    xlabel('Distance from center in nm')
    ylabel('# of mRNA')
    
    
    if not(isempty(psname))
       print (h1,'-dpsc', psname, '-append');
       close(h1)   
    end
end





