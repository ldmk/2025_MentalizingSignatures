function combined_data = prepare_dataset (pexp, studies, ref_group, ref_study)

% Dorukhan Açıl
% doacil@pm.me / dacil@cbs.mpg.de
% August 2025

    maps = fieldnames(pexp.(studies{1}));

    %when multiple studies are merged together, this column is not needed
    if isempty(ref_group)
        ref_group = 'X'; 
    end
    if isempty(ref_study)
        ref_study = 'X';
    end

    for m = 1:numel(maps)
        data.(maps{m}) = [];
        for i = 1:numel(studies)
            con = fieldnames(pexp.(studies{i}).(maps{m}));
            n = numel(pexp.(studies{i}).(maps{m}).(con{1}));
            data.(maps{m})(end+1:end+n,1:5) = [pexp.(studies{i}).(maps{m}).(con{1}) , ...
                pexp.(studies{i}).(maps{m}).(con{2}), pexp.(studies{i}).(maps{m}).(con{3}), ...
                repmat(double(contains(studies{i},ref_group)),n,1), ... %insert 1 for the reference group that is defined by the input argument, and 0 for the other.
                repmat(double(contains(studies{i}, ref_study)),n,1)]; %insert 1 for the reference study and 0 for the other
        end

        data.(maps{m}) = array2table(data.(maps{m}));
        data.(maps{m}).Properties.VariableNames = {'self', 'other', 'control', 'group','study'};
        data.(maps{m}).group = categorical(data.(maps{m}).group);
        data.(maps{m}).study = categorical(data.(maps{m}).study);

        if m == 1 | m == 4
            data.(maps{m}){:,6} = data.(maps{m}).self - data.(maps{m}).other;
        elseif m == 2
            data.(maps{m}){:,6} = data.(maps{m}).other - data.(maps{m}).self;
        elseif m == 3
            data.(maps{m}){:,6} = ((data.(maps{m}).self + data.(maps{m}).other)/2)-data.(maps{m}).control;
        end
        data.(maps{m}).Properties.VariableNames(6) = {'fit'};    
    end
    
combined_data = data;

end
