function result = eiCalc_helper_analyzeTransfer( ...
  wavedest, wavesrc, samprate, delaylist, params )

% function result = eiCalc_helper_analyzeTransfer( ...
%   wavedest, wavesrc, samprate, delaylist, params )
%
% This is an analysis function, per TIMEWINLAGFUNCS.txt.
%
% This calculates transfer entropy between the supplied signals. If multiple
% trials are supplied, the trials are concatenated.
%
% "wavedest" and "wavesrc" are expected to contain data that's either
%   continuous real-valued (such as ephys data) or discrete-valued (such as
%   task state data). These may be 1 x Nsamples vectors or Ntrials x Nsamples
%   matrices.
% "params" contains the following fields:
%   "discrete_dest" and "discrete_src" indicate whether the destination
%     and source channels are discrete (auto-binned if so).
%   "bins_dest" and "bins_src" specify the number of bins to use when
%     binning continuous-valued data.
%   "replicates" is the number of replicates to use for bootstrapped variance
%     estimation, or 0 to not use bootstrapping.
%   "want_extrap" is true to perform extrapolation, false otherwise.
%   "extrap_config" is an extrapolation configuration structure.
%   "want_parallel" is true to use the multithreaded implementation and
%     false otherwise.


% Check for the empty case (querying result fields).

if isempty(wavedest) || isempty(wavesrc) || isempty(delaylist)
  result = struct( 'transfer', [] );
  return;
end


% Get geometry.

if isrow(wavedest) || iscolumn(wavedest)
  % We were given one-dimensional vectors. Make sure they're rows.
  wavedest = reshape( wavedest, 1, [] );
  wavesrc = reshape( wavesrc, 1, [] );
end

trialcount = size(wavedest,1);
sampcount = size(wavedest,2);


% Get histogram bins.
% To handle the discrete case, always generate bins here and pass them
% via cell array.
% This handles matrix data without trouble.

binlist = {};

if params.discrete_dest
  binlist{1} = cEn_getHistBinsDiscrete( wavedest );
else
  binlist{1} = cEn_getHistBinsEqPop( wavedest, params.bins_dest );
end

if params.discrete_src
  binlist{2} = cEn_getHistBinsDiscrete( wavesrc );
else
  binlist{2} = cEn_getHistBinsEqPop( wavesrc, params.bins_src );
end


% Package the data.

scratchdata = { wavedest, wavesrc };


% Calculate transfer entropy.

if params.want_parallel
  if params.want_extrap
    [ telist tevars ] = cEn_calcTransferEntropy_MT( ...
      scratchdata, delaylist, binlist, params.replicates, ...
      params.extrap_config );
  else
    [ telist tevars ] = cEn_calcTransferEntropy_MT( ...
      scratchdata, delaylist, binlist, params.replicates );
  end
else
  if params.want_extrap
    [ telist tevars ] = cEn_calcTransferEntropy( ...
      scratchdata, delaylist, binlist, params.replicates, ...
      params.extrap_config );
  else
    [ telist tevars ] = cEn_calcTransferEntropy( ...
      scratchdata, delaylist, binlist, params.replicates );
  end
end


% Store this in an appropriately-named field.

result = struct();
result.transferdata = telist;
result.transfervar = tevars;
% FIXME - Ignore trial trimmin.
result.transfercount = ones(size( telist )) * trialcount * sampcount;


% Done.
end


%
% This is the end of the file.
