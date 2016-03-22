function hmm = build_hmm_htk(trdata, label, hmm, niter, verb, CVPRIOR)
% hmmparams = build_hmm_htk(trdata, hmm_template, niter, verb, cvprior);
%
%  Train a Hidden Markov Model using HTK.  hmm_template defines the
%  initial HMM parameters (number of states, emission type, initial
%  transition matrix...).  
%
% Inputs:
% trdata  - training data (cell array of training sequences, each
%                          column of the sequences arrays contains a
%                          data point in the time series)
% hmm_template - structure defining the initial HMM parameters:
%        .nstates       -  number of states.  Defaults to 2
%        .emission_type - 'gaussian' or 'GMM'.  Defaults to
%                         'gaussian'
%        .transmat      - initial transition matrix (log
%                          probabilities).  Defaults to fully
%                          connected 
% niter   - number of EM iterations to perform.  Defaults to 10
% verb    - set to 1 to output loglik at each iteration
%
% Outputs:
% hmmparams - structure containing hmm parameters learned from the training
%             data 
%
% 2006-06-16 ronw@ee.columbia.edu

% Copyright (C) 2006-2007 Ron J. Weiss
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

if nargin < 3
  hmm.nstates = 2;
end

if nargin < 4
  niter = 10;
end

if nargin < 5
  verb = 0;
end

% prior on observation covariances to avoid overfitting:
if nargin < 6
  CVPRIOR = 1;
end


% prior on observation covariances to avoid overfitting:
if nargin < 6
  CVPRIOR = 1;
end


if iscell(trdata)
    if  (size(trdata{1}, 1) == size(trdata{end}, 1))
        trdata = cell2mat(trdata);
    else
        trdata = cell2mat(trdata')';
    end
end
nseq = length(trdata);
[ndim, nobs(1)] = size(trdata);

% default hmm parameters
nstates = hmm.nstates;
if ~isfield(hmm, 'emission_type')
  hmm.emission_type = 'gaussian';
end
if ~isfield(hmm, 'transmat')
  hmm.transmat = log(ones(nstates)/nstates);
end
if ~isfield(hmm, 'start_prob')
  hmm.start_prob = log(ones(1, nstates)/nstates);
end
if ~isfield(hmm, 'end_prob')
  hmm.end_prob = log(ones(1, nstates)/nstates);

  % normalize transmat and end_prob properly
  if size(hmm.end_prob, 2) == 1
    hmm.end_prob = hmm.end_prob';
  end
  norm = log(exp(logsum(hmm.transmat, 2)) + exp(hmm.end_prob'));
  hmm.transmat = hmm.transmat - repmat(norm, 1, nstates);
  hmm.end_prob = hmm.end_prob - norm';
end

if strcmp(hmm.emission_type, 'gaussian') 
  if ~isfield(hmm, 'means')
    % init using k-means:
%     hmm.means = kmeans(cat(2, trdata{:}), nstates, niter/2);
    hmm.means = mean(trdata')';
  end
  if ~isfield(hmm, 'covars')
    hmm.covars = var(trdata')';
  end
end
if strcmp(hmm.emission_type, 'GMM') 
  if ~isfield(hmm, 'gmms')
%     hmm.gmms = cell(nstates);
    hmm.gmms = struct;
  end
  if ~isfield(hmm.gmms(1), 'nmix')
    nmix = 3;
    for x = 1:nstates
      hmm.gmms(x).nmix = nmix;
    end
  else
    nmix = hmm.gmms(1).nmix;
  end
  if ~isfield(hmm.gmms(1), 'priors')
    priors = log(ones(1, nmix)/nmix);
    for x = 1:nstates
      hmm.gmms(x).priors = priors;
    end
  end
  if ~isfield(hmm.gmms(1), 'means')
%     means = kmeans(cat(2, trdata{:}), nmix, niter/2);
    means = mean(trdata')';
    for x = 1:nstates
      hmm.gmms(x).means = means;
    end
  end
  if ~isfield(hmm.gmms(1), 'covars')
%     covars = ones(ndim, nmix);
    covars = var(trdata')';
    for x = 1:nstates
      hmm.gmms(x).covars = covars;
    end
  end
end


% Temporary file to use
if exist('hmm.ind_nr', 'var') || isempty(hmm.ind_nr)
    rnd = num2str(round(10000*rand(1)));
else
    rnd = num2str(hmm.ind_nr);
end
% initial HTK HMM: 
hmm.name = [label,'_htkhmm_' rnd];

if verb
  disp(['******** DONE ********'])
end

% done.
