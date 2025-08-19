function [pexp] = pattern_expressions(classifiers, full_paths, study_names)
% by Leonie Koban Dec 2022
% needs data mat file (saved as datname) in following format:
% a structure named dat that contains as many fields as conditions of interest. 
% Each field contains on fMRI data object with all subjects' first-level 
% images (one per subject). Labels will follow fieldnames (thus name fields
% corresponding to condition)
% returns pattern expression pexp. 
% saves classification statistics in stats output
% assumes same number of (paired) subjects for all conditions

% clear all
% close all
% clc

%% get weight maps (have to be on path)

cl = fieldnames(classifiers);

wmap.selfmap = classifiers.(cl{1});
wmap.othermap =  classifiers.(cl{2});
wmap.mentmap = classifiers.(cl{3});
wmap.SvOmap = classifiers.(cl{4});

wms = fieldnames(wmap);


%% first load images and rescale using L2norm

for i = 1:numel(study_names)

load(full_paths{i});

cnms = fieldnames(dat);

for c = 1:numel(cnms)
    D.(cnms{c}) = rescale(dat.(cnms{c}), 'l2norm_images');
end

%% pattern expression

for c = 1:numel(cnms)
    for w = 1:numel(wms)
        if compare_space(D.(cnms{c}), fmri_data(wmap.(wms{w}))) == 1
            D.(cnms{c}) = resample_space(D.(cnms{c}), fmri_data(wmap.(wms{w})));
        end
%        pexp{c}{w} = apply_mask(D.(cnms{c}), wmap.(wms{w}), 'pattern_expression', 'ignore_missing');
        pexp.(study_names{i}).(wms{w}).(cnms{c}) = apply_mask(D.(cnms{c}), wmap.(wms{w}), 'pattern_expression', 'ignore_missing');
    end
end

end