alter table public.profiles
  add column public_profile_id uuid not null default gen_random_uuid();

alter table public.profiles
  add constraint profiles_public_profile_id_key unique (public_profile_id);

alter table public.program_scores
  add column public_id uuid not null default gen_random_uuid();

alter table public.program_scores
  add constraint program_scores_public_id_key unique (public_id);

create index programs_public_catalog_idx
  on public.programs (starts_on desc, id)
  where status in ('scheduled', 'active', 'completed', 'archived');

create index profiles_public_coach_directory_idx
  on public.profiles (display_name, public_profile_id)
  where role = 'coach'
    and coach_is_approved
    and coach_is_public
    and onboarding_status = 'active';

create index program_enrollments_public_leaderboard_idx
  on public.program_enrollments (program_id, status, id)
  where status in ('active', 'completed');

create index winner_posters_public_idx
  on public.winner_posters (published_at desc, id)
  where is_published;

create or replace function public.list_public_programs(
  target_program_id uuid default null,
  result_limit integer default 50,
  result_offset integer default 0
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if result_limit not between 1 and 100 or result_offset < 0 then
    raise exception 'pagination_invalid';
  end if;

  return query
  select jsonb_build_object(
    'id', program.id,
    'source_program_id', program.source_program_id,
    'title', program.title,
    'summary', program.summary,
    'category', program.category,
    'cover_path', program.cover_path,
    'cover_alt_text', program.cover_alt_text,
    'status', program.status,
    'pace', program.pace,
    'duration_mode', program.duration_mode,
    'starts_on', program.starts_on,
    'ends_on', program.ends_on,
    'timezone', program.timezone,
    'participant_limit', program.participant_limit,
    'registration_closes_at', program.registration_closes_at,
    'past_step_policy', program.past_step_policy,
    'future_step_policy', program.future_step_policy,
    'wellness_disclaimer', program.wellness_disclaimer,
    'points_per_activity', program.points_per_activity,
    'points_per_weight_kg', program.points_per_weight_kg,
    'quiz_passing_percentage', program.quiz_passing_percentage,
    'pricing_mode', program.pricing_mode,
    'desired_price', program.desired_price,
    'program_days', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', day.id,
            'day_number', day.day_number,
            'title', day.title,
            'summary', day.summary,
            'scheduled_on', day.scheduled_on,
            'program_steps', coalesce(
              (
                select jsonb_agg(
                  jsonb_build_object(
                    'id', step.id,
                    'step_order', step.step_order,
                    'title', step.title,
                    'instructions', step.instructions,
                    'content_kind', step.content_kind,
                    'completion_policy', step.completion_policy,
                    'verification_mode', step.verification_mode,
                    'media_path', step.media_path,
                    'media_alt_text', step.media_alt_text,
                    'video_required', step.video_required,
                    'video_threshold', step.video_threshold,
                    'video_autoplay', step.video_autoplay,
                    'program_questions', coalesce(
                      (
                        select jsonb_agg(
                          jsonb_build_object(
                            'id', question.id,
                            'question_order', question.question_order,
                            'kind', question.kind,
                            'prompt', question.prompt,
                            'program_question_options', coalesce(
                              (
                                select jsonb_agg(
                                  jsonb_build_object(
                                    'id', option.id,
                                    'option_order', option.option_order,
                                    'title', option.title,
                                    'media_path', option.media_path,
                                    'media_alt_text',
                                      option.media_alt_text
                                  )
                                  order by option.option_order, option.id
                                )
                                from public.program_question_options option
                                where option.question_id = question.id
                              ),
                              '[]'::jsonb
                            )
                          )
                          order by question.question_order, question.id
                        )
                        from public.program_questions question
                        where question.step_id = step.id
                      ),
                      '[]'::jsonb
                    )
                  )
                  order by step.step_order, step.id
                )
                from public.program_steps step
                where step.program_day_id = day.id
              ),
              '[]'::jsonb
            )
          )
          order by day.day_number, day.id
        )
        from public.program_days day
        where day.program_id = program.id
      ),
      '[]'::jsonb
    )
  )
  from public.programs program
  where program.status in (
      'scheduled', 'active', 'completed', 'archived'
    )
    and (
      target_program_id is null
      or program.id = target_program_id
    )
  order by program.starts_on desc, program.id
  limit result_limit
  offset result_offset;
end;
$$;

create or replace function public.list_public_coaches(
  result_limit integer default 50,
  result_offset integer default 0
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if result_limit not between 1 and 100 or result_offset < 0 then
    raise exception 'pagination_invalid';
  end if;

  return query
  select jsonb_build_object(
    'id', profile.public_profile_id,
    'display_name', profile.display_name,
    'biography', '',
    'city', profile.city,
    'photo_reference', profile.provider_avatar_url
  )
  from public.profiles profile
  where profile.role = 'coach'
    and profile.coach_is_approved
    and profile.coach_is_public
    and profile.onboarding_status = 'active'
  order by profile.display_name, profile.public_profile_id
  limit result_limit
  offset result_offset;
end;
$$;

create or replace function public.list_public_leaderboard(
  target_program_id uuid,
  result_limit integer default 100,
  result_offset integer default 0
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if target_program_id is null then
    raise exception 'program_required';
  end if;
  if result_limit not between 1 and 100 or result_offset < 0 then
    raise exception 'pagination_invalid';
  end if;

  return query
  select jsonb_build_object(
    'id', score.public_id,
    'program_id', enrollment.program_id,
    'participant_id', profile.public_profile_id,
    'participant_display_name', profile.display_name,
    'rank', coalesce(
      score.rank,
      row_number() over (
        order by
          (
            score.activity_points
            + score.quiz_points
            + score.weight_points
            + score.adjustment_points
          ) desc,
          profile.display_name,
          score.public_id
      )::integer
    ),
    'progress_percentage', score.progress_percentage,
    'total_points',
      score.activity_points
      + score.quiz_points
      + score.weight_points
      + score.adjustment_points
  )
  from public.program_scores score
  join public.program_enrollments enrollment
    on enrollment.id = score.enrollment_id
  join public.profiles profile
    on profile.user_id = enrollment.participant_id
  join public.programs program
    on program.id = enrollment.program_id
  where enrollment.program_id = target_program_id
    and enrollment.status in ('active', 'completed')
    and program.status in (
      'scheduled', 'active', 'completed', 'archived'
    )
  order by
    (
      score.activity_points
      + score.quiz_points
      + score.weight_points
      + score.adjustment_points
    ) desc,
    profile.display_name,
    score.public_id
  limit result_limit
  offset result_offset;
end;
$$;

create or replace function public.list_public_winners(
  target_program_id uuid,
  result_limit integer default 5,
  result_offset integer default 0
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if target_program_id is null then
    raise exception 'program_required';
  end if;
  if result_limit not between 1 and 5 or result_offset < 0 then
    raise exception 'pagination_invalid';
  end if;

  return query
  select jsonb_build_object(
    'id', winner.id,
    'program_id', snapshot.program_id,
    'participant_id', profile.public_profile_id,
    'rank', winner.rank,
    'participant_display_name', winner.display_name,
    'total_points', winner.total_points,
    'locked_at', snapshot.locked_at
  )
  from public.program_winners winner
  join public.winner_snapshots snapshot
    on snapshot.id = winner.snapshot_id
  join public.profiles profile
    on profile.user_id = winner.participant_id
  join public.programs program
    on program.id = snapshot.program_id
  where snapshot.program_id = target_program_id
    and program.status in ('completed', 'archived')
  order by winner.rank, winner.id
  limit result_limit
  offset result_offset;
end;
$$;

create or replace function public.list_public_winner_posters(
  result_limit integer default 20,
  result_offset integer default 0
)
returns setof jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if result_limit not between 1 and 100 or result_offset < 0 then
    raise exception 'pagination_invalid';
  end if;

  return query
  select jsonb_build_object(
    'id', poster.id,
    'kind', 'winner_banner',
    'title', program.title,
    'body', poster.alt_text,
    'media_reference', poster.media_path,
    'program_id', poster.program_id,
    'winner_snapshot_id', poster.winner_snapshot_id,
    'visible_from', poster.published_at,
    'visible_until', null,
    'sort_order', row_number() over (
      order by poster.published_at desc nulls last, poster.id
    ),
    'is_published', true,
    'is_archived', false,
    'updated_at', coalesce(
      poster.published_at,
      '1970-01-01 00:00:00+00'::timestamptz
    )
  )
  from public.winner_posters poster
  join public.programs program
    on program.id = poster.program_id
  where poster.is_published
    and poster.published_at is not null
    and program.status in ('completed', 'archived')
  order by poster.published_at desc, poster.id
  limit result_limit
  offset result_offset;
end;
$$;

revoke all on function public.list_public_programs(uuid, integer, integer)
  from public, anon, authenticated, service_role;
revoke all on function public.list_public_coaches(integer, integer)
  from public, anon, authenticated, service_role;
revoke all on function public.list_public_leaderboard(
  uuid, integer, integer
) from public, anon, authenticated, service_role;
revoke all on function public.list_public_winners(uuid, integer, integer)
  from public, anon, authenticated, service_role;
revoke all on function public.list_public_winner_posters(integer, integer)
  from public, anon, authenticated, service_role;

grant execute on function public.list_public_programs(
  uuid, integer, integer
) to anon, authenticated;
grant execute on function public.list_public_coaches(integer, integer)
  to anon, authenticated;
grant execute on function public.list_public_leaderboard(
  uuid, integer, integer
) to anon, authenticated;
grant execute on function public.list_public_winners(
  uuid, integer, integer
) to anon, authenticated;
grant execute on function public.list_public_winner_posters(
  integer, integer
) to anon, authenticated;
