function info_sim = get_info_sim_v1(FQ_obj,file_info)

% Is there a comment?
if ~isempty(FQ_obj.comment)

    %- Is it a simulation?
    comment_file = FQ_obj.comment{1};
    if strfind(comment_file,'Simulation:::')

        %- Find pattern
        %  *? is a "lazy quantifier"
        [tokens,match]  = regexp(comment_file,'.*Pattern::(.*?)::.*','tokens','match');
        if isempty(tokens); info_sim.cell_label = '';
        else                info_sim.cell_label = tokens{1}{1};  end

        %- Find pattern strength
        %  *? is a "lazy quantifier"
        [tokens,match]  =  regexp(comment_file,'.*Pattern::.*?::(.*?)::.*','tokens','match');
        if isempty(tokens); info_sim.pattern_strength = '';
        else                info_sim.pattern_strength = tokens{1}{1};  end

        %- Find RNAdensity
        %  *? is a "lazy quantifier"
        [tokens,match]  = regexp(comment_file,'.*RNAdensity::(.*?):::.*','tokens','match');
        if isempty(tokens); info_sim.RNAdensity = '';
        else                info_sim.RNAdensity = tokens{1}{1};  end
        
        %- Find RNAlevel
        %  *? is a "lazy quantifier"
        [tokens,match]  = regexp(comment_file,'.*RNAlevel::(.*?):::.*','tokens','match');
        if isempty(tokens); info_sim.RNAlevel = '';
        else                info_sim.RNAlevel = tokens{1}{1};  end
        
    end
end

%==== Check if MIP is present
[path_file, name_base] = fileparts(FQ_obj.file_names.raw);
name_MIP = ['MAX_',name_base,'.tif'];
info_sim.name_MIP_full = fullfile(file_info.path_image,name_MIP);
if ~exist(info_sim.name_MIP_full); info_sim.name_MIP_full = []; end


%=== Get folders to save results of spot detection and localization features
full_file = fullfile(file_info.path_image,FQ_obj.file_names.raw);

%- Change folder to get to the detection folder
file_loop_detect = strrep(full_file,file_info.path_parent,file_info.path_parent_results);
path_detect_new = fileparts(file_loop_detect);
if ~exist(path_detect_new); mkdir(path_detect_new); end
info_sim.path_results = path_detect_new;

%- Change folder to get to the detection folder
file_loop_localize = strrep(full_file,file_info.path_parent,file_info.path_parent_localization);
path_loc_new = fileparts(file_loop_localize);
if ~exist(path_loc_new); mkdir(path_loc_new); end
info_sim.path_results_localization = path_loc_new;