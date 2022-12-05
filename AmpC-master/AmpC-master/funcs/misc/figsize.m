function figsize(fig, left_bottom_width_height)
lbwh = left_bottom_width_height;
% close all; 
% clear;
% fig = 1;
% norm_axes = [0 0 1 1];
    if isequal(class(fig), 'matlab.ui.Figure')== 0 && isnumeric(fig)==1 && isinteger(uint8(fig)) == 1
        fig = figure(fig);
    end
    
    test = figure;
    set(test, 'Units', 'normalized', 'WindowState', 'maximized', 'Color', [1 1 1]);
    pause(0.4);
    max_pos = get(test, 'OuterPosition');
%     disp(num2str(max_pos));
    
    close(test);
    
    final_L = (1-max_pos(1))*lbwh(1)+max_pos(1);
    final_B = (1-max_pos(2))*lbwh(2)+max_pos(2);
    final_W = max_pos(3)*lbwh(3);
    final_H = max_pos(4)*lbwh(4);
    
    final_lbwh = [final_L, final_B, final_W, final_H];
    
%     disp(num2str(final_lbwh));
    
    
    set(fig, 'Units', 'normalized', 'OuterPosition', final_lbwh);
    
    
end