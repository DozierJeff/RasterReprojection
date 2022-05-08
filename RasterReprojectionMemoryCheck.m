function RasterReprojectionMemoryCheck(neededMemory)

if ispc
    [~,sysview] = memory;
    availablePhysicalMemory = sysview.PhysicalMemory.Available;
    availableVirtualMemory = sysview.SystemMemory.Available;
elseif ismac
    [r,w] = system('vm_stat'); %#ok<*ASGLU>
    stats = str2double(regexp(w,'\d{1,}','match'));
    %(pages active + pages speculative + pages wired down + pages occupied by
    %compressor) * page size * bytes
    used = sum(stats([3 5 7 17]))*stats(1);
    [r,w] = system('sysctl hw.memsize');
    stats=regexp(w,'\d{1,}','match');
    availablePhysicalMemory=str2double(stats)-used;
    [r,w]=system('sysctl vm.swapusage');
    stats=regexp(w,'M','split');
    availableVirtualMemory=str2double(stats{3}(10:end))*1e6;
elseif isunix
    [r,w] = unix('free -b');
    stats=str2double(regexp(w,'\d{1,}','match'));
    availablePhysicalMemory = stats(3) + stats(6);
    availableVirtualMemory = availablePhysicalMemory + stats(9);
end
% warning if possible memory problems
if neededMemory>availableVirtualMemory
    error('not enough memory available, virtual=%g, needed=%g (so break the problem up)',...
        availableVirtualMemory,neededMemory)
end
if neededMemory>availablePhysicalMemory
    warning('not enough physical memory available, physical=%g, needed=%g (using virtual memory may slow processing)',...
        availablePhysicalMemory,neededMemory)
end
end