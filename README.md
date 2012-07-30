puppet-postgres
===============

A lot of stuff here is RHEL specific, although the providers and types should just work on pretty much any linux.
Between those and the definitions that should be most of the hard work done on a postgres module more tuned
to your environment.

This still has a lot of work to do.  The augeas pg_hba stuff is missing method options.
Pg_exec needs its regex-based constraint.  Not desperately, but it would be nice.  I also need to add in more
checks to make it less dangerous.

I'm also providing 2 different ways to do "groups" and they aren't compatable, you can define
members of a role, or groups on a role.  If these differ then depending on resource order it will
add/change them.  We can parse the resource table which is how the users provider/type does it, but
that may be overkill.

Anyway, there are 3 basic provider/types here:

* pg_exec     - a catchall for conditionally executing sql on a postgres server
* pg_database - manipulate databases.
* pg_role     - manipulate roles.
