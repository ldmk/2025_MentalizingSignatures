function extract_ROI (source_mask,training_set)

% EXTRACT_ROI - Extracts and saves ROI masks from a source mask image
%
% Dorukhan Açıl  
% doacil@pm.me / dacil@cbs.mpg.de 
% August 2025
%
% This function extracts clusters (ROIs) from a source mask (e.g., a Neurosynth map), 
% resamples them into the space of the training dataset, selects out clusters 
% larger than 200 voxels, and interactively prompts the user to name and save each 
% selected ROI to disk. 
%
% Inputs:
%   source_mask  - file path to the original ROI mask (e.g., Neurosynth meta-analysis result)
%   training_set - fmri_data object used for resampling reference space
%
% Output:
%   ROI images are saved to disk in '/inputData/ROIs/')
%
% Notes:
% - Displays orthviews for visual selection
% - User is prompted to name each selected ROI interactively

neurosynth_ROIs = fmri_data(source_mask);
%resample into the space of the training dataset
neurosynth_ROIs = resample_space(neurosynth_ROIs, training_set);
ment_regs = region(neurosynth_ROIs); %all clusters in the neurosynth mask

% create folder if unavailable
output_folder = fullfile(pwd, 'inputData', 'ROIs');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

orthviews(ment_regs)
i = 0; %select masks that are have at least 200 voxels
for r = 1:numel(ment_regs)
    disp (eval('size(ment_regs(1, r).val, 1)'))
    if (size(ment_regs(1, r).val, 1) > 200)
        i = i + 1;
        big_regs(i) = ment_regs(r);
        spm_orthviews('reposition', big_regs(i).mm_center);   % centers image in coordinates of region i
        rname{i} = input('Enter name to continue', 's');
        big_regs(1, i).title = rname{i};
        mask = region2imagevec(big_regs(1, i));
        mask.fullpath = fullfile(pwd, '/inputData/ROIs/', [sprintf('%02d',i), '_', rname{i}, '.img']);
        write(mask)
    end
end
orthviews(big_regs)


end