puppet-postgres
===============

Module for dealing with postgres and postgres databases in Puppet.

Still has a lot of work to do.  I'm not very happy with pg_exec but
the provider/type documentation in puppet is not too hot.  Right now it's set to
ensurable and completely bypasses this by doing nothing with instances, prefetch,
create, or exists?

I'm also providing 2 different ways to do "groups" and they aren't compatable, you can define
members of a role, or groups on a role.  If these differ then depending on resource order it will
add/change them.  I also had trouble getting arrays to take in type, which needs resolved.

The augeas pg_hba stuff is missing method options.
