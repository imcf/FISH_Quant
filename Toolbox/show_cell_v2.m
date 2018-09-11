function handles = show_cell_v2(handles)

%%% Function to display the images of the cell selected on the tSNE plot

%- Get the localization features table
loc_features_gene_selected = handles.loc_features_gene_selected; 

%- Get the selected cell
cell_selected  = loc_features_gene_selected(handles.ind_point,:);

%- Get MIP
cell_proj      = imread(cell_selected.name_img_MIP{1});

%- Load the detection results of this cell
FQ_obj = FQ_img;
FQ_obj.load_results(cell_selected.results_GMM{1},[],0);

%- Get which cell to display in the detection results structure
ind_cell_selected = find(squeeze(cell2array(cellfun(@(x)strfind(x,[cell_selected.cell_name{1},'_']), {FQ_obj.cell_prop.label}, 'UniformOutput', 0))));  % Adding the underscore avoids that multiple cells are found

%- plot the cell and the mRNA detection (if chosen in the GUI) 
axes(handles.axes2);

imshow(cell_proj,[])
hold on
plot(FQ_obj.cell_prop(ind_cell_selected).x - min(FQ_obj.cell_prop(ind_cell_selected).x), FQ_obj.cell_prop(ind_cell_selected).y - min(FQ_obj.cell_prop(ind_cell_selected).y))
text(2,10,strcat(cell_selected.gene_name(1),'--',FQ_obj.cell_prop(ind_cell_selected).label), 'col', 'yellow', 'FontSize',10, 'Interpreter', 'none')

plot(FQ_obj.cell_prop(ind_cell_selected).pos_Nuc.x - min(FQ_obj.cell_prop(ind_cell_selected).x), FQ_obj.cell_prop(ind_cell_selected).pos_Nuc.y - min(FQ_obj.cell_prop(ind_cell_selected).y))
if get(handles.show_detection, 'Value')
    plot(FQ_obj.cell_prop(ind_cell_selected).spots_fit(:,2)./FQ_obj.par_microscope.pixel_size.xy - min(FQ_obj.cell_prop(ind_cell_selected).x)+2, FQ_obj.cell_prop(ind_cell_selected).spots_fit(:,1)./FQ_obj.par_microscope.pixel_size.xy - min(FQ_obj.cell_prop(ind_cell_selected).y)+2,'+')
end
hold off











