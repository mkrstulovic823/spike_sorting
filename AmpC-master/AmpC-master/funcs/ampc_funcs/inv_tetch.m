function [tet, pin] = inv_tetch(channel)
    pin = mod(channel-1, 4)+1;
    tet = (channel-pin)/4+1;
end