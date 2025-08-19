function output = testing_ROI_classifiers(output_ROI_training, testing_sets, plot_fig)

% TESTING_ROI_CLASSIFIERS - Test ROI-based classifiers on validation datasets and visualize performance
%
% Dorukhan Açıl  
% doacil@pm.me / dacil@cbs.mpg.de  
% August 2025
%
% This function evaluates a set of trained ROI-based classifiers on independent 
% validation datasets. It applies each ROI weight map to the testing images, 
% computes pattern expression values, runs ROC-based classification, and 
% optionally plots training and testing accuracies.
%
% Inputs:
%   output_ROI_training - struct containing trained ROI classifiers and their training ROC metrics
%   testing_sets        - cell array of file paths to .mat files with external fmri_data (with fields: dat.self, dat.other, dat.control)
%   plot_fig            - logical flag (1 = generate bar plots of classification accuracy; 0 = skip plotting)
%
% Output:
%   output - struct containing:
%       .pattern_expressions - pattern expression values per ROI and condition
%       .statistics          - ROC classification results for each ROI and contrast
%
% Notes:
% - Assumes each testing set has fields for self, other, and control images
% - Classifiers include Self-RS, Other-RS, Mentalizing, and Self-vs-Other
% - Accuracy bars are color-coded and show significance if p < .05



%%  Get all Validation Data together
ref = fmri_data; %reference image to resample onto
conds = {'self','other','control'};
for i = 1:numel(testing_sets) %Merge all data together
    load(testing_sets{i});

    fn = fieldnames(dat);

    for v = 1:numel(fn) 
        if i == 1 %Create template images
            testingSet.(conds{v}) = fmri_data;
        end
    
        dat.(fn{v}) = resample_space(dat.(fn{v}),ref); %Resample space of validation datasets to reference image

        testingSet.(conds{v}) = cat(testingSet.(conds{v}), dat.(fn{v})); %Concatenate images
    end
    clear dat
end

% Rescale with L2_norm % delete the first image which is the reference image & 
% finally delete the removed_images field which caused a problem in
% subsequent operations (e.g., apply_mask)
for v = 1:numel(conds)
        testingSet.(conds{v}).dat(:,1) = [];
        testingSet.(conds{v}) = rescale(testingSet.(conds{v}), 'l2norm_images');
        testingSet.(conds{v}).removed_images = 0;
end
clear i v fn conds ref dat

%% Retrieve the ROI Classifiers

region_names = fieldnames(output_ROI_training.stats_ROI_MultiClass);
mc_classes = {'selfmaps', 'othermaps', 'mentmaps'};

for i = 1:numel(region_names)
    for t = 1:numel(mc_classes)
    roi_wmaps.(mc_classes{t}).(region_names{i}) = ...
        get_wh_image(output_ROI_training.stats_ROI_MultiClass.(region_names{i}).weight_obj, t);
    end
    roi_wmaps.SvOmaps.(region_names{i}) = output_ROI_training.stats_ROI_SvO.(region_names{i}).weight_obj;
end

wms = fieldnames(roi_wmaps);
conds = {'self','other','control'};

%% Pattern expressions per ROI mask per weight map per condition across all sample combinations

for w = 1:numel(wms)
    for m = 1:numel(region_names)
        for k = 1:numel(conds)
            pexp_ROI.(region_names{m}).(wms{w}).(conds{k}) = apply_mask(testingSet.(conds{k}), roi_wmaps.(wms{w}).(region_names{m}), 'pattern_expression', 'ignore_missing');
        end
    end
end


%% Predictions in the testing datasets

clapos = {1, 2, [1 2], 1}; % which contrast should be the correct one for each classifier
claneg = {[2 3], [1 3], 3, 2};

masks = fieldnames(pexp_ROI); 
n = length(pexp_ROI.(masks{1}).(wms{1}).(conds{1}));


for w = 1:numel(wms) 

   whp = clapos{w}; whn = claneg{w};

   for m = 1:numel(masks)
            
    for cp = 1:numel(whp)
        for cn = 1:numel(whn)
            true = pexp_ROI.(masks{m}).(wms{w}).(conds{whp(cp)});
            false = pexp_ROI.(masks{m}).(wms{w}).(conds{whn(cn)});
            stats_ROI.(masks{m}).(wms{w}).([conds{whp(cp)}, 'VS', conds{whn(cn)}]) = roc_plot([true; false], [ones(n,1); -ones(n,1)]==1, 'twochoice', 'noplot', 'nooutput');
        end
    end  
    
   end

end


output.pattern_expressions = pexp_ROI;
output.statistics = stats_ROI;

%% Display training and testing accuracies by region using bar plots

if plot_fig == 0; return; end % plot when requested

% Gather accuracy, standard error, and p values together
for m = 1:numel(masks)
    accs(1,2*m-1) = output_ROI_training.ROC.Self.vsOther.(masks{m}).accuracy;
    accs(2,2*m-1) = output_ROI_training.ROC.Self.vsControl.(masks{m}).accuracy;
    accs(3,2*m-1) = output_ROI_training.ROC.Other.vsSelf.(masks{m}).accuracy;
    accs(4,2*m-1) = output_ROI_training.ROC.Other.vsControl.(masks{m}).accuracy;
    accs(5,2*m-1) = output_ROI_training.ROC.Mentalizing.SelfvsControl.(masks{m}).accuracy;
    accs(6,2*m-1) = output_ROI_training.ROC.Mentalizing.OthervsControl.(masks{m}).accuracy;
    accs(7,2*m-1) = output_ROI_training.ROC.SvO.(masks{m}).accuracy;
    accs(1,2*m) = stats_ROI.(masks{m}).selfmaps.selfVSother.accuracy;
    accs(2,2*m) = stats_ROI.(masks{m}).selfmaps.selfVScontrol.accuracy;
    accs(3,2*m) = stats_ROI.(masks{m}).othermaps.otherVSself.accuracy;
    accs(4,2*m) = stats_ROI.(masks{m}).othermaps.otherVScontrol.accuracy;
    accs(5,2*m) = stats_ROI.(masks{m}).mentmaps.selfVScontrol.accuracy;
    accs(6,2*m) = stats_ROI.(masks{m}).mentmaps.otherVScontrol.accuracy;
    accs(7,2*m) = stats_ROI.(masks{m}).SvOmaps.selfVSother.accuracy;

    e(1,2*m-1) = output_ROI_training.ROC.Self.vsOther.(masks{m}).accuracy_se;
    e(2,2*m-1) = output_ROI_training.ROC.Self.vsControl.(masks{m}).accuracy_se;
    e(3,2*m-1) = output_ROI_training.ROC.Other.vsSelf.(masks{m}).accuracy_se;
    e(4,2*m-1) = output_ROI_training.ROC.Other.vsControl.(masks{m}).accuracy_se;
    e(5,2*m-1) = output_ROI_training.ROC.Mentalizing.SelfvsControl.(masks{m}).accuracy_se;
    e(6,2*m-1) = output_ROI_training.ROC.Mentalizing.OthervsControl.(masks{m}).accuracy_se;
    e(7,2*m-1) = output_ROI_training.ROC.SvO.(masks{m}).accuracy_se;
    e(1,2*m) = stats_ROI.(masks{m}).selfmaps.selfVSother.accuracy_se;
    e(2,2*m) = stats_ROI.(masks{m}).selfmaps.selfVScontrol.accuracy_se;
    e(3,2*m) = stats_ROI.(masks{m}).othermaps.otherVSself.accuracy_se;
    e(4,2*m) = stats_ROI.(masks{m}).othermaps.otherVScontrol.accuracy_se;
    e(5,2*m) = stats_ROI.(masks{m}).mentmaps.selfVScontrol.accuracy_se;
    e(6,2*m) = stats_ROI.(masks{m}).mentmaps.otherVScontrol.accuracy_se;
    e(7,2*m) = stats_ROI.(masks{m}).SvOmaps.selfVSother.accuracy_se;

    p(1,2*m-1) = output_ROI_training.ROC.Self.vsOther.(masks{m}).accuracy_p;
    p(2,2*m-1) = output_ROI_training.ROC.Self.vsControl.(masks{m}).accuracy_p;
    p(3,2*m-1) = output_ROI_training.ROC.Other.vsSelf.(masks{m}).accuracy_p;
    p(4,2*m-1) = output_ROI_training.ROC.Other.vsControl.(masks{m}).accuracy_p;
    p(5,2*m-1) = output_ROI_training.ROC.Mentalizing.SelfvsControl.(masks{m}).accuracy_p;
    p(6,2*m-1) = output_ROI_training.ROC.Mentalizing.OthervsControl.(masks{m}).accuracy_p;
    p(7,2*m-1) = output_ROI_training.ROC.SvO.(masks{m}).accuracy_p;
    p(1,2*m) = stats_ROI.(masks{m}).selfmaps.selfVSother.accuracy_p;
    p(2,2*m) = stats_ROI.(masks{m}).selfmaps.selfVScontrol.accuracy_p;
    p(3,2*m) = stats_ROI.(masks{m}).othermaps.otherVSself.accuracy_p;
    p(4,2*m) = stats_ROI.(masks{m}).othermaps.otherVScontrol.accuracy_p;
    p(5,2*m) = stats_ROI.(masks{m}).mentmaps.selfVScontrol.accuracy_p;
    p(6,2*m) = stats_ROI.(masks{m}).mentmaps.otherVScontrol.accuracy_p;
    p(7,2*m) = stats_ROI.(masks{m}).SvOmaps.selfVSother.accuracy_p;
    
end

clapos = {1, 2, [1 2], 1}; % which contrast should be the correct one for each classifier
claneg = {[2 3], [1 3], 3, 2};

colors = [0.55 0.06 0.15; 0.99 0.24 0.38; ... %dark and light red for SELF
          0.4 0.16 0.48; 0.84 0.37 0.99; ...  %dark and light purple for OTHER
          0 .33 .55; .02 .56 .93; ... %dark and light blue own for MENT
          0.8 0.3 0.1]; %orange for SvO
colors2 = [.77 .15 .27; .77 .15 .27; %these colors are the mean of dark and light variations for each condition. Used to plot training bars
           .62 .27 .74; .62 .27 .74;
           .01 .45 .74; .01 .45 .74;
           .8 .3 .1]; 

tick_labels = {' SELF\newline   vs.\newlineOther', '  SELF\newline    vs.\newlineControl', 'OTHER\newline    vs.\newline   Self', 'OTHER\newline    vs.\newlineControl', ...
    '        MENT:\newlineSelf vs. Control', '          MENT:\newline  Other vs. Control', '        SvO:\newlineSelf vs. Other'};


for r = 1:numel(masks)
    figure ('Name',masks{r});
    for t=1:2 %make two separate plots: One including SELF and OTHER. The other including MENT and SvO
        subplot(1,2,t);
    if t == 1 %index for tick labels
        ind = 1:4; x_loc = [1 1.5 2.25 2.75]; titl = 'Self-Classifier & Other-Classifier'; width1 = .9; width2 = .4; dist = .125;
    elseif t == 2
        ind = 5:7; x_loc = [1 1.5 2.25]; titl = 'Mentalizing-Classifier & SvO-Classifier'; width1 = .75; width2 = .33; dist = .105;
    end
    xtick_lab = tick_labels(ind); 
    
    b = bar(x_loc, accs(ind,r*2-1), 'FaceColor', 'flat', 'BarWidth', width1); %Plot the training accuracies  
    hold on; 
    c = bar(x_loc+dist, accs(ind,r*2), 'FaceColor', 'flat', 'BarWidth', width2); %Plot the validation accuracies
    
    sign_array = p(ind,r*2-1) < .05;
    c.YData(~sign_array) = NaN;
    accs2 = accs(ind,r*2); accs2 = accs2(sign_array);   
    e2 = e(ind,r*2); e2 = e2(sign_array);    

    %Error bars
    errorbar(b.XEndPoints', accs(ind,r*2-1), e(ind,r*2-1),'Color', 'black', 'LineWidth',1,'linestyle','none','CapSize', 1);
    errorbar(c.XEndPoints(sign_array)', accs2, e2,'Color', 'black', 'LineWidth',1,'linestyle','none','CapSize', 1);

    %Settings
    set(gca, 'YLim', [0 1.1],'XTick', x_loc, 'xticklabel', xtick_lab); 
    cols = colors(ind,:); %select colors for validation bars
    cols2 = colors2(ind,:); %select colors for training bars
    for i = 1:height(b.CData)
    b.CData(i,:) = cols2(i,:); %[.75 .75 .75];
    end
    for i = 1:height(c.CData)
    c.CData(i,:) = cols(i,:);
    end
    b.FaceAlpha = .2;

    %Significance asterisks
    sig_train = p(ind,r*2-1); sig_train_y = accs(ind,r*2-1) + e(ind,r*2-1) + .02;
    sig_valid = p(ind,r*2); sig_valid_y = accs(ind,r*2) - e(ind,r*2) - .075;
    acc = accs(ind,r*2-1:r*2);
    for w = 1:width(ind)
        if sig_train(w) <.05 && acc(w,1) > .5
            text(x_loc(w), sig_train_y(w), '*', 'FontSize', 40, 'HorizontalAlignment', 'center', 'Color', cols(w,:));
            if sig_valid(w) <.05 && acc(w,2) > .5
               text(x_loc(w)+dist, sig_valid_y(w), '*', 'FontSize', 40, 'HorizontalAlignment', 'center', 'Color', [1 1 1]); %cols(w,:));
            end
        end
    end

    plot([x_loc(1)-.225, x_loc(end) + .225], [0.5, 0.5], 'k:', 'LineWidth', 2.75); %Line at chance level

    %Settings
    set(gca, 'YTick', [0:.1:1], 'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'bold');
    set(gca,'XLim', [x_loc(1)-.3, x_loc(end) + .3]);
    ax = gca; ax.Box = 'off'; ax.XColor = 'k'; ax.YColor = 'k'; % Remove the upper and right axes
    %ax.YAxis.FontSize = 14; 
    title([masks{r},'  ', titl], 'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'bold', 'Interpreter', 'none');

    hold off

    end

    set(gcf, 'Position', [455 103 826 331]);

end



end