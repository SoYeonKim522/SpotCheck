delete from seat_check_ins
where occupant_id in (select id from auth.users where email like '%@spotcheck.test');

with held as (
    select *
    from (values
        ('Building 2', 4, 5),
        ('Building 2', 5, 17),
        ('Building 2', 6, 21),
        ('Building 2', 7, 7),
        ('Building 2', 8, 10),
        ('Building 2', 9, 3),
        ('Building 1', 3, 2),
        ('Building 1', 4, 6),
        ('Building 11', 5, 10),
        ('Building 11', 6, 3)
    ) as v (building, number, seat_count)
),
ranked as (
    select
        s.id as seat_id,
        l.id as level_id,
        h.seat_count,
        row_number() over (partition by l.id order by z.name, s.label) - 1 as position,
        count(*) over (partition by l.id) as total
    from seats s
    join zones z on z.id = s.zone_id
    join levels l on l.id = z.level_id
    join buildings b on b.id = l.building_id
    join held h on h.building = b.name and h.number = l.number
),
spread as (
    select distinct on (level_id, position * seat_count / total) seat_id, level_id
    from ranked
    order by level_id, position * seat_count / total, position
),
claimed as (
    select seat_id, row_number() over (order by level_id, seat_id) as n
    from spread
),
demo_occupants as (
    select id, row_number() over (order by email) as n
    from auth.users
    where email like '%@spotcheck.test'
)
insert into seat_check_ins (seat_id, occupant_id, checked_in_at, expires_at)
select seat_id, occupant_id, checked_in_at, checked_in_at + held
from (
    select
        c.seat_id,
        d.id as occupant_id,
        now() - interval '1 minute' * case
            when c.n % 4 = 0 then 40 + c.n % 61
            else 1 + c.n % 40
        end as checked_in_at,
        case when c.n % 4 = 0 then interval '2 hours' else interval '1 hour' end as held
    from claimed c
    join demo_occupants d on d.n = c.n
) as timed;

insert into seat_check_ins (seat_id, occupant_id, checked_in_at, expires_at)
select
    s.id,
    (select id from auth.users where email like '%@spotcheck.test' order by email desc limit 1),
    now() - interval '74 minutes',
    now() - interval '14 minutes'
from seats s
join zones z on z.id = s.zone_id
join levels l on l.id = z.level_id
join buildings b on b.id = l.building_id
where b.name = 'Building 2' and l.number = 9 and z.name = 'Library' and s.label = '9C6';
