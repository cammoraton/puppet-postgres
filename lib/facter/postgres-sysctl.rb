require 'facter'

# Get the Shared Memory All and Shared Memory Max sysctl values
# for the purposes of setting defaults.
Facter.add("kernel_shmall") do
  confine :kernel => :Linux
  result = %x{/bin/cat /proc/sys/kernel/shmall}.chomp
  setcode do
    result
  end
end

Facter.add("kernel_shmmax") do
  confine :kernel => :Linux
  
  result = %x{/bin/cat /proc/sys/kernel/shmmax}.chomp
  setcode do
    result
  end
end
