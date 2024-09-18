function newdata = eiAux_sortTimeLagChannels( olddata )

% function newdata = eiAux_sortTimeLagChannels( olddata )
%
% This sorts a time/lag dataset's source and destination channels by label.
%
% "olddata" is a time/lag data structure, per TIMEWINLAGDATA.txt.
%
% "newdata" is a copy of "olddata" with channels sorted.


newdata = olddata;


[ destchans destoldidx ] = sort(olddata.destchans);
[ srcchans srcoldidx ] = sort(olddata.srcchans);

newdata.destchans = destchans;
newdata.srcchans = srcchans;


% Walk through the fields, processing any that are four-dimensional.

fieldlist = fieldnames(olddata);
for fidx = 1:length(fieldlist)
  thisfield = fieldlist{fidx};
  if 4 == ndims(olddata.(thisfield))

    thisold = olddata.(thisfield);

    thisnew = nan(size(thisold));
    for destidx = 1:length(destchans)
      thisnew(destidx,:,:,:) = thisold( destoldidx(destidx), :, :, : );
    end

    thisold = thisnew;

    thisnew = nan(size(thisold));
    for srcidx = 1:length(srcchans)
      thisnew(:,srcidx,:,:) = thisold( :, srcoldidx(srcidx), :, : );
    end

    newdata.(thisfield) = thisnew;

  end
end


% Done.
end


%
% This is the end of the file.
