function [cell_prop, par_microscope, file_names, flag_file, version] = FQ2_load_results_v1(file_name,flag_identifier)
%  flag_identifier  .... indicates if 1st column of spots results contains 
%                        an identifier that shoul be ignoredd

% Function to read in outline definition for cells



%- Check for input arguments
if nargin < 2
    flag_identifier = 0;
end


%- Prepare structure
cell_prop = struct('label', {}, 'x', {}, 'y', {}, 'pos_Nuc',{},'pos_TS', {}, 'spots_fit', {},'thresh', {},'spots_detected',{},'FIT_Result',{});
    
par_microscope  = [];

file_names.raw      = '';
file_names.filtered = '';
file_names.DAPI     = '';
file_names.TS_label = '';
file_names.settings = '';

flag_file       = 0;

ind_cell = 0;   % Initialize block index
ind_nuc  = 0;
flag_line_read = 0;

%- Detect version number
version = 'NA';
str_version = sprintf('FISH-QUANT\tv');


%- Open file
fid  = fopen(file_name,'r');

if fid == -1
    warndlg('File cannot be opened','FISH_QUANT_load_results_v11'); 
    disp(['File cannot be opened: ' , file_name])
    flag_file = 0;
else

    tline = fgetl(fid);
    
    while ischar(tline)
        
        %- Version number

        if not(isempty(strfind(tline, str_version))) 
            k = strfind(tline, sprintf('\t') );
            version = tline(k+1:end);
        end
        
        
        %- File name of raw image
        if not(isempty(strfind(tline, 'IMG_Raw'))) ||  (not(isempty(strfind(tline, 'FILE'))) &&  isempty(strfind(tline, 'FILE_settings')))
            k = strfind(tline, sprintf('\t') );
            file_names.raw = tline(k+1:end);
            flag_file = 1;
        end
        
        %- File name of filtered image
        if not(isempty(strfind(tline, 'IMG_Filtered'))) ||  not(isempty(strfind(tline, 'FILTERED')))
            k = strfind(tline, sprintf('\t') );
            file_names.filtered  = tline(k+1:end);          
        end        
        
        %- File name of DAPI
        if not(isempty(strfind(tline, 'IMG_DAPI')))
            k = strfind(tline, sprintf('\t') );
            file_names.DAPI = tline(k+1:end);          
        end
        
        %- File name of file to locate TS
        if not(isempty(strfind(tline, 'IMG_TS_label')))
            k = strfind(tline, sprintf('\t') );
            file_names.TS_label = tline(k+1:end);          
        end   
        
        %- File name of file to locate TS
        if not(isempty(strfind(tline, 'FILE_settings'))) ||  not(isempty(strfind(tline, 'ANALYSIS-SETTINGS')))
            k = strfind(tline, sprintf('\t') );
            file_names.settings = tline(k+1:end);          
        end       
        
 
        %- Parameters
        if not(isempty(strfind(tline, 'PARAMETERS')))
 
            %- Header row
            tline = fgetl(fid);
            
            %- Row with actual numbers
            C = textscan(fid,'%f32',6,'delimiter','\t');
            par_microscope.pixel_size.xy  = double(C{1}(1));
            par_microscope.pixel_size.z   = double(C{1}(2));
            par_microscope.RI  = double(C{1}(3));
            par_microscope.Ex  = double(C{1}(4));
            par_microscope.Em  = double(C{1}(5));
            par_microscope.NA  = double(C{1}(6));

            C = textscan(fid,'%s',1,'delimiter','\n');
            par_microscope.type = char(C{1});   
        end
           
        
        %- Find cells
        if not(isempty(strfind(tline, 'CELL')))
                
            %=== Change index
            ind_cell = ind_cell + 1;
            ind_nuc  = 0;
            ind_TS   = 0;
            
            %=== Identifier of cell
            k = strfind(tline, sprintf('\t') );
            cell_label = tline(k+1:end); 
            cell_prop(ind_cell).label = cell_label;    

            %- Polygon of cell: x- coordinates
            tline = fgetl(fid);
            k     = strfind(tline, sprintf('\t') );
            x_pos = str2num(tline(k(1)+1:k(end)-1));
            cell_prop(ind_cell).x = x_pos;

            %- Polygon of cell: x- coordinates
            tline = fgetl(fid);
            k     = strfind(tline, sprintf('\t') );
            y_pos = str2num(tline(k(1)+1:k(end)-1));
            cell_prop(ind_cell).y = y_pos;
        end
        
        
        %- Find nucleus
        if not(isempty(strfind(tline, 'Nucleus')))
                
            ind_nuc = ind_nuc + 1;
            
            %=== Identifier of cell
            k = strfind(tline, sprintf('\t') );
            nuc_label = tline(k+1:end);
            cell_prop(ind_cell).pos_Nuc(ind_nuc).label = nuc_label;

            %- Polygon of cell: x- coordinates
            tline = fgetl(fid);
            k     = strfind(tline, sprintf('\t') );
            x_pos = str2num(tline(k(1)+1:k(end)-1));
            cell_prop(ind_cell).pos_Nuc(ind_nuc).x = x_pos;

            %- Polygon of cell: x- coordinates
            tline = fgetl(fid);
            k     = strfind(tline, sprintf('\t') );
            y_pos = str2num(tline(k(1)+1:k(end)-1));
            cell_prop(ind_cell).pos_Nuc(ind_nuc).y = y_pos;
       
        end
           
       %- Find TxSite
        if not(isempty(strfind(tline, 'TxSite')))
                
            ind_TS = ind_TS + 1;
            
            %=== Identifier of cell
            k = strfind(tline, sprintf('\t') );
            TS_label = tline(k+1:end); 
            cell_prop(ind_cell).pos_TS(ind_TS).label = TS_label;

            %- Polygon of cell: x- coordinates
            tline = fgetl(fid);
            k     = strfind(tline, sprintf('\t') );
            x_pos = str2num(tline(k(1)+1:k(end)-1));
            cell_prop(ind_cell).pos_TS(ind_TS).x = x_pos;

            %- Polygon of cell: x- coordinates
            tline = fgetl(fid);
            k     = strfind(tline, sprintf('\t') );
            y_pos = str2num(tline(k(1)+1:k(end)-1));
            cell_prop(ind_cell).pos_TS(ind_TS).y = y_pos;
        end  
        

        %- Results of spot detection
        if not(isempty(strfind(tline, 'SPOTS')))
                        
            spots_par  = [];
            iSpot      = 1;
            flag_line_read = 1;
            
            %- Header row
            tline = fgetl(fid);
            
            k     = strfind(tline, sprintf('\t') );
            N_col = length(k) + 1;
            
            %- First line of detected spots
            tline     = fgetl(fid);
            tline_num = str2num(tline); 
            
            while length(tline_num) == N_col
                
                spots_par(iSpot,:) = tline_num;
             	
                %- Get next line
                tline = fgetl(fid);
                
                if not(ischar(tline))
                    tline_num = [];
                else
                    tline_num = str2num(tline); 
                end
                
                %- Update counter for spots
                iSpot = iSpot + 1;     
            end
        
            %=== Assign values
            
            %- 1st col contains NO identifier
            if ~flag_identifier
                cell_prop(ind_cell).spots_fit       = spots_par(:,1:16);
                cell_prop(ind_cell).spots_detected  = spots_par(:,17:30);

                if N_col == 31
                    cell_prop(ind_cell).thresh.in       = (spots_par(:,31));
                    cell_prop(ind_cell).thresh.all      = ones(size(spots_par(:,31)));
                    
                elseif N_col == 32
                    cell_prop(ind_cell).spots_in_nuc    = (spots_par(:,31));
                    cell_prop(ind_cell).thresh.in       = (spots_par(:,32));
                    cell_prop(ind_cell).thresh.all      = ones(size(spots_par(:,32)));
                end 
            
            %- First col contains identifier 
            else
                cell_prop(ind_cell).identifier      = spots_par(:,1);
                cell_prop(ind_cell).spots_fit       = spots_par(:,2:17);
                cell_prop(ind_cell).spots_detected  = spots_par(:,18:31);

                if N_col == 31
                    cell_prop(ind_cell).thresh.in       = (spots_par(:,31));
                    cell_prop(ind_cell).thresh.all      = ones(size(spots_par(:,31)));
                elseif N_col == 32
                    cell_prop(ind_cell).spots_in_nuc    = (spots_par(:,31));
                    cell_prop(ind_cell).thresh.in       = (spots_par(:,32));
                    cell_prop(ind_cell).thresh.all      = ones(size(spots_par(:,32)));
                end                   
            end
        end
        
                
        
        %- Read line unless already read
        if not(flag_line_read)
            tline = fgetl(fid);
        else
            flag_line_read = 0;
        end
        
        
    end
end

fclose(fid);        
       
                
                
         
   



