function [accuracy, confmat, test_label, predicted_label] = get_results_seq(config)
%GET_RESULTS_SEQ computes accuracy of sequence recognition 
%
% Input:
% config - the config struct
%
% Output:
% accuracy - the overall activity (sequence recognition) accuracy 
% confmat - confusion matrix 
% test_label - test sequences
% predicted_label - predicted sequences
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
try

    %%% read reference file
    ref_files = struct('start', [], 'end', [], 'label', {});

    fid = fopen(config.ref_file);
    if fid == -1
        disp(['Reference file not found: ', config.ref_file])
        keyboard;
    end

    % skip first line
    tline = fgetl(fid);
    tline = fgetl(fid);
    next_start = 1;
    while ischar(tline)
        if next_start
            ref_files(end+1).name = tline;
            next_start = 0;
        elseif strcmp(tline, '.')
    %         [src] = getGrammarSource(ref_files(end).label, act)
            next_start = 1;
        else
            C = regexp(tline, ' ', 'split');
            ref_files(end).start(end+1) = str2num(C{1});
            ref_files(end).end(end+1) = str2num(C{2});
            ref_files(end).label{end+1} = C{3};
        end
        tline = fgetl(fid);
    end
    fclose(fid);

    %%% read recognition file
    recog_files = struct('start', [], 'end', [], 'label', {});

    fid = fopen(config.recog_file);
        if fid == -1
            disp(['Recog file not found: ', config.recog_file])
            keyboard;
        end
    % skip first line
    tline = fgetl(fid);
    tline = fgetl(fid);
    next_start = 1;
    while ischar(tline)
        if next_start
            recog_files(end+1).name = tline;
            next_start = 0;
        elseif strcmp(tline, '.')
            next_start = 1;
        else
            C = regexp(tline, ' ', 'split');
            recog_files(end).start(end+1) = str2num(C{1}); 
            recog_files(end).end(end+1) = str2num(C{2});
            recog_files(end).label{end+1} = C{3};
        end
        tline = fgetl(fid);
    end
    fclose(fid);

    % find prediction and org label
    for i=1:1:length(ref_files)

        ref_wrd_list = [];
        for j=1:1:length(ref_files(i).label)
    %         ref_wrd_list = [ref_wrd_list, ref_files(i).label{j}, ' '];
            ref_wrd_list{j} = ref_files(i).label{j};
        end
    %     ref_wrd_list
        x = 0;
        for k=1:1:length(config.unique_action_labels) 
    %        if sum(strcmp(config.unique_action_labels{k}, ref_wrd_list)) > 0
           if sum(cellfun(@isempty, strfind(ref_wrd_list, config.unique_action_labels{k})) == 0) > 0
                x = k;
                break;
           end
        end

        recog_wrd_list = [];
        for j=1:1:length(recog_files(i).label)
    %         recog_wrd_list = [recog_wrd_list, recog_files(i).label{j}, ' '];
            recog_wrd_list{j} = recog_files(i).label{j};
        end
    %     recog_wrd_list
        y = 0;
        for k=1:1:length(config.unique_action_labels) 
    %        if sum(strcmp( config.unique_action_labels{k}, recog_wrd_list )) > 0
           if  sum(cellfun(@isempty, strfind(recog_wrd_list, config.unique_action_labels{k})) == 0) > 0
               config.unique_action_labels{k};
               y = k;
               recog_wrd_list(:);
               break;
           end
        end

        test_label(i) = x;
        predicted_label(i) = y;

    end

    accuracy = (sum(test_label == predicted_label))/length(predicted_label);
    [ confmat, unique_labels ] = get_conf_matrix( predicted_label, test_label  );


catch ME
    getReport(ME)
    accuracy = -1;
    confmat = [];
    test_label = [];
    predicted_label = [];
end

end
