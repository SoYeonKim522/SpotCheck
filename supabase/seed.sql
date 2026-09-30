insert into buildings (name, address, display_order) values
    ('Building 2', '61 Broadway, Ultimo', 0),
    ('Building 1', '15 Broadway, Ultimo', 1),
    ('Building 11', '81 Broadway, Ultimo', 2);

insert into levels (building_id, number)
select b.id, v.number
from buildings b
join (values
    ('Building 2', 4), ('Building 2', 5), ('Building 2', 6),
    ('Building 2', 7), ('Building 2', 8), ('Building 2', 9),
    ('Building 1', 3), ('Building 1', 4),
    ('Building 11', 5), ('Building 11', 6)
) as v (building, number) on v.building = b.name;

insert into zones (level_id, name, noise_level)
select l.id, v.zone, v.noise_level
from levels l
join buildings b on b.id = l.building_id
join (values
    ('Building 2', 4, 'Open Study', 'collaborative'),
    ('Building 2', 5, 'Reading Room', 'silent'),
    ('Building 2', 5, 'Open Study', 'collaborative'),
    ('Building 2', 6, 'Open Study', 'collaborative'),
    ('Building 2', 6, 'Library', 'quiet'),
    ('Building 2', 7, 'Library', 'quiet'),
    ('Building 2', 8, 'Library', 'quiet'),
    ('Building 2', 9, 'Library', 'quiet'),
    ('Building 1', 3, 'Open Study', 'collaborative'),
    ('Building 1', 4, 'Open Study', 'collaborative'),
    ('Building 11', 5, 'Open Study', 'collaborative'),
    ('Building 11', 6, 'Open Study', 'collaborative')
) as v (building, number, zone, noise_level)
    on v.building = b.name and v.number = l.number;

insert into seats (
    zone_id, label,
    is_by_window, has_computer, has_power_outlet, has_partition, is_shared_table
)
select
    z.id,
    v.prefix || n,
    v.is_by_window, v.has_computer, v.has_power_outlet, v.has_partition, v.is_shared_table
from zones z
join levels l on l.id = z.level_id
join buildings b on b.id = l.building_id
join (values
    ('Building 2', 4, 'Open Study', '4A', 12, false, false, true, false, true),
    ('Building 2', 4, 'Open Study', '4B', 8, true, false, false, false, true),
    ('Building 2', 5, 'Reading Room', '5R', 16, false, false, true, true, false),
    ('Building 2', 5, 'Open Study', '5A', 10, false, false, true, false, true),
    ('Building 2', 6, 'Open Study', '6A', 12, false, false, false, false, true),
    ('Building 2', 6, 'Library', '6L', 10, false, false, true, true, false),
    ('Building 2', 7, 'Library', '7L', 14, false, false, true, false, false),
    ('Building 2', 7, 'Library', '7W', 6, true, false, false, false, false),
    ('Building 2', 8, 'Library', '8L', 18, false, false, true, true, false),
    ('Building 2', 9, 'Library', '9L', 12, false, false, false, true, false),
    ('Building 2', 9, 'Library', '9C', 6, false, true, true, false, false),
    ('Building 1', 3, 'Open Study', 'T3', 8, false, false, false, false, true),
    ('Building 1', 4, 'Open Study', 'T4', 10, false, false, true, false, true),
    ('Building 11', 5, 'Open Study', 'E5', 12, false, false, true, false, true),
    ('Building 11', 6, 'Open Study', 'E6', 10, true, false, false, false, true)
) as v (
    building, number, zone, prefix, seat_count,
    is_by_window, has_computer, has_power_outlet, has_partition, is_shared_table
) on v.building = b.name and v.number = l.number and v.zone = z.name
cross join generate_series(1, v.seat_count) as n;
