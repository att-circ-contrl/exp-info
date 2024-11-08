function newdata = eiAux_squashWithinProbeComparisons( ...
  olddata, probedefs, squashfields, squashdata, squashvar )

% function newdata = eiAux_squashWithinProbeComparisons( ...
%   olddata, probedefs, squashfields, squashdata, squashvar )
%
% This squashes pairwise information values corresponding to within-probe
% comparisons. This can either be to eliminate spurious associations due to
% multiple channels picking up the same neuron, or to allow easier analysis
% of between-probe information flow.
%
% "olddata" is a pairwise information data structure per TIMEWINLAGDATA.txt.
% "probedefs" is a struct array with probe definitions per PROBEDEFS.txt.
% "squashfields" is a cell array with the the prefixes of data fields being
%   operated on. For prefix "FOO", the fields "FOOdata", "FOOcount",
%   and "FOOvar" are expected to exist.
% "squashdata" is the value to replace squashed data values with.
% "squashvar" is the value to replace squashed data's variance values with.
%
% "newdata" is a copy of "olddata" with within-probe data values squashed.


newdata = olddata;


dstlabels = newdata.destchans;
srclabels = newdata.srcchans;


% Build lists of squash fields for data and for variance.

squashdatafields = {};
squashvarfields = {};
for fidx = 1:length(squashfields)
  thisprefix = squashfields{fidx};
  squashdatafields{fidx} = [ thisprefix 'data' ];
  squashvarfields{fidx} = [ thisprefix 'var' ];
end

squashdatafields = ...
  squashdatafields( contains(squashdatafields, fieldnames(newdata)) );

squashvarfields = ...
  squashvarfields( contains(squashvarfields, fieldnames(newdata)) );


% Do the squashing.

for pidx = 1:length(probedefs)
  probelabels = probedefs(pidx).chanlabels;

  dstmask = contains( dstlabels, probelabels );
  srcmask = contains( srclabels, probelabels );

  for fidx = 1:length(squashdatafields)
    thisfield = squashdatafields{fidx};
    newdata.(thisfield)(dstmask, srcmask, :, :, :) = squashdata;
  end

  for fidx = 1:length(squashvarfields)
    thisfield = squashvarfields{fidx};
    newdata.(thisfield)(dstmask, srcmask, :, :, :) = squashvar;
  end
end


% Done.
end


%
% This is the end of the file.
