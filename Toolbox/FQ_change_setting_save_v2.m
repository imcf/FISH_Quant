function settings_save = FQ_change_setting_save_v2(settings_save)

%- User-dialog
dlgTitle = 'Options to save results of quantification';
prompt_avg(1) = {'[SUMMARY] Start-index of file-name used as identifier (relative to end)'};
prompt_avg(2) = {'[SUMMARY] End-index of file-name used as identifier (relative to end)'};

defaultValue_avg{1} = num2str(settings_save.file_id_start);
defaultValue_avg{2} = num2str(settings_save.file_id_end);

options.Resize='on';

userValue = inputdlg(prompt_avg,dlgTitle,1,defaultValue_avg,options);

%- Return results if specified
if( ~ isempty(userValue))
    settings_save.file_id_start = str2double(userValue{1});
    settings_save.file_id_end = str2double(userValue{2});
end


