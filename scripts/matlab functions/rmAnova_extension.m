function output_rmAnova = rmAnova_extension(pexp_vals)

% Run repeated-measures ANOVAs on pattern expression values
%
% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% 2025 August
%
% This function performs repeated-measures ANOVAs on pattern expression values 
% across three within-subject conditions (self, other, control) for multiple 
% classifier weight maps. It also computes Bonferroni-corrected pairwise 
% comparisons and partial eta-squared effect sizes.
%
% Input:
%   pexp_vals - struct containing pattern expression values per classifier and condition
%
% Output:
%   output_rmAnova - struct with ANOVA tables, multiple comparisons, condition means, and effect sizes
%
% Dependencies: fitrm, ranova, multcompare, margmean (requires Statistics and Machine Learning Toolbox)

    conditions = ["self"; "other"; "control"]; 
    map_names = {'SELF RS', 'OTHER RS', 'MENTALIZING SIG'};

    wmaps = fieldnames(pexp_vals);
    for i = 1:3
       conds = fieldnames(pexp_vals.(wmaps{i}));
       for k = 1:3 %conditions
           table_pexp.(wmaps{i})(:,k) =array2table(pexp_vals.(wmaps{i}).(conds{k}));
       end
       table_pexp.(wmaps{i}).Properties.VariableNames = conditions;
       rm.(wmaps{i}) = fitrm(table_pexp.(wmaps{i}),'self-control~1', 'WithinDesign', array2table(conditions));
       anv.(wmaps{i}) = ranova(rm.(wmaps{i}),  'WithinModel', 'conditions');
       multicomp.(wmaps{i}) = multcompare(rm.(wmaps{i}), 'conditions', 'ComparisonType', 'bonferroni');
       means.(wmaps{i}) = margmean(rm.(wmaps{i}), {'conditions'});
       SS_effect = anv.(wmaps{i}).SumSq('(Intercept):conditions'); % Calculate the effect size
       SS_error = anv.(wmaps{i}).SumSq('Error(conditions)'); 
       effectSize.(wmaps{i}) = SS_effect / (SS_effect + SS_error); % partial eta-squared
    end


    % Display results

    for i = 1:3
        disp('-------------------')
        disp('-----------')

        disp(['RM ANOVA RESULTS --- ', map_names{i}])
        disp('-----------')
        disp(anv.(wmaps{i}))
        disp('-----------')
        disp(['Effect Size - partial eta-sq: ', num2str(effectSize.(wmaps{i}))]);
        disp('-----------')
        disp('Bonferroni corrected multiple comparisons')
        disp(multicomp.(wmaps{i}))
        disp('-----------')       
        disp(means.(wmaps{i}))
        disp('-----------')
        disp('-------------------')
    end
    
    for i = 1:3
    output_rmAnova.(wmaps{i}).repMeasModel = rm.(wmaps{i});
    output_rmAnova.(wmaps{i}).anova = anv.(wmaps{i}); 
    output_rmAnova.(wmaps{i}).multiComp = multicomp.(wmaps{i});
    output_rmAnova.(wmaps{i}).conditionMeans = means.(wmaps{i});
    end

end
