function FQ_plot_spots_axes_v1(h_ax,img,pixel,spot_pos,title_str)

%- Show image
cla(h_ax)
imshow(img,[ ],'XData',[0 (size(img,2)-1)*pixel.x],'YData',[0 (size(img,1)-1)*pixel.y],'Parent', h_ax)  
%colorbar('peer',h_ax)

%- Show center coordinates
% hold on
%  	plot(spot_pos.x,spot_pos.y,'+g')
% hold off

title(h_ax,title_str)