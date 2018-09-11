function handles = plot_tSNE(handles)
%
% %%%% Function to plot the t-SNE projection of the cellls

if ~isempty(handles.data_tSNE)
    
    data_tSNE     = handles.data_tSNE;
    
    gene_selected = getappdata(0,'gene_selected');
    n_gene        = length(gene_selected); % Get how many gene in the table.
    
    gene_num_code_level = [1:1:n_gene]; % Generate a vector to code the pattern with numeric value.
    gene_num_code       = categorical(handles.loc_features_gene_selected.gene_name, gene_selected,cellfun(@(x) num2str(x), num2cell(gene_num_code_level), 'UniformOutput', 0)); % Code the gene with numbers

    colormap_rndm = distinguishable_colors(n_gene) ; 

    colormap_tot_GT      = zeros(numel(data_tSNE(:,1)),3); % One for the GT plot
    
    for i =1:numel(data_tSNE(:,1))
        colormap_tot_GT(i,:)      = colormap_rndm(gene_num_code(i),:); % Fill the colormap.
    end

    axes(handles.axes1);
    set(gcf,'color','w')
    scatter(data_tSNE(:,1), data_tSNE(:,2), 15,colormap_tot_GT,'filled');
   title('t_SNE of cells colored by gene identity.', 'Interpreter','none');
   
    %- Make separate plot for figure legends
    figure(101), clf, set(gcf,'color','w')
    dy = 1/(n_gene-1);
    for i = 1:n_gene
        text(0,(i-1)*dy,gene_selected(i), 'Color',colormap_rndm(i,:), 'Interpreter','none'); % write the pattern identifier.
    end
    axis off
    title('Color code for gene identity.', 'Interpreter','none');
    
else
    disp('No tSNE projection found')
end

    
    
