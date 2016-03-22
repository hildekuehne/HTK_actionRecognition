function [ unit_acc_rate, ins, del, sub] = get_unit_acc( test_labels_dtw, predicted_labels_dtw, w)
%GET_UNIT_ACC computes the number of insertions, deletions and substitute
%units as well as the over unit accuracy  = 1 - unit error rate 
%
% Input:
% test_labels_dtw - test labels after dtw 
% predicted_labels_dtw - predicted labels after dtw 
% w - Matrix w is the result of dtw and contains in the first col the predicted label path, second col the test
% label path. If the predicted label path label stays constant over more
% then one step, units are counted as deletions. If the predicted label path label stays constant over more
% then one step, units are counted as insertions. The other mismatches are
% substitutes.
%
% Output:
% unit_acc_rate -  unit accuracy  = 1 - unit error rate 
% ins - insertions 
% del - deletions
% sub - substitutions
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


% find deletions ... a bit cumbersome, but it works
del = 0;
for i=2:1:size(w,1)
    if w(i, 1) == w(i-1, 1) 
        if test_labels_dtw(w(i-1, 2)) ~= predicted_labels_dtw(w(i-1, 1))  
            del(i-1) = 1;
            del(i) = 0;
        else
            del(i) = 1;
        end
    else
        del(i) = 0;
    end
end

% count insertions
ins = 0;
for i=2:1:size(w,1)
    if w(i, 2) == w(i-1, 2) 
        if test_labels_dtw(w(i-1, 2)) ~= predicted_labels_dtw(w(i-1, 1)) 
            ins(i-1) = 1;
            ins(i) = 0;
        else
            ins(i) = 1;
        end
    else
        ins(i) = 0;
    end
end

% count subsitutions
w1 = predicted_labels_dtw([~(max(ins, del))] == 1);
w2 = test_labels_dtw([~(max(ins, del))] == 1);
sub = (w1 ~= w2);
corr = (w1 == w2);

unit_error_rate = (sum(ins) + sum(del) + sum(sub)) / (sum(del) + sum(sub) + sum(corr));
unit_acc_rate = 1 - unit_error_rate;

end