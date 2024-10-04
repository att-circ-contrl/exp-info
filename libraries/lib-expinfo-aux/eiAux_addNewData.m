function newdata = eiAux_addNewData( olddata, patchdata )

% function newdata = eiAux_addNewData( olddata, patchdata )
%
% This adds a subset of a time-and-lag dataset to a larger set.
% The idea is to be able to compute patches of the larger dataset
% independently and then merge them.
%
% "olddata" is a time and lag dataset, per TIMEWINLAGDATA.txt. This needs
%   to have metadata fields, but data arrays can be absent.
% "patchdata" is a time and lag dataset using a subset of the source and
%   destination channels used by "olddata".
%
% "newdata" is a copy of "olddata" with data elements corresponding to
%   "patchdata" overwritten with the content of "patchdata".


newdata = olddata;


% Figure out the channel mapping.
% Don't assume that they're in order.

newdestchans = newdata.destchans;
newsrcchans = newdata.srcchans;

patchdestchans = patchdata.destchans;
patchsrcchans = patchdata.srcchans;

newdestfrompatch = nan(size(patchdestchans));
for cidx = 1:length(patchdestchans)
  thischan = patchdestchans(cidx);
  thispos = min(find( strcmp(newdestchans, thischan) ));
  if ~isempty(thispos)
    newdestfrompatch(cidx) = thispos;
  end
end

newsrcfrompatch = nan(size(patchsrcchans));
for cidx = 1:length(patchsrcchans)
  thischan = patchsrcchans(cidx);
  thispos = min(find( strcmp(newsrcchans, thischan) ));
  if ~isempty(thispos)
    newsrcfrompatch(cidx) = thispos;
  end
end


% Squawk if we couldn't map channels, but tolerate it.
if any(isnan(newdestfrompatch)) || any(isnan(newsrcfrompatch))
  disp('###  [eiAux_addNewData]  Couldn''t map all patch channels!');
end


% Walk through fields, merging. Assume anything four-dimensional is data.
% We can initialize missing fields.

scratchblank = nan([ length(newdata.destchans), length(newdata.srcchans), ...
  length(newdata.windowlist_ms), length(newdata.delaylist_ms) ]);

fieldlist = fieldnames(patchdata);
for fidx = 1:length(fieldlist)
  thisfield = fieldlist{fidx};
  scratchpatch = patchdata.(thisfield);
  if 4 == ndims(scratchpatch)
    scratchnew = scratchblank;
    if isfield(newdata, thisfield)
      scratchnew = newdata.(thisfield);
    end

    % Do this by hand instead of playing indexing games, just in case.
    for destidx = 1:length(newdestfrompatch)
      for srcidx = 1:length(newsrcfrompatch)
        scratchnew( newdestfrompatch(destidx), newsrcfrompatch(srcidx), ...
          :, :) = scratchpatch( destidx, srcidx, :, : );
      end
    end

    newdata.(thisfield) = scratchnew;
  end
end


% Done.
end


%
% This is the end of the file.
