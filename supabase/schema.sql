create table buildings (
    id uuid primary key default gen_random_uuid(),
    name text not null unique,
    address text not null,
    display_order int not null default 0
);

create table levels (
    id uuid primary key default gen_random_uuid(),
    building_id uuid not null references buildings (id) on delete cascade,
    number int not null,
    unique (building_id, number)
);

create table zones (
    id uuid primary key default gen_random_uuid(),
    level_id uuid not null references levels (id) on delete cascade,
    name text not null,
    noise_level text check (noise_level in ('silent', 'quiet', 'collaborative')),
    unique (level_id, name)
);

create table seats (
    id uuid primary key default gen_random_uuid(),
    zone_id uuid not null references zones (id) on delete cascade,
    label text not null,
    is_by_window boolean not null default false,
    has_computer boolean not null default false,
    has_power_outlet boolean not null default false,
    has_partition boolean not null default false,
    is_shared_table boolean not null default false,
    unique (zone_id, label)
);

create table seat_check_ins (
    id uuid primary key default gen_random_uuid(),
    seat_id uuid not null references seats (id) on delete cascade,
    occupant_id uuid not null references auth.users (id) on delete cascade,
    checked_in_at timestamptz not null default now(),
    expires_at timestamptz not null,
    released_at timestamptz
);

create index seat_check_ins_active_by_seat
    on seat_check_ins (seat_id, expires_at)
    where released_at is null;

create index seat_check_ins_active_by_occupant
    on seat_check_ins (occupant_id, expires_at)
    where released_at is null;

grant select on buildings, levels, zones, seats, seat_check_ins to authenticated;
grant insert, update on seat_check_ins to authenticated;

alter table buildings enable row level security;
alter table levels enable row level security;
alter table zones enable row level security;
alter table seats enable row level security;
alter table seat_check_ins enable row level security;

create policy "signed in students can read buildings"
    on buildings for select to authenticated using (true);

create policy "signed in students can read levels"
    on levels for select to authenticated using (true);

create policy "signed in students can read zones"
    on zones for select to authenticated using (true);

create policy "signed in students can read seats"
    on seats for select to authenticated using (true);

create policy "signed in students can read every check in"
    on seat_check_ins for select to authenticated using (true);

create policy "a student checks in only as themselves"
    on seat_check_ins for insert to authenticated
    with check (occupant_id = auth.uid());

create policy "a student releases only their own seat"
    on seat_check_ins for update to authenticated
    using (occupant_id = auth.uid())
    with check (occupant_id = auth.uid());
