function show_feature_v1(handles)

%%% Function to display the distribution (boxplot) of the features around
%%% the selected cell ( one with image displayed). The distribution of each
%%% features are plotted for the cells with random pattern, the cells with
%%% the same simulated pattern as the selected cell, and the cell that
%%% belong to the family of the selected cell ( from k-means results).


feature_current_cell =   handles.data_feature_subset(handles.ind_image_navigation,1:handles.n_feature);
columnname           =   feature_current_cell.Properties.VariableNames;
data_random          =   handles.results_classif(strcmp(handles.results_classif.cell_label,'random'),:);

%% Remove outliers
%  We remove outliers from the data to generate better boxplots. This is
%  for plotting purposes only. The problem occurs since the boxplot
%  function in Matlab is not well designed to not show outliers. 

% Definition of outliers follows the default definition of Matlab
data_expected = table2array(handles.data_true_subset(:,1:handles.n_feature));
data_result   = table2array(handles.data_feature_subset(:,1:handles.n_feature));
data_random   = table2array(data_random(:,1:handles.n_feature));

ind_data_exist     = double(size(data_result,1) >0)*double(size(data_random,1) >0)*double(size(data_expected,1) >0);
ind_expected_exist = double(size(data_expected,1) >0);
ind_result_exist   = double(size(data_result,1) >0);

if ind_expected_exist
    
    Q_75          = quantile(data_expected,0.75,1);
    Q_25          = quantile(data_expected,0.25,1);
    
    for i_cell_expected = 1:size(data_expected,1)
        
        ind_expected_1(i_cell_expected,:)  = data_expected(i_cell_expected,:) < Q_25 - 1.5*(Q_75 - Q_25);
        ind_expected_2(i_cell_expected,:)  = data_expected(i_cell_expected,:) > Q_75 + 1.5*(Q_75 - Q_25);  
    end
    ind_expected = ind_expected_1 + ind_expected_2;
end

if ind_result_exist
    
    Q_75         = quantile(data_result,0.75,1);
    Q_25         = quantile(data_result,0.25,1);
    
    for i_cell_result = 1:size(data_result,1)
        ind_result_1(i_cell_result,:)  = data_result(i_cell_result,:) < Q_25 - 1.5*(Q_75 - Q_25);
        ind_result_2(i_cell_result,:)  = data_result(i_cell_result,:) > Q_75 + 1.5*(Q_75 - Q_25);
    end
    ind_result = ind_result_1 + ind_result_2;
    
end

Q_75       = quantile(data_random,0.75,1);
Q_25       = quantile(data_random,0.25,1);

for i_cell_random = 1:size(data_random,1)
    ind_random_1(i_cell_random,:)  = data_random(i_cell_random,:) < Q_25 - 1.5*(Q_75 - Q_25);
    ind_random_2(i_cell_random,:)  = data_random(i_cell_random,:) > Q_75 + 1.5*(Q_75 - Q_25);
end

ind_random = ind_random_1 + ind_random_2;
n_plot = floor(handles.n_feature/5)  +1;


%% Determine what kind of plots should be shown
%  This catches the rare cases, when no cell is placed in the correct
%  category

%- 
if ind_data_exist == 1
    ind_plot = 1;
%
elseif ind_expected_exist == 1
    ind_plot = 2;
%
elseif ind_result_exist == 1
    ind_plot = 3;
end


%% Display the features distribution

switch ind_plot
    
    %- Off-diagonal - cells that are not in the class where they belong
    case 1
        
        figure, set(gcf,'color','w')
        
        for i = 1:handles.n_feature
            
            data_show_temp =  [data_expected(~ind_expected(:,i),i) ; data_result(~ind_result(:,i),i); data_random(~ind_random(:,i),i) ];
            ind_boxplot    =  [ ones(sum(~ind_expected(:,i)),1) ; 2*ones(sum(~ind_result(:,i)),1); 3*ones(sum(~ind_random(:,i)),1) ];
            
            subplot(5,n_plot,i)
            boxplot(data_show_temp, ind_boxplot, 'Labels',{'Pattern', 'Selected', 'random'}, 'whisker',100)
            hold on
            plot(table2array(feature_current_cell(:,i)), '*', 'MarkerSize',8, 'col', 'black')
            hold on
            plot(2 ,table2array(feature_current_cell(:,i)), '*', 'MarkerSize',8, 'col', 'black')
            hold on
            plot(3 ,table2array(feature_current_cell(:,i)), '*', 'MarkerSize',8, 'col', 'black')
            title(columnname{i}, 'Interpreter', 'none')
        end
 
    %- 
    case 2
        
        figure, set(gcf,'color','w')
        
        for i = 1:handles.n_feature
            
            data_show_temp =  [data_expected(~ind_expected(:,i),i) ; data_random(~ind_random(:,i),i) ];
            ind_boxplot    =  [ ones(sum(~ind_expected(:,i)),1) ; 2*ones(sum(~ind_random(:,i)),1) ];
            
            
            subplot(5,n_plot,i)
            boxplot(data_show_temp, ind_boxplot,'Labels',{'Pattern', 'random'}, 'whisker',100)
            hold on
            plot(table2array(feature_current_cell(:,i)), '*', 'MarkerSize',8, 'col', 'black')
            title(columnname{i}, 'Interpreter', 'none')
        end
        
    %- Off-diagonal - cells that are not in the class where they belong    
    case 3
           
        figure, set(gcf,'color','w')
        for i = 1:handles.n_feature
            
            
            data_show_temp =  [ data_result(~ind_result(:,i),i); data_random(~ind_random(:,i),i) ];
            ind_boxplot    =  [ ones(sum(~ind_result(:,i)),1); 2*ones(sum(~ind_random(:,i)),1) ];
            
            subplot(5,n_plot,i)
            boxplot(data_show_temp,ind_boxplot, 'Labels',{'Selected','random'}, 'whisker',100)
            hold on
            plot(table2array(feature_current_cell(:,i)), '*', 'MarkerSize',8, 'col', 'black')
            title(columnname{i}, 'Interpreter', 'none')
        end  
end

