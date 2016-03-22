function [ confMat, unique_labels ] = get_conf_matrix( pred_label, org_label  )
% GET_CONF_MATRIX - Create confusion matrix
%   returns the confusion matrix confMat determined by the known and predicted groups
%   rows are perdictions, cols are known labels 
%
% Input:
% pred_label - the predicted label
% org_label - the original label
%
% Output:
% confMat - confusion matrix
% unique_labels - list and order of unique labels
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if size(pred_label, 1) ~=  size(org_label, 1)
    org_label = org_label';
end

unique_labels = unique(org_label);
% unique_pred = unique(pred_label);
% unique_labels = union(unique_org, unique_pred);
% 
% Evaluate confusion matrix....
%      Condition/ Org values
% T
% e
% s
% t
     
confMat = zeros(length(unique_labels));

for i_org = 1:1:length(unique_labels)
        
    for j_pred = 1:1:length(unique_labels)
        
            confMat(j_pred, i_org) = sum( min( pred_label == unique_labels(j_pred), org_label == unique_labels(i_org)) ) ;
    end
    
end

% normalize
confMat = confMat ./ repmat( sum(confMat), size(confMat, 1), 1 );

end

