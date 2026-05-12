# Project Structure Rules

## Folder Structure

```
lib/
  main.dart
  firebase_options.dart

  app/
    app.dart
    router/
      app_router.dart
      route_names.dart

  core/
    constants/
      app_constants.dart
      app_assets.dart
      app_strings.dart
    errors/
      app_exception.dart
      failure.dart
    services/
      firebase_service.dart
      gemini_service.dart
      file_picker_service.dart
      link_validation_service.dart
    theme/
      app_colors.dart
      app_theme.dart
      app_text_styles.dart
    utils/
      date_formatter.dart
      validators.dart
      json_parser.dart
    widgets/
      app_button.dart
      app_text_field.dart
      app_loader.dart
      empty_state.dart
      status_chip.dart

  features/
    auth/
      data/
        datasources/
          auth_remote_datasource.dart
        repositories/
          auth_repository_impl.dart
      domain/
        entities/
          app_user.dart
        repositories/
          auth_repository.dart
        usecases/
          login_usecase.dart
          register_usecase.dart
          logout_usecase.dart
          forgot_password_usecase.dart
      presentation/
        providers/
          auth_provider.dart
        pages/
          login_page.dart
          register_page.dart
          forgot_password_page.dart
        widgets/
          auth_header.dart
          auth_form.dart

    home/
      presentation/
        pages/
          home_page.dart
        widgets/
          home_quick_actions.dart
          recent_meetings_list.dart
          task_overview_card.dart
          dashboard_stats.dart

    meeting_import/
      data/
        models/
          meeting_import_request_model.dart
        repositories/
          meeting_import_repository_impl.dart
      domain/
        entities/
          meeting_import_request.dart
        repositories/
          meeting_import_repository.dart
        usecases/
          import_meeting_file_usecase.dart
          import_meeting_link_usecase.dart
      presentation/
        providers/
          meeting_import_provider.dart
        pages/
          import_meeting_page.dart
        widgets/
          upload_file_card.dart
          paste_link_card.dart
          processing_status_card.dart

    meetings/
      data/
        models/
          meeting_model.dart
          meeting_summary_model.dart
          decision_model.dart
        repositories/
          meetings_repository_impl.dart
      domain/
        entities/
          meeting.dart
          meeting_summary.dart
          decision.dart
        repositories/
          meetings_repository.dart
        usecases/
          get_meetings_usecase.dart
          get_meeting_details_usecase.dart
          save_meeting_result_usecase.dart
          delete_meeting_usecase.dart
      presentation/
        providers/
          meetings_provider.dart
          meeting_details_provider.dart
        pages/
          meetings_page.dart
          meeting_details_page.dart
        widgets/
          meeting_card.dart
          summary_section.dart
          mom_section.dart
          decisions_section.dart
          participants_section.dart
          follow_ups_section.dart

    tasks/
      data/
        models/
          task_model.dart
        repositories/
          tasks_repository_impl.dart
      domain/
        entities/
          meeting_task.dart
        repositories/
          tasks_repository.dart
        usecases/
          get_tasks_usecase.dart
          update_task_status_usecase.dart
          create_task_usecase.dart
      presentation/
        providers/
          tasks_provider.dart
        pages/
          tasks_page.dart
        widgets/
          task_card.dart
          task_status_filter.dart
          task_priority_chip.dart

    settings/
      presentation/
        pages/
          settings_page.dart
        widgets/
          profile_card.dart
          theme_switcher.dart
          api_info_card.dart
```

---

## Structure Rules

- **Do not** put all code in `main.dart`.
- **Do not** mix UI with API logic.
- **Do not** call Firebase directly from widgets.
- **Do not** call Gemini directly from widgets.
- Use repositories and services as intermediary layers.
- Keep each feature isolated from others.
- Shared/reusable widgets go inside `core/widgets/`.
- Feature-specific widgets stay inside their own feature folder.
- Providers belong inside `presentation/providers/` of the corresponding feature.
- Domain entities must remain pure Dart — no Flutter/Firebase dependencies.
- Data models implement/extend domain entities and include serialization logic.
