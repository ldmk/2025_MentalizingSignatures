
function figure_brain(classifiers, names)

% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% August 2025
%
% This function visualizes the voxel-wise weight maps of trained classifiers
% by displaying axial and sagittal brain slices with both unthresholded and
% FDR-thresholded overlays. Contours outline significant clusters.
%
% Inputs:
%   classifier_stats - struct containing statistical output of different classifiers, which
%           contain .weight_obj fields (image_vector)
%   names            - cell array of classifier names (for figure labels)
%   fig_count        - number of classifiers to plot

    st = fieldnames(classifiers);
    

    %define parameters
    space = 10; sag_slice = [0.03 0.45 .1 .5]; trans_val = .6;


    for i = 1:numel(st)
    
        image = classifiers.(st{i});
        image_thr = threshold(image, 0.05, 'fdr', 'k', 10);
        t = image; t2 = image_thr;
    
        figure('Color', 'w');  % Create one figure window for all panels
    
        
        % create illustrations
        o2 = fmridisplay;
        
        o2 = montage(o2, 'noverbose', 'existing_figure', 'axial', 'slice_range', [-30 60], 'onerow', 'spacing', space); 
        axh = axes('Position', sag_slice); 
        o2 = montage(o2, 'noverbose', 'saggital', 'wh_slice', [0 0 0], 'existing_axes', axh); clear axh
        
        %overlay t image that stores uncorrected maps
        o2 = addblobs(o2, region(t), 'compact2', 'splitcolor',{[.4 .73 .98] [.15 .26 .99] [.99 .25 .23] [1 .81 .02]}, 'transvalue', trans_val); 
        %overlay t2 image that stores corrected maps
        o2 = addblobs(o2, region(t2), 'splitcolor',{[.4 .73 .98] [.15 .26 .99] [.99 .25 .23] [1 .81 .02]}, 'transvalue', .9); 
        o2 = addblobs(o2, region(t2), 'contour', 'color', [0 0 0], 'linewidth', 2); %draw lines around t2 image
        
        for t = 1:numel(o2.montage{1}.axis_handles) % Write Z coordinates
            o2.montage{1}.axis_handles(t).Title.String{1} = ['z = ', num2str(o2.montage{1}.slice_mm_coords(t))];
            o2.montage{1}.axis_handles(t).Title.FontName = 'Arial';
            o2.montage{1}.axis_handles(t).Title.FontSize = 12;
            o2.montage{1}.axis_handles(t).Title.Position(2) = -145;
        end
        for t = 1:numel(o2.montage{2}.axis_handles) % Write X coordinates
            o2.montage{2}.axis_handles(t).Title.String{1} = ['x = ', num2str(o2.montage{2}.slice_mm_coords(t))];
            o2.montage{1}.axis_handles(t).Title.FontName = 'Arial';
            o2.montage{2}.axis_handles(t).Title.FontSize = 12;
            o2.montage{2}.axis_handles(t).Title.Position(2) = -130;
        end
    
        text(0.75, 1.25, strrep(names{i}, '_', '\_'), 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontSize', 18, 'FontWeight', 'bold');

    end


end