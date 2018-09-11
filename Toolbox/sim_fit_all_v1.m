function table_feat_all = sim_fit_all_v1(param)


%% General parameters

%- Are the analyzed files simulated or real data? Changes how some
%  additional information is extracted, e.g. the simulated localization pattern
param.flags.is_simulation = 1;

%- Extract some properties allowing to judge the overall performance of the
%  spot detection. Usually used for experimental data
param.flags.analyze_summary = 0;  % Create summary plots allowing to judge quantification results

%- Table to save all localization features
table_feat_all = table;
i_file_proc    = 1;

%% Get information about files and autosave
file_list = param.file_list;
file_info = param.file_info; 
name_autosave = param.name_autosave;

%% Check if auto-save is present (e.g. from aborted quantification)
if exist(name_autosave)
    choice = questdlg('Should quantification be continued from auto-save?', ...
	'Analyze smFISH data', 'Yes','No','Yes');

    switch choice
        case 'Yes'
            load(name_autosave)
            i_file_proc = i_file + 1;
    end
end
    
%% Loop over all files

%- For debugging
param.features.verbose = {''} ;

%- Loop over all file
h = waitbar(0,'Please wait...');
startTime = tic; 


%- Loop over all files
for i_file = i_file_proc:length(file_list)
    
    %- For FOR loop
    dT_s         = toc(startTime);
    dT_remain    = (dT_s / i_file) * (length(file_list)-i_file);
    txt_waitbar  = ['File ', num2str(i_file),' of ' ,num2str(length(file_list)), ...
                     '; elapsed: ',num2str(round(dT_s/60)), ' min', ...
                     ', remaining: ',num2str(round(dT_remain/60)), ' min'];
    waitbar(i_file / length(file_list),h,txt_waitbar)

    %- File-name
    file_loop = file_list(i_file).name;
    [path_file, name_base] = fileparts(file_loop);
    
    %- Ignore all image files containing "MAX" in their name, these are projections
    if  isempty(strfind(file_loop, 'MAX'))

        %==================================================================
        % === Open results file from simulation to obtain outline
        outline_name = strrep(file_loop,'.tif','.txt');
        
        if ~exist(outline_name)
            disp('NO OUTLINE FILE FOUND')
            disp(outline_name)
            continue
        end
        
        %- Call function that does the actual analysis
        file_info.path_image    = path_file ;
        file_info.outline_name  = outline_name;
        
        try
            table_feat_all = analyze_smFISH_v2(file_info,param,table_feat_all);
        catch err
           disp('ERROR during mRNA detection')
           disp(' - Try to recompile one of the required toolboxes with the command: toolboxCompile')
           disp(' - Maybe your Matlab version is too old (use at least version 2015b)')
           disp(' - If problems persist, contact Florian (muellerf.research@gmail.com) and copy the error message shown below')
           disp('')
           disp(err)
        end
        
        %- Save to .mat file for autosave        
        save(name_autosave,'file_list','i_file','file_info','param');
        
        %- Close all files
        fclose('all');
    end
end

delete(h)