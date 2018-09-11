function sim_localization_patterns_v1(param)

%% Ask user where data should be saved
fprintf('\n == Specify folder where simulation results should be saved\n')
folder_save_parent = uigetdir('Specify folder where simulation results should be saved');

if folder_save_parent == 0; return; end
if ~exist(folder_save_parent); mkdir(folder_save_parent); end

fprintf('Folder: %s\n', folder_save_parent)


%% Flag to decide which function to use to open images
flag_use_tiff_class = 1;

%== Should only positions be saved or also image? BY default images as well
if ~isfield(param,'flags_savePosOnly')
    param.flags_savePosOnly = 0;
end

%% Get path of this function to get default path containing library with
%  cell shapes. Change this path to consider different cell library. 
path_locFISH = fileparts(which('WRAPPER_simulate_smFISH_v1'));
path_library = fullfile(path_locFISH,'data_simulation');

%% Get basic properties of simulation
mRNA_level_struct =  param.mRNA_level;
pattern_struct    =  param.pattern;
n_cell            =  param.n_cell;  % How many cells will be simulated


%% Check if folder with Matlab file with cell outlines exists

%- Check if folder with data exists
if not(exist(path_library))
   errordlg('Folder containing date is missing. More details in command window.')
   disp(' ')
   disp('== NEED DATA TO SIMULATE CELLS ')
   disp(['Should be located in folder :',path_library])
   disp('Fore more information visit website of FISH-loc')
   return
end


%% Data needed to simulate images
if ~param.flags_savePosOnly
    
    %== Get backgroung image
    folder_img_lib = fullfile(path_library,'cropped_img');
    
    choice = questdlg('Use default folder for cropped images ?',mfilename,'Yes','No','Yes');
    if strcmp(choice,'No')
        folder_img_lib = uigetdir('Specify folder where cropped images are stored.');
        if folder_img_lib == 0; return; end
    end
    
    %== Load image of PSF used to simulate individual mRNA molecules
    file_PSF = fullfile(path_library,'PSF.tif');
    
    fprintf('\n == Loading PSF \n')
    fprintf('%s\n',file_PSF)
    
    if flag_use_tiff_class
        PSF_img = load_tif_3D(file_PSF);
    else
        PSF     = load_stack_data_v7(file_PSF);
        PSF_img = PSF.data
    end
end

%% Load library with cell shapes
file_library = fullfile(path_library,'cell_library_v2.mat');

fprintf('\n == Loading cell shape library \n')
fprintf('%s\n',file_library)
load(file_library);

n_cells_library = numel(cell_library_v2);
fprintf(' Number of cells in library: %d \n',n_cells_library)


%% Check if cell extensions where annotated
if ~isfield(cell_library_v2,'pos_extension')
    warndlg('No annotation of cell extensions. Necessary if localization to extension should be simulated. ',mfilename)
end


%% Check if auto-save is present (e.g. from crashed simulations)
name_autosave =  fullfile(folder_save_parent,'_SIM_auto_save.mat');

i_cell_sim_proc    = 1;
performPreProc  = 1;

if exist(name_autosave)
    choice = questdlg('Should simulation be continued from auto-save?', ...
	'Simulate smFISH image', 'Yes','No','Yes');

    switch choice
        case 'Yes'
            load(name_autosave)
            i_cell_sim_proc = i_cell_sim + 1;
            performPreProc = 0;
    end
end


%% Perform pre-processing 
%  Will not be performed if autosave file is loaded
if performPreProc
    
    %=== Analyze what patterns will be simulated
    pattern_names  = fieldnames(pattern_struct);
    
    fprintf('\n == Will simulate %d patterns: \n',numel(pattern_names))
    disp(pattern_names)
    
    %=== Analyze what patterns will be simulated
    mRNA_level_names  = fieldnames(mRNA_level_struct);
    
    fprintf('\n == Will simulate %d mRNA levels: \n',numel(mRNA_level_names))
    disp(mRNA_level_names)
    
    %- Determine average cell volume
    cell_vol_nm_avg = mean([cell_library_v2.vol_cell_nm]);
    
    %=== Define all cells that will be simulated
    
    i_cell_tot = 1;
    cell_prop_sim  = {};
    
    %- Loop over density
    for i_density = 1:numel(mRNA_level_names)
        
        mRNA_level_label = mRNA_level_names{i_density};
        mRNA_level       = mRNA_level_struct.(mRNA_level_label);
        
        %- Loop over pattern
        for i_pattern = 1:numel(pattern_names)
            
            %- Loop over pattern strength
            level_struct = pattern_struct.(pattern_names{i_pattern}).level;
            level_names  = fieldnames(level_struct);
            
            for i_level = 1:numel(level_names)
                
                %- Loop over individual cells
                for i_cell = 1:n_cell
                    
                    %- Which cell to use
                    ind_cell_for_sim = randi([1 n_cells_library]);
                    
                    %- For cell extension: make sure that cell has extension
                    if strcmp(pattern_names{i_pattern},'cellext') && isempty(cell_library_v2(ind_cell_for_sim).ext_prop)
                        while isempty(cell_library_v2(ind_cell_for_sim).ext_prop)
                            ind_cell_for_sim = randi([1 n_cells_library]);
                        end
                    end
                    
                    %- How many mRNAs will be placed
                    vol_cell_nm =  cell_library_v2(ind_cell_for_sim).vol_cell_nm ;
                    n_RNA       = round((vol_cell_nm/cell_vol_nm_avg)*mRNA_level(1) + poissrnd(mRNA_level(1))-mRNA_level(1));
                    
                    %- Summarize
                    cell_prop_sim(i_cell_tot).pattern_name = pattern_names{i_pattern};
                    cell_prop_sim(i_cell_tot).pattern_level = level_names{i_level};
                    cell_prop_sim(i_cell_tot).n_RNA = n_RNA;
                    cell_prop_sim(i_cell_tot).mRNA_level_label = mRNA_level_label;
                    cell_prop_sim(i_cell_tot).mRNA_level_avg   = mRNA_level(1);
                    cell_prop_sim(i_cell_tot).ind_cell_for_sim = ind_cell_for_sim;
                    i_cell_tot = i_cell_tot + 1;
                    
                end
            end
        end
    end
    
    %= Sort structure based on simulated cell
    cell_prop_sim = sortStruct(cell_prop_sim, 'ind_cell_for_sim');
    
    fprintf('\n == Will simulate %d cells \n',i_cell_tot-1)
    fprintf(' PROGRESS will be shown on a wait bar.\n')
    fprintf(' ERROR messages will be shown in command window.\n')
end

%% Loop over simulation

%- For regular for loop%
h = waitbar(0,'Please wait...');
startTime = tic;
ind_cell_for_sim_LOADED = 0;

%- Specific counter to save positions in batches.
batch_id = 1;
batch_subtract = 0;

%- Path to save erros
path_save_errors = fullfile(folder_save_parent,'_bugs');
if ~exist(path_save_errors); mkdir(path_save_errors); end

for i_cell_sim = i_cell_sim_proc:numel(cell_prop_sim)
    
    %- Progress bar
    dT_s         = toc(startTime);
    dT_remain    = (dT_s / i_cell_sim) * (numel(cell_prop_sim)-i_cell_sim);
    txt_waitbar  = ['Cell ', num2str(i_cell_sim),' of ' ,num2str(numel(cell_prop_sim)), ...
                     '; elapsed: ',num2str(round(dT_s/60)), ' min', ...
                     ', remaining: ',num2str(round(dT_remain/60)), ' min'];
    waitbar(i_cell_sim / numel(cell_prop_sim),h,txt_waitbar)
    
    
    %==== Some preparations
    
    %- Get pattern and strength
    pattern_loop     = cell_prop_sim(i_cell_sim).pattern_name;
    pattern_level    = cell_prop_sim(i_cell_sim).pattern_level ;
    mRNA_level_label = cell_prop_sim(i_cell_sim).mRNA_level_label;
    mRNA_level_avg   = cell_prop_sim(i_cell_sim).mRNA_level_avg;
    
    sim_prop = {};
    sim_prop.pattern_name  = pattern_loop;
    sim_prop.pattern_level = pattern_level;
    sim_prop.pattern_prop  = pattern_struct.(pattern_loop);
   
    %- mRNA expression level and density label
    sim_prop.n_RNA             = cell_prop_sim(i_cell_sim).n_RNA;
    sim_prop.mRNA_level_label = mRNA_level_label;
    sim_prop.mRNA_level_avg   = mRNA_level_avg;
    
    %- Get cell that will be used for simulations
    ind_cell_for_sim = cell_prop_sim(i_cell_sim).ind_cell_for_sim;
    cell_prop = cell_library_v2(ind_cell_for_sim);
    
    %=== Various steps that are only necessary when images are created
    if  ~param.flags_savePosOnly
        
        %- Folder to save
        path_save = fullfile(folder_save_parent,['mRNAlevel_',num2str(mRNA_level_avg)],pattern_loop,pattern_level);
        if ~exist(path_save); mkdir(path_save); end
        
        
        %- Load background image - unless it has already been loaded
        if ind_cell_for_sim_LOADED ~= ind_cell_for_sim
            if flag_use_tiff_class
                if ~exist(fullfile(folder_img_lib,cell_prop.name_img_BGD))
                    disp('BACKGROUND FILE NOT FOUND. Will not simulated cells')
                    disp(fullfile(folder_img_lib,cell_prop.name_img_BGD))
                    continue
                else
                    img_bgd = load_tif_3D(fullfile(folder_img_lib,cell_prop.name_img_BGD));
                end
            else
                img_bgd_struct = load_stack_data_v7(fullfile(folder_img_lib,cell_prop.name_img_BGD));
                img_bgd = img_bgd_struct.data;
            end
            
            ind_cell_for_sim_LOADED = ind_cell_for_sim;
        end
        
        cell_prop.img_bgd = img_bgd;
    end
    
    %- Simulate cells, save property structures if simulation didn't work
     try
    
        %==== Simulate mRNA positions
        sim_prop.RNA_pos = simulate_RNA_pos_v4(sim_prop, cell_prop,cell_library_info);
        
        %==== Either simulate image or save positions in structure
        if  ~param.flags_savePosOnly
            
            %==== Simulate and save actual smFISH image
            sim_prop.factor_binning = param.factor_binning;
            sim_prop.amp            = param.amp;
            sim_prop.path_save      = path_save;
            sim_prop.folder_img_lib = folder_img_lib;
            sim_prop.PSF            = PSF_img;
            sim_prop.flag_use_tiff_class = flag_use_tiff_class;
            
            simulate_smFISH_img_v2(sim_prop,cell_prop,cell_library_info);
            fclose('all');
        else
            
            sim_prop.name_img_BGD = cell_prop.name_img_BGD;
            sim_prop.cell_ID = ind_cell_for_sim;
            smFISH_sim(i_cell_sim-batch_subtract) = sim_prop;
 
        end
        
    catch err
        fprintf('\n == ERROR while simulating cell %d \n',i_cell_sim)        
        fprintf('Pattern: %s\n',pattern_loop)
        fprintf('Pattern: %s\n',pattern_level)
        fprintf('Error message: %s\n',err.message)
        fprintf('Function : %s\n',err.stack(1).name)
        fprintf('Line : %d\n',err.stack(1).line)

        %- For FOR loop
        save(fullfile(path_save_errors,['cell_',num2str(i_cell_sim)]),'sim_prop','cell_prop','cell_library_info')
     end 
    
     %- Save to .mat file for autosave   
     if  ~param.flags_savePosOnly
        save(name_autosave,'cell_prop_sim','sim_prop','i_cell_sim');
     else
         
         %- Save data in batches
         if rem(i_cell_sim,500) == 0
             
             %- Save batch
             name_save_json = fullfile(folder_save_parent,['smFISH_simulations__batch_',sprintf('%04d',batch_id),'.json']);
             savejson('',smFISH_sim,name_save_json);
             
             %- Make archive
             gzip(name_save_json)
             
             %- Delete json file
             delete(name_save_json)
             
             %- Update counters
             batch_id = batch_id + 1;
             batch_subtract = i_cell_sim;
             clear smFISH_sim
         end 
     end
end

fprintf(' FINISHED!\n')
delete(h)