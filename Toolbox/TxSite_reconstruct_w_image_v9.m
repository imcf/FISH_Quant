function [TS_rec, Q_all, img_bgd] = TxSite_reconstruct_w_image_v9(TS_analysis,img_PSF,parameters)

%% Parameters
flags               = parameters.flags;
N_mRNA_analysis_MAX = parameters.N_mRNA_analysis_MAX;
N_reconstruct       = parameters.N_reconstruct;
mRNA_prop           = parameters.mRNA_prop;
pixel_size_os       = parameters.pixel_size_os;
psname              = parameters.file_name_save_PLOTS_PS;


%% Extract results from analysis with TxSite_reconstruct_ANALYSIS_v1
img_TS_crop_xyz  = TS_analysis.img_TS_crop_xyz;
coord            = TS_analysis.coord;
index_table      = TS_analysis.index_table;
bgd_amp          = TS_analysis.bgd_amp;
N_run_prelim     = parameters.N_run_prelim;   


%% Parameters for reconstruction
parameters_rec.coord         = coord;
parameters_rec.mRNA_prop     = mRNA_prop;
parameters_rec.index_table   = index_table;
parameters_rec.index_table   = index_table;
parameters_rec.pixel_size_os = pixel_size_os;
parameters_rec.flags         = flags;
parameters_rec.flags.output = 0;
 
    
%% Determine background (if range is specified, otherwise local background)

%- Sample multiple background values for the best one
if  length(bgd_amp) > 1 
    
    disp(' ')
    disp('== Determining background of TxSite')
    disp(['Values that will be tested: ', num2str(bgd_amp)]);
    fprintf('.')

    
    N_bgd = length(bgd_amp);
    
    %- Loop over background
    for i_bgd = 1: N_bgd
        fprintf('.')
        bgd_loop = bgd_amp(i_bgd);

        img_bgd  = bgd_loop*ones(size(img_TS_crop_xyz));

        %- Repeat reconstruction to reduce noise
        if(flags.parallel)
            parfor i=1:N_run_prelim
                [N_MAX_loop(i) res_all{i}] =  TxSite_reconstruct_w_image_FUN_est_N_v3(img_TS_crop_xyz,img_bgd,img_PSF,parameters_rec);    
                [min_res_loop(i) ind_min_res_loop(i)] = min(res_all{i});
            end
        else
            for i=1:N_run_prelim
                [N_MAX_loop(i) res_all{i}] =  TxSite_reconstruct_w_image_FUN_est_N_v3(img_TS_crop_xyz,img_bgd,img_PSF,parameters_rec);    
                [min_res_loop(i) ind_min_res_loop(i)] = min(res_all{i});
            end    
        end

        N_mRNA_analysis_MAX(i_bgd) = round(mean(N_MAX_loop));
        min_res_all(i_bgd)         = round(mean(min_res_loop));
        min_res_all_std(i_bgd)     = round(std(min_res_loop));
        min_res_it(i_bgd)          = round(mean(ind_min_res_loop));
        min_res_it_std(i_bgd)      = round(std(ind_min_res_loop));
    end
    fprintf('\n')
    
    %- Get max number of mRNA and background for quantification
    [res_min_val res_min_ind] = min(min_res_all);    
    N_mRNA_MAX = N_mRNA_analysis_MAX(res_min_ind);    
    bgd_rec    = bgd_amp(res_min_ind);
    

    disp(['Best fit with background value: ', num2str(bgd_rec)])

    if parameters.fid ~= -1
        fprintf(parameters.fid, 'Best fit with bgd value:  %g \n\n', bgd_rec);
    end
    
    if flags.output == 2 || not(isempty(psname))
        
        [bgd_sort ind_sort] = sort(bgd_amp);
        
        x1 = bgd_amp(ind_sort);
        y1 = min_res_all(ind_sort);
        e1 = min_res_all_std(ind_sort);
        
        x2 = bgd_amp(ind_sort);
        y2 = min_res_it(ind_sort);
        e2 = min_res_it_std(ind_sort);
        
        h1 = figure;
        subplot(1,3,1)
        errorbar(x1,y1,e1,'-or','MarkerEdgeColor','r', 'MarkerFaceColor','r', 'MarkerSize',10)
        xlabel('Background of TxSite')
        ylabel('AVGed minimum residuals')   
        title('Residuals as a function of TS background')
        box on 
        
        subplot(1,3,2)        
        errorbar(x2,y2,e2,'-or','MarkerEdgeColor','r', 'MarkerFaceColor','r', 'MarkerSize',10)
        xlabel('Background of TxSite')
        ylabel('# placements for minimum = # nascent mRNA')
        title('# nascent mRNA as a function of TS background')
        box on
       
        subplot(1,3,3)
        [AX,H1,H2] = plotyy(x1,y1,x2,y2);
        xlabel('Background of TxSite')
        set(get(AX(1),'Ylabel'),'String','Residuals') 
        set(get(AX(2),'Ylabel'),'String','# nascent mRNA')
        set(H1,'LineStyle','-')
        set(H2,'LineStyle','-')
        set(H1,'Marker','o')
        set(H2,'Marker','o')
         xlabel('Background of TxSite')
        title('residuals and # nascent mRNA')
        
        if not(isempty(psname))
            print (h1,'-dpsc', psname, '-append');
            close(h1)   
        end
        
    end

    
%=== Determine local background    
else
    bgd_rec = bgd_amp;
    img_bgd = bgd_rec*ones(size(img_TS_crop_xyz));
    
    disp(['Using background: ', num2str(bgd_rec)])
    
    %- Repeat reconstruction to reduce noise
    if(flags.parallel)
        parfor i=1:N_run_prelim
            [N_MAX_loop(i) res_all{i}] =  TxSite_reconstruct_w_image_FUN_est_N_v3(img_TS_crop_xyz,img_bgd,img_PSF,parameters_rec);    
            min_res_loop(i) = min(res_all{i});
        end
    else
        for i=1:N_run_prelim
            [N_MAX_loop(i) res_all{i}] =  TxSite_reconstruct_w_image_FUN_est_N_v3(img_TS_crop_xyz,img_bgd,img_PSF,parameters_rec);    
            min_res_loop(i) = min(res_all{i});
        end    
    end
    
    N_mRNA_MAX = round(mean(N_MAX_loop));

    if flags.output == 2
        figure, hold on
        for i=1:N_run_prelim 
            x_value = (1:1:length(res_all{i}))-1;
            plot(x_value,res_all{i}/min(res_all{i}))
        end       
        xlabel('Number of mRNAs')
        ylabel('Quality score [rel to min]')
        title(['BGD: ' num2str(round(bgd_rec)), ', max # of PSFs for quant: ', num2str(N_mRNA_MAX)])
        box on 
    end   
    
end


%% Determine # nascent mRNA's
parameters_rec.N_mRNA_MAX = N_mRNA_MAX;
img_bgd                   = bgd_rec*ones(size(img_TS_crop_xyz));

%- Parameters for distance calculations
parameters_dist.fid                     = -1;
parameters_dist.flags.output            = 0;
parameters_dist.file_name_save_PLOTS_PS = [];

%- Generate output
disp(' ')
disp('Sampling different configurations')
disp(' .... ')

%== Other variables

%= RUN LOOP
TS_rec = struct('Q_min', [], 'N_mRNA', [],'data', [],'pos', [],'amp', [],'dist_3D_shift', [],'dist_3D', [],'dist_avg', [],'dist_avg_shift',[]);
Q_all  = struct('data', []);

%- Run loop and do reconstruction
if(flags.parallel)
     disp('Parallel computing ....')
      
     parfor iRun_p = 1 : N_reconstruct
         %- Quantification
         [TS_rec_loop Q_all(iRun_p).data]  = TxSite_reconstruct_w_image_FUN_v3(img_TS_crop_xyz,img_bgd,img_PSF,parameters_rec);
     
     
        %- Analyse size distribution
        TxSite_SIZE = TxSite_size_v4(TS_rec_loop.pos,coord,parameters_dist);

        TS_rec_loop.dist_3D_shift  = TxSite_SIZE.dist_3D_shift;
        TS_rec_loop.dist_3D        = TxSite_SIZE.dist_3D;
        TS_rec_loop.dist_avg       = TxSite_SIZE.dist_avg;
        TS_rec_loop.dist_avg_shift = TxSite_SIZE.dist_avg_shift;        
        
        TS_rec(iRun_p) = TS_rec_loop;
     end
 
 else
    for iRun = 1 : N_reconstruct    

        if (rem(iRun,10) == 0);
            disp(['Configurations tested: ', num2str(100*(iRun/N_reconstruct)),'%']) 
        end
        
        %- Quantification
        [TS_rec_loop Q_all(iRun).data]  = TxSite_reconstruct_w_image_FUN_v3(img_TS_crop_xyz,img_bgd,img_PSF,parameters_rec);
    
        %- Analyse size distribution
        TxSite_SIZE = TxSite_size_v4(TS_rec_loop.pos,coord,parameters_dist);

        TS_rec_loop.dist_3D_shift  = TxSite_SIZE.dist_3D_shift;
        TS_rec_loop.dist_3D        = TxSite_SIZE.dist_3D;
        TS_rec_loop.dist_avg       = TxSite_SIZE.dist_avg;
        TS_rec_loop.dist_avg_shift = TxSite_SIZE.dist_avg_shift;        
        
        TS_rec(iRun) = TS_rec_loop;

    end
end

disp(' .... ')
disp('RECONSTRUCTION FINISHED')









