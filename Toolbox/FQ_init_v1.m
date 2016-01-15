function handles = FQ_init_v1(handles)
%
% Initiate the GUI with all relevant parameter. Call populate function
% afterwards to use these values to prepare GUI. Split in two function
% occurs to allow loading of (partial settings).


%== Flags and sliders
if isfield(handles,'checkbox_th_lock')
    set(handles.checkbox_th_lock, 'Value',0);
%    set(handles.checkbox_parallel_computing, 'Value',0);

    set(handles.slider_th_min,'Value', 0)
    set(handles.text_th_min,'String', '');     

    set(handles.slider_th_max,'Value',1)
    set(handles.text_th_max,'String', '');

    %== Pop-up menus
    set(handles.pop_up_outline_sel_cell,'Value',1)
    set(handles.pop_up_outline_sel_cell,'String',{''})
end


%= Invisible plots

%- Clear the plot axes
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

%=== Plot rendering
handles.h_VTK = [];
handles.settings_rendering.factor_BGD = 1;
handles.settings_rendering.factor_int = 1;
handles.settings_rendering.flag_crop  = 1;
handles.settings_rendering.opacity    = 0.5;

%- Set some controls to their default value
set(handles.pop_up_image_select,'Value',1);
set(handles.pop_up_image_spots,'Value',1)




%- Status of current processing steps
handles.status_filtered     = 0;    % Image filterd
handles.status_image        = 0;    % Image loaded
handles.status_detect_auto  = 0;    % Did an automated threshold calculation already take place?
handles.flag_fit            = 0;    % Fit mode (0 for free parameters, 1 for fixed size parameters)

%- Status updates for averaging
handles.status_avg_settings = 0;  % Settings defined
handles.status_avg_calc     = 0;  % Average calculated
handles.status_avg_fit      = 0;  % Average calculated
