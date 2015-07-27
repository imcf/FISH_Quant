function handles = FQ_populate_v1(handles)

%=== Changes values in FQ that are affected by different settings.

%== PSF values
set(handles.text_psf_theo_xy,'String',num2str(round(handles.img.PSF_theo.xy_nm)));
set(handles.text_psf_theo_z, 'String',num2str(round(handles.img.PSF_theo.z_nm)));

% %== Filtering
% set(handles.text_kernel_factor_bgd_xy,'String',num2str(handles.img.settings.filter.kernel_size.bgd_xy));
% set(handles.text_kernel_factor_bgd_z,'String',num2str(handles.img.settings.filter.kernel_size.bgd_z));
% 
% set(handles.text_kernel_factor_filter_xy,'String',num2str(handles.img.settings.filter.kernel_size.psf_xy));
% set(handles.text_kernel_factor_filter_z,'String',num2str(handles.img.settings.filter.kernel_size.psf_z));   

%== Minimum distance between spots
set(handles.text_min_dist_spots,'String',num2str(handles.img.settings.thresh.Spots_min_dist))    


%==== Set other control elements

%- Delete results of detection
set(handles.pop_up_outline_sel_cell,'Value',1);
set(handles.pop_up_outline_sel_cell,'String',' ');
set(handles.pop_up_image_spots,'Value',1);

%- Prepare figure axis
cla(handles.axes_image,'reset');
cla(handles.axes_histogram_th,'reset');
cla(handles.axes_histogram_all,'reset');
cla(handles.axes_proj_xy,'reset');
cla(handles.axes_proj_xz,'reset');
cla(handles.axes_resid_xy,'reset');

set(handles.axes_image,'Visible','off');
set(handles.axes_histogram_th,'Visible','off');
set(handles.axes_histogram_all,'Visible','off');
set(handles.axes_proj_xy,'Visible','off');
set(handles.axes_proj_xz,'Visible','off');
set(handles.axes_resid_xy,'Visible','off'); 

%- Set text for averaged PSF to zero
set(handles.text_psf_fit_sigmaX,'String', ' ');
set(handles.text_psf_fit_sigmaY,'String', ' ');
set(handles.text_psf_fit_sigmaZ,'String', ' ');
set(handles.text_psf_fit_amp,'String',    ' ');
set(handles.text_psf_fit_bgd,'String',    ' ');