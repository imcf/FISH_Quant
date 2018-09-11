function handles = Number_classes_v1(handles)

%- Test of how many classes are relevant in the clustering
    
   
if get(handles.classif_tSNE, 'Value')
    
    
    
    if isempty(handles.data_tSNE_classif) %- test if the t-SNE is already done
        
        n_t_SNE                   = str2num(get(handles.n_tSNE, 'String'));
        data_tSNE_classif         = tsne(table2array(handles.loc_features_gene_selected_feature_selected) ,[],n_t_SNE, size(handles.loc_features_gene_selected_feature_selected,2),25);
        handles.data_tSNE_classif = data_tSNE_classif;
        
    else
        
%- Get the data in the tSNE space

        data_tSNE_classif               = handles.data_tSNE_classif;
        handles.data_tSNE_classif = data_tSNE_classif;
    end
    
    
    
else
    
    data_tSNE_classif = table2array(handles.loc_features_gene_selected_feature_selected) ;
    handles.data_tSNE_classif = data_tSNE_classif;
end
    
    
    
%- silhouette method 

ind_sil = [] ;
for i = 1:10
    
    idx                             = kmeans(data_tSNE_classif,i,'Replicates',50);
    sil = silhouette(data_tSNE_classif,idx);
    ind_sil(i) = mean(sil);
    
end

figure
subplot(3,3,1)
plot(1:10, ind_sil)
ylim([0 1])
title('Silouhette')


%- GMM BIC method 


AIC = [] ;
for i = 1:10
    
    GMModel = fitgmdist(data_tSNE_classif,i)
    AIC(i) = GMModel.AIC;
    BIC(i) = GMModel.BIC;

    
end


subplot(3,3,2)
plot(1:10, AIC)
title('AIC GMM')


subplot(3,3,3)
plot(1:10, BIC)
title('BIC GMM')


%- kmeans BIC method 


% 
% BIC = [] ; 
% 
% 
% for i_clust = 1:10
% i_clust
%     [idx  C]                           = kmeans(data_tSNE_classif,i_clust,'Replicates',50);
% 
%    
%     % assign centers and labels
%     centers = C;
%     labels  = idx;
%     
%     m       = i_clust;
%     
%     % size of the clusters
%     
%     
%     clust_vect = repmat(1:m,length(idx),1);
%     idx_mat    = repmat(idx, 1, m)  ; 
%     n          = sum(idx_mat == clust_vect);
%              
%     %size of data set
%     [N d] = size(data_tSNE_classif);
% 
%     %compute variance for all clusters beforehand
%     var_clust   = [];      
%     for i_class = 1:m
%         
%         var_clust(i_class)= sum(distmat(data_tSNE_classif(idx == i_class,:), C(i_class,:)).^2);
%         
%     end
%     
%     
%     cl_var =   (1 / (N - m) / d)*sum(var_clust);
%     const_term = 0.5 * m *log(N) * (d+1);
%     
%     bic_term = [] ; 
%     for i_class = 1:m
%         
%         bic_term(i_class) = n(i_class) + log(n(i_class)) - n(i_class)*log(N) - ((n(i_class)*d)/2)*log(2*pi*cl_var) - ((n(i_class) - 1)*d/2);
%         
%     end
%     
%     BIC(i_clust) = sum(bic_term) - const_term;
%     
%     
% 
% end     
%              
%              
%              
% subplot(3,3,4)
% plot(BIC)
% title('BIC kmeans')
%              
%              

%- Elbow method


AIC       = [] ;
within_SS = [] ; 

for i_clust = 1:10
    
    
    m = i_clust ;
    idx            = kmeans(data_tSNE_classif,i_clust,'Replicates',50);
    n              = [] 
    centroid_all   = mean(data_tSNE_classif)
    
    
    
    clust_vect = repmat(1:m,length(idx),1);
    idx_mat    = repmat(idx, 1, m); 
    n          = sum(idx_mat == clust_vect);
    
    
    centroid_clust = [] ; 
    
    for i_class=1:i_clust        
        centroid_clust(i_class,:) = mean(data_tSNE_classif(idx == i_class,:))            
    end
    
%     
%     within_dist = sum((centroid_clust - repmat(centroid_all,size(centroid_clust,1),1)).^2,2) 
%     group_var   = sum(transpose(n).*within_dist)/(i_clust-1)
%     
    tot_var_group_tot =[]; 
    
    for i_class=1:i_clust                
        
        tot_var_group     = distmat(data_tSNE_classif(idx == i_class,:), centroid_clust(i_class,:)).^2    ; 
        tot_var_group_tot = [ tot_var_group_tot ; tot_var_group ] ; 
        
    end
    
    
    
    tot_var = sum(tot_var_group_tot);
   
    within_SS(i_clust) = tot_var; 
    
    
    
end



subplot(3,3,5)
plot(within_SS)
title('Within varibility')



dist_mat_data = pdist(data_tSNE_classif);
Z             = linkage(data_tSNE_classif);











