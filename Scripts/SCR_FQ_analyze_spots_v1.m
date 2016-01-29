% SCR_FQ_analyze_spots_v1

%% Specify outline files

%- Get file names
[file_results,path_results] = uigetfile('*.txt','Select files with FQ results','MultiSelect', 'on');

if ~iscell(file_results)
    dum =file_results; 
    file_results = {dum};
end
   
% Generate folder to save data
path_save = fullfile(path_results,'_FQ_post_proc');
if ~exist(path_save), mkdir(path_save), end

%%  Loop over files

img_loop = FQ_img;

if file_results{1} ~= 0 
    
    for i_file =1:length(file_results)
    
        %- Load file
        file_name_open = fullfile(path_results,file_results{i_file});
        fprintf('\n\n==== ANALYZE IMAGE %d of %d \n',i_file,length(file_results))
        disp(file_name_open)
        img_loop.reinit;
        status_load = img_loop.load_results(file_name_open,[]);
        
        %- Check if result file was opened
        if status_load.outline
            
            %- Calculate distances
            img_loop.calc_loc_features;
             
            %- Calculate integrated intensity
            img_loop.calc_intint;
            
            %- Save results                 
            parameters.path_save           = path_save;
            parameters.path_name_image     = img_loop.path_names.img;
            parameters.version             = img_loop.version;
            parameters.flag_type           = 'spots'; 
            parameters.flag_th_only        = 0;
            
            [dum, name_base] = fileparts(file_name_open);
            name_full = fullfile(path_save,[name_base,'_POSTPROC.txt']);
            img_loop.save_results_flex(name_full,parameters);
            fprintf('\nResults saved in file')
            disp(name_full)
            
        end

    end
end