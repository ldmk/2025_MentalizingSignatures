function output = train_LOSO_classifiers(LOSiO_set, sites, sampleSizes)
% Trains and evaluates SVM classifiers using leave-one-site-out (LOSiO) cross-validation.
%
% Dorukhan Acil
% doacil@pm.me / dacil@cbs.mpg.de
% Aug 2025
% 
% 
% INPUTS:
%   LOSiO_set - fMRI dataset containing contrast images for all three conditions (self, other, control)
%   sites - Cell array of site/study names (e.g., {'Study1', 'Study2', ...})
%   sampleSizes - Vector indicating number of subjects per site (in same order as 'sites')
%
% OUTPUT:
%   output - Struct containing trained classifier stats for Self, Other, Mentalizing, and SvO classifiers
%
% This function:
%   - Trains four classifiers (Self, Other, Mentalizing, SvO) using five-fold LOSiO cross-validation
%   - Computes overall and site-specific ROC metrics
%   - Plots classification accuracies for each classifier across sites
%


%Prepare folds
loso_folds = repmat([ones(sampleSizes(1),1);ones(sampleSizes(2),1)*2;ones(sampleSizes(3),1)*3;ones(sampleSizes(4),1)*4;ones(sampleSizes(5),1)*5],3,1);
loso_folds_SvO = repmat([ones(sampleSizes(1),1);ones(sampleSizes(2),1)*2;ones(sampleSizes(3),1)*3;ones(sampleSizes(4),1)*4;ones(sampleSizes(5),1)*5],2,1);


% Run Classifiers
    
    % Self-Classifier
    LOSiO_set.Y = [ones(232,1); ones(464,1)*-1]; %classes for self classifier
    [cverr_self, stats_self, reg_weights_self] = predict(LOSiO_set, 'algorithm_name', 'cv_svm', ...
        'nfolds', loso_folds,'error_type', 'mcr', 'Balanced', 0.5);
    
    % Other-Classifier
    LOSiO_set.Y = [ones(232,1)*-1; ones(232,1); ones(232,1)*-1]; %classes for other classifier
    [cverr_other, stats_other, reg_weights_other] = predict(LOSiO_set, 'algorithm_name', 'cv_svm', ...
        'nfolds', loso_folds,'error_type', 'mcr', 'Balanced', 0.5);
    
    % Mentalizing Classifier
    LOSiO_set.Y = [ones(464,1); ones(232,1)*-1]; %column for ment classifier
    [cverr_ment, stats_ment, reg_weights_ment] = predict(LOSiO_set, 'algorithm_name', 'cv_svm', ...
        'nfolds', loso_folds,'error_type', 'mcr', 'Balanced', 0.5);

    % SvO Classifiers
    LOSO_set_SvO = get_wh_image(LOSiO_set,1:464); 
    LOSO_set_SvO.Y = [ones(232,1); ones(232,1)*-1]; 
    
    [cverr_SvO, stats_SvO, reg_weights_SvO] = predict(LOSO_set_SvO, 'algorithm_name', 'cv_svm', ...
        'nfolds', loso_folds_SvO, 'error_type', 'mcr');


%% Overall and site-specific predictions
conds = [ones(232,1); 2.*ones(232,1); 3.*ones(232,1)];
ima = {'self', 'other', 'ment', 'SvO'};
versus = {'Other', 'Self', 'Other'; 'Control', 'Control', 'Control'};
ccc = [1,2,3; 2,1,3; 3,1,2]; % true (1) and false (2:3) classes for each test
images = {[1:464], [1:232 465:696]; [1:464], [233:696]; [1:232 465:696], [233:696]};


for c = 1:3 %predictions of self-, other-, and mentalizing-classifiers
    X = eval(['stats_',ima{c}]).dist_from_hyperplane_xval;
    Y = eval(['stats_',ima{c}]).Y;

    %overall accuracy
    ROC_OV.(ima{c}) = roc_plot(X(images{c,1}), Y(images{c,1})==1, 'twochoice', 'noplot', 'nooutput'); 
    ROC2_OV.(ima{c}) = roc_plot(X(images{c,2}), Y(images{c,2})==1, 'twochoice', 'noplot', 'nooutput');

    for f = 1:numel(sites)
        ROC = roc_plot([X(loso_folds==f & conds==c); X(loso_folds==f & conds==ccc(c,2))], [Y(loso_folds==f & conds==c); Y(loso_folds==f & conds==ccc(c,2))]==1, 'twochoice', 'noplot', 'nooutput'); 
        ROC2 = roc_plot([X(loso_folds==f & conds==c); X(loso_folds==f & conds==ccc(c,3))], [Y(loso_folds==f & conds==c); Y(loso_folds==f & conds==ccc(c,3))]==1, 'twochoice', 'noplot', 'nooutput');
       
        ROCs.(ima{c}).(sites{f}) = ROC; clear ROC
        ROCs2.(ima{c}).(sites{f}) = ROC2; clear ROC2
    end

end

%SvO predictions
X = eval(['stats_',ima{4}]).dist_from_hyperplane_xval;
Y = eval(['stats_',ima{4}]).Y;
ROC_OV.SvO = roc_plot(X, Y==1, 'twochoice', 'noplot', 'nooutput'); %for overall accuracy


for f = 1:numel(sites)
    ROC = roc_plot(stats_SvO.dist_from_hyperplane_xval(loso_folds_SvO==f), ...
        stats_SvO.Y(loso_folds_SvO==f)==1, 'twochoice', 'nooutput', 'noplot');
    ROCs.SvO.(sites{f}) = ROC; clear ROC
end


%% Accuracy Plots

wms = fieldnames(ROCs);
stud = fieldnames(ROCs.self);
position = [1:1.7:7.8; 14.2:1.7:21; 2 5 8 13 16]; 
labels = { {'SvO','SvC'}, {'OvS','OvC'}, {'SvC','OvC'}, {'SvO'} };
titles = {'LOSiO Self Classifier', 'LOSiO Other Classifier', ...
    'LOSiO Mentalizing Classifier','LOSiO SelfvsOther Classifier'};

for w = 1:4 % PLOT

    for i = 1:numel(stud)
    
    study = stud{i};
    n = ROCs.(wms{w}).(stud{i}).N;
    
    %color code the samples
    if contains(study, 'Study1'); col = [.39, .39, .39]; %grey
        elseif contains(study, 'Study4'); col = [.90, .33, .05]; %orange
        elseif contains(study, 'Study3'); col = [0, 0.41, .22]; %green
        elseif contains(study, 'Study2'); col = [.48, .004, .467]; %purple
        elseif contains(study, 'Study5'); col = [.255, .714, .77]; %blue
        elseif disp('ERROR! Color could not be found')
    end

    shape = 'o'; %circles for everyone

    if w == 1 && i == 1; figure; else hold on; end
        
    subplot(2,2,w);
    
    if w == 4; roc_stat = {ROCs.(wms{w}).(stud{i})}
    else; roc_stat = {ROCs.(wms{w}).(stud{i}), ROCs2.(wms{w}).(stud{i})};
    end
    
    accs = [];    
    for f = 1:2
        if w == 4 && f == 2
        else
            accs = [accs, [roc_stat{f}.accuracy; roc_stat{f}.accuracy_se]];
            if roc_stat{f}.accuracy_p <0.05 && roc_stat{f}.accuracy > 0.5
                sig{f} = col;
            else
                sig{f} = [1 1 1];
            end
        end
    end
  
    hold on; 
    for k = 1:2 
        if w == 4 
            if k == 1
            sd = roc_stat{k}.accuracy_se;
            plot(position(3,i), accs(1,k), shape, 'MarkerSize', 8, 'Color', col, 'MarkerFaceColor', sig{k}, 'LineWidth', 1.5);
            errorbar(position(3,i), accs(1,k), sd, 0, 'LineWidth', .5, 'Color', col, 'CapSize', 5);
            end
        else 
            sd = roc_stat{k}.accuracy_se;
            plot(position(k,i), accs(1,k), shape, 'MarkerSize', 8, 'Color', col, 'MarkerFaceColor', sig{k}, 'LineWidth', 1.5); 
            errorbar(position(k,i), accs(1,k), sd, 0, 'LineWidth', .5, 'Color', col, 'CapSize', 5);
        end
    end
    
    
    if w == 4 
        ylim([.45 1.05]); xlim([0, 17]); set(gca, 'YTick', [0:.1:1], 'XTick', [9], 'XTickLabel', labels{w}, 'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold');      
    else ylim([.45 1.05]); xlim([0, 22]); set(gca, 'YTick', [0:.1:1], 'XTick', [6, 16], 'XTickLabel', labels{w}, 'FontName', 'Arial', 'FontSize', 13, 'FontWeight', 'bold'); %for main classifiers
        line([11 11], [.46, 1.05], 'Color', 'black', 'LineStyle','--'); 
    end
 

    if i == numel(stud)
    plot([0.2, 21.7], [0.5, 0.5], 'k:', 'LineWidth', 2); %Line at chance level
    title(titles{w})
        if w == 4
            overall_acc = ROC_OV.(wms{w}).accuracy; 
            plot(9.5, overall_acc, 'p', 'MarkerSize', 13, 'Color', [.74 0 .15], 'MarkerFaceColor', [.74 0 .15], 'LineWidth', 2);
            text(9.5, overall_acc-.04, ['%',num2str(round(overall_acc,2)*100)], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12, 'FontWeight', 'bold');
        else
            overall_acc = ROC_OV.(wms{w}).accuracy; overall_acc2 = ROC2_OV.(wms{w}).accuracy;
            plot(9.5, overall_acc, 'p', 'MarkerSize', 13, 'Color', [.74 0 .15], 'MarkerFaceColor', [.74 0 .15], 'LineWidth', 2);
            text(9.5, overall_acc-.04, ['%',num2str(round(overall_acc,2)*100)], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12, 'FontWeight', 'bold');
            plot(12.5, overall_acc2, 'p', 'MarkerSize', 13, 'Color', [.74 0 .15], 'MarkerFaceColor', [.74 0 .15], 'LineWidth', 2);
            text(12.5, overall_acc2-.04, ['%',num2str(round(overall_acc2,2)*100)], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12, 'FontWeight', 'bold');     
        end
    end

    end

    set(gca,  'FontSize', 14); set(gcf, 'Position', [270, 100, 1000, 600]);

end


output.Self = stats_self;
output.Other = stats_other;
output.Mentalizing = stats_ment;
output.SvO = stats_SvO;

end