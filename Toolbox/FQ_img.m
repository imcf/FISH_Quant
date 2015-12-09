classdef FQ_img < handle
    % FQ object containing all data and routines used to fit smFISH data in
    % 3D. 
    
    properties 
        
        %- General image properties
        file_names = struct('raw', '', 'filtered', '','DAPI', '', 'TS_label', '', 'settings', '', 'settings_TS', '', 'settings_TS_detect', '');
        path_names = struct('img', '', 'settings', '','results', '','outlines', '','root', '', 'settings_TS', '','settings_TS_detect', '');
        par_microscope = struct('pixel_size',struct('xy',160, 'z', 300),'RI',1.458, 'NA', 1.25,'Em', 547, 'Ex', 583, 'type', 'widefield');
        PSF_theo
        PSF_exp
        version
        comment     % Comment
        range       % Range for planes in a mult-plane image (e.g. 4D stack)
        
        %- 3D stacks
        raw
        filt
        DAPI
        TS_label
        
        spot_avg
        spot_avg_fit
        spot_avg_os
        spot_avg_os_fit
        
        %-- Projections
        raw_proj_z
        filt_proj_z  
        DAPI_proj_z
        TS_label_proj_z
        
        %- Dimensions
        dim
        status_3D              = 1;  % Analysis is 3D
        
        %- mRNA 
        mRNA_prop
        
        
        %- Status updates
        status_filter          = 0;
        status_detect_val_auto = 0;  % Did an automated calculation of the thresholds already take place?
        status_detect   = 0;
        status_fit      = 0;
        status_mRNA_avg = 0;
        
        
        %=== Settings
        settings = struct('filter', '', 'detect', '', 'avg_spots', '','thresh','','fit', '','TS_quant','');
        col_par
        
        
        %- Cell geometry
        cell_prop = struct('label', {}, 'x', {}, 'y', {}, 'pos_Nuc', {}, 'pos_TS', {}, 'spots_fit', [],'spots_detected',[],'thresh',{},'sub_spots',{},'sub_spots_filt',{},'spots_proj',{},'FIT_Result',{});
    end


    %% ===== METHODS
    methods
          
        
        %% === Constructor
        function img = FQ_img
            
            img.comment = {};    % Comment
            img.range   = [];    % Range for planes in a mult-plane image (e.g. 4D stack)
            
            %- Calculate theoretical PSF
            img.calc_PSF_theo;
            
            %- Where to find the results
            img.col_par = FQ_define_col_results_v1; %- Columns of results file  
            
            %=====  SETTINGS FOR MATURE DETECTION
                     
            %- Default filter settings
            img.settings.filter.method = '3D_LoG';
            
            % For 2xGauss  [3D_2xGauss]
          
            img.settings.filter.kernel_size.bgd_xy = 5;
            img.settings.filter.kernel_size.bgd_z  = 5;
            img.settings.filter.kernel_size.psf_xy = 0.5;
            img.settings.filter.kernel_size.psf_z  = 0.5;         
   
            % For LoG       [3D_2xGauss]
            img.settings.filter.LoG_H     = 5;            
            img.settings.filter.LoG_sigma = 1;
            
            %- Default detection settings
            img.settings.detect.reg_size.xy = round(2*img.PSF_theo.xy_pix)+1;       % Size of detection zone in xy 
            img.settings.detect.reg_size.z  = round(2*img.PSF_theo.z_pix)+1;       % Size of detection zone in z 
            
            %- Separate region for detection and fitting
            img.settings.detect.reg_size.xy_sep = img.settings.detect.reg_size.xy;
            img.settings.detect.reg_size.z_sep  = img.settings.detect.reg_size.z; 
               
            %- Detection 
            img.settings.detect.thresh_int   = 0;        % Minimum score of quality parameter for predetection
            img.settings.detect.thresh_score = 0;        % Minimum score of quality parameter for predetection
            img.settings.detect.score        = 'Standard deviation';
            img.settings.detect.method       = 'nonMaxSupr';

            img.settings.thresh.Spots_min_dist    = img.par_microscope.pixel_size.xy;         
          
            img.settings.detect.flags.region_smaller = 0;  % Flag to indicate if smaller region in Z can be detected
            img.settings.detect.flags.detect_region  = 0;  % Define in which regions detection should be performed (0 = cell, 1 = only ctyo, 2 = only nuc)
            img.settings.detect.flags.reg_pos_sep    = 0;
            img.settings.detect.flags.output         = 0;  % Show output
            img.settings.detect.flags.parallel       = 0;  % Parallel computing (0 - no; 1 - GPU)
            img.settings.detect.flags.auto_th        = 0;  % Automatically calculate threshold
            
            
            %=== Options for mature mRNA detection
            img.settings.detect.nTH         = 50;
            img.settings.detect.th_int_min  = 5;
            img.settings.detect.th_int_max  = 150;
            
            
            %==== Settings for spot fitting in 3D
            img.settings.fit.N_spots_fit_max = -1;  % Maximum number of spots that will be fit per cell (-1 = fit all; 0 = fit none). If spots are not fit, then the pre-detected position will be assigned. 
            img.settings.fit.flags.parallel  = 0; 
            
            % -- LIMITS FOR FIT WITH 3D GAUSSIAN 
            img.settings.fit.limits.sigma_xy_min = 0;
            img.settings.fit.limits.sigma_xy_max = round(5*img.PSF_theo.xy_nm);

            img.settings.fit.limits.sigma_z_min = 0;
            img.settings.fit.limits.sigma_z_max = round(5*img.PSF_theo.z_nm);

            img.settings.fit.limits.sigma_xy_min_def = img.settings.fit.limits.sigma_xy_min;
            img.settings.fit.limits.sigma_xy_max_def = img.settings.fit.limits.sigma_xy_max;

            img.settings.fit.limits.sigma_z_min_def = img.settings.fit.limits.sigma_z_min;
            img.settings.fit.limits.sigma_z_max_def = img.settings.fit.limits.sigma_z_max;
            
                    
            %==========================================================================
            % Transcription site (TS)
            %==========================================================================

            %=====  SETTINGS FOR TS detection
            img.settings.TS_detect.conn     = 26;
            img.settings.TS_detect.min_dist = 10;         % Minimum distance between identified components
 
            %- Size of detection region
            img.settings.TS_detect.size_detect.xy_nm     = 200;
            img.settings.TS_detect.size_detect.z_nm      = 500;

            %- Number of detected sites
            img.settings.TS_detect.N_max_TS_total     = 100;  % Maximum number of detected TS per image
            img.settings.TS_detect.N_max_TS_cell      = 4;    % Maximum number of detected TS per cell

            %- Offset between detected site (with TS label) and FISH
            img.settings.TS_detect.dist_max_offset               = 0;       % Maximum offset [nm] around each TS to find brightest pixel (for LacI)
            img.settings.TS_detect.dist_max_offset_FISH_min_int  = 100000;  % Minimum intensity the FISH signal must have to be considered                      
                       
            %=====  SETTINGS FOR TS QUANTIFICATION
            img.settings.TS_quant.flags.quant_simple_only = 1;  % By default only integrated intensity comparison
            
            img.settings.TS_quant.flags.placement = 2;
            img.settings.TS_quant.flags.quality   = 2;
            img.settings.TS_quant.N_Run_analysis = 500;
            img.settings.TS_quant.N_reconstruct   = 100;
            img.settings.TS_quant.N_run_prelim   = 5;
            img.settings.TS_quant.nBins          = 50;
            img.settings.TS_quant.per_avg_bgd    = 0.95;
            img.settings.TS_quant.crop_image.xy_nm = 500;
            img.settings.TS_quant.crop_image.z_nm  = 1000;
            img.settings.TS_quant.factor_Q_ok      = 1.5;
            
            %= Background auto calculation 
            img.settings.TS_quant.bgd_N_bins            = 10;
            img.settings.TS_quant.bgd_fact_min          = 3;
            img.settings.TS_quant.bgd_fact_max          = 1;
            
            %= Cropping
            img.settings.TS_quant.crop_image.xy_nm      = 500;
            img.settings.TS_quant.crop_image.z_nm       = 1000;

            %= Various flags to control detection
            img.settings.TS_quant.flags.posWeight   = 1;   % 1 to recalc position weighting vector after placement of each PSF, 0 to use only image of TS
            img.settings.TS_quant.flags.bgd_local   = 2;   % For local background measurement from actual image, 1 with defined threshold, 2 from actual image of cell or nucleus
            img.settings.TS_quant.flags.crop        = 1;   % [0] no crop, [1] specified size, [2] padding (for simulated sites)
            img.settings.TS_quant.flags.psf         = 2;   % 1: model, 2: image
            img.settings.TS_quant.flags.shift       = 1;   % Shift yes (1) - no (0)  


            %= Control size of region to sum up pixel intensity
            img.settings.TS_quant.N_pix_sum.xy = 1;  % Size of region to sum pixel intensity for quantification
            img.settings.TS_quant.N_pix_sum.z = 1;  % Size of region to sum pixel intensity for quantification
            
            
            
            
            %==========================================================================
            % Spot averaging
            %==========================================================================

            img.settings.avg_spots.fact_os.xy = 1;
            img.settings.avg_spots.fact_os.z  = 1;
            img.settings.avg_spots.flags.bgd  = 0;
            
            %- Area to consider around the spots +/- in xy and z
            img.settings.avg_spots.crop.xy = 1+ 2*ceil(img.settings.TS_quant.crop_image.xy_nm  / img.par_microscope.pixel_size.xy);
            img.settings.avg_spots.crop.z  = 1+ 2*ceil(img.settings.TS_quant.crop_image.z_nm  / img.par_microscope.pixel_size.z);

    
            
        end 
                
        
        %% === Make new FQ_img object
        function img = reinit(img)
            %- Make new FQ object and keep experimental parameters
            img_old            = img;
            img                = FQ_img;
            img.par_microscope = img_old.par_microscope; 
            img.settings       = img_old.settings; 
            img.version        = img_old.version; 
            img.path_names     = img_old.path_names; 
            img.status_3D      = img_old.status_3D;
        end
        
        
        %% ==== Load image
        function status_file = load_img(img,file_name,img_type)
            
            %- Ask for file-name if not specified
            if isempty(file_name)
                [file_name_image,path_name_image] = uigetfile({'*.tif';'*.stk';'*.dv';'*.TIF'},'Select image');
                
                if file_name_image ~= 0
                    file_name = fullfile(path_name_image,file_name_image);
                else
                    status_file = 0;
                    return
                end
            end
            
            %- Open file
            par.range = img.range;
            par.status_3D = img.status_3D;
            [img_struct, status_file] = img_load_stack_v1(file_name,par);

            %- Continue if status is ok
            if status_file
                                                    
                %- Display results
                fprintf('\nName of loaded image: %s\n', file_name);
                
                %- Get path
                [img.path_names.img, file_name_only,ext] = fileparts(file_name);
                
                %- Dimensions
                img.dim.X             = img_struct.NX;
                img.dim.Y             = img_struct.NY;
                img.dim.Z             = img_struct.NZ;
                
                
%                 %- 2D image
%                 if ~img.status_3D && img.dim.Z > 1
% 
%                     dlg_title = ['Processing in 2D. Image has ', num2str(img.dim.Z),' frames. '];
%                     prompt    = {'Specify which image should be loaded                            :'};    
%                     num_lines = 1; def = {'1'};
%                     answer    = inputdlg(prompt,dlg_title,num_lines,def);
%                     ind_load  = str2double(answer{1});
%                     img_struct.data = img_struct.data(:,:,ind_load);
%                     img.dim.Z = 1;
%                     
%                     if ind_load < 0
%                         return
%                     end           
%                 end
                    
               %- Which type of image?
                switch img_type
                
                    case {'raw','RAW'}
                        img.raw  = uint32(img_struct.data);
                        img.file_names.raw = [file_name_only,ext];
                        
                    case {'filt','filtered'}
                        img.filt  = uint32(img_struct.data);
                        img.file_names.filtered = [file_name_only,ext];
                        
                    case {'DAPI','dapi'}
                        img.DAPI  = uint32(img_struct.data);
                        img.file_names.DAPI = [file_name_only,ext];
                        
                    case {'TS_label','ts_label'}
                        img.TS_label  = uint32(img_struct.data);
                        img.file_names.TS_label = [file_name_only,ext];             
                end
                
            else
                disp('Image not found')
                disp(file_name)
            end
       
        end
        
              
        %% ==== Save image
        function status_file = save_img(img,file_name,img_type)
            
            %- If Get file name if not specified
            if isempty(file_name)
                
                %- Get file name
                [dum, name_file] = fileparts(img.file_names.raw); 
                               
                 switch img_type
                
                    case 'raw'
                        file_name_save   = [name_file,'_raw.tif'];
                        
                    case 'filt'
                       file_name_save   = [name_file,'_filtered.tif'];    
                       
                     case 'avg_ns'
                       file_name_save   = '_mRNA_AVG_ns.tif';                        
                       
                     case 'avg_os'
                       file_name_save   = '_mRNA_AVG_os.tif';                           
                 end
                
                %- Ask user for file-name 
                [file_name_save,path_name_save] = uiputfile(file_name_save,'Specify file name to save filtered image'); 

                %- Continue only if name was defined
                if file_name_save ~= 0
                    file_name = fullfile(path_name_save,file_name_save);
                else
                    status_file = 0;
                    return;
                end
            end
            
            %- Which type of image?
            [dum, name_only,ext] = fileparts(file_name);
            
            switch img_type

                case 'raw'
                    image_save_v2(img.raw,file_name);
                    img.file_names.raw = [name_only,ext];

                case 'filt'
                   image_save_v2(img.filt,file_name);
                   img.file_names.filtered = [name_only,ext];
                   
                case 'avg_ns'
                   image_save_v2(img.spot_avg,file_name);
                              
                   
                case 'avg_os'
                   image_save_v2(img.spot_avg_os,file_name);             
                   
            end
        end
            
        
        %% ==== Load settings
        function status = load_settings(img,file_name_full)
            [img, status] = FQ_load_settings_v1(file_name_full,img);
            
            if status
                [img.path_names.settings, img.file_names.settings] = fileparts(file_name_full);
            end
        
        end
        
        
        %% ==== Load settings for TS quantification
        function [img, file_ok] = load_settings_TS(img,file_name)
            
            [img, file_ok] = FQ_TS_settings_load_v3(file_name,img);

            %- Get name of settings
            [path, name,ext] = fileparts(file_name);
            img.file_names.settings_TS = [name,ext];
            img.path_names.settings_TS = path;
            
            %- Assign averaging region
            if not(isfield(img.settings.TS_quant,'N_pix_sum'))
                img.settings.TS_quant.N_pix_sum.xy = 1;
                img.settings.TS_quant.N_pix_sum.z = 1;
            end
            
            %- Check if folder for AMP is defined
            if ~isfield(img.mRNA_prop,'AMP_path_name') || isempty(img.mRNA_prop.AMP_path_name)
                img.mRNA_prop.AMP_path_name = img.path_names.settings_TS;
            end
  
        end
        
            
        %% ==== Save settings
        function [file_save, path_save] = save_settings(img,file_name_full)
            [file_save, path_save] = FQ_save_settings_v1(file_name_full,img);
            img.file_names.settings = file_save;
            img.path_names.settings = path_save;
        
        end
         
        
        %% ==== Save settings
        function [file_save, path_save] = save_settings_TS(img,file_name_full)
            [file_save, path_save] = FQ_TS_settings_save_v9(file_name_full,img);
            img.file_names.settings = file_save;
            img.path_names.settings = path_save;
        
        end
        
        
        %% ==== Load results file
        function status_open = load_results(img,file_name_open,path_img)
  
            %- Default output
            status_open.outline = 0;
            status_open.img     = 0;
            
            %- Specify file-name if not specified
            if isempty(file_name_open)
            
                current_dir = pwd;

                if ~isempty(img.path_names.outlines)
                   cd(img.path_names.outlines)
                elseif ~isempty(img.path_names.root)
                   cd(img.path_names.root) 
                end

                %- Load file
                [file_name,path_name] = uigetfile({'*.txt'},'Select file');
                cd(current_dir)
                
                if file_name ~= 0
                    file_name_open = fullfile(path_name,file_name);
                else
                    exit
                    
                end
            else
                path_name = fileparts(file_name_open);
            end
    
            %- Load outline file and microscope parameters
            par.flag_identifier = 0;
            par.col_par         = img.col_par;
            
            [img.cell_prop, img.par_microscope, img.file_names, status_open.outline,dum,dum,img.comment] = FQ_load_results_WRAPPER_v2(file_name_open,par); 
               
            %==== Load settings
            if (isfield(img.file_names,'settings')) && ~isempty(img.file_names.settings)
                file_name_open = fullfile(path_name,img.file_names.settings);
                img.load_settings(file_name_open);
            end
            
            %==== Analyze comment
            
            if ~isempty(img.comment)
            
               for ic = 1:numel(img.comment)
                   
                   comment_loop = img.comment{ic};
                   
                   %- Check if there are substacks
                   %  They are save in the format substack_5-12, where 5-12
                   %  indicates the planes that should be considered.
                   if strfind(comment_loop,'substack')                      
                       range  = regexp(comment_loop,'substack_(?<start>\d*)-(?<end>\d*)', 'names');     
                       img.range.start = str2num(range.start);
                       img.range.end   = str2num(range.end);
                   end
   
               end
                
            end
            %- Don't open image 
            if path_img == -1
                return
            end
            
            %- Assign path with images
            if isempty(path_img)
                if     not(isempty(img.path_names.img))
                    path_img = img.path_names.img;
                elseif not(isempty(img.path_names.root))
                    path_img = img.path_names.root;                
                end
            end
            
            %- Load image file
            if ~isempty(path_img)
                status_open.img = img.load_img(fullfile(path_img,img.file_names.raw),'raw');
                
                if status_open.img
                    img.project_Z('raw','max');
                end
            else
                status_open.img = -1;
            end
        end
            
        
          %% ==== Save results file
        function [file_save, path_save] = save_results(img,name_full,parameters)
            
           %- Parameters to save results
           parameters.file_names          = img.file_names;
           parameters.cell_prop           = img.cell_prop;
           parameters.par_microscope      = img.par_microscope;

           %- Save settings if not already saved
           if isempty(img.file_names.settings)
               
               if isfield(parameters,'path_save_settings')
                   path_save_settings = parameters.path_save_settings;
               else
                   path_save_settings = parameters.path_save;
               end
                   
               file_name_full = fullfile(path_save_settings,'_FQ_settings_MATURE.txt');
               save_settings(img,file_name_full);
               
           end          
           
           [file_save, path_save] = FQ_save_results_v1(name_full,parameters);

        end      
        
        
        %% ==== Define experimental parameters
        function define_par(img)
                    
            %- Define input dialog
            dlgTitle = 'Experimental parameters';

            prompt(1) = {'Pixel-size xy [nm]'};
            prompt(2) = {'Pixel-size z [nm]'};
            prompt(3) = {'Refractive index'};
            prompt(4) = {'Numeric aperture NA'};
            prompt(5) = {'Excitation wavelength'};
            prompt(6) = {'Emission wavelength'};
            prompt(7) = {'Microscope'};

            defaultValue{1} = num2str(img.par_microscope.pixel_size.xy);
            defaultValue{2} = num2str(img.par_microscope.pixel_size.z);
            defaultValue{3} = num2str(img.par_microscope.RI);
            defaultValue{4} = num2str(img.par_microscope.NA);
            defaultValue{5} = num2str(img.par_microscope.Ex);
            defaultValue{6} = num2str(img.par_microscope.Em);
            defaultValue{7} = num2str(img.par_microscope.type);

            userValue = inputdlg(prompt,dlgTitle,1,defaultValue);

            if( ~ isempty(userValue))
                img.par_microscope.pixel_size.xy = str2double(userValue{1});
                img.par_microscope.pixel_size.z  = str2double(userValue{2});   
                img.par_microscope.RI            = str2double(userValue{3});   
                img.par_microscope.NA            = str2double(userValue{4});
                img.par_microscope.Ex            = str2double(userValue{5});
                img.par_microscope.Em            = str2double(userValue{6});                
                img.par_microscope.type    = userValue{7};     
                
            end
            
            %- Calculate theoretical PSF and show it 
            img.calc_PSF_theo;
        end
        
        
        %% ==== Calculate theoretical PSF
        function  calc_PSF_theo(img)
            [img.PSF_theo.xy_nm, img.PSF_theo.z_nm] = sigma_PSF_BoZhang_v1(img.par_microscope);
            img.PSF_theo.xy_pix = img.PSF_theo.xy_nm / img.par_microscope.pixel_size.xy ;
            img.PSF_theo.z_pix  = img.PSF_theo.z_nm  / img.par_microscope.pixel_size.z ;
        end
        
        
        %% ==== Make projection along Z
        function project_Z(img,img_type,method)
           
           
            %- Choose image type: raw
            switch img_type
               
               case 'raw'                    
   
                    switch method
               
                       case 'max'                    
                            img.raw_proj_z = max(img.raw,[],3); 

                       case 'median'                    
                            img.raw_proj_z = median(img.raw,[],3);    
                   end    
                    
                    
               %- Choose image type: filtered     
               case 'filt'                    
                    
                    switch method
               
                       case 'max'                    
                            img.filt_proj_z = max(img.filt,[],3); 

                       case 'median'                    
                            img.filt_proj_z = median(img.filt,[],3);    
                    end    
                    
               %- Choose image type: filtered     
               case {'dapi','DAPI'}                    
                    
                    switch method
               
                       case 'max'                    
                            img.DAPI_proj_z = max(img.DAPI,[],3); 

                       case 'median'                    
                            img.DAPI_proj_z = median(img.DAPI,[],3);    
                    end               
           end    

        end       
       
        
        %% === FILTER
        function status_filter = filter(img,flag)
                   
            if nargin == 1
                flag.output = 1;
            end
            
           %- Output
           status_filter = 1;
            
           %- Perform filtering
           fprintf('\n= FILTERING IMAGE with ')
           switch img.settings.filter.method
               
               %- Double Gaussian filter
               case {'3D_DoG','3D_2xGauss','2xGauss'}
                   fprintf('3D Double Gaussian filter ...')
                   flag.output = 0;
                   img.filt    = img_filter_Gauss_v5(img.raw,img.settings.filter.kernel_size,flag);        
                
               %- 3D LoG (From Battich et al., Nature Methods)           
               case '3D_LoG'
                   fprintf('3D LoG filter ...')
                   
                   % If both values are zero, don't filter
                   if img.settings.filter.LoG_H == 0 && img.settings.filter.LoG_sigma == 0
                        img.filt = img.raw;
                   else
                        filt_log = fspecialCP3D('3D LoG, Raj', img.settings.filter.LoG_H, img.settings.filter.LoG_sigma);
                        img.filt = imfilter(double(img.raw), filt_log, 'replicate') *(-1);   %- Picture is inversed & has  negative elements;
                   end
                   
               %- No valid filter found
               otherwise 
                    
                    status_filter = 0;
           end
           
           if status_filter           
                fprintf('... FINISHED. \n')
           else
               fprintf('No valide filter specified: %s\n',img.settings.filter.method) 
           end
           
           
        end
        
        
        %% ==== Detect nuclei
        function  segment_nuclei(img,par)           
                 img.cell_prop   = FQ3_segment_nuclei_v1(img,par);
        end
        
        
        %% === Make entire image one cell
        function make_one_cell(img,ind_cell)
            
            %- Dimension of entire image
            w = img.dim.X;
            h = img.dim.Y;
            
            img.cell_prop(ind_cell).x      = [1 1 w w];
            img.cell_prop(ind_cell).y      = [1 h h 1];
    
            %- Other parameters
            img.cell_prop(ind_cell).label    = 'EntireImage';
            img.cell_prop(ind_cell).pos_TS   = [];
            img.cell_prop(ind_cell).pos_Nuc  = [];
        end
        
   
        %% === TS detection: change settings
         function TS_detect_settings_change(img)
            img.settings.TS_detect = FQ_TS_settings_detect_modify_v5(img.settings.TS_detect);
         end
        
        
        %% === TS detection: save settings
        function TS_detect_settings_save(img)
            

            if ~isfield(img.settings.TS_detect,'img_det_type')
                warndlg('No settings specified. TS detection has to be performed at least once.',mfilename)
                
            else

                %- Get current directory and go to directory with results/settings
                current_dir = cd;

                if   not(isempty(img.path_names.outlines)); 
                    path_save = img.path_names.outlines;
                elseif  not(isempty(img.path_names.root)); 
                    path_save = img.path_names.root;
                else
                    path_save = cd;
                end

                cd(path_save)

                %- Save settings
                img.settings.TS_detect.path_save = path_save;
                img.settings.TS_detect.version   = img.version;

                [img.file_names.settings_TS_detect, handles.path_names.settings_TS_detect] = FQ_TS_settings_detect_save_v2([],img);

                %- Go back to original directory
                cd(current_dir) 

            end
        end
        
        
         %% === TS detection: save settings
        function status_ok = TS_detect_settings_load(img)
            
            %- Get current directory and go to directory with results/settings
            current_dir = cd;

            if    not(isempty(img.path_names.results)); 
                path_save = img.path_names.results;
            elseif  not(isempty(img.path_names.root)); 
                path_save = img.path_names.root;
            else
                path_save = cd;
            end

            cd(path_save)

            %- Get settings
            [file_name_settings,path_name_settings] = uigetfile({'*.txt'},'Select file with settings');

            if file_name_settings ~= 0
                [img.settings.TS_detect, status_ok] = FQ_TS_detect_settings_load_v2(fullfile(path_name_settings,file_name_settings),img.settings.TS_detect);

                if status_ok

                    %- Older version might not have this parameter
                    if not(isfield(img.settings.TS_detect,'dist_max_offset_FISH_min_int'))
                        img.settings.TS_detect = 0;
                    end

                end
            end
            
            cd(current_dir)
        end
        
        
        %% === TS detection: apply
        function TS_detect(img)
            img.cell_prop = FQ3_TS_detect_v2(img);
            
        end
        
        
        %% === Automated threshold calculation
        function [int_th, count_th,h_fig] = calc_auto_det_th(img,data_th,par)
            [int_th, count_th,h_fig] = FQ_th_detect_auto_v1(data_th,par);
        end
        
        
        %% === Predetect
        function [spots_detected, img_mask, CC_best, sub_spots, sub_spots_filt] = spots_predect(img,ind_cell)
            
            [spots_detected, sub_spots, sub_spots_filt, img_mask, CC_GOOD,prop_img_detect] = FQ_spots_predetect_v1(img,ind_cell);
            img.cell_prop(ind_cell).spots_detected  = spots_detected;
            img.cell_prop(ind_cell).sub_spots       = sub_spots;
            img.cell_prop(ind_cell).sub_spots_filt  = sub_spots_filt;
        end
        
        
        %% === Calculate sub-regions
        function spots_mosaic(img,ind_cell)
        
              %- Get subregions .... 
              [sub_spots, sub_spots_filt, spots_detected] = FQ_spots_moscaic_v1(img,img.cell_prop(ind_cell).spots_detected);
        
              img.cell_prop(ind_cell).spots_detected = spots_detected;
              img.cell_prop(ind_cell).sub_spots = sub_spots;
              img.cell_prop(ind_cell).sub_spots = sub_spots_filt;
       
        end
        
        
        %% === Calculate predect quality score
        function spots_detected = spots_quality_score(img,ind_cell)
                
            spots_detected                         = FQ_spots_quality_score_v1(img,ind_cell);
            img.cell_prop(ind_cell).spots_detected = spots_detected;  
        end
        
        
        %% === Apply threshold for pre-detect quality score
         function [th_counts] = spots_quality_score_apply(img,ind_cell,flag_remove)
        
             % flag_remove ... indicates if spots below quality score
             %                 should be removed (1) or not (0)

            spots_detected  = img.cell_prop(ind_cell).spots_detected;
            N_Spots         = size(spots_detected,1);    % Number of candidates 

            if N_Spots > 0

                %- Get threshold
                quality_score          = spots_detected(:,img.col_par.det_qual_score);
                detect_threshold_score = img.settings.detect.thresh_score; 
                
                %- Threshold spots
                ind_th_out  = find ( quality_score < detect_threshold_score);
                ind_all     = (1:N_Spots);
                ind_th_in   = setdiff(ind_all,ind_th_out);

                spots_detected(ind_th_in,img.col_par.det_qual_score_th)  = 1;    
                spots_detected(ind_th_out,img.col_par.det_qual_score_th) = 0; 

                %- Remove spots
                if flag_remove             
                    spots_detected(ind_th_out,:) = [];
                    img.cell_prop(ind_cell).sub_spots(ind_th_out) = [];
                end
                
                
                %- Save results
                img.cell_prop(ind_cell).spots_detected  = spots_detected;
                th_counts = [length(ind_all) length(ind_th_in) length(ind_th_out)];
                
            else
                th_counts = [0 0 0];
            end
         end
        
        
        %% === Fit spots
        function [spots_fit, FIT_Result,thresh] = spots_fit_3D(img,ind_cell)
            
            
            %- 2D or 3D fitting
            if img.status_3D
                [spots_fit, FIT_Result,thresh] = FQ_spots_fit_3D_v1(img,ind_cell);
            else
                [spots_fit, FIT_Result,thresh] = FQ_spots_fit_2D_v1(img,ind_cell);    
            end

            
            
            %- Set-up structure for thresholding
            if ~isempty(spots_fit)
                spots_detected  = img.cell_prop(ind_cell).spots_detected;

                thresh.sigmaxy.min   = min(spots_fit(:,img.col_par.sigmax));
                thresh.sigmaxy.max   = max(spots_fit(:,img.col_par.sigmax));
                thresh.sigmaxy.diff  = max(spots_fit(:,img.col_par.sigmax)) - min(spots_fit(:,img.col_par.sigmax));             

                thresh.sigmaz.min    = min(spots_fit(:,img.col_par.sigmaz));
                thresh.sigmaz.max    = max(spots_fit(:,img.col_par.sigmaz));
                thresh.sigmaz.diff   = max(spots_fit(:,img.col_par.sigmaz)) - min(spots_fit(:,img.col_par.sigmaz));             

                thresh.amp.min      = min(spots_fit(:,img.col_par.amp));
                thresh.amp.max      = max(spots_fit(:,img.col_par.amp));
                thresh.amp.diff     = max(spots_fit(:,img.col_par.amp)) - min(spots_fit(:,img.col_par.amp));             

                thresh.bgd.min      = min(spots_fit(:,img.col_par.bgd));
                thresh.bgd.max      = max(spots_fit(:,img.col_par.bgd));
                thresh.bgd.diff     = max(spots_fit(:,img.col_par.bgd)) - min(spots_fit(:,img.col_par.bgd));             

                thresh.int_raw.min  = min(spots_detected(:,img.col_par.int_raw));
                thresh.int_raw.max  = max(spots_detected(:,img.col_par.int_raw));
                thresh.int_raw.diff = max(spots_detected(:,img.col_par.int_raw)) - min(spots_detected(:,img.col_par.int_raw));             

                thresh.int_filt.min   = min(spots_detected(:,img.col_par.int_filt));
                thresh.int_filt.max   = max(spots_detected(:,img.col_par.int_filt));
                thresh.int_filt.diff  = max(spots_detected(:,img.col_par.int_filt)) - min(spots_detected(:,img.col_par.int_filt));             

                thresh.pos_z.min      = min(spots_fit(:,img.col_par.pos_z));
                thresh.pos_z.max      = max(spots_fit(:,img.col_par.pos_z));
                thresh.pos_z.diff     = max(spots_fit(:,img.col_par.pos_z)) - min(spots_fit(:,img.col_par.pos_z));             
            end
            
            %- Assign parameters
            img.cell_prop(ind_cell).spots_fit  = spots_fit;
            img.cell_prop(ind_cell).FIT_Result = FIT_Result;
            img.cell_prop(ind_cell).thresh     = thresh;
            img.cell_prop(ind_cell).status_fit = 1;  
                       
            
        end
     
        
        %%  === Filter, detect, fit       
        function status_file_ok = proc_mature_all(img,parameters)
        
            status_file_ok = FQ3_detect_fit_v1(img,parameters);
        end
        
        
        %% === Function to apply fitting thresholds
        function spots_fit_th_apply(img)
            
            %=== Get parameters that should be thresholded
            names_all = fieldnames(img.settings.thresh);   
            N_names   = size(names_all,1);

            for iC = 1:length(img.cell_prop)
                
                thresh.in = true(size( img.cell_prop(iC).spots_fit,1),1);
                
                % =====================================================================   
                % Loop over all possible thresholding parameters
                % =====================================================================  
                
                for i_name = 1:N_names
                    
                    %- Get parameter
                    par_name   = char(names_all{i_name});
                    par_fields = getfield(img.settings.thresh,par_name);
                            
                    %- Get column of data
                    col_loop = 0;
                    
                    switch par_name

                        case 'sigmaxy'
                            col_loop = img.col_par.sigmax;

                        case 'sigmaz'
                            col_loop = img.col_par.sigmaz;

                        case 'amp'
                            col_loop = img.col_par.amp;            

                        case 'bgd'
                            col_loop = img.col_par.bgd;   
                    end
                    
                    %- Continue only if col_loop is defined
                    if col_loop 
                        %- Threshold data: only if locked
                        if par_fields.lock
                            thresh_loop = img.cell_prop(iC).spots_fit(:,col_loop) >= par_fields.min_th  & img.cell_prop(iC).spots_fit(:,col_loop) <= par_fields.max_th;
                            thresh.in   = thresh.in & thresh_loop;
                        end
                    end
                        
                end
                
                    
                % =====================================================================   
                % Exclude spots that are too close
                % =====================================================================  

                %- Mask with relative distance and matrix with radius
                data    = img.cell_prop(iC).spots_fit(:,1:3);
                N_spots = size(data,1);
                dum        = [];
                dum(1,:,:) = data';
                data_3D_1  = repmat(dum,[N_spots 1 1]);
                data_3D_2  = repmat(data,[1 1 N_spots]);

                d_coord = data_3D_1-data_3D_2;

                r = sqrt(squeeze(d_coord(:,1,:).^2 + d_coord(:,2,:).^2 + d_coord(:,3,:).^2)); 

                %- Determine spots that are too close
                r_min =  img.settings.thresh.Spots_min_dist;

                mask_close          = zeros(size(r));
                mask_close(r<r_min) = 1;
                mask_close_inv      = not(mask_close);

                %- Mask with intensity ratios
                data_int     = img.cell_prop(iC).spots_detected(:,img.col_par.int_raw);
                mask_int_3D1 = repmat(data_int,1,N_spots);
                mask_int_3D2 = repmat(data_int',N_spots,1);

                mask_int_ratio = mask_int_3D2 ./ mask_int_3D1;

                %- Find close spots and remove the ones with the dimmest pixel
                m_diag = logical(diag(1*(1:N_spots)));

                mask_close_spots = mask_int_ratio;
                mask_close_spots(mask_close_inv) = inf;  % Set all spots that are not too close to inf 
                mask_close_spots(m_diag)         = inf;  %- Set diagonal to inf;

                %- Find ratios of spot that are <= 1 
                [row,col] = find(mask_close_spots <= 1);
                ind_spots_too_close2 = unique(col(2:end));

                thresh_dist = true(size( img.cell_prop(iC).spots_fit,1),1);
                thresh_dist(ind_spots_too_close2) = false;
                
              

                %=== Combine info about thresholding and spatial distance
                thresh.in = thresh.in & thresh_dist;
                
                %=== Out are all the ones that are not in
                thresh.out               = ~(thresh.in);                    
                img.cell_prop(iC).thresh = thresh;
  
                fprintf('Number of spots after thresholding: %g\n', sum(thresh.in))
                
            end
            
        end
        
             
        %%  == Thresholds: reset locks
        function  th_lock_reset(img)
            img.settings.thresh.sigmaxy.lock = 0; 
            img.settings.thresh.sigmaz.lock  = 0;
            img.settings.thresh.amp.lock     = 0; 
            img.settings.thresh.bgd.lock     = 0;               
            img.settings.thresh.pos_z.lock   = 0;
            img.settings.thresh.int_raw.lock = 0;               
            img.settings.thresh.int_filt.lock= 0;
        end
        
        
        %%  === Function to define parameters for spot averaging
        function status_change = define_par_avg(img)
        
            dlgTitle = 'Parameters for averaging';

            prompt_avg(1) = {'Size of region around center [XY]'};
            prompt_avg(2) = {'Size of region around center [Z]'};
            prompt_avg(3) = {'Factor for oversampling [XY]'};
            prompt_avg(4) = {'Factor for oversampling [Z]'};
            prompt_avg(5) = {'Background subtracted form each spot (Y=1, N=0)'};

            defaultValue_avg{1} = num2str(img.settings.avg_spots.crop.xy);
            defaultValue_avg{2} = num2str(img.settings.avg_spots.crop.z);
            defaultValue_avg{3} = num2str(img.settings.avg_spots.fact_os.xy);
            defaultValue_avg{4} = num2str(img.settings.avg_spots.fact_os.z);
            defaultValue_avg{5} = num2str(img.settings.avg_spots.flags.bgd);

            userValue = inputdlg(prompt_avg,dlgTitle,1,defaultValue_avg);

            if( ~ isempty(userValue))
                img.settings.avg_spots.crop.xy    = str2double(userValue{1});
                img.settings.avg_spots.crop.z     = str2double(userValue{2}); 
                img.settings.avg_spots.fact_os.xy = str2double(userValue{3});
                img.settings.avg_spots.fact_os.z  = str2double(userValue{4});     
                img.settings.avg_spots.flags.bgd    = str2double(userValue{5}); 
                
                status_change = 1;
            else
                status_change = 0;
            end
        end
        
        
        %%  === Function to average all spots 
        function [spot_avg, spot_avg_os,pixel_size_os,img_sum] = avg_spots(img,ind_cell,img_sum)
                       
            [spot_avg, spot_avg_os,pixel_size_os,img_sum] = spot_3D_avg_v1(img,ind_cell,img_sum);

           %- Save results 
           if not(isempty(spot_avg))
                img.par_microscope.pixel_size_os = pixel_size_os;
                img.spot_avg                     = spot_avg;
                img.spot_avg_os                  = spot_avg_os;
           end
       
        end
        
        
        %%  === Function to average all spots 
        function  avg_spots_plot(img)       
            spot_3D_avg_plot_v1(img)
        end
        
        
       %% === Function to load PSF image
       function img = load_mRNA_avg(img,file_name)
       
           
           if isempty(file_name)
           
               %- Get current directory and go to directory with results/settings
                current_dir = cd;

                if    not(isempty(img.path_names.results)); 
                    path_load = img.path_names.results;
                elseif  not(isempty(img.path_names.root)); 
                    path_load = img.path_names.root;
                else
                    path_load = cd;
                end

                cd(path_load)

                %- Load PSF & go back to original directory
                [PSF_file_name,PSF_path_name] = uigetfile('.tif','Select averaged image of mRNA,','MultiSelect','off');
                cd(current_dir) 

           else
               [PSF_path_name,PSF_file_name,ext] = fileparts(file_name);
               PSF_file_name                     = [PSF_file_name,ext];
               
           end
               

            if PSF_file_name ~= 0
                img.mRNA_prop.file_name = PSF_file_name;
                img.mRNA_prop.path_name = PSF_path_name; 
                
                %- Same cropping as for TS quant
                par_crop_TS                     = img.settings.TS_quant.crop_image;
                pixel_size                      = img.par_microscope.pixel_size;
                parameters.par_crop_NS_quant.xy = ceil(par_crop_TS.xy_nm / pixel_size.xy);
                parameters.par_crop_NS_quant.z  = ceil(par_crop_TS.z_nm / pixel_size.z);

                %- Sum of pixels
                parameters.N_pix_sum            = img.settings.TS_quant.N_pix_sum;

                %- Same cropping as for detection
                parameters.par_crop_NS_detect = img.settings.detect.reg_size;
                
                %- Load and analyze average mRNA image    
                parameters.flags.output = 0;
                parameters.flags.norm   = 0;      
                img                     = FQ_analyze_mRNA_avg_v1(img,parameters); 

                img.status_mRNA_avg = 1;
                
             end
       end 
    end
end

