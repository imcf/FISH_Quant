function show_feature_exp_v1(handles)
%%% Display the features for the currently displayed cell

ind_point    = handles.ind_point;
n_feature    = length(handles.features_selected);

feature_cell = handles.loc_features_gene_selected_feature_selected(ind_point,:);
feature_tot  = handles.loc_features_gene_selected_feature_selected;

figure, set(gcf,'color','w')

for i_feature = 1:n_feature
    
    temp_feat = table2array(feature_tot(:,i_feature));
    cell_feat = table2array(feature_cell(:,i_feature));
    
    Q_75          = quantile(temp_feat,0.75);
    Q_25          = quantile(temp_feat,0.25);
    
    for i_cell = 1:size(temp_feat,1)
        
        ind_expected_1(i_cell,:)  = temp_feat(i_cell,:) < Q_25 - 1.5*(Q_75 - Q_25);
        ind_expected_2(i_cell,:)  = temp_feat(i_cell,:) > Q_75 + 1.5*(Q_75 - Q_25);
    end
    ind_expected = ind_expected_1 + ind_expected_2;
    
    subplot(floor(sqrt(n_feature)) + 1, floor(sqrt(n_feature)) + 1,i_feature)
    boxplot(temp_feat(~ind_expected),'whisker',100)
    ylim([min(min(temp_feat(~ind_expected)), cell_feat) max(max(temp_feat(~ind_expected)), cell_feat)])
    hold on
    plot(1,cell_feat,'o','MarkerSize',4,'col','green','MarkerFacecolor','green')
    title(handles.feature_selected(i_feature), 'Interpreter', 'none')
end
    
    
    
    
