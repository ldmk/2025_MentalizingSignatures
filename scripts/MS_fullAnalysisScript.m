%% Replication Code for "Brain neuromarkers predict self- and other-related mentalizing across adult, clinical, and developmental samples"
% This code reproduces all analyses reported in:
% Açıl et al. https://doi.org/10.1101/2025.03.10.642438
%
% DESCRIPTION:
% This repository contains the full analysis pipeline for the manuscript, 
% including but not limited to
%   (i) cross-validated training four SVM classifiers as mentalizing signatures
%   (ii) validation in independent samples 
%   (iii) developing ROI classifiers
%   (v) generating figures for main text and supplementary material.
%
% REQUIREMENTS:
% MATLAB R2022b or above and the following toolboxes:
% - Canlab Core Toolbox [version number, GitHub link]
% - SPM12
% - Statistics and Machine Learning Toolbox
% - Signal Processing Toolbox
% - DataViz toolbox (by Karvelis) for violin plots: https://github.com/povilaskarvelis/DataViz
% - R Software (required for generating only one figure)
%
% INPUT DATA:
% Single-subject contrast images of the training and testing datasets.
% The training dataset is available at: https://doi.org/10.6084/m9.figshare.29908139
% The validation (testing & extension) datasets are not shared publicly.
% Therefore, only the training sections of the code will work with the
% available images. For access at the validation datasets, please reach out to the
% authors.
%
% OUTPUT:
% Running this code will reproduce all analyses and figures as reported in the paper.
%
% CONTACT:
% For questions or issues, please contact Dorukhan Açıl (doacil@pm.me) or Leonie Koban (leonie.koban@cnrs.fr).

%% Setup
clear all; close all;

%Set up paths 
project_path = './projectFolder';
% This path should contain the input data in /inputData

addpath(genpath('./CanlabCore')) % CanlabCore toolbox
addpath(genpath('./spm12')) % SPM12
rmpath(genpath('./CanlabCore/spm12/external/fieldtrip'))  % Remove FieldTrip to avoid function conflicts

cd(project_path)
addpath(project_path)

% NOTE: Adjust ./ and project_path directories based on your repo structure.

signatureNames = {'Self_RS', 'Other_RS', 'MS', 'SvO_RS'}';

%% 1. Load and prepare training data

% Download the training images from the Figshare link above 
% and store under /inputData
load('inputData/training_contrast_images.mat')
% This contains the unmasked training fmri data storing 63 images. 21
% subjects x 3 conditions. First 21 images belong to the self condition,
% 22th-42th belong to the other-condition, and 43th-63th belong to the
% control condition

%Rescale using l2norm
training_set_unmasked = rescale(training_set_unmasked, 'l2norm_images');

% Create the social cognition mask and apply it on the training images
% Association and uniformity tests masks from NeuroSynth of three terms
% (mentalizing, self-referential, social) are downloaded on 06/06/2024. 
% These are stored in /inputData/Social_Mask
fs = filenames('inputData/Social_Mask/*FDR*.nii');

for f = 1:numel(fs) %computing union of the six masks
    if f==1 
        d{f} = fmri_data(fs{f});
        social_mask = d{f};
    elseif f>1
        d{f} = fmri_data(fs{f});
        if f>4
            d{f} = threshold(d{f}, [0 100], 'raw-between');
        end
        social_mask = union(social_mask, d{f});
    end
end

%orthviews(social_mask) %to visually inspect

training_set_masked = apply_mask(training_set_unmasked, social_mask);
clear fs f d

%% %% % Training Mentalizing Signatures (i) Self-RS, ii) Other-RS, iii) Mentalizing-RS, iv) Self-vs-Other RS
    % Input images are from n=21 participants performing a trait-evaluation task with three conditions: Self, Other, Control.  
    % 1) Self-Referential Signature (Self-RS) – self-condition vs. other two conditions
    % 2) Other-Referential Signature (Other-RS) – other-condition vs. the other two conditions
    % 3) Mentalizing Signature (Mentalizing-RS) – mentalizing (self+other) vs. control condition
    % 4) Self-vs-Other (SvO-RS) – direct contrast between self- vs. other-related mentalizing
    %
    % Outputs: Uncorrected weight maps that are effectively the brain signatures of mentalizing, 
    % statistics of the cross-validated training stage, and bootstrapped
    % thresholded images used for visualization

% Train bootstrapped SVM classifiers
    % Using 10-fold CV, 5000 bootstraps for weight stability, and .5 ridge parameter for class balancing.

    training_stats = train_mentalizing_classifiers(training_set_masked, 1);
    % Second argument requires a logical input to enable or disable bootstrapping

    % Here define the mentalizing signatures
    for i = 1:numel(fieldnames(training_stats))
        fn = fieldnames(training_stats);
        mentalizing_signatures.(signatureNames{i}) = training_stats.(fn{i}).weight_obj; clear fn
    end

% Compute prediction accuracies and visualize the training ROC plots
    % The output is displayed in the command window and also stored in the training_results struct. 

    results.trainingPredictions = training_ROC(training_stats, signatureNames, 21, []); %third argument is the sample size, fourth argument defines the true and false classes
    
% Visualize the weight maps
    %this will plot the unthresholded and thresholded weight maps of the classifiers in separate windows
    %requires statistical weight map as an output of bootstrapping

    figure_brain(mentalizing_signatures, signatureNames); 

%% %% %% Validating Mentalizing Signatures in 6 Independent Datasets 

% % Validation datasets:
% Study 2-5 are testing datasets. Study 6-7 are extension datasets. 
study_names = {'Study2', 'Study3', 'Study4a', 'Study4b', 'Study5a', 'Study5b', 'Study5c', 'Study6a', 'Study6b', 'Study7'};

% Load validation datasets - Note: these are not shared publicly
validation_sets = {'DAT_Study2.mat', 'DAT_Study3.mat', ...
    'DAT_Study4a.mat', 'DAT_Study4b.mat', ...
    'DAT_Study5a.mat', 'DAT_Study5b.mat', 'DAT_Study5c.mat',...
    'DAT_Study6a.mat', 'DAT_Study6b.mat', 'DAT_Study_7.mat'}; %not publicly available
% The testing and extension datasets are stored in /inputData in standard
% format where conditions are fields of the struct .dat, each of which contains
% single-subject contrast images for the condition. 

full_paths = fullfile(['/inputData/', validation_sets]);
%full_paths should store the paths as characters that will be used to load
%the images in next steps. load(full_paths{1}) should load struct called
%'dat' with three fields (per condition) each corresponding to an fmri_data object that
%stores images of the respective condition.
clear validation_sets path_validation_data

% Applying the signatures (weight maps) onto the testing and extension datasets
    %  Here we compute pattern expression values by taking the dot products of
    %  four mentalizing classifiers and single-subject condition contrast
    %  images from each study. Validation images are first rescaled using
    %  l2-norm, then resampled onto the same image space as the classifiers.
    
    pexp = pattern_expressions(mentalizing_signatures, full_paths, study_names);
    % First argument contains the classifiers, second argument must indicate
    % the paths to the validation datasets, and the third argument stores
    % names for these datasets

% Testing Accuracies using ROC and Accuracy Plots
    
% i) Testing datasets
    
    studies = {'Study2', 'Study3', 'Study4a', 'Study4b', 'Study5a', 'Study5b', 'Study5c'};
    %only Study 2-5 are testing signatures. Beware that the color and shape
    %codes are dependent on the study_names, so if they are changed, it might
    %throw an error.
        
    results.testingPredictions = testing_signatures(pexp, studies, [], []); 
    %this will plot ROC and accuracy plots and store accuracy statistics in the
    %"testing_results" structs along with average accuracy values
    %3rd and 4th arguments define true and false classes which are also defined
    %in the function
    
        
% ii) Extension datasets
        % a) Study 7 in which signatures were tested using linear effects models

        results.extension.stat_study7 = rmAnova_extension(pexp.Study7);
        
        % Violin Plots for illustrating pattern expressions by condition
        conditions = {'Feedback on Self', 'Feedback on Partner', 'Control Condition'};
        plot_data = pexp.Study7;
        num_classifiers = 3; % plot in order Self-RS, Other-RS, MS
        plot_asterisks = 1; %beware that the function below is not coded to adapt to plot a different dataset
        % in that case, turn this to 0
        violPlot_pexp(plot_data, conditions, num_classifiers, plot_asterisks);

        % b) Study 6 in which signatures predictions are tested using binary prediction tests
        % ROC plots are produced. This dataset has only two conditions or a
        % 2x2 design, so it is structurally different than other datasets
        
        % Input 
        %pexp struct with Study6a and Study6b fields must be there
        col = [.73 .01 .32; .07 .6 1]; %colors for the lines
        maps_to_plot = {'othermap', 'mentmap'}; %this indicates that only Other-RS and MS should be tested. 
        
        figure; %Create plots
        for w = 1:2 
            
            pexp_vals = pexp.Study6a.(maps_to_plot{w});
        
            subplot(2,2,w);
            true_con = 'attributional'; false_con = 'factual'; n = numel(pexp.Study6a.(maps_to_plot{1}).attributional);
            
            ROC_6a = roc_plot([pexp_vals.attributional; pexp_vals.factual], [ones(n,1); -ones(n,1)]==1, 'twochoice', 'color', col(1,:)); hold on
            title('Attributional vs Factual');

            %plot features
            ROC_6a.line_handle(1).Marker = 'v'; ROC_6a.line_handle(1).MarkerSize = 6; 
            ROC_6a.line_handle(2).LineWidth = 2; set(gca,  'FontSize', 12);
            acc = num2str(ROC_6a.accuracy, '%.2f'); 
            acc_str = num2str(str2double(acc)*100); 
            text(0.95, .4, 'Accuracies', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold')
            text(0.95, .3, ['Social: %', acc_str], 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Color', col(1,:), 'FontSize', 12, 'FontWeight', 'bold')
        
            subplot(2,2,w+2);
            pexp_vals = pexp.Study6b.(maps_to_plot{w})
            true_con = {'attrib_social', 'attrib_nonsocial'}; false_con = {'fact_social', 'fact_nonsocial'}; n = numel(pexp.Study6b.(maps_to_plot{1}).attrib_social);
            
            ROC_6b1 = roc_plot([pexp_vals.(true_con{1}); pexp_vals.(false_con{1})], [ones(n,1); -ones(n,1)]==1, 'twochoice', 'color', col(1,:)); hold on
            ROC_6b2 = roc_plot([pexp_vals.(true_con{2}); pexp_vals.(false_con{2})], [ones(n,1); -ones(n,1)]==1, 'twochoice', 'color', col(2,:)); hold on
            title('Attributional vs Factual');

            %plot features
            ROC_6b1.line_handle(1).Marker = 'v'; ROC_6b2.line_handle(1).Marker = '*'; ROC_6b2.line_handle(2).LineStyle = ':'; 
            ROC_6b1.line_handle(1).MarkerSize = 6; ROC_6b2.line_handle(1).MarkerSize = 6;
            ROC_6b1.line_handle(2).LineWidth = 2; ROC_6b2.line_handle(2).LineWidth = 2;
        
            set(gca,  'FontSize', 12);
            acc = num2str(ROC_6b1.accuracy, '%.2f'); acc2 = num2str(ROC_6b2.accuracy, '%.2f');
            acc_str = num2str(str2double(acc)*100); acc_str2 = num2str(str2double(acc2)*100);
            text(0.95, .4, 'Accuracies', 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Color', 'k', 'FontSize', 12, 'FontWeight', 'bold')
            text(0.95, .3, ['Social: %', acc_str], 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Color', col(1,:), 'FontSize', 12, 'FontWeight', 'bold')
            text(0.95, .2, ['Nonsocial: %', acc_str2], 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Color', col(2,:), 'FontSize', 12, 'FontWeight', 'bold')
        
        end; set(gcf, 'Position', [750 150 530 450]);
        results.extension.ROC_6a = ROC_6a; results.extension.ROC_6b1 = ROC_6b1; results.extension.ROC_6b2 = ROC_6b2; clear ROC_6a ROC_6b1 ROC_6b2
        %ROC_6a, ROC_6b1, and ROC_6b2 fields store the ROC output for each comparison

clear acc acc2 acc_str acc_str2 ans col conditions false_con maps_to_plot n num_classifiers ...
    pexp_vals plot_asterisks plot_data true_con w i

%% %% %% Testing for Individual Differences (Clinical status and Age)
% These analyses test whether clinical status and age are associated with
% the degree of the signatures' separatability of the Self and Other
% conditions. 

% i) Testing for sex effects in overall pattern expressions

    % Organize datasets - including only testing datasets each with three
    % conditions
    studies = {'Study2', 'Study3', 'Study4a', 'Study4b', 'Study5a', 'Study5b', 'Study5c'};
    combinedData = prepare_dataset(pexp, studies, [], []);
    
    demographics = readtable('inputData/Demographics_ALL.xlsx'); %This is not shared publicly due to data protection
     
    maps = fieldnames(combinedData);
    studies = {'Study2', 'Study3', 'Study4', 'Study5'};
    indexes = [{1:44}, {45:105}, {106:161}, {162:211}]; %using fixed indexes as they are concatenated in this order

    for m = 1:numel(maps) % merge covariates and the pattern fit data 
        for i = 1:numel(studies)
            n = sum(contains(demographics.Study,studies{i}));
            combinedData.(maps{m})(indexes{i},7) = ...
                demographics(contains(demographics.Study,studies{i}),2); %get Sex info
        end
        combinedData.(maps{m}).Properties.VariableNames(7) = {'sex'};
        combinedData.(maps{m}).sex = categorical(combinedData.(maps{m}).sex);
    end
    
    % linear mixed effects model with age and sex as predictor variables
    model_formula = 'fit ~  sex + (1|study)'; clear lme
    for m = 1:numel(maps) %run the model for each map
        results.sexEffect.(maps{m}) = fitlme(combinedData.(maps{m}), model_formula);
    end
    

% ii) Clinical status
    % a) Healthy controls vs Schizophrenia patients - LME models

    % Organize datasets
    studies = {'Study4a', 'Study4b', 'Study5a', 'Study5b'};
    ref_group = 'a'; ref_study = '4';
    HCvsSZ = prepare_dataset(pexp, studies, ref_group, ref_study);
    
    % linear mixed effects model
    model_formula = 'fit ~ group + (1|study)'; %LME for SZ vs HC
    maps = fieldnames(HCvsSZ);
    for m = 1:numel(maps) %run the model for each map
        results.indDiff.HCvsSZ.(maps{m}) = fitlme(HCvsSZ.(maps{m}), model_formula);
        disp('-------'); disp('----');
        disp(['LME RESULTS FOR: ', maps{m}])
        disp(results.indDiff.HCvsSZ.(maps{m})); disp('----'); disp('-------');
    end

    % Plot pexp distributions
    violPlot_pexp2(HCvsSZ)


    % b) Healthy controls vs Bipolar patients - t-test

    studies = {'Study5a', 'Study5c'};
    ref_group = 'a'; ref_study = '5';
    output_HCvsBP = prepare_dataset(pexp, studies, ref_group, ref_study);
   
    % two-sample t-test for HC vs BP comparison
    for m = 1:numel(maps)
        dat = output_HCvsBP.(maps{i});
        [results.indDiff.HCvsBP.h results.indDiff.HCvsBP.p results.indDiff.HCvsBP.ci ...
            results.indDiff.HCvsBP.stats] = ttest2(dat.fit(dat.group == '1'), dat.fit(dat.group == '0'), 'Vartype', 'unequal');
        if h == 1
            disp(maps);
            disp(p); disp(stats);
        end
    end


% iii) Age

    studies = {'Study2', 'Study3'};
    ref_group = 'not needed'; ref_study = '2'; 
    output_dev = prepare_dataset(pexp, studies, ref_group, ref_study);

    ages = readtable('inputData/developmentalSamples_age.xlsx'); %load age info
    
    %run LME models
    maps = fieldnames(output_dev);
    model_formula = 'fit ~ ages + sex + (1|study)'; 
    clc;
    for k = 1:numel(maps)
        output_dev.(maps{k}).ages = ages{:,1};
        output_dev.(maps{k})(find(output_dev.(maps{k}).study == '1'), 8) = ...
            demographics(contains(demographics.Study,'Study2'),"Sex");
        output_dev.(maps{k})(find(output_dev.(maps{k}).study == '0'), 8) = ...
            demographics(contains(demographics.Study,'Study3'),"Sex");
        output_dev.(maps{k}).Properties.VariableNames(8) = {'sex'};
        results.indDiff.age.(maps{k}) = fitlme(output_dev.(maps{k}), model_formula);
          if double(results.indDiff.age.(maps{k}).Coefficients(2,6)) < .05
          disp('-----------')
          disp(maps{k})
          disp(results.indDiff.age.(maps{k}));
          end
    end

    % Plots for the Age effects
    % These are produced in R. So we are first exporting the data for R
    % access, which we'll use to produce Figures in R via system command,
    % and then illustrate them here as images
    
    % Save data for R 
    dat_table = table(output_dev.selfmap.fit, output_dev.othermap.fit, output_dev.SvOmap.fit, ...
        output_dev.selfmap.ages, output_dev.selfmap.study);
    dat_table.Properties.VariableNames = {'self_fit', 'other_fit', 'SvO_fit', 'ages', 'sample'};
    writetable(dat_table, 'temp/MapFitsAge.xlsx');
    
    %make sure that the R is in the path
    addpath(genpath('/Library/Frameworks/R.framework/Resources')); %this is an example path - it should be updated
    % This R script should save three figures in temp/Fig_Age. Make sure to
    % change the working directory in the R script (figure_Age.R)to the /ProjectFolder
    system('/Library/Frameworks/R.framework/Resources/bin/Rscript scripts/figure_Age.R'); %update the path to the R

    % Display figures in matlab
    img1 = imread('temp/Age_SelfRS.png');
    img2 = imread('temp/Age_OtherRS.png');
    img3 = imread('temp/Age_SvORS.png');
    subplot(1, 3, 1); imshow(img1); subplot(1, 3, 2); imshow(img2); subplot(1, 3, 3); imshow(img3); 
    set(gcf, 'Position', [1, 299, 1280, 420]);

    clear ages ans combinedData dat dat_table demographics i img1 img2 img3 indexes k m maps model_formula n ...
        other_fit output_dev output_HCvsBP HCvsSZ ref_group ref_study sample self_fit studies SvO_fit

%% %% %% ROI Analyses
% Training ROI classifiers instead of brain-wide /whole-brain classifiers
% using the same analytic strategy as above
    
% 1. Extract and create ROI masks from the Neurosynth (NS) mask
    source_mask = 'inputData/mentalizing_ass-test_z_FDR_0.01.nii';
    
    % this function will select ROIs with at least 200 voxels, and ask the user
    % to assign a name to save this image to the output folder. 
    % The output is saved in inputData/ROIs
    % This step could be skipped because images are provided in inputData/ROIs
    extract_ROI(source_mask, training_set_masked)
    
% 2. Train predictive maps for each ROI
    path4ROImasks = 'inputData/ROIs';
    results.ROI_training = train_ROI_classifiers(path4ROImasks, training_set_masked);
    % MultiClass field contains results from three classifiers (in each column
    % of relevant objects): Self classifiers, other classifiers, and
    % mentalizing classifiers. ROC field contains training results
    
% 3. Validate the ROI classifiers in the testing datasets and display
    % prediction accuracies both in training and testing datasets
    testing_sets = {'DAT_Study2.mat', 'DAT_Study3.mat', ...
        'DAT_Study4a.mat', 'DAT_Study4b.mat', ...
        'DAT_Study5a.mat', 'DAT_Study5b.mat', 'DAT_Study5c.mat'};
    
    results.ROI_testing = testing_ROI_classifiers(results.ROI_training, testing_sets, 1); 
    % last argument is logical input argument to either make (1) or not make
    % the figure (0)
    
    
% 4. Display weights of each ROI as Self-vs-Other Classifiers 
    % beware that, if ROIs are recreated by assigning a user-given name above,
    % these names must be updated accordingly
    regs_to_plot_weights = {'aMTG_L', 'aMTG_R', 'mPFC', 'TPJ_R', 'TPJ_L', 'Precuneus'};
        %SvO classifiers of these regions could predict self vs other both in
        %the training and testing datasets - so we are illustrating their weights
    regs_to_plot_green = {'Cerebellum_R', 'Cerebellum_L', 'Cerebellum_BL', 'SMA_L'};
        %SvO classifiers of these regions weren't successfuly in separating two
        %conditions - we are not illustrating their weights
    
    for m = 1:numel(regs_to_plot_weights)
        figure; % this surface function may crash in matlab versions after 2022b. It requires a fix in render_on_surface.m function that it refers. 
        surface_handles = surface(results.ROI_training.stats_ROI_SvO.(regs_to_plot_weights{m}).weight_obj, 'foursurfaces', 'noverbose');
        text(0, 1, regs_to_plot_weights{m}, 'FontSize', 20, 'HorizontalAlignment', 'center', 'Interpreter', 'none'); 
        set(gcf,'Position', [5, 208, 807, 420]);
    end
    for m = 1:numel(regs_to_plot_green)
        figure;
        reg_col = colormap_tor([0.10 0.82 0.0039], [0.10 0.82 0.0039]); 
        surface_handles = surface(results.ROI_training.stats_ROI_SvO.(regs_to_plot_green{m}).weight_obj, 'foursurfaces', 'noverbose', 'pos_colormap', reg_col, 'neg_colormap', reg_col);
        text(0, 1, regs_to_plot_green{m}, 'FontSize', 20, 'HorizontalAlignment', 'center', 'Interpreter', 'none'); 
        set(gcf,'Position', [5, 208, 807, 420]);
    end
    
    clear regs_to_plot_weights regs_to_plot_green

%% %% %% Leave-One-Site-Out (LOSO) Classifiers
% Training leave-one-site-out classifiers combining all datasets that used
% the same or similar task with three conditions: Study 1-5
    
% 1. Gather data together
    testing_sets = {'DAT_Study2.mat', 'DAT_Study3.mat', ...
        'DAT_Study4a.mat', 'DAT_Study4b.mat', ...
        'DAT_Study5a.mat', 'DAT_Study5b.mat', 'DAT_Study5c.mat'};
    ref = fmri_data; %reference image to resample onto
    conds = {'self','other','control'};
    
    for i = 1:numel(testing_sets) %Merge all data together
    
        load(testing_sets{i});
        fn = fieldnames(dat);
    
        for v = 1:numel(fn) 
            if i == 1 %Create template images
                datLOSO.(conds{v}) = fmri_data;
            end
        
            dat.(fn{v}) = resample_space(dat.(fn{v}),ref); %Resample space of validation datasets to reference image
    
            datLOSO.(conds{v}) = cat(datLOSO.(conds{v}), dat.(fn{v})); %Concatenate images
        end
        clear dat
    end
    
    training_set_unmasked_LOSO = resample_space(training_set_unmasked,datLOSO.self);
    
    for v = 1:numel(conds) % Include the training dataset
            datLOSO.(conds{v}).dat(:,1) = []; %delete the first image which was the reference image
            datLOSO.(conds{v}) = rescale(datLOSO.(conds{v}), 'l2norm_images'); %L2norm normalization
            datLOSO.(conds{v}) = cat(datLOSO.(conds{v}), get_wh_image(training_set_unmasked_LOSO,(v-1)*21+1:21*v));
    end
    
    LOSO_set = cat(datLOSO.self, datLOSO.other, datLOSO.control);  clear datLOSO ref
    LOSO_set.removed_images = zeros(696,1); % correction to prevent crashes
    LOSO_set = apply_mask(LOSO_set,social_mask); %apply the social cognition mask
    
% 2. Train SVM classifiers using 5 folds with each study in a single fold 
    sites = {'Study2', 'Study3', 'Study4', 'Study5', 'Study1'}; % in the order that they appear in LOSO_set dataset
    sampleSizes = [44, 61, 56, 50, 21];
    
    results.LOSO_classifiers = train_LOSO_classifiers(LOSO_set, sites, sampleSizes);
    % Second argument lists the studies in the order they were concatenated in
    % the LOSO_set fmri_dataset. Third argument defines the sample size of each study
    
    clear conds fn i output_folder path4ROImasks v sampleSizes sites training_set_unmasked_LOSO

%% %% %% Supplementary Tables and Figures 

% i) Label tables that show significant clusters in the thresholded maps of
% mentalizing signatures

    cluster_labels = get_cluster_labels(training_stats, signatureNames);

% ii) Whole-brain results - Train and test new classifiers using the
% unmasked training dataset, or in other words that masked with whole-brain
% gray matter mask. 

    clasf_wBrain = train_mentalizing_classifiers(training_set_unmasked, 1);
    
    %Training ROCs
    results.wBrain_training = training_ROC(clasf_wBrain, signatureNames, 21, []); 

    %Test the whole brain classifiers in the testing datasets    
    pexp_wB = pattern_expressions(clasf_wBrain, full_paths, study_names);

    % Testing state ROC and Accuracy Plots
    study_names = {'Study2', 'Study3', 'Study4a', 'Study4b', 'Study5a', 'Study5b', 'Study5c'};
    results.wBrain_testing = testing_signatures(pexp_wB, study_names, [], []);
        %this will plot ROC and accuracy plots and store accuracy statistics in the
        %"testing_results" structs along with average accuracy values

    % Brain images
    figure_brain(clasf_wBrain, signatureNames); 

% ii) RFE images - Compute new SVM models using recursive feature
% elimination with final n = 5000
    map_names = {'Self', 'Other', 'Mentalizing', 'SelfvsOther'};
    results.svm_rfe = svm_rfe_models(training_set_masked, map_names);


