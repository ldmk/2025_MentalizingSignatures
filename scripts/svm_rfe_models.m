function [rfe_stats] = svm_rfe_models(training_set_masked, maps)

% Computes SVM Classifiers using Recursive Feature Elimination (RFE).
%
% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% August 2025
%
% INPUTS:
%   training_set_masked - A canlab-type image_vector object with features and labels
%   maps                - Cell array of strings indicating the classifier types (e.g., {'Self', 'Other', ...})
%
% OUTPUT:
%   rfe_stats           - Struct containing RFE results for each classifier, including final models and selected features
%
%   - Runs SVM with recursive feature elimination for each classifier
%   - Uses fixed removal and final feature count parameters (5000, 2000)
%   - Thresholds and visualizes final RFE-selected weight maps
%

%Run SVM models with RFE
for i = 1:numel(maps)
    
    training_set_masked.Y = ones(63,1);
    
    if i == 1
        training_set_masked.Y(22:end,1)= -1; cv = repmat([1:10, 1:10, 1]', 3, 1); 
    elseif i == 2
        training_set_masked.Y([1:21 43:63],1) = -1; cv = repmat([1:10, 1:10, 1]', 3, 1); 
    elseif i == 3
        training_set_masked.Y(43:63,1)= -1; cv = repmat([1:10, 1:10, 1]', 3, 1); 
    elseif i == 4
        training_set_masked_SvO = get_wh_image(training_set_masked, 1:42); 
        training_set_masked_SvO.Y(22:end)= -1; cv = repmat([1:10, 1:10, 1]', 2, 1);
    end
    
    if i == 4
        rfe_stats.(maps{i}) = svm_rfe(training_set_masked_SvO, 'algorithm_name', 'cv_svm', 'nfolds', cv, 'error_type', 'mcr', ...
    'n_removal', 5000, 'n_finalfeat', 2000);
    else
        rfe_stats.(maps{i}) = svm_rfe(training_set_masked, 'algorithm_name', 'cv_svm', 'nfolds', cv, 'error_type', 'mcr', ...
    'n_removal', 5000, 'n_finalfeat', 2000);
    end

    % Visualize
    
    w_rfe = rfe_stats.(maps{i}).smallestnfeat_stats.weight_obj;
    %This correction is needed, because removed_voxels filled is not updated
    %properly
    inc_vox = find(training_set_masked.removed_voxels == 0);
    selec_vox = inc_vox(rfe_stats.(maps{i}).whkeep_orginal_idx{end});
    removed_vox = ones(206801,1);
    removed_vox(selec_vox,1) = 0;
    w_rfe.removed_voxels = removed_vox;
    
    w_rfe = threshold(w_rfe, [-Inf Inf], 'raw-between', 'k', 20);
    montage(w_rfe, 'compact2'); 
    
    text(2.5, 17, ['RFE maps - ', maps{i}], 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'FontSize', 18, 'FontWeight', 'bold')


end









end