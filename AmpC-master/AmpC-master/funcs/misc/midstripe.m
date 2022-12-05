function centres = midstripe(total_width, n_divs, div)
    switch numel(total_width)
        case 1
            offset = 0;
        case 2
            offset = total_width(1);
            total_width = total_width(2)-total_width(1);
    end
    stripe_width = total_width/n_divs;
    centres = (stripe_width/2):(stripe_width):(total_width-(stripe_width/2));
    if exist('div', 'var') == 1
        centres = centres(div);
    end
    centres = centres + offset;
end