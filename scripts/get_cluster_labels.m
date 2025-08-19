function output = get_cluster_labels(training_stats, names)

% Extracts and summarizes cluster-level information from thresholded weight maps.
%
% D.Acil, 
% doacil@pm.me / dacil@cbs.mpg.de
% Aug 2025
%
% INPUTS:
%   training_stats - Struct containing classifier weight objects (e.g., from cv_svm) for each signature
%   names          - Cell array of classifier/signature names corresponding to fields in training_stats
%
% OUTPUT:
%   output         - Struct containing a table for each signature, summarizing the labeled clusters
%
% For each signature, the function:
%   - Applies FDR thresholding (p < .05) and minimum cluster size of 10 voxels
%   - Extracts anatomical and spatial information per cluster
%   - Constructs a table with region name, coordinates, voxel count, and peak Z-score
%

cla = fieldnames(training_stats);

for c = 1:numel(cla)

image = threshold(training_stats.(cla{c}).weight_obj,.05,'fdr','k',10);
disp('******************')
disp(names{c})
regs = table(image, 'nolegend'); %select clusters

%Rearrange information to write in table format
cell_array = cell(numel(regs),1);
str_array = strings(numel(regs),1);
doubl_array = nan(numel(regs),1);
cluster_table = table(cell_array,str_array, doubl_array, doubl_array, doubl_array, doubl_array, doubl_array);
cluster_table.Properties.VariableNames = {'Title', 'Atlas_region', 'X_coord', 'Y_coord', 'Z_coord', 'Voxel_number', 'Max_Z'};
    for i = 1:numel(regs)
        cluster_table.Title{i} = regs(i).title;
        cluster_table.Atlas_region(i) = regs(i).shorttitle;
        cluster_table.X_coord(i) = regs(i).mm_center(1);
        cluster_table.Y_coord(i) = regs(i).mm_center(2);
        cluster_table.Z_coord(i) = regs(i).mm_center(3);
        cluster_table.Voxel_number(i) = regs(i).numVox;
        [value index] = max(abs(regs(i).Z));
        cluster_table.Max_Z(i) = regs(i).Z(index); clear value index
    end

output.(names{c}) = cluster_table;

end


end