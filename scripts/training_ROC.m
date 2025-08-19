function stat_output = training_ROC(training_stats, names, n, classes)

% TRAINING_ROC - Plot ROC curves for trained classifiers
%
% This function plots ROC curves for each classifier based on distances from 
% the SVM hyperplane, comparing positive vs. negative class distinctions 
% for different condition pairs. It tests two-alternative forced-choice
% predictions.
%
% Inputs:
%   training_stats - struct with classifier outputs (must include .dist_from_hyperplane_xval)
%   names          - cell array of classifier names
%   n              - number of samples per class
%   classes        - (optional) cell array defining positive/negative class labels for comparisons
%
% Output:
%   stat_output - struct with ROC statistics for each comparison

    classifiers = fieldnames(training_stats);
    
    set1 = n; set2 = 2*n; set3 = 3*n;
    indexes = {1:set2, [1:set1 set2+1:set3]; 1:set2, set1+1:set3; [1:set1 set2+1:set3], set1+1:set3; 1:set2, 1:set2};

    if isempty(classes)
        claPosNeg = {[1 2], [1 3]; ...
            [2 1], [2 3]; ...
            [1 3], [2 3]; ...
            [1 2], [1 2]};
    else 
        claPosNeg = classes;
    end

for i = 1:numel(classifiers)

    subplot(1,4,i);

    if contains(names{i}, 'Self', 'IgnoreCase',true); comp1 = 'SelfvsOther'; comp2 = 'SelfvsControl';
    elseif contains(names{i}, 'Other', 'IgnoreCase',true); comp1 = 'OthervsSelf'; comp2 = 'OthervsControl';
    elseif contains(names{i}, 'MS', 'IgnoreCase',true); comp1 = 'SelfvsControl'; comp2 = 'OthervsControl';
    elseif contains(names{i}, 'SvO', 'IgnoreCase',true); comp1 = 'SelfvsOther';
    end

    disp('-----')
    disp(names{i})


    disp(comp1)

    
    tCl = claPosNeg{i,1}(1); fCl= claPosNeg{i,1}(2); if tCl < fCl; criteria = 1; else; criteria = -1; end
    ROC = roc_plot(training_stats.(classifiers{i}).dist_from_hyperplane_xval(indexes{i,1}, 1),[ones(n,1); -ones(n,1)]==criteria, 'twochoice'); 

    if i ~= 4
        disp(comp2)
        tCl = claPosNeg{i,2}(1); fCl= claPosNeg{i,2}(2); if tCl < fCl; criteria = 1; else; criteria = -1; end
        ROC2 = roc_plot(training_stats.(classifiers{i}).dist_from_hyperplane_xval(indexes{i,2}, 1), [ones(n,1); -ones(n,1)]==criteria, 'twochoice'); 
    end
    disp('------')

        hold on %Step 2 for plot features
        ROC.line_handle(1).Marker = 'v'; 
        ROC.line_handle(1).Color = [.45 .45 .45]; 
        ROC.line_handle(1).MarkerFaceColor = [.45 .45 .45]; 
        ROC.line_handle(1).MarkerSize = 7; 
        ROC.line_handle(2).LineWidth = 3; 
        ROC.line_handle(2).Color = [.45 .45 .45]; 
        if i ~= 4
        ROC2.line_handle(1).Marker = '*';
        ROC2.line_handle(2).LineStyle = ':';  
        ROC2.line_handle(1).Color = [0 0 0];
        ROC2.line_handle(1).MarkerFaceColor = [0 0 0];
        ROC2.line_handle(1).MarkerSize = 7;
        ROC2.line_handle(2).LineWidth = 3;
        ROC2.line_handle(2).Color = [0 0 0];
        end

    stat_output.(names{i}).(comp1) = ROC;
    if i ~= 4
        stat_output.(names{i}).(comp2) = ROC2;
    end
    
    title(names{i}, 'FontWeight', 'bold', 'Interpreter','none')
    set(gca,  'FontSize', 12); 
    set(gcf, 'Position', [34, 409, 1286, 255])


end


end