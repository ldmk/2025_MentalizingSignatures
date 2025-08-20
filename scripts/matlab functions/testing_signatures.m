function testing_results = testing_signatures(pexp, study_names, clapos, claneg)

% TESTING_SIGNATURES - Evaluate and plot classifier generalization across studies
% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% August 2025
%
% This function computes and plots ROC curves and classification accuracies 
% for mentalizing signatures applied to external testing datasets. It includes 
% both per-study and weighted average accuracy plots.
%
% Inputs:
%   pexp        - struct containing pattern expression values for each study and condition
%   study_names - cell array of strings naming each testing dataset
%   clapos      - (optional) cell array defining which conditions are treated as positive class per classifier
%   claneg      - (optional) cell array defining the corresponding negative classes
%
% Output:
%   testing_results - struct containing ROC statistics and weighted average accuracies per classifier


% Define positions of accuracy markers
itemNum = numel(study_names);
start = 1; step = 1.5; midDistance = 2;

posit1 = start + (0:step:step*(itemNum-1)); %first half of the plots
mid = posit1(end)+midDistance; %mid point where accuracy will be plotted

posit2 = posit1 + mid + midDistance - start; %second half of the plots
endPoint = posit2(end)+start;
start = 3; step = 2.5;

posit3 = start + (0:step:step*(itemNum)); %positions for the SvO map (w=4)
endPoint_SvO = posit3(end)+start-1;
mid_SvO = posit3(round(itemNum/2)); 
posit3(round(itemNum/2)) = [];

position = [posit1; posit2; posit3]; 


labels = { % X Axis Labels
    {sprintf('    Self-processing\\newline              vs.\\newline   Other-processing'), sprintf('   Self-processing\\newline             vs.\\newline         Control')},
    {sprintf('   Other-processing\\newline               vs.\\newline    Self-processing'), sprintf('    Other-processing\\newline               vs.\\newline            Control')},
    {sprintf('   Self-processing\\newline             vs.\\newline         Control'), sprintf('    Other-processing\\newline               vs.\\newline           Control')}
    {sprintf('Self-processing\\newline                vs.\\newline   Other-processing')}
};

map_names = {'Self-RS', 'Other-RS', 'MS', 'SvO-RS'};

for w = 1:4

    for i = 1:numel(study_names) 
    
    pexp_vals = pexp.(study_names{i}); % get pattern expression values
    wmaps = fieldnames(pexp.(study_names{i})); 
    conds = fieldnames(pexp.(study_names{i}).(wmaps{1}));

    %true and false classes for each classifier
    if isempty(clapos)
        clapos = {1, 2, [1 2], 1};
    end
    if isempty(claneg)
        claneg = {[2 3], [1 3], 3, 2};
    end

    %color code the samples
    if contains(study_names(i), 'Study1'); col = [.39, .39, .39]; %grey
        elseif contains(study_names(i), 'Study4'); col = [.90, .33, .05]; %orange
        elseif contains(study_names(i), 'Study3'); col = [0, 0.41, .22]; %green
        elseif contains(study_names(i), 'Study2'); col = [.48, .004, .467]; %purple
        elseif contains(study_names(i), 'Study5'); col = [.255, .714, .77]; %blue
        elseif disp('ERROR! Color could not be found')
    end

    %shape code the cohort type
    if contains(study_names(i), 'a') | contains(study_names(i), '1'); shape = 'o'; %circles for healthy controls
        elseif contains(study_names(i), 'b'); shape = 'd'; %diamond for schizophrenia
        elseif contains(study_names(i), 'c'); shape = 's'; %square for bipolar
        elseif contains(study_names(i), '2') | contains(study_names(i), '3'); shape = '^'; %triangle for developmental
        elseif disp('ERROR! Shape could not be found')
    end

    n = numel(pexp_vals.(wmaps{1}).(conds{1})); % assuming same number of subjects for all conditions
    sampleSize.(study_names{i}) = n;

    if w == 1 && i == 1; figure('Name', 'Testing ROC and Accuracy Plots');
    else hold on; end
        
      
    % ROC Plots
    subplot(2,4,w); 

    whp = clapos{w};
    whn = claneg{w};

    for cp = 1:numel(whp) % Compute two-alternative forced-choice accuracies and create ROC plots
        for cn = 1:numel(whn)
            comp = [conds{whp(cp)}, 'VS', conds{whn(cn)}];
            ROC.(comp) = roc_plot([pexp_vals.(wmaps{w}).(conds{whp(cp)}); pexp_vals.(wmaps{w}).(conds{whn(cn)})], [ones(n,1); -ones(n,1)]==1, 'twochoice', 'nooutput'); hold on
            ROC.(comp).line_handle(1).Marker = 'none';
            ROC.(comp).line_handle(2).Color = col;
            if cn == 2 | (cp == 2 && cn == 1) %this second part is necessary to change lines in Mentalizing Plots
            ROC.(comp).line_handle(2).LineStyle = ':';
            elseif cn == 3
            ROC.(comp).line_handle(2).LineStyle = '--';
            end
        end
    end  
    
    set(gca,  'FontSize', 10, 'FontWeight', 'bold');    
    title(map_names{w}, 'FontName', 'Arial', 'FontSize', 14, 'FontWeight', 'bold');

    % Accuracy Plots
    
    subplot(2,4,4+w);

    fns = fieldnames(ROC);
    
    accs = [];
    for f = 1:numel(fns) %get accuracy statistics from the ROC object
        accs = [accs, [ROC.(fns{f}).accuracy; ROC.(fns{f}).accuracy_se]];
        if ROC.(fns{f}).accuracy_p <0.05 && ROC.(fns{f}).accuracy > 0.5
            sig{f} = col; %if the prediction accuracy is significantly better than chance level, fill the shape.
        else
            sig{f} = [1 1 1]; %if not, keep it white
        end
    end
  
    hold on; 
    for k = 1:numel(fns)
        sd = ROC.(fns{k}).accuracy_se;
        if w == 4   
            plot(position(3,i), accs(1,k), shape, 'MarkerSize', 8, 'Color', col, 'MarkerFaceColor', sig{k}, 'LineWidth', 1.5);
            errorbar(position(3,i), accs(1,k), sd, 0, 'LineWidth', .5, 'Color', col, 'CapSize', 5);

        else 
            plot(position(k,i), accs(1,k), shape, 'MarkerSize', 8, 'Color', col, 'MarkerFaceColor', sig{k}, 'LineWidth', 1.5); 
            errorbar(position(k,i), accs(1,k), sd, 0, 'LineWidth', .5, 'Color', col, 'CapSize', 5);
        end

    end

    
    ROCs.(study_names{i}) = ROC; 


        if i == numel(study_names) 
            
            %Calculate average accuracies
            accs = []; se = [];
            for v = 1:numel(study_names)
                nn(1,v) = sampleSize.(study_names{v});
                stats = ROCs.(study_names{v});                
                fn = fieldnames(stats);
                    for f = 1:numel(fn)
                        accs(f,v) = stats.(fn{f}).accuracy;
                        se(f,v) = stats.(fn{f}).accuracy_se;
                    end
            end            
            weights = nn / sum(nn); % to be weighted by sample size
            if w == 4
                averagedAccuracy = sum(accs(1,:) .* weights);
                averagedAccuracy_se = sum(se(1,:) .* weights);
            else
                averagedAccuracy = (sum(accs(1,:) .* weights) +  sum(accs(2,:) .* weights))/2;
                averagedAccuracy_se = (sum(se(1,:) .* weights) + sum(se(2,:) .* weights))/2;
            end
            
           
            plot([0.2, posit2(end)+1-.2], [0.5, 0.5], 'k:', 'LineWidth', 2); % Line at chance level

                    
            if w == 4 
                %plot features
                ylim([.27 1.05]); set(gca, 'YTick', [0:.1:1], 'XTick', [13], 'XTickLabel', labels{w}, 'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'bold');       
                xlim([0, endPoint_SvO]);
                % plot the average accuracy
                plot(mid_SvO, averagedAccuracy, 'p', 'MarkerSize', 13, 'Color', [.35 .35 .35], 'MarkerFaceColor', [.35 .35 .35], 'LineWidth', 2);
                text(mid_SvO, averagedAccuracy-.06, sprintf('%.2f', round(averagedAccuracy,2)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12);
            else 
                %plot features
                ylim([.27 1.05]);set(gca, 'YTick', [0:.1:1], 'XTick', [5.5, 18.5], 'XTickLabel', labels{w}, 'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'bold'); %for main classifiers
                xlim([0, endPoint]); 
                % plot the average accuracy
                plot(mid, averagedAccuracy, 'p', 'MarkerSize', 13, 'Color', [.35 .35 .35], 'MarkerFaceColor', [.35 .35 .35], 'LineWidth', 2);
                text(mid, averagedAccuracy-.06, sprintf('%.2f', round(averagedAccuracy,2)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12)
                line([mid mid], [.3, averagedAccuracy-.1], 'Color', 'black', 'LineStyle','--'); 
                line([mid mid], [averagedAccuracy+.05, 1.05], 'Color', 'black', 'LineStyle','--'); 
            end
    
        end
    
    clear ROC

    hold on

    end
    
  testing_results.(wmaps{w}) = ROCs; 
  testing_results.(wmaps{w}).weightedAverageAccuracy = averagedAccuracy;
  testing_results.(wmaps{w}).weightedAverageSE = averagedAccuracy_se;

end


set(gcf,  'Units', 'normalized', 'OuterPosition', [0 0 1 1])
   
end