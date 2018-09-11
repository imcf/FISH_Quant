function handles  = create_subset_table_v1(handles)
%% Function to update the table to process (gene and features)

%- Get the table with features 
loc_features      = handles.loc_features; 

%- Only keep the cells that have more mRNA than a threshold
n_RNA_lim         = get(handles.nRNA_lim, 'String'); 
loc_features      = loc_features(loc_features.nRNA > str2num(n_RNA_lim),:); 

%- Only keep the cell of the selected genes
gene_selected               = getappdata(0, 'gene_selected');
ind_gene                    = cellfun(@(x) strcmp(x, gene_selected),loc_features.gene_name, 'UniformOutput', 0);
temp_mat                    = cell2mat(ind_gene); 
ind_gene                    = sum(temp_mat,2)>0;
loc_features_gene_selected  = loc_features(ind_gene,:);


%- Only keep the selected features
feature_selected = getappdata(0, 'features_selected');
a = zscore(table2array(loc_features_gene_selected(:,feature_selected))) ; 

handles.loc_features_gene_selected_feature_selected  =  array2table(a, 'VariableNames',feature_selected); 
handles.loc_features_gene_selected                   = loc_features_gene_selected ; 
