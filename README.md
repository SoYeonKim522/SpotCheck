# SpotCheck

SpotCheck is an iOS app that shows which study seats are free in UTS buildings, so students can choose a level before walking there. Students can check in to a seat to hold it for one hour, and other students can see the updated availability.

Built for UTS 40005 Advanced iOS Development, Assessment 3.

Repository: https://github.com/SoYeonKim522/SpotCheck

## Domain context

A student with a one-hour gap between classes has no way to see where a free self-study seat is. Students may need to walk between several levels to find an available seat, which can use up much of their limited break.

UTS does not have occupancy sensors for individual open study seats, so SpotCheck relies on students reporting availability themselves. Students check in when they take a seat, and other students see the resulting availability counts. Because this information can become outdated, each availability count records when it was read, and every check-in automatically expires after one hour unless the student extends it, up to a maximum of three hours.

## Architecture

The app uses MVVM with a Use Case layer between the ViewModels and the data layer.

```
Views -> ViewModels -> Use Cases -> Repository protocols -> Supabase implementation -> Supabase Postgres + Auth
```

- Views and ViewModels are responsible for displaying state and error messages.
- Use Cases contain the business rules and define their own typed error enums.
- Repositories are defined as protocols, so the tests can use mock repositories instead of connecting to Supabase.
- Only the `Data` group imports Supabase. It maps database rows to domain structs, keeping the rest of the application independent of the Supabase SDK.
- After every successful availability read, the app writes an `AvailabilitySnapshot` to the App Group container. The widget reads this snapshot and never connects to Supabase directly.

The four use cases are `CheckIntoSeatUseCase`, `ReleaseSeatUseCase`, `ExtendHoldUseCase` and `ViewLevelAvailabilityUseCase`.

## Extensions

### Widget (`SpotCheckWidget`)

The WidgetKit extension lets a student between classes check the availability of the building they last viewed without opening the app. It can also show their currently held seat and the time remaining on the hold.

The widget supports `systemSmall`, `systemMedium` and `accessoryRectangular`. It shows when the availability data was last read and displays "Not recent" after 15 minutes.

The widget works without a network connection because it only reads the latest `AvailabilitySnapshot` from the shared App Group container. It never accesses Supabase directly.

### Notification Content Extension (`SpotCheckNotificationContent`)

Crowdsourced data goes wrong when students forget to release a seat they have left. The reminder lets a student keep the seat or release it without opening the app.

Ten minutes before a seat hold expires, the app sends a reminder. The expanded notification shows the current seat and remaining hold time, with actions to extend or release the hold.

The main app handles these actions, so the notification extension does not need to access the Supabase session directly.

## Database

SpotCheck uses Supabase, which provides a hosted PostgreSQL database and Supabase Auth. Check-ins need to be shared between students, so the availability data has to be stored remotely rather than only on the user's device.

The database contains five related tables: `buildings`, `levels`, `zones`, `seats` and `seat_check_ins`. Row Level Security (RLS) is enabled for every table. A student can only insert or update a check-in associated with their own authenticated account.

A seat is considered occupied only when it has an active check-in that has not been released or expired.

The database does not store a separate occupancy count. Instead, the app calculates availability from active check-ins. This means an expired hold stops affecting availability automatically, without needing a timer or a cleanup job.

## App Group

```
group.com.soyeonkim.spotcheck
```

The identifier is defined in `SpotCheck/Shared/AppGroup.swift`. The main app, widget extension and notification content extension all include this App Group in their entitlements so they can access the shared container.

The shared container stores the latest `AvailabilitySnapshot`, which allows the widget to display availability without making its own network request.

## Setup

You need Xcode 26. The project targets iOS 26.2.

The app is preconfigured to connect to a hosted Supabase project containing the required database schema and seeded data. No Supabase setup is required to run the project.

1. Clone the repository with `git clone https://github.com/SoYeonKim522/SpotCheck.git`.
2. Open `SpotCheck.xcodeproj`. Xcode downloads the Supabase Swift package dependencies.
3. In Signing & Capabilities, select your Apple Developer team for the main app and both extensions. If you change the bundle identifiers, update the App Group identifier in `AppGroup.swift` and in all three `.entitlements` files.
4. Run the `SpotCheck` scheme on an iPhone simulator.
5. Sign in with the test account. The app does not have a sign-up screen.
   - Email: `spotcheck@gmail.com`
   - Password: `spotcheck`

### Using your own Supabase project

This is optional and only required if the hosted project is unavailable.

1. Create a new Supabase project.
2. In the Supabase SQL Editor, run the following files from the `supabase` folder in this order:
   1. `schema.sql` creates the tables, grants and Row Level Security policies.
   2. `seed.sql` adds the buildings, levels, zones and seats.
   3. `demo-occupants.sql` adds the demo accounts used for other students' check-ins.
   4. `refresh-demo-check-ins.sql` adds the demo check-ins.
3. In Supabase Authentication, create a user with an email and password and confirm the email.
4. Replace the project URL and anon key in `SupabaseConfig.swift`. Do not put the `service_role` key anywhere in the project.

## Running the tests

Choose the `SpotCheck` scheme and press Cmd+U. The tests use `MockStudySpaceRepository`, `MockWidgetRefresher` and `MockReminderScheduler`, so they do not require a network connection or a live Supabase project.

## Testing the extensions quickly

A seat hold normally lasts one hour, and the reminder is sent ten minutes before it expires. To test the timing in minutes, add the following launch argument in Edit Scheme > Run > Arguments:

```
-holdTimeDivisor 60
```

This divides the hold duration by 60, so a hold lasts one minute and the reminder fires after 50 seconds. The argument only affects Debug builds. Release builds always use the real durations defined in `SeatHoldPolicy`.

## Seeded data

The other students' check-ins are seeded using demo accounts ending in `@spotcheck.test`. These accounts and their check-ins are created by the SQL files described in the Setup section.

Run `refresh-demo-check-ins.sql` again only if the seeded demo check-ins have expired before a demonstration.
