puppet-postgres
===============

A lot of stuff here is RHEL specific(but really, RHEL isn't incredibly wierd or anything when it comes to postgres paths, it's really just the
data directory that changes), although the providers and types should just work on pretty much any linux.
Between those and the definitions that should be most of the hard work done on a postgres module more tuned
to your environment.

This still has a lot of work to do.  The augeas pg_hba stuff needs a better way to do multiple methods.  Right now it will 
work just fine the first time and then fail.  Pg_exec needs its regex-based constraint.  Not desperately, but it would 
be nice.  I also need to add in more checks to make it less dangerous.

I was going to do a template for postgresql.conf but augeas > 10.1 includes a generic lens which can parse it and that's much preferable.  I need to craft a spec for it so I can make an rpm though.

I'm also providing 2 different ways to do "groups" and they aren't compatable, you can define
members of a role, or groups on a role.  If these differ then depending on resource order it will
add/change them.  We can parse the resource table which is how the users provider/type does it, but
that may be overkill.  I'm not familiar enough yet with whether I can just set a value to non-unique and if puppet
is smart enough to do it, or if I should drop to the ddl or something.

Anyway, there are 3 basic provider/types here:
* pg_exec     - a catchall for conditionally executing sql on a postgres server
* pg_database - manipulate databases.
* pg_role     - manipulate roles.

Additionally it provides 2 shared memory facts from sysctl for the purposes of autotuning things like shared buffers.