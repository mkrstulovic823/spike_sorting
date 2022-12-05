function out = colsp(color_code)
    if isnumeric(color_code)
        rgbcmykw = 'rgbcmykw';
        if color_code > 0
            color_code = rgbcmykw(color_code);
        elseif color_code == 0
            color_code = 'k';
        end
    end
    
    switch color_code
        case 'r'
            out = [1 0 0];
        case 'g'
            out = [0 1 0];
        case 'b'
            out = [0 0 1];
        case 'c'
            out = [0 1 1];
        case 'm'
            out = [1 0 1];
        case 'y'
            out = [1 1 0];
        case 'k'
            out = [0 0 0];
        case 'w'
            out = [1 1 1];
    end
end