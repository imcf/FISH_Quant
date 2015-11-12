function [int_th, count_th,h_fig] =FQ_th_detect_auto_v1(data_th,par)


if ~isfield(par,'flag_plot')
   par.flag_plot = 0; 
end

%% Prepare figure

%=== Interpolate data
x =  data_th(:,1); y =  data_th(:,2);


x_min = min(x); x_max = max(x);
Nq = round(length(x) / 3);
xq = linspace(x_min,x_max,Nq);
yq = interp1(x,y,xq,'pchip');

data_intp = []; 
data_intp(:,1) =  xq; data_intp(:,2) =  yq;


%== RAW DATA - Calculate gradient & determine best threshold
data_proc = data_th;

FX = gradient(data_proc(:,2));
a  = abs(1./FX);
a(isinf(a)) = 0;

%- Renormalize with actual value - force tail go to 0
cv.raw = a.* ((data_proc(:,2)));

%- Find maximum,its index and the corresponding intensity value for
%  intrapolated data
[dum, index_th_raw] = max(cv.raw);
int_th.raw          = x(index_th_raw);
count_th.raw        = y(index_th_raw);


%== Interpolated DATA - Calculate gradient & determine best threshold
data_proc = data_intp;

FX = gradient(data_proc(:,2));
a  = abs(1./FX);
a(isinf(a)) = 0;

%- Renormalize with actual value - force tail go to 0
cv.intp = a.* ((data_proc(:,2)));

%- Find maximum,its index and the corresponding intensity value for
%  intrapolated data
[dum, index_th_intp] = max(cv.intp);
int_th_intp          = data_proc(index_th_intp,1);

%- Find corresponding value in raw data
index_th_raw_from_intp = find(x<=int_th_intp,1,'last');
int_th.intp   = x(index_th_raw_from_intp);
count_th.intp = y(index_th_raw_from_intp);


%== Calculate mean
int_th.mean = mean([int_th.intp,int_th.raw]);  
index_th_mean = find(x<=int_th.mean,1,'last');
count_th.mean = y(index_th_mean);

%% === Plot
h_fig = [];

if par.flag_plot

    if par.flag_plot > 1
        figure(par.flag_plot)
    else
        figure
    end
        
    clf, set(gcf,'color','w') 
    h_fig = gcf;

    %= RAW image
    ax1 = subplot(2,2,1);cla
    hold on
        plot(x,y,'k')
        plot([int_th.intp,int_th.intp],[0, max(y)],'-b')
        plot([int_th.raw,int_th.raw],[0, max(y)],'-g')
        plot([int_th.mean,int_th.mean],[0, max(y)],'-r')

    hold off
    xlabel('Intensity')
    ylabel('Number of dots')
    legend('Raw data',['TH-intp: ',num2str(round(int_th.intp)),' (',num2str(round(count_th.intp)),')'] , ...
                       ['TH-raw: ',num2str(round(int_th.raw)),' (',num2str(round(count_th.raw)),')']   , ...
                       ['TH-mean: ',num2str(round(int_th.mean)),' (',num2str(round(count_th.mean)),')'],1)
    title('RAW data')



    subplot(2,2,2),cla
    hold on
    plot(data_th(:,1),cv.raw)
    plot(data_th(index_th_raw,1),cv.raw(index_th_raw),'or')
    xlabel('Intensity')
    ylabel('Inverse (gradient  x  number of dots)')



    %= Interpolated data
    ax2 = subplot(2,2,3);cla
    hold on
        plot(xq,yq,'k')
        plot([int_th.intp,int_th.intp],[0, max(y)],'-b')
        plot([int_th.raw,int_th.raw],[0, max(y)],'-g')
        plot([int_th.mean,int_th.mean],[0, max(y)],'-r')

    hold off
    xlabel('Intensity')
    ylabel('Number of dots')
    legend('Raw data',['TH-intp: ',num2str(round(int_th.intp)),' (',num2str(round(count_th.intp)),')'] , ...
                       ['TH-raw: ',num2str(round(int_th.raw)),' (',num2str(round(count_th.raw)),')']   , ...
                       ['TH-mean: ',num2str(round(int_th.mean)),' (',num2str(round(count_th.mean)),')'],1)
    title('Interpolated data')

    subplot(2,2,4),cla
    hold on
    plot(data_intp(:,1),cv.intp)
    plot(data_intp(index_th_intp,1),cv.intp(index_th_intp),'or')
    xlabel('Intensity')
    ylabel('Inverse (gradient  x  number of dots)')


    linkaxes([ax1,ax2],'xy')
end

% %% From Solving Applied Mathematical Problems with MATLAB
% % https://books.google.fr/books?id=V4vulPEc29kC&pg=PA68&lpg=PA68&dq=matlab+higher+order+numeric+differentiation&source=bl&ots=E3GcquW2dO&sig=9Tx29ZWEKO62_BZg840hIeetrf8&hl=en&sa=X&ved=0CCUQ6AEwATgKahUKEwihq-rs7vbIAhUG1BoKHSkkBDw#v=onepage&q=matlab%20higher%20order%20numeric%20differentiation&f=false
% %  Page 69
% 
% yx1 = [y' 0 0 0 0 0];
% yx2 = [0 y' 0 0 0 0];
% yx3 = [0 0 y' 0 0 0];
% yx4 = [0 0 0 y' 0 0];
% yx5 = [0 0 0 0 y' 0];
% yx6 = [0 0 0 0 0 y'];
% 
% dx = x(2) - x(1);
% 
% 
% dy = (-diff(yx1)+8*diff(yx2)-8*diff(yx3)+diff(yx4))/12*dx;
% L0=2;
% dy = dy(L0+1:end-L0);
% 
% aa = abs(1./dy);
% aa(isinf(aa)) = 0;
% 
% figure
% subplot(2,1,1)
% plot(aa)
% 
% %- Renormalize with actual value
% %  Make tail go to 0
% bb = aa.* y';
% 
% 
% figure
% plot(bb)
% 
