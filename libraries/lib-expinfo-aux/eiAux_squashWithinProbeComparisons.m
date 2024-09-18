function newdata = eiAux_squashWithinProbeComparisons( ...
  olddata, probedefs, squashval, squashfields )

% function newdata = eiAux_squashWithinProbeComparisons( ...
%   olddata, probedefs, squashval, squashfields )
%
% This squashes pairwise information values corresponding to within-probe
% comparisons. This can either be to eliminate spurious associations due to
% multiple channels picking up the same neuron, or to allow easier analysis
% of between-probe information flow.
%
% "olddata" is a pairwise information data structure per TIMEWINLAGDATA.txt.
% "probedefs" is a struct array with probe definitions per PROBEDEFS.txt.
% "squashval" is the value to replace existing data with.
% "squashfields" is a cell array with the field names of matrices to replace
%   data in (e.g. 'xcorrsingle', 'mutualavg').
%
% "newdata" is a copy of "olddata" with within-probe data values squashed.


newdata = olddata;


dstlabels = newdata.destchans;
srclabels = newdata.srcchans;

squashfields = squashfields( contains(squashfields, fieldnames(newdata)) );


for pidx = 1:length(probedefs)
  probelabels = probedefs(pidx).chanlabels;

  dstmask = contains( dstlabels, probelabels );
  srcmask = contains( srclabels, probelabels );

  for fidx = 1:length(squashfields)
    thisfield = squashfields{fidx};
    newdata.(thisfield)(dstmask, srcmask, :, :) = squashval;
  end
end


% Done.
end


%
% This is the end of the file.
