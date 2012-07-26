# Query the postgres database as the postgres user
# for all of the stored procedures in the public schema
# you should then be able to use these facts to determine
# if the sql component of a module(IE: postgis) is installed
result = %x{psql -U postgres -t -A -c "SELECT proname  
            FROM pg_catalog.pg_namespace n 
            JOIN pg_catalog.pg_proc p ON pronamespace = n.oid
            WHERE nspname = 'public';"}.split(/\n\r|\n|\r\n/).uniq.sort.join('|')
# Do the query then split it by newline.  
# Then join it so we can split it later.  
# We'll use the default postgres return separator since it's both a special character 
# and if you script things you probably won't be using it in function names.

Facter.add('postgres_functions') do
  setcode do

    result
  end
end
