function output = train_ROI_classifiers(path4ROImasks, training_set)

% Train ROI-based classifiers and compute training ROC metrics
%
% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% 2025 August
%
% This function loads ROI mask files from a specified folder, applies them to the 
% training dataset, and trains binary SVM classifiers for different mentalizing 
% contrasts (Self, Other, Mentalizing, and Self-vs-Other) within each ROI.
% It computes cross-validated classification accuracy and ROC metrics for each ROI.
%
% Inputs:
%   path4ROImasks - path to folder containing .img ROI mask files
%   training_set  - fmri_data object with .dat (images) and .Y (label matrix)
%
% Output:
%   output - struct containing:
%       .stats_ROI_MultiClass - SVM stats for Self, Other, and Mentalizing classifiers
%       .stats_ROI_SvO        - SVM stats for Self vs Other classifier
%       .ROC                  - ROC metrics for all classifier contrasts per ROI

masks = filenames([path4ROImasks,'/*.img'], 'absolute');
names = filenames([path4ROImasks,'/*.img']);
names = extractAfter(extractBefore(extractAfter(names, 'ROIs/'), '.img'), 3);

% assign true and false classes in Y 
training_set.Y = ones(63,3);
training_set.Y(22:63,1) = -1; training_set.Y([1:21 43:63],2) = -1; training_set.Y(43:63,3) = -1;    

% SvO classifiers use data from only two conditions, therefore a separate
% object is built for them
train_set_SvO = get_wh_image(training_set, 1:42);
train_set_SvO.Y = ones(42,1);
train_set_SvO.Y(22:end)= -1; 

for m = 1:numel(masks)

    %% data 
    all_conds_roi = apply_mask(training_set, masks{m});
    self_oth_roi = apply_mask(train_set_SvO, masks{m});
    
    %% Multiclass SVM that train Self, Other, and Mentalizing Classifiers in one-go
    [cverr_ROI_mc.(names{m}), stats_ROI_mc.(names{m}), regOutput_ROI_mc.(names{m})] = predict(all_conds_roi, 'algorithm_name', 'cv_svm', 'nfolds', repmat([1:10, 1:10, 1]', 3, 1),'error_type', 'mcr', 'MultiClass', 'Balanced', 0.5, 'verbose', 0);
    
    % ROC plots for Training
    ROC.Self.vsOther.(names{m}) = roc_plot(stats_ROI_mc.(names{m}).dist_from_hyperplane_xval(1:42, 1), training_set.Y(1:42,1)==1, 'twochoice', 'nooutput', 'noplot');
    ROC.Self.vsControl.(names{m}) = roc_plot(stats_ROI_mc.(names{m}).dist_from_hyperplane_xval([1:21 43:63], 1), training_set.Y([1:21 43:63],1)==1, 'twochoice', 'nooutput', 'noplot');
    
    ROC.Other.vsSelf.(names{m}) = roc_plot(stats_ROI_mc.(names{m}).dist_from_hyperplane_xval(1:42, 2), training_set.Y(1:42,2)==1, 'twochoice', 'nooutput', 'noplot');
    ROC.Other.vsControl.(names{m}) = roc_plot(stats_ROI_mc.(names{m}).dist_from_hyperplane_xval([22:63], 2), training_set.Y([22:63],2)==1, 'twochoice', 'nooutput', 'noplot');

    ROC.Mentalizing.SelfvsControl.(names{m}) = roc_plot(stats_ROI_mc.(names{m}).dist_from_hyperplane_xval([1:21 43:63], 3), training_set.Y([1:21 43:63],3)==1, 'twochoice', 'nooutput', 'noplot'); 
    ROC.Mentalizing.OthervsControl.(names{m}) = roc_plot(stats_ROI_mc.(names{m}).dist_from_hyperplane_xval(22:63, 3), training_set.Y(22:63,3)==1, 'twochoice', 'nooutput', 'noplot');
    

    %% Self vs Other
    
    [cverr_ROI_SvO.(names{m}), stats_ROI_SvO.(names{m}), regOutput_ROI_SvO.(names{m})] = predict(self_oth_roi, 'algorithm_name', 'cv_svm', 'nfolds', repmat([1:10, 1:10, 1]', 2, 1),'error_type', 'mcr', 'verbose', 0);

    ROC.SvO.(names{m}) = roc_plot(stats_ROI_SvO.(names{m}).dist_from_hyperplane_xval(1:42, 1), train_set_SvO.Y(1:42,1)==1, 'twochoice', 'nooutput', 'noplot'); 
      
    clear self_vs_rest_roi other_vs_rest_roi syll_vs_rest_roi all_conds_roi self_oth_roi self_vs_other_roi
end

    output.stats_ROI_MultiClass = stats_ROI_mc;
    output.stats_ROI_SvO =  stats_ROI_SvO;
    output.ROC = ROC;


end
