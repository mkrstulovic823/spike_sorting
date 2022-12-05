%Fx beeper
function Beeper(number, interval)
    for i=(1:number)
        beep;
        pause(interval);
    end
end