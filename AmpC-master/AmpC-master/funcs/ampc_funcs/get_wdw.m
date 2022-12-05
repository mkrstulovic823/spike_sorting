function W = get_wdw(stamp, pre_stamp_ms, post_stamp_ms, oe_sample_rate)
    if nargin < 4
        oe_sample_rate = 3e4;
        if nargin < 3
            post_stamp_ms = 0.8;
            if nargin < 2
                pre_stamp_ms = 0.2;
            end
        end
    end
    a = round(stamp-((pre_stamp_ms/1000)*oe_sample_rate));
    b = round(stamp+((post_stamp_ms/1000)*oe_sample_rate));
    if length(a)~=length(b) 
        error("Window start and end lengths don't match");
    end
    W = cell(length(a), 1);
    for i = 1:length(a)
        W{i, 1} = double(a(i):b(i));
    end
end