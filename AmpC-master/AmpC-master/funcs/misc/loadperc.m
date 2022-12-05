function loadperc(i, tot, n_divs)
if nargin < 3
    n_divs = 10;
end

if floor(i/tot*n_divs) ~= floor((i-1)/tot*n_divs)
    k = round(i/tot*n_divs);
    print = [repmat(char(9679), 1, k), repmat(char(9675), 1, n_divs-k)];
    clc;
    disp(print);
    disp([sprintf('%.1f', 100*i/tot) '% complete']);
end