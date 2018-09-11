function handles = classif_exp_v1(handles)
%%%%% Function to perform k-means clustering on experimental data
if get(handles.classif_tSNE, 'Value')
    if isempty(handles.data_tSNE_classif) %- test if the t-SNE is already done
        
        n_t_SNE                   = str2num(get(handles.n_tSNE, 'String'));
        data_tSNE_classif         = tsne(table2array(handles.loc_features_gene_selected_feature_selected) ,[],n_t_SNE, size(handles.loc_features_gene_selected_feature_selected,2),25);
        handles.data_tSNE_classif = data_tSNE_classif;
        
    else
        %- Get the data in the tSNE space
        data_tSNE_classif               = handles.data_tSNE_classif;
    end
    
else
    data_tSNE_classif = table2array(handles.loc_features_gene_selected_feature_selected) ;
end

%- Perform clustering 
n_class                      = str2num(get(handles.Kclass,'String'));
idx                          = kmeans(data_tSNE_classif,n_class,'Replicates',50);

data_classif_results         = handles.loc_features_gene_selected ;
data_classif_results.class   = idx;
handles.data_classif_results = data_classif_results;


