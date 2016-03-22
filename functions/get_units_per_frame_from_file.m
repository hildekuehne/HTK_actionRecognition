function [unit_index, ref_file] = get_units_per_frame_from_file(tags, file)
%GET_UNITS_PER_FRAME_FROM_FILE reads the frame based result from an HTK mlf
%file
%
% Input:
% tags - list with unit names, indicating the order of units 
% file - the file name
%
% Output:
% unit_index - strcut with unit IDs (based on the order given in tags) for each frame of each video 
% ref_file - struct with file names, start frame, end frame, and name of each unit 
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

    ref_file = struct('start', [], 'end', [], 'label', {});

    fid = fopen(file);
    if fid == -1
        keyboard;
    end
    % skip first line
    tline = fgetl(fid);
    tline = fgetl(fid);
    next_start = 1;
    while ischar(tline)
        if next_start
            ref_file(end+1).name = tline;
            next_start = 0;
        elseif strcmp(tline, '.')
    %         [src] = getGrammarSource(ref_files(end).label, act)
            next_start = 1;
        else
            C = regexp(tline, ' ', 'split');
            ref_file(end).start(end+1) = str2num(C{1}) / 100000;
            ref_file(end).end(end+1) = str2num(C{2}) / 100000;
            ref_file(end).label{end+1} = C{3};
        end
        tline = fgetl(fid);
    end
    fclose(fid);

    for i_files=1:1:length(ref_file)
       unit_index{i_files} = [];
        for i_entries=1:1:length(ref_file(i_files).start)
           % idx_tmp =  find( cellfun(@isempty, strfind(tags', ref_file(i_files).label{i_entries}) ) == 0)
           idx_tmp =  find( strcmpi(ref_file(i_files).label{i_entries}, tags') );
           if isempty(idx_tmp)
               keyboard;
           end
           unit_index{i_files}(max( ref_file(i_files).start(i_entries), 1 ) : ref_file(i_files).end(i_entries) ) = idx_tmp(1);
        end
    end
    
end