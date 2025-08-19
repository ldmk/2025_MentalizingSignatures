function violPlot_pexp (plot_data, conditions, num_classifiers, plot_asterisks)

% Plot pattern expression values using violin plots
%
% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% August 2025
%
% This function visualizes pattern expression values for different classifiers 
% across multiple conditions using a customized version of daviolinplot 
% (daviolinplot2). The function supports plotting asterisks to indicate 
% significance and formats the axes and labels for publication-ready output.
%
% daviolinplot.m is part of the DataViz toolbox (P. Karvelis)
%   https://github.com/povilaskarvelis/DataViz/tree/master
% this function references to daviolinplot2.m which I adapted for my
% personal use.
%
% Inputs:
%   plot_data        - struct containing pattern expression values (by classifier and condition)
%   conditions       - cell array of condition labels
%   num_classifiers  - number of classifiers to plot
%   plot_asterisks   - logical flag (1 = add significance asterisks, 0 = skip)
%
% Dependencies: daviolinplot2 (custom function)

maps = fieldnames(plot_data);
conds = fieldnames(plot_data.(maps{1}));
n = numel(plot_data.(maps{1}).(conds{1}));

% each column stored data from one map in "data" array
for i = 1:num_classifiers 
    for t = 1:numel(conds)
    data((t-1)*n+1:n*t, i) = plot_data.(maps{i}).(conds{t});
        if i == numel(num_classifiers)
            condition_array((t-1)*n+1:n*t) = t;
        end
    end
end

condition_array = categorical(condition_array);
leg = conditions;


classifier_labels = {'Self-Referential \newline     Signature', 'Other-Referential \newline       Signature', 'Mentalizing \newline  Signature', 'Self vs. Other \newline  Signature'};
labels = classifier_labels(1:num_classifiers);

colors = [0.5294 0.1922 0.1686; 0.1922 0.2863 0.4588; 0.2745 0.3255 0.1804];
cols = colors(:,1:(numel(conditions)));

% I'm using a manually adapted version of daviolinplot that I named
% daviolinplot2. This limits outliers to 3 SD +/- Mean which wasn't
% possible with the original code. Whiskers didn't work as properly, so I
% deleted them
h = daviolinplot2(data,'groups',condition_array, 'smoothing', .5, 'violin', 'half', 'violinalpha', .8, 'violinwidth', 1, 'colors', cols, ...
    'boxspacing', 1, 'boxwidth', 1, 'box', 3, 'boxcolors', 'k', 'boxalpha', .9, 'whiskers', 1, 'outsymbol', 'kx', ...
    'scatter', 2, 'scattersize', 20,   'scattercolors', [.5 .5 .5],  'jitter', 1, 'jitterspacing', 2, ...
    'xtlabels', labels, 'legend', leg, 'smoothing', .1, 'outlier_type', 'sd3', 'linkline', 0, 'withinlines', 0);

ylabel('Pattern expressions of signatures', 'Interpreter', 'tex');

xBeg = 1-.4; xEnd = num_classifiers + .4; 
yBeg = floor(min(data(:))); yEnd = ceil(max(data(:)));
set(gca, 'YLim', [yBeg yEnd], 'XLim', [xBeg xEnd], 'YTick', [yBeg:1:yEnd], 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold')
ax = gca; ax.YAxis.FontSize = 12; ax.YLabel.FontSize = 14;
%h.lg.Position = [0.2    0.84    0.3196    0.0821];
set(gcf,'Position', [669   307   600   421]);


if plot_asterisks == 1
    plot([.72 1], [2.4 2.4], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off'); plot([.86], [2.5], 'k*', 'HandleVisibility', 'off'); 
    plot([.72 1.28], [2.7 2.7], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off'); plot([.96 1 1.04], [2.8 2.8 2.8], 'k*', 'HandleVisibility', 'off'); 
    plot([1 1.28], [1.9 1.9], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off'); plot([1.14], [2], 'k*', 'HandleVisibility', 'off'); 
    plot([3 3.28], [1.3 1.3], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off'); plot([3.14], [1.4], 'k*', 'HandleVisibility', 'off'); 
    plot([2.72 3.28], [1.6 1.6], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off'); plot([2.96 3 3.04], [1.7 1.7 1.7], 'k*', 'HandleVisibility', 'off'); 
end





end