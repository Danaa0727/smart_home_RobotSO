update public.profiles set role = 'ADMIN' where email = 'admin@robotos.com';
update public.profiles set role = 'USER' where email = 'user@robotos.com';
update public.profiles set role = 'GUEST' where email = 'guest@robotos.com';

select email, role from public.profiles order by role;
