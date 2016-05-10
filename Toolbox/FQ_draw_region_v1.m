function output = FQ_draw_region_v1(param)

h_axes   = param.h_axes;
pos      = param.pos;
reg_type = param.reg_type;


%- Draw region according to selection
switch reg_type;
    
    case 'Freehand'
        fcn = makeConstrainToRectFcn('imfreehand',get(h_axes,'XLim'),get(h_axes,'YLim'));         
        h_fh = imfreehand(h_axes,'PositionConstraintFcn',fcn);        
        setColor(h_fh,'b');        
        reg_pos = getPosition(h_fh);         
        delete(h_fh)
        
        if size(reg_pos,1) == 1
           position = []; 
        else
            position = reg_pos;
        end
        
    case 'Polygon'
        fcn = makeConstrainToRectFcn('impoly',get(h_axes,'XLim'),get(h_axes,'YLim'));    
        h_poly = impoly(h_axes,pos,'PositionConstraintFcn',fcn);         
        setColor(h_poly,'b');
        wait(h_poly);
        reg_pos = getPosition(h_poly);         
        
        position = reg_pos;
        
        delete(h_poly)
        
    case 'Rectangle'       
        fcn = makeConstrainToRectFcn('imrect',get(h_axes,'XLim'),get(h_axes,'YLim'));    
        h_rect = imrect(h_axes,pos,'PositionConstraintFcn',fcn);    
        setColor(h_rect,'b');
        wait(h_rect);  
        reg_pos = getPosition(h_rect);
        
        xmin = reg_pos(1);
        ymin = reg_pos(2);
        w    = reg_pos(3);
        h    = reg_pos(4);
        
        position(:,1) = [xmin xmin+w xmin+w xmin];
        position(:,2) = [ymin ymin   ymin+h ymin+h];

        delete(h_rect)
    case 'Ellipse' 
        fcn = makeConstrainToRectFcn('imellipse',get(h_axes,'XLim'),get(h_axes,'YLim')); 
        h_ell    = imellipse(h_axes,pos,'PositionConstraintFcn',fcn);    
        setColor(h_ell,'b');
        wait(h_ell); 
        reg_pos  = getPosition(h_ell);
        position = getVertices(h_ell);
        
        delete(h_ell)
end


output.position = position;
output.reg_type = reg_type;
output.reg_pos  = reg_pos;