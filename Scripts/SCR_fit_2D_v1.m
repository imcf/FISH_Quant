function SCR_fit_3D_v1(file_name)


flag_fit = 1;  % Fit spot position or not

%% Define image
if nargin == 0
    [file_raw, path_img] = uigetfile('*.tif','Select image.');

    if isequal(file_raw,0); 
        return; 
    end
    file_name = fullfile(path_img,file_raw);
else
    [path_img, file_raw,ext] = fileparts(file_name);
    file_raw = [file_raw,ext];
end
    
%- Check if path with results is present
[dum, name_base,ext] = fileparts(file_raw);
path_detect = strrep(path_img,'images','detection');
path_save = fullfile(path_detect,name_base);

if ~exist(path_save)
    disp('Path to save results not present. Will exit')
    disp(path_save)
    return
end

%- Generate folder for plots
folder_plots = fullfile(path_save,['FQ_plots_',datestr(date,'yymmdd')]);
if not(exist(folder_plots)); mkdir(folder_plots); end

%- Generate folder for FQ-results
folder_results = fullfile(path_save,['FQ_results_',datestr(date,'yymmdd')]);
if not(exist(folder_results)); mkdir(folder_results); end

%% Get the channel filler for raw image

%- Initializes Bio-Formats and its logging level
try
    bfInitLogging();
catch 
    disp('FQ-startup: problems with bfInitlogging!')
end

%- Open pointer to image
r_raw = bfGetReader(fullfile(path_img,file_raw));

%=== Get the total number of images;
N_img = r_raw.getImageCount();
fprintf('Total number of images: \t%g\n',N_img)

%== Get size in Y and X
N_Y = r_raw.getSizeY;
N_X = r_raw.getSizeX;

%=== Get the number of Z slices;
N_Z = 1;%;r_raw.getSizeZ();

%% Get detection settings

img_raw=FQ_img;
img_raw.file_names.raw = [name_base,ext];

%- Dimensions
img_raw.dim.X             = N_X;
img_raw.dim.Y             = N_Y;
img_raw.dim.Z             = N_Z;

%- Check if their is an outline file
file_outline  = fullfile(path_save,[name_base,'__outline.txt']);
if exist(file_outline,'file')
    img_raw.load_results(file_outline,[]);
    disp('== Found outline')
else
    img_raw.make_one_cell(1);
    disp('== No outline found - will use entire image for spot detection')
end

%- Load settings
file_sett = [name_base,'__settings_MATURE.txt'];
status_sett = img_raw.load_settings(fullfile(path_save,file_sett));
img_raw.status_3D = 0;  % Set detection to 2d
img_raw.file_names.settings = file_sett;

if status_sett == 0
    disp('== No FQ settings file found.')
    fprintf('Expected folder: %s\n',path_save)
    fprintf('Expected file  : %s\n',file_sett)
    return
else
    disp('== FQ settings loaded.')
end


%- Number of cells per image
N_cell = size(img_raw.cell_prop,2);
if N_cell > 1
    disp('Script works currently only for one cell.')
    return
end



%% Read each of the z-stacks
tic

summary_img_raw = [];
spots_max = 1;
h_fig_detect = figure(107); clf
set(h_fig_detect,'color','w')
title('Number of detected (blue) and fit (red) spots per time-point')
axis([0 N_img 0 1.05*spots_max])

clear movieInfo

for iT = 1: N_img
    
    %- Plot points as indicator where we are 
    fprintf('\n\n=== Analyzing time-point %g \n  ',iT);
     
    %== OPEN time-point: RAW
    img_loop    = bfGetPlane(r_raw, iT);
    img_raw.raw = img_loop;   
    
    %== Filter image
    flag_filter.output = 0;
    status_filter      = img_raw.filter(flag_filter);
     
    
    %=== Detect and fit spots in OPB corrected image

        %- Pre-detect
        img_raw.spots_predect(1);

        %- Calculate quality score only if it will be used for thresholding
        if img_raw.settings.detect.thresh_score > 0
            img_raw.spots_quality_score(1);
            img_raw.spots_quality_score_apply(1,1);
        end

    
    %- Fit or not?
    if flag_fit 
        
        %- Fit
        fprintf('\n= Fit \n');
        img_raw.spots_fit_3D(1); 

         %- Apply fitting threshold
        img_raw.spots_fit_th_apply;
    end 
    
    %=== Save results
    name_save              = ['FQ_results_T-',sprintf('%02d',iT),'.txt']; 
    name_save              = fullfile(folder_results,name_save);
    
    parameters.comment     = ['substack_',num2str(iT),'-',num2str(iT)]; 
    parameters.path_save   = folder_results; 
    parameters.version     = 'v3';
    parameters.flag_type   = 'spots';
      
    img_raw.save_results(name_save,parameters);
    
    %== Save movieInfo
    % Important for utrack
    
    if ~isempty(img_raw.cell_prop.spots_fit)
    
        %- Use fit
        if flag_fit
            movieInfo(iT).xCoord(:,1) = img_raw.cell_prop.spots_fit(:,2) / img_raw.par_microscope.pixel_size.xy +1 ;
            movieInfo(iT).xCoord(:,2) = 0;

            movieInfo(iT).yCoord(:,1) = img_raw.cell_prop.spots_fit(:,1)/ img_raw.par_microscope.pixel_size.xy +1;
            movieInfo(iT).yCoord(:,2) = 0;

            movieInfo(iT).amp(:,1) = img_raw.cell_prop.spots_fit(:,4);
            movieInfo(iT).amp(:,2) = 0;

        %- Use predetected position without fit
        else
            movieInfo(iT).xCoord(:,1) = img_raw.cell_prop.spots_detected(:,2);
            movieInfo(iT).xCoord(:,2) = 0;

            movieInfo(iT).yCoord(:,1) = img_raw.cell_prop.spots_detected(:,1);
            movieInfo(iT).yCoord(:,2) = 0;

            movieInfo(iT).amp(:,1) = img_raw.cell_prop.spots_detected(:,10);
            movieInfo(iT).amp(:,2) = 0;
        end
        
    else
        
            movieInfo(iT).xCoord(:,1) = zeros(0,1);
            movieInfo(iT).xCoord(:,2) = zeros(0,1);

            movieInfo(iT).yCoord(:,1) = zeros(0,1);
            movieInfo(iT).yCoord(:,2) = zeros(0,1);

            movieInfo(iT).amp(:,1) = zeros(0,1);
            movieInfo(iT).amp(:,2) = zeros(0,1);
    end
    
    %====  Calc average parameters from raw image
     if flag_fit && ~isempty(img_raw.cell_prop.spots_fit)
        ind_in        = img_raw.cell_prop(1).thresh.in;
        amp_raw_th    = img_raw.cell_prop(1).spots_fit(ind_in,img_raw.col_par.amp);
        bgd_raw_th    = img_raw.cell_prop(1).spots_fit(ind_in,img_raw.col_par.bgd);
        sigmax_raw_th = img_raw.cell_prop(1).spots_fit(ind_in,img_raw.col_par.sigmax);
        sigmaz_raw_th = img_raw.cell_prop(1).spots_fit(ind_in,img_raw.col_par.sigmaz);
        N_spots_raw   =  sum(img_raw.cell_prop(1).thresh.in);

        summary_img_raw(iT,:) = [N_spots_raw median(sigmax_raw_th) std(sigmax_raw_th) , ...
                                 median(sigmaz_raw_th) std(sigmaz_raw_th), ...
                                 median(amp_raw_th) std(amp_raw_th), ...
                                 median(bgd_raw_th) std(bgd_raw_th)];   
     else
         N_spots_raw = 0;
     end
   
   %- Update plot
   N_detect = size(img_raw.cell_prop(1).spots_detected,1);
   max_loop = max([N_spots_raw N_detect]);
   if max_loop>   spots_max
       spots_max = max_loop;
       axis([0 N_img 0 1.05*spots_max])
   end
    hold on
        plot(iT,N_detect,'ob')  
        plot(iT,N_spots_raw,'or')  
        drawnow
    hold off
    
end

toc

%==== Save settings file
copyfile(fullfile(path_save,file_sett),fullfile(folder_results,file_sett))

%===== Save summary for utrack

%- Save detection
analysisInfo.name_movie = file_name;
save(fullfile(path_save,['Detection_',datestr(date,'yymmdd'),'.mat']),'movieInfo','analysisInfo')
save(fullfile(path_detect,[name_base,'__DETECT.mat']),'movieInfo','analysisInfo')

%==== Save figure with number of detections
name_save = fullfile(folder_plots,'FQ_number_detections');
save2pdf(name_save,h_fig_detect,300)
saveas(h_fig_detect,name_save,'fig')


%====== Plot summary figure of spot detection
N_plot = size(summary_img_raw,1);

h_fig = figure; set(gcf,'color','w'), set(gcf,'visible','off')
subplot(2,3,1)
plot(summary_img_raw(:,1))
title('# detection [RAW]')

subplot(2,3,2)
shadedErrorBar(1:N_plot,summary_img_raw(:,2),summary_img_raw(:,3),'b'); 
title('sigma-xy')

subplot(2,3,3)
shadedErrorBar(1:N_plot,summary_img_raw(:,4),summary_img_raw(:,5),'b'); 
title('sigma-z')

subplot(2,3,4)
shadedErrorBar(1:N_plot,summary_img_raw(:,6),summary_img_raw(:,7),'b'); 
title('amp')

subplot(2,3,5)
shadedErrorBar(1:N_plot,summary_img_raw(:,8),summary_img_raw(:,9),'b'); 
title('bgd')

%===== Save figure with number of detections
name_save = fullfile(folder_plots,'FQ_fit_parameters');
save2pdf(name_save,h_fig,300)
saveas(h_fig,name_save,'fig')
close(h_fig)