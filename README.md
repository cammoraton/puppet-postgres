puppet-postgres
===============

Still has a lot of work to do.  The augeas pg_hba stuff is missing method options.
I'm still not very happy with pg_exec(a chunk of which I ripped out of regular exec), 
and a number of params should do things with arrays, validations and autorequires that 
they don't currently do.

I'm also providing 2 different ways to do "groups" and they aren't compatable, you can define
members of a role, or groups on a role.  If these differ then depending on resource order it will
add/change them.  We can parse the resource table which is how the users provider/type does it, but
that may be overkill.

I'm thinking definitions that wrap the pg_role function and provide pg_user and pg_group(which differ based on the
login setting these days).

