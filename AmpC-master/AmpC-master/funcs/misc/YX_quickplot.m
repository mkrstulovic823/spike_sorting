function [Y, X] = YX_quickplot(mat)
    mat = double(mat);
    Y = [mat; NaN(1, size(mat, 2))];
    Y = reshape(Y, numel(Y), 1);
    X = [1:size(mat, 1), size(mat, 1)]';
    X = repmat(X, numel(Y)/numel(X), 1);
end
