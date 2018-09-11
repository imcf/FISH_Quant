function classif_plot_v1(handles)

%%% Function to plot the results of the classification 
if ~isempty(handles.data_classif_results) %- Test if classification has been done
    
    n_class                          = str2num(get(handles.Kclass,'String'));
    data_classif_results             = handles.data_classif_results;
    idx = data_classif_results.class; 
    
    data_tSNE     = handles.data_tSNE;
     
    colormap_rndm        = distinguishable_colors(n_class) ; 
    colormap_tot_classif = zeros(numel(data_classif_results(:,1)),3); % One for the classif result plot.

    for i =1:numel(data_classif_results(:,1))
        colormap_tot_classif(i,:)      = colormap_rndm(idx(i),:); % Assign a color to each cell according to classif results  
    end
    
    axes(handles.axes1);
    set(gcf,'color','w')
    scatter(data_tSNE(:,1), data_tSNE(:,2), 15,colormap_tot_classif,'filled');
    %ylim([min(data_tSNE(:,2))- 3*n_gene   max(data_tSNE(:,2))+5]); % ymin is adjusted
    % ylim([min(data_tSNE(:,2)) - 3*n_gene   max(data_tSNE(:,2))+5]); % ymin is adjusted
    % for i = 1:n_gene
    %     text(1,min(data_tSNE(:,2)) - 3*(i-1),gene_selected(i), 'Color',colormap_rndm(i,:), 'Interpreter','none'); % write the pattern identifier.
    % end
    title('t_SNE of cells colored by classification results', 'Interpreter','none');
    
else
    disp('No classification results found')
end

