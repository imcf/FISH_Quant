function drift = FQ3_calc_coloc_v3(parameters,dist_th)

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

%- Generate folder for results
if flags.drift_apply == 0
    folder_coloc = fullfile(folder_ch1, ['_results_coloc_NoDriftCorrection',datestr(date,'yymmdd')]);
else
    folder_coloc = fullfile(folder_ch1, ['_results_coloc_DriftCorrection',datestr(date,'yymmdd')]);
end
if ~(exist(folder_coloc,'dir')); mkdir(folder_coloc); end

%- Generate folder for results
if flags.img_indiv_spots
    folder_img_indiv_coloc = fullfile(folder_coloc,'IMG_indiv','+');
    if ~(exist(folder_img_indiv_coloc,'dir')); mkdir(folder_img_indiv_coloc); end
    
    folder_img_indiv_not_coloc = fullfile(folder_coloc,'IMG_indiv','-');
    if ~(exist(folder_img_indiv_not_coloc,'dir')); mkdir(folder_img_indiv_not_coloc); end
end

if flags.save_results
    file_name_save = ['__FQ_coloc_summary' , datestr(now,'yymmdd'),'.txt'];  % Name to save the results
end

%% Loop over files
result_coloc = [];
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
    disp(['== Loading file for ch1: ' , file_name_ch1])
        
    img1        = FQ_img;
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
    disp(['Loading file for ch2: ' , file_name_ch2])
  
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
    if flags.img_indiv_spots

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
                img_ch1       = uint32(img1.raw);
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
                img_ch2 = uint32(img2.raw);
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

        %== Get spot data
        ind_ch1_good = logical(cell_prop_ch1.thresh.in);
        ind_ch2_good = logical(cell_prop_ch2.thresh.in);

        spots_fit_ch1 = cell_prop_ch1.spots_fit;
        spots_fit_ch2 = cell_prop_ch2.spots_fit;

        data_ch1_th = spots_fit_ch1(ind_ch1_good,1:3);
        data_ch2_th = spots_fit_ch2(ind_ch2_good,1:3);
        
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
        
        ind_close_ch1   = find(target_indices>0);
        ind_close_ch2   = target_indices(ind_close_ch1);
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
        
        %=== Save results for each cell - will be used for the summary file     
        perc_coloc_ch2 = length(ind_close_ch2)/N_ch2;
        perc_coloc_ch1 = length(ind_close_ch1)/N_ch1;
        result_coloc(i_cell_all,:)      = [100*perc_coloc_ch2 100*perc_coloc_ch1 N_ch2 length(ind_close_ch2) N_ch1 length(ind_close_ch1)];
        name_outline_all{i_cell_all,1}  = file_name_ch1;
        name_cell_all{i_cell_all,1}     = cell_prop_ch1.label;
        i_cell_all = i_cell_all +1;

        %==================================================================
        % ===  Plot results of individual images
        
        if  flags.img_indiv_spots

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
    end
end


%% Check if any colocalization results were obtained

if isempty(result_coloc)
     disp(' ')
     disp('!!! NO CO-LOCALIZATION RESULTS OBTAINED')
     disp('This can happen if no spots were considered - check threshold for maximum number of spots per cell')
     return
end


%% Plot summary results for different length thresholds
[f,x] = ecdf(distance_spots_all);
N_total = length(distance_spots_all);

figure; set(gcf,'Color', 'w')

hold on
plot(x,f*N_total,'r' )
plot([0 dist_th], [N_ch2_total N_ch2_total],'--g' )
plot([0 dist_th], [N_ch1_total N_ch1_total],'b' )            
hold off
v=axis;
axis([v(1) v(2) v(3) 1.05*v(4)])
box on

xlabel('Distance [nm]')
ylabel('Number of mRNA')

legend('# colocalized','Total ch2', 'Total ch1',4)

saveas(gcf,fullfile(folder_coloc,'_FQ_coloc_distance_threshold'),'png');
save2pdf(fullfile(folder_coloc,'_FQ_coloc_distance_threshold.pdf'),gcf,300)


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

        saveas(gcf,fullfile(folder_coloc,'_FQ_drift_3D'),'png');
        save2pdf(fullfile(folder_coloc,'_FQ_drift_3D.pdf'),gcf,300)

end



%% === Save summary file 
if flags.save_results

    file_save_full = fullfile(folder_coloc,file_name_save);

    %- Summarize all outputs
    cell_data    = num2cell(result_coloc);   

    cell_write_all  = [name_outline_all,name_cell_all,cell_data];
    cell_write_FILE = cell_write_all';

    N_col = size(cell_data,2); 
    string_write = ['%s\t%s',repmat('\t%g',1,N_col), '\n'];

    N_ch1_total = sum(result_coloc(:,5));
    N_ch1_coloc = sum(result_coloc(:,6));
    N_ch2_total = sum(result_coloc(:,3));
    N_ch2_coloc  = sum(result_coloc(:,4));

    %- Write file    
    fid = fopen(file_save_full,'w');
    fprintf(fid,'FISH-QUANT\n');
    fprintf(fid,'Colocalization analysis of images: %s \n\n',ident_ch1);

    fprintf(fid,'\nDrift-correction: \t%g\n',flags.drift_apply);
    fprintf(fid,'Dist_threshold: \t%g\n\n',dist_th);

    fprintf(fid,'CH1: perc-coloc, total, coloc : \t%g\t%g\t%g\n', round(100*N_ch1_coloc/N_ch1_total),N_ch1_total,N_ch1_coloc);
    fprintf(fid,'CH2: perc-coloc, total, coloc : \t%g\t%g\t%g\n\n', round(100*N_ch2_coloc/N_ch2_total),N_ch2_total,N_ch2_coloc);

    fprintf(fid,'Name_File\tName_Cell\tPERC_coloc_CH2\tPERC_coloc_CH1\tCH2_N_total\tCH2_N_coloc\tCH1_N_total\tCH1_N_coloc\n');        
    fprintf(fid,string_write, cell_write_FILE{:});
    fclose(fid);

    %- Display file name
    disp(' ')
    disp('===== RESULTS SAVED')
    disp(file_save_full)      
end


%% Plot shift matrix
if 0
    
    N_plot = length(x);
    color_maps = distinguishable_colors(N_plot);


    figure, set(gcf,'color','w')
    subplot(2,1,1)
    hold on

    for i=1:length(x)
        quiver(x{i},y{i},u{i},v{i},'Color',color_maps(i,:))      
    end            
    hold off
    axis off
    axis image
    title('Abberation XY')

    subplot(2,1,2)
    hold on

    for i=1:length(x)
        quiver(x{i},z{i},u{i},w{i},'Color',color_maps(i,:),'ShowArrowHead','off')      
    end            
    hold off
    axis image
    title('Abberation Z')
    
    saveas(gcf,fullfile(folder_coloc,'_FQ_image_abberations'),'pdf');

    figure, set(gcf,'color','w')

    subplot(1,2,1)
    hold on

    for i=1:length(x)
        quiver3(x{i},y{i},z{i}-mean(z{i}),u{i},v{i},w{i},'Color',color_maps(i,:),'ShowArrowHead','off')           
    end            
    hold off
    axis image
    title('Abberations 3D')


    %== Analysis shifts in more detail
    disp('=== Some more details on abberations')
    for i=1:length(x)
        disp(['= Image element :',num2str(i)'])
        fprintf('Z (avg - ch 1): %d \n',round(mean(z1{i})))
        fprintf('Z (avg - ch 2): %d \n',round(mean(z{i})))
        fprintf('dZ (avg)      : %d \n',round(mean(w{i})))     
    end
end

