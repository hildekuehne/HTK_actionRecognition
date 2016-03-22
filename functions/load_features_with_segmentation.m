function [ features, labels, seg_file, label_list, label_count, label_idx ] = load_features_with_segmentation( path_features, path_seg, file_ending, normalization, doSegmentation, pattern_select, no_sil)
%LOAD_FEATURES_WITH_SEGMENTATION loads frame representations and related segmentations and returns then in unit form  
% Input:
% path_features - path to the feature folder
% path_seg - path to the segmentation folder
% file_ending - feature file ending (default '.txt')
% normalization - normalization mode (default 'none')
% doSegmentation - load features with (1) or without segmentation (0) (default 1)
% pattern_select - pattern for regular expression, if not all files should
% be loaded (default [])
% no_sil - name of the silence unit, that should be ommitted (default [])
%
% Output:
% features - the features per unit / sequence
% labels - the unit labels
% seg_file - the segmentation information
% label_list - list of all labels (corresponding to 'labels')
% label_count - number of available units per label
% label_idx - index of each label
%

% Copyright (C) 2014 H. Kuehne
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


warning off;

if ~exist('file_ending', 'var') || isempty(file_ending)
    file_ending = '.txt';
end

if ~exist('normalization', 'var') || isempty(normalization)
    normalization = 'none';
end

if ~exist('doSegmentation', 'var') || isempty(doSegmentation)
    doSegmentation = 1;
end

if ~exist('pattern_select', 'var') || isempty(pattern_select)
    pattern_select = [];
end

if ~exist('no_sil', 'var') || isempty(no_sil)
    no_sil = [];
end

features = {};
labels = {};
seg_file = {};

count_file = 0;

actions = dir(fullfile(path_features));

for i_actions = 1:length(actions)
    
    actions(i_actions).name
    
    disp(fullfile(path_features, actions(i_actions).name, ['*', file_ending]))
    txt_files = dir(fullfile(path_features, actions(i_actions).name, ['*', file_ending]))

    for i_files = 1:length(txt_files)
        
        if isempty(regexp(txt_files(i_files).name, pattern_select, 'start'))
            disp(['Skipping file: ', fullfile(path_features, actions(i_actions).name, txt_files(i_files).name)]);
            continue
        end
        
        % load features
        disp(['Loading file: ', fullfile(path_features, actions(i_actions).name, txt_files(i_files).name)]);

        feat = load(fullfile(path_features, actions(i_actions).name, txt_files(i_files).name));

        % assume that it is a txt histogramm ... leave out first row and
        % column : 
        feat = feat(2:end, 2:end);
        feat(isnan(feat)) = 0;
        
%         figure(1);
%         imagesc(feat)

        % check segmentataion
        if ~isempty(path_seg)
            
            xml = fullfile(path_seg, actions(i_actions).name, strrep(strrep(strrep(txt_files(i_files).name, '.avi', ''), '_histOF_openCV_', ''), file_ending, '.xml'));
            if ~exist(xml, 'file')
                xml = strrep(xml, '_stereo_', '_stereo01_');
            end
            
            if  doSegmentation == -99
                xml = fullfile(path_seg, actions(i_actions).name, 'dummy.xml');
            end
            
            if exist(xml, 'file')
                disp(['Loading segmenation: ', xml]);
                seg.xml_file = xml;
                [segmentation, segmentation_end, segment_name] = get_segmentation_frames(xml);
                ind_valid = find(segmentation <= size(feat, 1));
                if length(ind_valid) < length(segmentation)
                    disp(['Loosing last ', num2str( length(segmentation) -  length(ind_valid)), ' units'])
%                     segment_name(:)
                end
                seg.segmentation = max(segmentation(ind_valid), 1); 
                if ~isempty(segmentation_end)
                    seg.segmentation_end = [segmentation_end(ind_valid(1:end-1)), size(feat, 1)];
                else
                    seg.segmentation_end = [seg.segmentation(ind_valid(2:end))-1, size(feat, 1)];
                end
                seg.segment_name = segment_name(ind_valid);
%                 seg_file{count_file} = seg;
            else
                disp(['could not find segmentation xml file for: ' xml ' ... skipping']);
                continue;
            end
        end
        
        % keep zero lines resp. remove them later ...
        nonzero_lines = (sum(abs(feat')) ~= 0);
        feat_tmp = feat(nonzero_lines, :);
        
        if strcmp(normalization, 'full')
            feat_tmp = (feat_tmp-min(feat_tmp(:)))/(max(feat_tmp(:)) -min(feat_tmp(:)));
        elseif strcmp(normalization, 'row')
            norm1 = min(feat_tmp, [], 2);
            norm1 = ones(size(feat_tmp, 2), 1)*norm1';
            norm2 = max(feat_tmp, [], 2);
            norm2 = ones(size(feat_tmp, 2), 1)*norm2';
            feat_tmp = feat_tmp - norm1';
            feat_tmp = feat_tmp ./ norm2';
            feat_tmp(isnan(feat_tmp)) = 0;
        elseif strcmp(normalization, 'neg_log')
            feat_tmp = -log(feat_tmp);
%             feat_tmp(isnan(feat_tmp)) = 0;
        elseif strcmp(normalization, 'log')
            feat_tmp = log(feat_tmp);
%             feat_tmp(isnan(feat_tmp)) = 0;
        elseif strcmp(normalization, 'col')
            norm1 = min(feat_tmp, [], 1);
            norm1 = ones(size(feat_tmp, 1), 1)*norm1;
            norm2 = max(feat_tmp, [], 1);
            norm2 = ones(size(feat_tmp, 1), 1)*norm2;
            feat_tmp = feat_tmp - norm1;
            feat_tmp = feat_tmp ./ norm2;
            feat_tmp(isnan(feat_tmp)) = 0;
        elseif strcmp(normalization, 'std')
            norm1 = mean(feat_tmp, 1);
            norm1 = ones(size(feat_tmp, 1), 1)*norm1;
            norm2 = std(feat_tmp, [], 1);
            norm2 = ones(size(feat_tmp, 1), 1)*norm2;
            feat_tmp = feat_tmp - norm1;
            feat_tmp = feat_tmp ./ norm2;
            feat_tmp(isnan(feat_tmp)) = 0;
        elseif strcmp(normalization, 'std_row')
            norm1 = mean(feat_tmp, 2);
            norm1 = ones(size(feat_tmp, 2), 1)*norm1';
            norm2 = std(feat_tmp, [], 2);
            norm2 = ones(size(feat_tmp, 2), 1)*norm2';
            feat_tmp = feat_tmp - norm1';
            feat_tmp = feat_tmp ./ norm2';
            feat_tmp(isnan(feat_tmp)) = 0;
        elseif strcmp(normalization, 'full_std')
            feat_tmp = (feat_tmp-mean(feat_tmp(:)));
            feat_tmp = feat_tmp/std(feat_tmp(:));
        elseif strcmp(normalization, 'none')
            %nothing
            feat_tmp(isnan(feat_tmp)) = 0;
        else
            error('invalid normalization');
        end
        
        feat(nonzero_lines, :) = feat_tmp;
%         figure(2);
%         imagesc(feat)

        ending = size(feat, 1);
        
        if isempty(path_seg) || ( doSegmentation < 1 && length(no_sil) == 0)
            features{end+1} = feat;
%             features{end+1} = feat(sum(feat') ~= 0, 1:min(end, 100) );
            labels{end+1} = actions(i_actions).name;
            seg.xml_file = fullfile(path_features, actions(i_actions).name, txt_files(i_files).name); 
            seg_file{end+1} = seg;
        elseif doSegmentation < 1 && length(no_sil) > 0

            ind_feat = [];
            segmenatation_new = [];
            segmentation_end_new = [];
            segment_name_new = {};
            count_seg = 1;
            for i_seg = 1:length(seg.segmentation)
                if isempty(strfind(seg.segment_name{i_seg}, no_sil))
                    segmenatation_new(count_seg) = length(ind_feat)+1;
                    ind_feat = [ind_feat, seg.segmentation(i_seg):seg.segmentation_end(i_seg)];
                    segmentation_end_new(count_seg) = length(ind_feat);
                    segment_name_new{count_seg} = seg.segment_name{i_seg};
                    count_seg = count_seg + 1;
                end
            end
            
            seg.segmentation = segmenatation_new;
            seg.segmentation_end =segmentation_end_new;
            seg.segment_name = segment_name_new;
            
            features{end+1} = feat(ind_feat, :);
%             features{end+1} = feat(sum(feat') ~= 0, 1:min(end, 100) );
            if length(actions(i_actions).name) > 1
                labels{end+1} = actions(i_actions).name;
            else
                labels{end+1} = segment_name_new{1};
            end
            seg_file{length(features)} = seg;
            
        else
            for i_seg = 1:length(seg.segmentation)
                
                % check length
                if size(feat, 1) < seg.segmentation_end(i_seg)
                    disp(['Cutting off ', num2str(seg.segmentation_end(i_seg) - size(feat, 1)), ' frames from ', seg.segment_name{i_seg}])
                    seg.segmentation_end(i_seg) = size(feat, 1) ;
%                             continue;
                end
                
                % check if valid
                if seg.segmentation(i_seg) < seg.segmentation_end(i_seg)
                    
                    % check for SIL
                    if isempty(strfind(seg.segment_name{i_seg}, no_sil))
                        
%                         ind_feat = seg.segmentation(i_seg):seg.segmentation_end(i_seg);
%                         if length(ind_feat) < 5
%                             ind_feat(end+1:5) = ind_feat(end); % +[1:5-length(ind_feat)]
%                         end 
                        
                        feat_ = feat(seg.segmentation(i_seg):seg.segmentation_end(i_seg), :);
                        feat_ = feat_(sum(feat_') ~= 0, :);
                        if size(feat_, 1) == 0
                            disp(['Removing empty feature ',seg.segment_name{i_seg}])
                            size(feat_);
                            continue;
                        end
        %                 feat_ = feat_(sum(feat_') ~= 0, 1:min(end, 100) );
    %                     if size(feat_, 1) > 100
    %                         seg.segment_name{i_seg}
    %                         size(feat_)
    %                     end
                        features{end+1} = feat_;
                        labels{end+1} = seg.segment_name{i_seg};
                        seg_file{length(features)} = seg;
                    end
                end
            end
        end
        
        count_file = count_file +1;
        
    end

end

% create label list and count labels
label_list = {};
label_count = [];
label_idx = [];
i_label_list = 1;
for i_labels=1:1:length(labels)
    if sum(strcmp(label_list, labels{i_labels})) == 0
        label_list{i_label_list} = labels{i_labels};
        label_count(i_label_list) = 1;
        label_idx(i_labels) = i_label_list;
        i_label_list = i_label_list + 1;
    else
        ind_tmp = find(strcmp(label_list, labels{i_labels}));
        label_count(ind_tmp) = label_count(ind_tmp) + 1;
        label_idx(i_labels) = ind_tmp;
    end
end


disp([num2str(count_file), ' files loaded'])

warning on;

end