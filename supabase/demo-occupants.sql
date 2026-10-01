insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at
)
select
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    'demo' || lpad(n::text, 3, '0') || '@spotcheck.test',
    '',
    now(),
    now(),
    now()
from generate_series(1, 85) as n;
