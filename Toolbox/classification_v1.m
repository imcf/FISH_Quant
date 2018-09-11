function handles = classification_v1(handles)
%%% Function to perform the classification of the cells

%% Get the different features
tableFeatures     = getappdata(0,'tableFeatures');
tableInfo         = getappdata(0,'tableInfo');
features_selected = getappdata(0,'features_selected'); 
feature_names_all = getappdata(0,'feature_names_all'); 
pattern           = handles.pattern;

%% Get the parameter ( pattern degree, mRNA density ) and build the database

%- Get sub-table with only the selected features & add table with info
%  Will be used to select only user-defined sub-sets
n_Features          = length(features_selected);
tabelFeatures_sel   = tableFeatures(:,features_selected);
tableFeatures       = [tabelFeatures_sel tableInfo] ;

%=== Select only cells with a given RNA densities and pattern strength

%=== RNA density - use all selected ones

%- Check if mRNA levels were defined as density (old version) or not
indexSTRING = strfind(feature_names_all, 'RNAdensity');

if ~isempty(find(not(cellfun('isempty', indexSTRING))))
    ind_density = cellfun(@(x) strcmp(x,tableFeatures.RNAdensity), handles.density_sel, 'UniformOutput', false);
    ind_density = logical(sum(cell2mat(ind_density),2));
else  
    ind_density_indiv = zeros(size(tableFeatures.RNAlevel,1),  length(handles.density_sel));
    for i=1:length(handles.density_sel)
       ind_density_indiv(:,i) = (tableFeatures.RNAlevel == str2double(handles.density_sel(i)));
    end     
    ind_density = sum(ind_density_indiv,2);
end

%- Pattern level - use all selected ones
ind_pattern = cellfun(@(x) strcmp(x,tableFeatures.pattern_strength), handles.pattern_sel, 'UniformOutput', false);
ind_pattern = logical(sum(cell2mat(ind_pattern),2));

ind_NR = cellfun(@(x) strcmp(x,tableFeatures.pattern_strength), {'NR'}, 'UniformOutput', false);
ind_NR = logical(sum(cell2mat(ind_NR),2));

%- Select only cell that 
ind_sel       = ind_density & (ind_pattern|ind_NR);
tableFeatures = tableFeatures(ind_sel,:);

%- Create array with features from the feature table
arrayFeatures   = table2array(tableFeatures(:,1:n_Features));
ind             = any(isnan(arrayFeatures), 2);
arrayFeatures(ind, :)    = [];
tableFeatures    = tableFeatures(~ind,:);

%- Renormalize data
data_normalized = zscore(arrayFeatures);

%% Perform (or not) the pre processing with t-SNE
if get(handles.tSNE, 'Value')
    n_comp = str2num(get(handles.ncomp, 'String'));
    initial_dim = min([n_Features size(data_normalized,1)]);
    data_normalized = tsne(data_normalized ,[], n_comp, initial_dim, 15);
end

ind_pattern_column  = find(cell2array(cellfun(@(x) strfind('cell_label',x), tableFeatures.Properties.VariableNames,'UniformOutput' ,0)) == 1) ;

idx          = kmeans(data_normalized,length(pattern),'Replicates',50);  % Perform k-means classification
vect_family  = [tableFeatures(:,ind_pattern_column) array2table(idx)];
num_code     = [];

%% Build the confuson matrix

%- Loop over all cells
for i_cell = 1:size(vect_family,1)
    temp = vect_family(i_cell,1).cell_label;
    
    for i_pattern = 1:length(pattern)
        if strcmp(temp, pattern{i_pattern})
            num_code(i_cell) = i_pattern;
        end 
    end
end

vect_family      = [tableFeatures(:,ind_pattern_column) array2table(idx) table(transpose(num_code))];
results_classif = [tableFeatures array2table(idx)] ;

%- Loop over all patterns
for i_pattern = 1:length(pattern)
    
    table_pattern{i_pattern} =  vect_family(vect_family(:,3).Var1 ==  i_pattern,:);
    table_class{i_pattern}   =  vect_family(vect_family(:,2).idx ==  i_pattern,:);
    
    freq_pattern{i_pattern} = tabulate(table_pattern{i_pattern}.idx);
    freq_class{i_pattern}   = tabulate(table_class{i_pattern}.Var1);
    
    
    if size(freq_pattern{i_pattern},1) < length(pattern)
        temp = repmat([0 0 0],length(pattern)-size(freq_pattern{i_pattern},1),1);
        freq_pattern{i_pattern} = [freq_pattern{i_pattern} ; temp] ;
    end
    
    if size(freq_class{i_pattern},1) < length(pattern)
        temp = repmat([0 0 0],length(pattern)-size(freq_class{i_pattern},1),1);
        freq_class{i_pattern} = [freq_class{i_pattern} ; temp] ;
    end
end

conf_mat = [] ;

for i_pattern = 1:length(pattern)
    temp     = freq_class{i_pattern} ;
    conf_mat = [conf_mat ; transpose(temp(:,2))];
end

freq       =  repmat(sum(conf_mat,1),length(pattern),1);
freq_mat   = conf_mat./freq;

class_corr  =[];

for i=1:length(pattern) - 1
    
    temp_vect         = reshape(freq_mat, numel(freq_mat),1);
    [val pos ]        = max(temp_vect);
    
    [class_corr(i,1) class_corr(i,2)] = ind2sub([length(pattern) length(pattern)],pos);
    %[pos_1 pos_2]     = ind2sub([length(pattern) length(pattern)],pos);
    %class_corr(i,1)   = pos_1;     class_corr(i,2)   = pos_2;
    
    freq_mat(class_corr(i,1),:) = 0;
    freq_mat(:,class_corr(i,2)) = 0;
end

ind             = 1:length(pattern);
ind_class_1     = ismember(ind,class_corr(:,1));
ind_class_2     = ismember(ind,class_corr(:,2));

class_corr(length(pattern),1) = find(ind_class_1 == 0) ;
class_corr(length(pattern),2) = find(ind_class_2 == 0) ;

[B, I]           = sort(class_corr(:,2));
ind_row          = class_corr(I,1);
confusion_matrix = conf_mat(ind_row,:);

confusion_matrix_perc = confusion_matrix./repmat(sum(confusion_matrix,1), size(confusion_matrix,1),1).*100;


%% Calculat the rand index
vect_tot  = [];
for i_column = 1:size(confusion_matrix,1)
    
    temp = confusion_matrix(:,i_column);
    vect_column = [] ;
    for i_row = 1:size(confusion_matrix,1)
        
        dum = i_row*ones(temp(i_row),1); 
        vect_column = [ vect_column ; dum ];
        
    end
    
    vect_tot = [ vect_tot ; vect_column ];  
end

conf_ground_truth = diag(sum(confusion_matrix));

vect_tot_GT  = [];

for i_column = 1:size(confusion_matrix,1)
    
    temp = conf_ground_truth(:,i_column);
    vect_column = [] ;
    for i_row = 1:size(confusion_matrix,1)
        
        dum = i_row*ones(temp(i_row),1);
        
        vect_column = [ vect_column ; dum ];
        
    end
    vect_tot_GT = [ vect_tot_GT ; vect_column ];
    
end

rand_index = RandIndex(vect_tot,vect_tot_GT);

%% Display the confusion matrix
ytick_cell = {} ;

for i = 1:size(confusion_matrix,1)
    ytick_cell{i} = num2str(i);
end

%- Show confusion matrix either in figure or in external window
if get(handles.checkbox_show_confusion_separate,'Value')
    figure, set(gcf,'color','w')
else
    axes(handles.axes1);
end

current_ax = gca;

%- Show confusion matrix
imagesc(confusion_matrix_perc);                  
colormap(flipud(summer)); 

textStrings = num2str(confusion_matrix_perc(:),'%.0f');  % Create strings from the matrix values
textStrings = strtrim(cellstr(textStrings));  % Remove any space padding
[x,y] = meshgrid(1:size(confusion_matrix_perc,1));   % Create x and y coordinates for the strings
hStrings = text(x(:),y(:),textStrings(:),'HorizontalAlignment','center');
midValue = mean(get(current_ax,'CLim'));  % Get the middle value of the color range
textColors = repmat(confusion_matrix_perc(:) > midValue,1,3);  
set(hStrings,{'Color'},num2cell(textColors,2)); 
set(current_ax,'XTick',1:length(pattern),...                        
    'XTickLabel',pattern,...  %   and tick labels
    'YTick',1:size(confusion_matrix_perc,1),...
    'YTickLabel',ytick_cell,...
    'TickLength',[0 0],'TickLabelInterpreter', 'none');
current_ax.XTickLabelRotation=45;
title(strcat('rand index = ',num2str(rand_index)))
freezeColors

handles.n_feature        = n_Features;
handles.results_classif = results_classif ;
handles.pattern          = pattern;
handles.ind_row          = ind_row;

%% Display the t-SNE results

if get(handles.show_tSNE,'Value')
    
    %- Perform t-SNE with 2 dimensions
    initial_dim = min([n_Features size(data_normalized,1)]);
    %data_tSNE_2D = fast_tsne(zscore(arrayFeatures) , 2, initial_dim,15,0.5);  % Faster t-sne implementation. needs to be tested more.
    data_tSNE_2D = tsne(zscore(arrayFeatures) ,[], 2, initial_dim, 15);
    
    n_pattern = length(unique(tableFeatures.cell_label)); % Get how many pattern in the table.
    
    pattern_num_code_level = [1:1:n_pattern]; % Generate a vector to code the pattern with numeric value.
    pattern_num_code       = categorical(tableFeatures.cell_label, unique(tableFeatures.cell_label),cellfun(@(x) num2str(x), num2cell(pattern_num_code_level), 'UniformOutput', 0)); % Code the pattern with numbers
    
    colormap_rndm          = distinguishable_colors(n_pattern);
    colormap_tot_GT        = zeros(numel(data_tSNE_2D(:,1)),3); % One for the GT plot
    colormap_tot_classif   = zeros(numel(data_tSNE_2D(:,1)),3); % One for the classif result plot.
    
    
    for i =1:numel(data_tSNE_2D(:,1))
        colormap_tot_GT(i,:)      = colormap_rndm(pattern_num_code(i),:); % Fill the colormap.
        colormap_tot_classif(i,:) = colormap_rndm(idx(i),:);
        
    end
  
    %- Plot t-SNE and clustering results
    figure, set(gcf,'color','w')
    subplot(1,2,1), hold all
    for i=1:n_pattern
        ind_cell = double(pattern_num_code)==pattern_num_code_level(i) ;
        scatter(data_tSNE_2D(ind_cell,1), data_tSNE_2D(ind_cell,2), 15,repmat(colormap_rndm(i,:),sum(ind_cell),1),'filled');
    end
    legend(pattern)
    title('t_SNE of cells colored by simulated pattern', 'Interpreter','none')

    subplot(1,2,2), hold all
    for i=1:n_pattern
        ind_cell = idx == pattern_num_code_level(i) ;
        scatter(data_tSNE_2D(ind_cell,1), data_tSNE_2D(ind_cell,2), 15,repmat(colormap_rndm(i,:),sum(ind_cell),1),'filled');
    end
    title('t_SNE of cells colored by classif result', 'Interpreter','none')
    
      
%     figure, set(gcf,'color','w')
%     subplot(1,2,1)
%     scatter(data_tSNE_2D(:,1), data_tSNE_2D(:,2), 15,colormap_tot_GT);
%     ylim([min(data_tSNE_2D(:,2)) - 3*n_pattern   max(data_tSNE_2D(:,2))+5]) % ymin is adjusted to let space to write the pattern identifier in the corresponding color.
%     
%     for i = 1:n_pattern
%         
%         text(1,min(data_tSNE_2D(:,2)) - 3*(i-1),pattern(i), 'Color',colormap_rndm(i,:), 'Interpreter','none') % write the pattern identifier.
%     end
%     
%     title('t_SNE of cells colored by simulated pattern', 'Interpreter','none')
%     subplot(1,2,2)
%     scatter(data_tSNE_2D(:,1), data_tSNE_2D(:,2), 15,colormap_tot_classif); % Plot the cells colored by the classification results.
%     ylim([min(data_tSNE_2D(:,2)) - 3*n_pattern   max(data_tSNE_2D(:,2))+5]) % ymin is adjusted to let space to write the pattern identifier in the corresponding color.
%     
%     title('t_SNE of cells colored by classif result', 'Interpreter','none')
end
    
    
 
    
    






