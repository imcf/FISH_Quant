function FQ_enable_controls_v1(handles)

%- Change name of GUI
if not(isempty(handles.img.file_names.raw))
    set(handles.h_fishquant,'Name', ['FISH-QUANT ', handles.img.version, ': main interface - ', handles.img.file_names.raw ]);
else
    set(handles.h_fishquant,'Name', ['FISH-QUANT ', handles.img.version, ': main interface']);
end

% ==== OUTLINE SELECTION AND IMAGEJ visualization
% Only if image was loaded

if handles.status_image
 
    %- Enable filtering or loading of filtered image
    set(handles.button_outline_define,'Enable','on')
    set(handles.button_filter,'Enable','on')
    set(handles.popup_filter_type,'Enable','on')

    set(handles.text_kernel_factor_bgd_xy,'Enable','on')
    set(handles.text_kernel_factor_bgd_z,'Enable','on')
    
    set(handles.text_kernel_factor_filter_xy,'Enable','on')
    set(handles.text_kernel_factor_filter_z,'Enable','on')

    set(handles.menu_load_image_filt,'Enable','on')    
    
    %- Enable plots in image
    set(handles.pop_up_image_select,'Enable','on')
    set(handles.button_plot_image,'Enable','on')
    set(handles.checkbox_plot_outline,'Enable','on')

else
    
    %- Disable filtering
    set(handles.button_outline_define,'Enable','off')
    set(handles.button_filter,'Enable','off')
    set(handles.popup_filter_type,'Enable','off')
    
    set(handles.text_kernel_factor_bgd_xy,'Enable','off')
    set(handles.text_kernel_factor_bgd_z,'Enable','off')
    
    set(handles.text_kernel_factor_filter_xy,'Enable','off')
    set(handles.text_kernel_factor_filter_z,'Enable','off')
    
    set(handles.menu_load_image_filt,'Enable','off') 

    %- Disable plots in image
    set(handles.pop_up_image_select,'Enable','off')
    set(handles.button_plot_image,'Enable','off')
    set(handles.checkbox_plot_outline,'Enable','off') 
end 

% ==== Outline definition
if not(isempty(handles.img.cell_prop))
    set(handles.menu_save_outline,'Enable','on')
else
    set(handles.menu_save_outline,'Enable','off')
end


% ==== Filtered image
if handles.status_filtered
    set(handles.menu_save_filtered_img,'Enable','on')
else
    set(handles.menu_save_filtered_img,'Enable','off')
end


% % ==== PSF values
if isempty(handles.img.PSF_exp)
    set(handles.pop_up_select_psf,'Enable','off')
else
    set(handles.pop_up_select_psf,'Enable','on')
end


% ==== PRE-DETECTION
% Only if image was filtered
if handles.status_filtered 
    set(handles.button_predetect,'Enable','on')
else
    set(handles.button_predetect,'Enable','off')
end

% === Cells are defined
if not(isempty(handles.img.cell_prop))
    
    set(handles.pop_up_outline_sel_cell,'Enable','on')
    
    ind_cell  = get(handles.pop_up_outline_sel_cell,'Value');
    cell_prop = handles.img.cell_prop(ind_cell);
    
    % ==== Fit
    % Only afer pre-detection
    if cell_prop.status_detect
        set(handles.button_fit_3d,'Enable','on')
    else
        set(handles.button_fit_3d,'Enable','off')
    end
    
    %===== Fit with averaged width
    str_x = (get(handles.text_psf_fit_sigmaX,'String'));
    str_y = (get(handles.text_psf_fit_sigmaY,'String'));
    str_z = (get(handles.text_psf_fit_sigmaZ,'String'));

    if not(isempty(str_x)) && not(isempty(str_y)) && not(isempty(str_z)) 
         
        %- Enable restriction of fitting parameters
        set(handles.button_fit_restrict,'Enable','on')
        
    else
        
        %- Disable restriction of fitting parameters
        set(handles.button_fit_restrict,'Enable','on')
    end
    

    % ==== After fit is done
    if cell_prop.status_fit

        %- Enable thresholding
        set(handles.button_threshold,'Enable','on')
        set(handles.pop_up_threshold,'Enable','on')
        set(handles.slider_th_min,'Enable','on')
        set(handles.slider_th_max,'Enable','on')
        set(handles.text_th_min,'Enable','on')
        set(handles.text_th_max,'Enable','on')
        set(handles.checkbox_th_lock,'Enable','on')
        set(handles.button_th_unlock_all,'Enable','on')        
        set(handles.button_visualize_matlab,'Enable','on')  
        set(handles.text_min_dist_spots,'Enable','on') 

        %- Enable plot of fitted spots
        set(handles.pop_up_image_spots,'Enable','on')

        %- Selection of different parameters of PSF
        set(handles.pop_up_select_psf,'Enable','on')
        

    else

        %- Enable thresholding
        set(handles.button_threshold,'Enable','off')
        set(handles.pop_up_threshold,'Enable','off')
        set(handles.slider_th_min,'Enable','off')
        set(handles.slider_th_max,'Enable','off')
        set(handles.text_th_min,'Enable','off')
        set(handles.text_th_max,'Enable','off')
        set(handles.checkbox_th_lock,'Enable','off')
        set(handles.button_th_unlock_all,'Enable','off')
        set(handles.button_visualize_matlab,'Enable','off')
        set(handles.text_min_dist_spots,'Enable','off') 
        
        %- Enable plot of fitted spots
        set(handles.pop_up_image_spots,'Enable','off')

        %- Selection of different parameters of PSF
        set(handles.pop_up_select_psf,'Enable','off')

    end
       
  
    %====== Averaged spot
    if handles.status_avg_settings && cell_prop.status_fit
    
        set(handles.menu_avg_calc,'Enable','on')
        set(handles.menu_avg_calc_all,'Enable','on')
    
    else
        set(handles.menu_avg_calc,'Enable','off')
        set(handles.menu_avg_calc_all,'Enable','off')
    end
    
    
    if handles.status_avg_calc;
    
            set(handles.menu_avg_fit,'Enable','on')
            set(handles.menu_spot_avg_imagej_ns,'Enable','on')
            set(handles.menu_spot_avg_imagej_os,'Enable','on')
            set(handles.menu_avg_save_os,'Enable','on')
            set(handles.menu_avg_save_ns,'Enable','on')  
            set(handles.menu_spot_avg_save,'Enable','on')


    else

            set(handles.menu_avg_fit,'Enable','off')
            set(handles.menu_spot_avg_imagej_ns,'Enable','off')
            set(handles.menu_spot_avg_imagej_os,'Enable','off')
            set(handles.menu_avg_save_os,'Enable','off')
            set(handles.menu_avg_save_ns,'Enable','off')    

    end
        
    
%- No spot results defined    
else
    
    set(handles.pop_up_outline_sel_cell,'Enable','off')
    set(handles.button_fit_3d,'Enable','off')
    set(handles.button_threshold,'Enable','off')
    set(handles.pop_up_threshold,'Enable','off')
    set(handles.button_fit_restrict,'Enable','off')
    set(handles.slider_th_min,'Enable','off')
    set(handles.slider_th_max,'Enable','off')
    set(handles.text_th_min,'Enable','off')
    set(handles.text_th_max,'Enable','off')
    set(handles.checkbox_th_lock,'Enable','off')
    set(handles.button_th_unlock_all,'Enable','off')
    set(handles.button_visualize_matlab,'Enable','off')
    set(handles.pop_up_image_spots,'Enable','off')
    set(handles.pop_up_select_psf,'Enable','off')
    set(handles.menu_avg_calc,'Enable','off')
    set(handles.menu_avg_calc_all,'Enable','off')
    set(handles.menu_avg_fit,'Enable','off')
    set(handles.menu_spot_avg_imagej_ns,'Enable','off')
    set(handles.menu_spot_avg_imagej_os,'Enable','off')
    set(handles.menu_spot_avg_save,'Enable','off')
    
end


