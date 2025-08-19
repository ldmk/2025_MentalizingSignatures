function output = train_mentalizing_classifiers (training_data, use_boot)
% This function trains a set of Support Vector Machine (SVM) classifiers to distinguish between 
% different types of mentalizing-related brain activation patterns.
% 
% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% August 2025
%
% It trains up to four classifiers:
% 	1.	Self-Referential Signature (Self vs Other & Control)
% 	2.	Other-Referential Signature (Other vs Self & Control)
% 	3.	Mentalizing Signature (Self & Other vs Control)
% 	4.	Self-vs-Other Signature (Self vs Other)
% 
% For each classifier:
% 	- Labels (Y) are assigned to contrast images in training_data.
% 	- 10-fold cross-validation is used.
% 	- 5000 bootstrap iterations are run to assess classifier weight stability.

cv_folds = repmat([1:10, 1:10, 1]', 3, 1);  % 63 samples, 3 conditions
cv_folds_SvO = repmat([1:10, 1:10, 1]', 2, 1);  % 42 samples, 2 conditions

output = struct('Self_RS', [], 'Other_RS', [], 'MS', [], 'SvO', []);

if use_boot == 1;
    
    % Self-Referential Signature (Self vs [Other & Control])
    training_data.Y = ones(63,1);
    training_data.Y(22:end,1) = -1; % +1 = target condition, -1 = false conditions
    [cverr_self, stats_self, regOutput_self] = predict(training_data, ...
        'algorithm_name', 'cv_svm', 'nfolds', cv_folds, ...
        'error_type', 'mcr', 'bootsamples', 5000, 'bootweights', 'Balanced', 0.5);
    
    % Other-Referential Signature (Other vs [Self & Control])
    training_data.Y = ones(63,1); training_data.Y([1:21 43:63],1) = -1;
    [cverr_other, stats_other, regOutput_other] = predict(training_data, ...
        'algorithm_name', 'cv_svm', 'nfolds', cv_folds, ...
        'error_type', 'mcr', 'bootsamples', 5000, 'bootweights', 'Balanced', 0.5);
    
    % Mentalizing Signature ([Self & Other] vs Control)
    training_data.Y = ones(63,1); training_data.Y(43:end,1) = -1;
    [cverr_ment, stats_ment, regOutput_ment] = predict(training_data, ...
        'algorithm_name', 'cv_svm', 'nfolds', cv_folds, ...
        'error_type', 'mcr', 'bootsamples', 5000, 'bootweights', 'Balanced', 0.5);
    
    % Self-vs-Other Referential Signature (Self vs Other)
    training_data.Y = []; training_data.Y = ones(42,1); training_data.Y(22:end,1) = -1;
    [cverr_SvO, stats_SvO, regOutput_SvO] = predict(get_wh_image(training_data, 1:42), ...
        'algorithm_name', 'cv_svm', 'nfolds', cv_folds_SvO, ...
        'error_type', 'mcr', 'bootsamples', 5000, 'bootweights');

elseif use_boot == 0 

    % Self-Referential Signature (Self vs [Other & Control])
    training_data.Y = ones(63,1);
    training_data.Y(22:end,1) = -1; % +1 = target condition, -1 = false conditions
    [cverr_self, stats_self, regOutput_self] = predict(training_data, ...
        'algorithm_name', 'cv_svm', 'nfolds', cv_folds, ...
         'error_type', 'mcr', 'Balanced', 0.5);
    
    % Other-Referential Signature (Other vs [Self & Control])
    training_data.Y = ones(63,1); training_data.Y([1:21 43:63],1) = -1;
    [cverr_other, stats_other, regOutput_other] = predict(training_data, ...
        'algorithm_name', 'cv_svm', 'nfolds', cv_folds, ...
            'error_type', 'mcr', 'bootweights', 'Balanced', 0.5);
    
    % Mentalizing Signature ([Self & Other] vs Control)
    training_data.Y = ones(63,1); training_data.Y(43:end,1) = -1;
    [cverr_ment, stats_ment, regOutput_ment] = predict(training_data, ...
        'algorithm_name', 'cv_svm', 'nfolds', cv_folds, ...
         'error_type', 'mcr', 'bootweights', 'Balanced', 0.5);
    
    % Self-vs-Other Referential Signature (Self vs Other)
    training_data.Y = []; training_data.Y = ones(42,1); training_data.Y(22:end,1) = -1;
    [cverr_SvO, stats_SvO, regOutput_SvO] = predict(get_wh_image(training_data, 1:42), ...
        'algorithm_name', 'cv_svm', 'nfolds', cv_folds_SvO, ...
            'error_type', 'mcr');

else disp('define use_bootrapping argument as 1 or 0')
end


output.Self_RS = stats_self;
output.Other_RS = stats_other;
output.MS = stats_ment;
output.SvO = stats_SvO;


end