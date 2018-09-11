function setting_identifier = dlg_str_settings(default_str)
%% Specify an string that must be contained in the settings file to be considered in the analysis 
%  This is usually not the NAME of the settings files, but the folder it is stored in.

prompt = {'String within folder name to be processed:'};
dlg_title = 'Specify results folder to process';
num_lines = 1;
defaultans = {default_str};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);

if isempty(answer)
    setting_identifier = '';
else
    setting_identifier = answer{1};
end