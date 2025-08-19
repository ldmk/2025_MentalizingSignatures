function violPlot_pexp2 (plot_data)

% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% August 2025

    maps = fieldnames(plot_data);
    
    for i = 1:numel(maps)
        data(:,i) = plot_data.(maps{i}).fit;
    end
    
    groups = plot_data.(maps{1}).group;
    
    labels = {'Self-Referential \newline     Signature', 'Other-Referential \newline       Signature', 'Mentalizing \newline  Signature', '            Self-vs-Other \newline    Referential  Signature'};
    leg = {'Healthy adult sample', 'Schizophrenia sample'};
    cols = [.15 .15 .15; .80 .80 .80]; 
    
    
    h = daviolinplot2(data,'groups',groups, 'smoothing', .2, 'violin', 'half', 'violinalpha', .9, 'violinwidth', 1, 'colors', cols, ...
        'boxspacing', 1.1, 'boxwidth', 1, 'box', 3, 'boxcolors', 'k', 'boxalpha', .7, 'whiskers', 1, 'outsymbol', 'kx', ...
        'scatter', 2, 'scattersize', 30,   'scattercolors', [.5 .5 .5], 'jitter', 1, ...
        'xtlabels', labels, 'legend', leg, 'smoothing', .1, 'outlier_type', 'sd3');
    ylabel('     Pattern expression \newline of True minus False class', 'Interpreter', 'tex');
    set(gca, 'YLim', [-1.1 2.4], 'XLim', [.6 4.4], 'YTick', [-1:.5:2.5], 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold')
    ax = gca; ax.YAxis.FontSize = 12; ax.YLabel.FontSize = 14; ax.XAxis.FontSize = 14;
    h.lg.Position = [0.2    0.84    0.3196    0.0821];
    plot([.8 1.2], [1.6 1.6], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off'); 
    plot([1], [1.7], 'k*', 'HandleVisibility', 'off'); 
    plot([1.8 2.2], [1.6 1.6], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off');  
    plot([2], [1.7], 'k*', 'HandleVisibility', 'off'); 
    plot([3.8 4.2], [1.6 1.6], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off');  
    plot([4], [1.7], 'k*', 'HandleVisibility', 'off'); 
    set(gcf, 'Position', [429 215 875 449])


end