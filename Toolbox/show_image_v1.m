function show_image_v1(handles)
%% Function to display images in the GUI

%- Get some parameters from main interface
status_show_det =  get(handles.show_detections, 'Value');

%-- Get the subset of the database corresponding to the selected group on
data_feature_subset = handles.data_feature_subset;

%- Get the name of the projection and load it
MIP_name  = data_feature_subset(handles.ind_image_navigation,:).name_img_MIP;

if isempty(MIP_name) || ~exist(MIP_name{1})
    disp('No projection found')
    disp(MIP_name{1})
    return
end

im  = imread(MIP_name{1});

%- Load results of GMM detection
file_GMM  = data_feature_subset(handles.ind_image_navigation,:).results_GMM;

FQ_obj = FQ_img;
flags_load.load_settings = 0;
flags_load.use_tiffread = 0;
status = FQ_obj.load_results(file_GMM{1},[],flags_load);

if ~(status.outline == 1)
    disp('Outline can not be opened')
    disp(file_GMM{1})
    return
end

%- Get RNA positions in pixel
RNA_pos_pix = FQ_obj.cell_prop(1).spots_fit(:,1:2)  / FQ_obj.par_microscope.pixel_size.xy;

%- Get position of cell and nucleus
cell_x = FQ_obj.cell_prop(1).x;
cell_y = FQ_obj.cell_prop(1).y;

nuc_x = FQ_obj.cell_prop(1).pos_Nuc.x;
nuc_y = FQ_obj.cell_prop(1).pos_Nuc.y;

%% Display the image with or without the mRNA detection
axes(handles.axes2);
imshow(im,[])
hold on
plot(cell_x, cell_y, 'col', 'red')
plot(nuc_x, nuc_y, 'col', 'blue')
if status_show_det
    plot(RNA_pos_pix(:,2) , RNA_pos_pix(:,1) , '+','col', 'red')
end
hold off
