function [drift, summary_coloc, results_coloc,ch1_all_spots,ch2_all_spots] = FQ3_calc_coloc_v5(parameters,dist_th)


%% Output
summary_coloc = {};
values_coloc = [];
results_coloc = [];
ch1_all_spots = [];
ch2_all_spots = [];

%% Global variables for shifts in 3D
global X1 X2 Y1 Y2 Z1 Z2 u v w 
X1 = []; X2 = [];Y1 = [];Y2= []; Z1 = [];Z2= []; u = [];v= []; w = [];

%% Get Parameters
flags              = parameters.flags;
N_spots_max        = parameters.N_spots_max;
file_name_results  = parameters.file_name_results;

folder_ch1         = parameters.folder_ch1;
folder_ch2         = parameters.folder_ch2;

ident_ch1          = parameters.ident_ch1;
ident_ch2          = parameters.ident_ch2;

folder_img_ch1     = parameters.folder_img_ch1;
folder_img_ch2     = parameters.folder_img_ch2;

drift              = parameters.drift;



flag_save_results = flags.save_results;

%% Check if routine is called to correct for drift
if isempty(drift)
    drift.mean = [0 0 0];
end
drift_all = [];  

%% To generate plot with number of co-localized spots as a function of distance
N_ch1_total        = 0;
N_ch2_total        = 0;
distance_spots_all = [];


%% Generate folders to save results


%- Folder to save results
if flag_save_results ||  flags.save_img_spots || flags.save_img_cells
    %- Generate folder for results
    if flags.drift_apply == 0
        folder_coloc = fullfile(folder_ch1, ['_results_coloc_NoDriftCorrection',datestr(date,'yymmdd')]);
    else
        folder_coloc = fullfile(folder_ch1, ['_results_coloc_DriftCorrection',datestr(date,'yymmdd')]);
    end
    if ~(exist(folder_coloc,'dir')); mkdir(folder_coloc); end
    
    summary_coloc.folder_coloc   = folder_coloc;
else
    summary_coloc.folder_coloc = [];
end

%- Generate folder for results
if flags.save_img_spots
    folder_img_indiv_coloc = fullfile(folder_coloc,'IMG_spots','+');
    if ~(exist(folder_img_indiv_coloc,'dir')); mkdir(folder_img_indiv_coloc); end
    
    folder_img_indiv_not_coloc = fullfile(folder_coloc,'IMG_spots','-');
    if ~(exist(folder_img_indiv_not_coloc,'dir')); mkdir(folder_img_indiv_not_coloc); end
end

%- Generate folder for results
if flags.save_img_cells
    folder_img_cells = fullfile(folder_coloc,'IMG_cells');
    if ~(exist(folder_img_cells,'dir')); mkdir(folder_img_cells); end
    
end



%% Loop over files
N_files      = length(file_name_results);

%- Plot range for the individual images    
d_plot.x = 6; 
d_plot.y = 6;
d_plot.z = 5;  
        
%- Keep track which image is open
file_ch1_open = '';
file_ch2_open = '';

%- Loop while status_loop is set to 1
i_cell_all = 1;

for i_file = 1:N_files

    fprintf('\n=== ANALYZE file %g of %g\n',i_file,N_files)

    %- Clear the new cell-props (used to save new outline files)
    clear cell_prop_ch1_all_coloc cell_prop_ch1_all_coloc_NOT  cell_prop_ch2_all_coloc cell_prop_ch2_all_coloc_NOT

    %- Get file-names
    file_name_ch1 = file_name_results{i_file};

    if isempty(strfind(file_name_ch1,ident_ch1))
        disp('REPLACEMENT OF FILE-NAME NOT POSSIBLE')
        disp(file_name_ch1)
        disp(ident_ch1)
        continue
    end

    file_name_ch2 = strrep(file_name_ch1, ident_ch1, ident_ch2);

    %- Try to load file from channel 1
    disp(['== Loading result file for ch1: ' , file_name_ch1])
    disp(folder_ch1)
    disp(' ')
        
    img1            = FQ_img;
    status_open_ch1 = img1.load_results(fullfile(folder_ch1,file_name_ch1),[]); 

    cell_prop_ch1_all  = img1.cell_prop;
    par_microscope_ch1 = img1.par_microscope;
    file_names_ch1     = img1.file_names;

    if status_open_ch1.outline == 0
       disp('= Results for channel 1 could not be loaded')
       disp(fullfile(folder_ch1,file_name_ch1))
       continue
    end

    %- Try to load file from channel 1  
    disp(['Loading result file for ch2: ' , file_name_ch2])
    disp(folder_ch2)
    disp(' ')
    
    img2        = FQ_img;
    status_open_ch2 = img2.load_results(fullfile(folder_ch2,file_name_ch2),[]); 

    cell_prop_ch2_all  = img2.cell_prop;
    file_names_ch2     = img2.file_names;

     if status_open_ch2.outline == 0
       disp('= Results for channel 2 could not be loaded')
       disp(fullfile(folder_ch2,file_name_ch2))
       continue
    end

   %==== Open images if plots will be generated
    if flags.save_img_spots || flags.save_img_cells

        %- Open raw images
        file_raw_ch1 = file_names_ch1.raw;           
        file_raw_ch2 = file_names_ch2.raw;

        if ~strcmp(file_ch1_open,file_raw_ch1)
            
            status_img = img1.load_img(fullfile(folder_img_ch1,file_raw_ch1),'raw');
            
            if status_img == 0
                disp(' ')
                disp(' !!! CAN NOT LOAD IMAGE for channel 1')
                disp(['File  : ', file_raw_ch1])
                disp(['Folder: ', folder_img_ch1])
                continue
                
            else
                img_ch1       = (img1.raw);
                img_ch1_MIP   = max(img_ch1,[],3);
                file_ch1_open = file_raw_ch1; 
            
                [dim.Y, dim.X, dim.Z] = size(img_ch1);
            end

        end

        if ~strcmp(file_ch2_open,file_raw_ch2)
            
            status_img = img2.load_img(fullfile(folder_img_ch2,file_raw_ch2),'raw');
            
             if status_img == 0
                 disp(' ')
                disp(' !!! CAN NOT LOAD IMAGE for channel 2')
                disp(['File  : ', file_raw_ch1])
                disp(['Folder: ', folder_img_ch1])
                continue
                
             else
                img_ch2       = (img2.raw);
                img_ch2_MIP   = max(img_ch2,[],3);
                file_ch2_open = file_raw_ch2;  
             end

        end
    end
    
    %=== Loop over cells
    disp('== Loop over individual cells')
    N_cells = length(cell_prop_ch1_all);
    pixel_size = par_microscope_ch1.pixel_size;
    
    for i_cell = 1:N_cells

        disp(' ')
        disp(['= Cell ',num2str(i_cell)]);
               
        %== Get property of cell
        cell_prop_ch1 = cell_prop_ch1_all(i_cell);
        cell_prop_ch2 = cell_prop_ch2_all(i_cell);

        %- Skip if no spots were detected
        if isempty(cell_prop_ch1.spots_fit) || isempty(cell_prop_ch2.spots_fit) 
            continue
        end

        %- Set values to zero
        clear data_ch1_th  data_ch2_th  data_ch1_th_coloc data_ch1_th_coloc_NOT data_ch2_th_coloc data_ch2_th_coloc_NOT 

        %== Get spot data fit
        ind_ch1_good = logical(cell_prop_ch1.thresh.in);
        ind_ch2_good = logical(cell_prop_ch2.thresh.in);

        spots_fit_ch1 = cell_prop_ch1.spots_fit;
        spots_fit_ch2 = cell_prop_ch2.spots_fit;

        data_ch1_th = spots_fit_ch1(ind_ch1_good,1:3);
        data_ch2_th = spots_fit_ch2(ind_ch2_good,1:3);
        
        spots_fit_ch1 = spots_fit_ch1(ind_ch1_good,:);
        spots_fit_ch2 = spots_fit_ch2(ind_ch2_good,:);
        
        %- Detected spots
        spots_det_ch1 = cell_prop_ch1.spots_detected;
        spots_det_ch2 = cell_prop_ch2.spots_detected;
  
        spots_det_ch1 = spots_det_ch1(ind_ch1_good,:);
        spots_det_ch2 = spots_det_ch2(ind_ch2_good,:);
        
        N_ch1  = size(data_ch1_th,1);
        N_ch2  = size(data_ch2_th,1);
            
         %- Abort if no spots or too many spots are present
        if N_ch1 == 0 || N_ch2 == 0 || N_ch1 > N_spots_max || N_ch2 > N_spots_max
            disp('!!! Cell not considered in analysis - either no spots or too many spots')
            fprintf('N_ch1 = %d, N_ch2 = %d, N_spots_max = %d \n',N_ch1,N_ch2,N_spots_max)
            continue
        end

        %- Correct for drift
        data_ch2_th_init = data_ch2_th;
        
        if flags.drift_apply
            data_ch2_th(:,1:3) = data_ch2_th(:,1:3) - repmat(drift.mean,size(data_ch2_th,1),1);
        end

        %- LAP with hungarian algorithm
        [target_indices, target_distances] = hungarianlinker(data_ch1_th, data_ch2_th, dist_th);
        
        ind_close_ch1       = find(target_indices>0);
        ind_NOT_close_ch1   = find(target_indices<0);
        
        ind_close_ch2       = target_indices(ind_close_ch1);
        ind_ch2_all         = (1:size(data_ch2_th,1));        
        ind_NOT_close_ch2   = setdiff(ind_ch2_all,ind_close_ch2);
        
        distance_spots  = target_distances(ind_close_ch1);

        %- Save results for summary plot
        N_ch1_total = N_ch1_total + N_ch1;
        N_ch2_total = N_ch2_total + N_ch2;
        distance_spots_all = [distance_spots_all; distance_spots];

        %==================================================================
        % === Other analysis
        %==================================================================
        
        %=== Save drift: from ch1 to ch2
        if flags.drift_calc
            drift_loop = data_ch2_th(ind_close_ch2,1:3) - data_ch1_th(ind_close_ch1,1:3);
            drift_all  = [drift_all;drift_loop];
        end

        %== Calculate vector field of shifts
        shift = data_ch2_th(ind_close_ch2,1:3) - data_ch1_th(ind_close_ch1,1:3);

        Z1{i_cell_all} = data_ch1_th(ind_close_ch1,3);
        X1{i_cell_all} = data_ch1_th(ind_close_ch1,2);
        Y1{i_cell_all} = data_ch1_th(ind_close_ch1,1);

        X2{i_cell_all} = data_ch2_th(ind_close_ch2,2);
        Y2{i_cell_all} = data_ch2_th(ind_close_ch2,1);
        Z2{i_cell_all} = data_ch2_th(ind_close_ch2,3);

        if ~isempty(shift)
            u{i_cell_all} = shift(:,2);
            v{i_cell_all} = shift(:,1);
            w{i_cell_all} = shift(:,3);
        end
        

        %- Summary 
        perc_coloc_ch2 = length(ind_close_ch2)/N_ch2;
        perc_coloc_ch1 = length(ind_close_ch1)/N_ch1;
       
        values_coloc(i_cell_all,:)      = [100*perc_coloc_ch2 100*perc_coloc_ch1 N_ch2 length(ind_close_ch2) N_ch1 length(ind_close_ch1)];
        
        
        %- Save summary 
        results_coloc.perc_coloc_ch2{i_cell_all,1}   = perc_coloc_ch2;
        results_coloc.perc_coloc_ch1{i_cell_all,1}   = perc_coloc_ch1;    
        
        index_match= [];
        
        %- Only if co-localized spots were found
        if ~isempty(ind_close_ch1)
            index_match(:,1) = ind_close_ch1;
            index_match(:,2) = ind_close_ch2;
        end
        results_coloc.index_match{i_cell_all,1} = index_match;
        
        results_coloc.name_ch1{i_cell_all,1} = file_name_ch1;
        results_coloc.name_ch2{i_cell_all,1} = file_name_ch2;
        results_coloc.name_cell{i_cell_all,1} = cell_prop_ch1.label;
        
        results_coloc.data_ch1{i_cell_all,1} = spots_fit_ch1(ind_close_ch1,:);
        results_coloc.data_ch2{i_cell_all,1} = spots_fit_ch2(ind_close_ch2,:);
        
        results_coloc.data_det_ch1{i_cell_all,1} = spots_det_ch1(ind_close_ch1,:);
        results_coloc.data_det_ch2{i_cell_all,1} = spots_det_ch2(ind_close_ch2,:);
  
        
        %- Save results co-localization results for all spots
        ch1_all_spots = [ch1_all_spots;
                         spots_fit_ch1(ind_close_ch1,:) spots_det_ch1(ind_close_ch1,:),ones(length(ind_close_ch1),1);
                         spots_fit_ch1(ind_NOT_close_ch1,:) spots_det_ch1(ind_NOT_close_ch1,:),zeros(length(ind_NOT_close_ch1),1)];
                     
        ch2_all_spots = [ch2_all_spots;
                 spots_fit_ch2(ind_close_ch2,:) spots_det_ch2(ind_close_ch2,:),ones(length(ind_close_ch2),1);
                 spots_fit_ch2(ind_NOT_close_ch2,:) spots_det_ch2(ind_NOT_close_ch2,:),zeros(length(ind_NOT_close_ch2),1)];             

        
        %- Update counter
        i_cell_all = i_cell_all +1;
        
        %==================================================================
        % ===  Plot results of individual images
        
        if  flags.save_img_spots

            %- Assign all parameters needed for plot
            par.ind_close_ch1 = ind_close_ch1;
            par.ind_close_ch2 = ind_close_ch2;

            par.distance_spots = distance_spots;
            par.data_ch1_th   = data_ch1_th;
            par.data_ch2_th   = data_ch2_th_init;  % Drift correction is only for distance calculation but not for plotting
            par.pixel_size    = pixel_size;
            par.d_plot        = d_plot;
            par.dim           = dim;
            par.img_ch1       =  img_ch1;
            par.img_ch2       =  img_ch2;
            par.file_ch1_open = file_ch1_open;
            par.file_ch2_open = file_ch2_open;
            par.cell_prop_ch1 = cell_prop_ch1;
            par.cell_prop_ch2 = cell_prop_ch2;
            par.folder_img_indiv_coloc      = folder_img_indiv_coloc;
            par.folder_img_indiv_not_coloc = folder_img_indiv_not_coloc;
            par.N_ch1 =  N_ch1;
            par.N_ch2 =  N_ch2;

            coloc_plot_img_indiv_v2(par)
        end
        

        %- Plot results for individual cells
        if flags.save_img_cells
            
            %- Get bounding rectangle
            x_min = min(cell_prop_ch1(1).x)-5;
            x_max = max(cell_prop_ch1(1).x)+5;
            y_min = min(cell_prop_ch1(1).y)-5;
            y_max = max(cell_prop_ch1(1).y)+5;
            
            if x_min <1; x_min = 1; end                
            if x_max > size(img_ch1_MIP,2); x_max = size(img_ch1_MIP,2); end         
            if y_min <1; y_min = 1; end
            if y_max > size(img_ch1_MIP,1); y_max = size(img_ch1_MIP,1); end
    
            %- Crop images
            img_ch1_crop = img_ch1_MIP(y_min:y_max,x_min:x_max);
            img_ch2_crop = img_ch2_MIP(y_min:y_max,x_min:x_max);
            
            %- Get detection data
            y1_plot = data_ch1_th(:,1) / img1.par_microscope.pixel_size.xy - y_min+2;
            x1_plot = data_ch1_th(:,2) / img1.par_microscope.pixel_size.xy - x_min+2;
            
            y2_plot = data_ch2_th(:,1) / img1.par_microscope.pixel_size.xy - y_min+2;
            x2_plot = data_ch2_th(:,2) / img1.par_microscope.pixel_size.xy - x_min+2;
      
            
            %- Plot the thing            

            figure, set(gcf,'color','w'), set(gcf,'visible','off')
                
            subplot(2,3,1)
            imshow(log(double(img_ch1_crop)),[])
            title(['CH1 - ',ident_ch1 ])
          
            subplot(2,3,4)
            imshow(log(double(img_ch2_crop)),[])
            title(['CH2 - ',ident_ch2 ])
            
            subplot(2,3,2)
            imshow(log(double(img_ch1_crop)),[])
            hold on
                plot(x1_plot(:),y1_plot(:),'.r','MarkerSize',1)            
            hold off
            axis image
            title('CH1 - detected spots','FontSize',8)
            
            subplot(2,3,5)
            imshow(log(double(img_ch2_crop)),[])
            hold on
                plot(x2_plot(:),y2_plot(:),'.r','MarkerSize',1)              
            hold off
            title('CH2 - detected spots','FontSize',8)
            
            subplot(2,3,3)
            imshow(log(double(img_ch1_crop)),[])          
            hold on
                plot(x1_plot(ind_close_ch1),y1_plot(ind_close_ch1),'.b','MarkerSize',1) 
                plot(x1_plot(ind_NOT_close_ch1),y1_plot(ind_NOT_close_ch1),'.r','MarkerSize',1) 
                plot(x2_plot(ind_NOT_close_ch2),y2_plot(ind_NOT_close_ch2),'.y','MarkerSize',1,'LineWidth',0.5) 
            hold off
            title({'CH1: blue-coloc; red-NOT coloc'; 'CH2: yellow - not coloc'},'FontSize',7,'Fontweight','normal')
            
            subplot(2,3,6)
            imshow(log(double(img_ch2_crop)),[])   
            hold on
                plot(x2_plot(ind_close_ch2),y2_plot(ind_close_ch2),'.b','MarkerSize',1) 
                plot(x2_plot(ind_NOT_close_ch2),y2_plot(ind_NOT_close_ch2),'.r','MarkerSize',1) 
                plot(x1_plot(ind_NOT_close_ch1),y1_plot(ind_NOT_close_ch1),'.y','MarkerSize',1,'LineWidth',0.5) 
            hold off
            title({'CH2: blue-coloc; red-NOT coloc'; 'CH1: yellow - not coloc'},'FontSize',7,'Fontweight','normal')
            
            tightfig(gcf);
            
            %-- Save figure and close
            [dum, img_name_only] = fileparts(file_ch1_open);
            name = [img_name_only,'___',cell_prop_ch1.label,'.pdf'];            
            save2pdf(fullfile(folder_img_cells,name),gcf,300)
            close(gcf);
            
        end
    end
end

%% Check if any colocalization results were obtained

if isempty(values_coloc)
     disp(' ')
     disp('!!! NO CO-LOCALIZATION RESULTS OBTAINED')
     disp('This can happen if no spots were considered - check threshold for maximum number of spots per cell')
     return
end

summary_coloc.values      = values_coloc;
summary_coloc.ident_ch1   =  ident_ch1;
summary_coloc.flags_drift =  flags.drift_apply;
summary_coloc.dist_th     =  dist_th;
summary_coloc.N_spots_max =  N_spots_max;


%% Plot summary results for different length thresholds
if isempty(distance_spots_all)
    x= [0 dist_th];
    fplot = zeros(1,length(x));
else
    [f,x] = ecdf(distance_spots_all);
    N_total = length(distance_spots_all);
    fplot = f*N_total;
end


figure; set(gcf,'Color', 'w')

hold on
plot(x,fplot,'r' )
plot([0 dist_th], [N_ch2_total N_ch2_total],'--g' )
plot([0 dist_th], [N_ch1_total N_ch1_total],'b' )            
hold off
vax=axis;
axis([vax(1) vax(2) vax(3) 1.05*vax(4)])
box on

xlabel('Distance [nm]')
ylabel('Number of mRNA')

legend({'# colocalized','Total ch2', 'Total ch1'},'Location','north')

if flag_save_results
    saveas(gcf,fullfile(folder_coloc,'_FQ_coloc_distance_threshold'),'png');
    save2pdf(fullfile(folder_coloc,'_FQ_coloc_distance_threshold.pdf'),gcf,300)
end

%% === Analyze & plot drift

if flags.drift_calc

        %- Calculate shifts
        drift.mean = mean(drift_all,1);
        drift.std  = std(drift_all,1);
        drift.all  = drift_all;

        %- Plot drift
        h_fig = figure; set(h_fig,'Color','w')
        subplot(1,3,1)
        hist(drift_all(:,2))
        title(['ch2->ch1: dx: ', num2str(round(drift.mean(2))), ' nm'])

        subplot(1,3,2)
        hist(drift_all(:,1))
        title(['ch2->ch1: dy: ', num2str(round(drift.mean(1))), ' nm'])

        subplot(1,3,3)
        hist(drift_all(:,3))
        title(['ch2->ch1: dz: ', num2str(round(drift.mean(3))), ' nm'])

        if flag_save_results
            saveas(gcf,fullfile(folder_coloc,'_FQ_drift_3D'),'png');
            save2pdf(fullfile(folder_coloc,'_FQ_drift_3D.pdf'),gcf,300)
        end

end


%% Plot shift matrix
if 0
    
      N_plot = length(X1);
    color_maps = distinguishable_colors(N_plot);

    figure, set(gcf,'color','w')
    subplot(2,1,1)
    hold on

    for i=1:length(X1)
        quiver(X1{i},Y1{i},u{i},v{i},'Color',color_maps(i,:))      
    end            
    hold off
    axis off
    axis image
    title('Abberation XY')

    subplot(2,1,2)
    hold on

    for i=1:length(X1)
        quiver(X1{i},Z1{i},u{i},w{i},'Color',color_maps(i,:),'ShowArrowHead','off')      
    end            
    hold off
    axis image
    title('Abberation Z')
    
    if flag_save_results
        saveas(gcf,fullfile(folder_coloc,'_FQ_image_abberations'),'pdf');
    end
    
    %--- Plots with arrows
    figure, set(gcf,'color','w')

    subplot(1,2,1)
    hold on

    for i=1:length(X1)
        quiver3(X1{i},Y1{i},Z1{i}-mean(Z1{i}),u{i},v{i},w{i},'Color',color_maps(i,:),'ShowArrowHead','off')           
    end            
    hold off
    axis image
    title('Abberations 3D')


    %== Analysis shifts in more detail
    disp('=== Some more details on abberations')
    for i=1:length(X1)
        fprintf('\n= Image element : %d\n',i)
        fprintf('Z (avg - ch 1): %d \n',round(mean(Z1{i})))
        fprintf('Z (avg - ch 2): %d \n',round(mean(Z2{i})))
        fprintf('dZ (avg)      : %d \n',round(mean(w{i})))     
    end
end

