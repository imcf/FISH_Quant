function data_tSNE = tSNE_proj_v1(handles,ntSNE)

handles.loc_features_gene_selected_feature_selected;

%%% Function to perform the tSNE projection on the loc features. This projection can then be used for the classification of the cells.  
data_tSNE      = tsne(table2array(handles.loc_features_gene_selected_feature_selected) ,[],ntSNE, size(handles.loc_features_gene_selected_feature_selected,2),25);


