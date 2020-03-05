function RNA_pos = simulate_RNA_pos_v4(sim_prop,cell_prop,cell_library_info,flag)

if nargin < 4
    flag.output = 0;
end

%% Function to simulate  a non random distribution of mRNA in a 3D cell polygon
switch sim_prop.pattern_name
    
    case 'random' 
        RNA_pos = sim_random_v2(sim_prop,cell_prop);
        
   case 'random_cell' 
        RNA_pos = sim_random_cell_v1(sim_prop,cell_prop);
    
    case 'cell3D'
        RNA_pos = sim_cell_membrane_v2(sim_prop,cell_prop);
        
    case 'cell2D' 
        RNA_pos = sim_cell_edge_v2(sim_prop,cell_prop);
 
    case 'nuc3D'
        RNA_pos = sim_nuclear_membrane_v2(sim_prop,cell_prop);
  
    case 'nuc2D' 
        RNA_pos = sim_nucleus_edge_v2(sim_prop,cell_prop,cell_library_info); 

    case 'perinuc'
        RNA_pos = sim_perinuclear_v1(sim_prop,cell_prop);    
        
    case 'foci' 
        RNA_pos = sim_foci_v3(sim_prop,cell_prop,cell_library_info)  ;
        
    case 'polarized' 
        RNA_pos = sim_polarized_v2(sim_prop,cell_prop);

    case 'cellext' 
        RNA_pos = sim_cell_extension_v2(sim_prop,cell_prop);
        
    case 'TS' 
        RNA_pos = sim_TS_v1(sim_prop,cell_prop,cell_library_info)  ;       
        
    case 'inNUC' 
        RNA_pos = sim_inNucleus_v1(sim_prop,cell_prop)  ;
           
    otherwise
        fprintf(' Pattern not known: %s \n',sim_prop.pattern_name)

end

%- Plot simulated image
if flag.output
    
    K_cell   = cell_prop.K_cell;
    pos_cell = cell_prop.pos_cell_pix; 
    K_nuc    = cell_prop.K_nuc ;
    pos_nuc  = cell_prop.pos_nuc_pix;
    nuc_2D  = cell_prop.nuc_2D;
    cell_2D  = cell_prop.cell_2D;
    cell_bottom_pix = cell_prop.cell_bottom_pix;
 
    figure, set(gcf,'color','w')
    subplot(1,3,1)
    hold on
    trisurf(K_cell,pos_cell(:,1),pos_cell(:,2),pos_cell(:,3), ...
        'FaceColor','yellow','FaceAlpha', 0.1);
    trisurf(K_nuc,pos_nuc(:,1),pos_nuc(:,2),pos_nuc(:,3),0.1)
    plot3(RNA_pos(:,1),RNA_pos(:,2),RNA_pos(:,3) + cell_bottom_pix ,'.','MarkerSize',15, 'col','red')
    hold off
    box on
    axis image
    
    subplot(1,3,2)
    hold on
    plot(cell_2D(:,1),cell_2D(:,2),'b')
    plot(nuc_2D(:,1),nuc_2D(:,2),'b')
    plot(RNA_pos(:,1),RNA_pos(:,2),'.','MarkerSize',4, 'col','red')
    hold off
    axis image
    box on
    title(sim_prop.pattern_name,'interpreter','none')
    
    subplot(1,3,3)
    plot3(RNA_pos(:,1),RNA_pos(:,2),RNA_pos(:,3)+cell_bottom_pix ,'.','MarkerSize',10, 'col','red')
end

