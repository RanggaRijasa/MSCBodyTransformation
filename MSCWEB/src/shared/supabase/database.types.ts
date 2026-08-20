export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      apple_notification_inbox: {
        Row: {
          decoded_fields: Json
          environment: string
          id: string
          last_error_code: string | null
          notification_type: string
          notification_uuid: string
          original_transaction_id: string | null
          processed_at: string | null
          received_at: string
          retry_count: number
          signed_at: string
          signed_payload_hash: string
          status: string
          subtype: string | null
          transaction_id: string | null
        }
        Insert: {
          decoded_fields?: Json
          environment: string
          id?: string
          last_error_code?: string | null
          notification_type: string
          notification_uuid: string
          original_transaction_id?: string | null
          processed_at?: string | null
          received_at?: string
          retry_count?: number
          signed_at: string
          signed_payload_hash: string
          status?: string
          subtype?: string | null
          transaction_id?: string | null
        }
        Update: {
          decoded_fields?: Json
          environment?: string
          id?: string
          last_error_code?: string | null
          notification_type?: string
          notification_uuid?: string
          original_transaction_id?: string | null
          processed_at?: string | null
          received_at?: string
          retry_count?: number
          signed_at?: string
          signed_payload_hash?: string
          status?: string
          subtype?: string | null
          transaction_id?: string | null
        }
        Relationships: []
      }
      audit_events: {
        Row: {
          actor_id: string | null
          created_at: string
          id: string
          kind: string
          payload: Json
          subject_id: string | null
          summary: string
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          id?: string
          kind: string
          payload?: Json
          subject_id?: string | null
          summary: string
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          id?: string
          kind?: string
          payload?: Json
          subject_id?: string | null
          summary?: string
        }
        Relationships: [
          {
            foreignKeyName: "audit_events_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      coach_access_entitlements: {
        Row: {
          application_id: string
          coach_user_id: string
          created_at: string
          ends_at: string
          id: string
          payment_record_id: string
          period_sequence: number
          revoked_at: string | null
          starts_at: string
          status: string
          supersedes_entitlement_id: string | null
        }
        Insert: {
          application_id: string
          coach_user_id: string
          created_at?: string
          ends_at: string
          id?: string
          payment_record_id: string
          period_sequence?: number
          revoked_at?: string | null
          starts_at: string
          status: string
          supersedes_entitlement_id?: string | null
        }
        Update: {
          application_id?: string
          coach_user_id?: string
          created_at?: string
          ends_at?: string
          id?: string
          payment_record_id?: string
          period_sequence?: number
          revoked_at?: string | null
          starts_at?: string
          status?: string
          supersedes_entitlement_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "coach_access_entitlements_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "coach_applications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coach_access_entitlements_coach_user_id_fkey"
            columns: ["coach_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "coach_access_entitlements_payment_record_id_fkey"
            columns: ["payment_record_id"]
            isOneToOne: true
            referencedRelation: "coach_payment_records"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coach_access_entitlements_supersedes_entitlement_id_fkey"
            columns: ["supersedes_entitlement_id"]
            isOneToOne: false
            referencedRelation: "coach_access_entitlements"
            referencedColumns: ["id"]
          },
        ]
      }
      coach_applications: {
        Row: {
          applicant_user_id: string
          created_at: string
          decided_at: string | null
          decided_by: string | null
          decision_idempotency_key: string | null
          display_name_snapshot: string
          draft_idempotency_key: string
          has_completed_hom_sts: boolean
          has_completed_ict: boolean
          id: string
          member_level_snapshot: string
          participant_profile_id: string
          phone_number_snapshot: string
          rejection_reason: string | null
          status: string
          submit_idempotency_key: string | null
          submitted_at: string | null
          terms_version: string
          updated_at: string
        }
        Insert: {
          applicant_user_id: string
          created_at?: string
          decided_at?: string | null
          decided_by?: string | null
          decision_idempotency_key?: string | null
          display_name_snapshot: string
          draft_idempotency_key: string
          has_completed_hom_sts: boolean
          has_completed_ict: boolean
          id?: string
          member_level_snapshot: string
          participant_profile_id: string
          phone_number_snapshot: string
          rejection_reason?: string | null
          status: string
          submit_idempotency_key?: string | null
          submitted_at?: string | null
          terms_version: string
          updated_at?: string
        }
        Update: {
          applicant_user_id?: string
          created_at?: string
          decided_at?: string | null
          decided_by?: string | null
          decision_idempotency_key?: string | null
          display_name_snapshot?: string
          draft_idempotency_key?: string
          has_completed_hom_sts?: boolean
          has_completed_ict?: boolean
          id?: string
          member_level_snapshot?: string
          participant_profile_id?: string
          phone_number_snapshot?: string
          rejection_reason?: string | null
          status?: string
          submit_idempotency_key?: string | null
          submitted_at?: string | null
          terms_version?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "coach_applications_applicant_user_id_fkey"
            columns: ["applicant_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "coach_applications_decided_by_fkey"
            columns: ["decided_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "coach_applications_participant_profile_id_fkey"
            columns: ["participant_profile_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      coach_payment_records: {
        Row: {
          amount_minor_units: number
          application_id: string
          created_at: string
          duration_months: number
          id: string
          period_sequence: number
          price_band: string
          provider_reference: string | null
          state: string
          transaction_id: string | null
          updated_at: string
          verified_at: string | null
        }
        Insert: {
          amount_minor_units: number
          application_id: string
          created_at?: string
          duration_months?: number
          id?: string
          period_sequence?: number
          price_band: string
          provider_reference?: string | null
          state: string
          transaction_id?: string | null
          updated_at?: string
          verified_at?: string | null
        }
        Update: {
          amount_minor_units?: number
          application_id?: string
          created_at?: string
          duration_months?: number
          id?: string
          period_sequence?: number
          price_band?: string
          provider_reference?: string | null
          state?: string
          transaction_id?: string | null
          updated_at?: string
          verified_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "coach_payment_records_application_id_fkey"
            columns: ["application_id"]
            isOneToOne: false
            referencedRelation: "coach_applications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "coach_payment_records_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: true
            referencedRelation: "commerce_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      coach_public_media_namespaces: {
        Row: {
          coach_user_id: string
          media_namespace: string
        }
        Insert: {
          coach_user_id: string
          media_namespace?: string
        }
        Update: {
          coach_user_id?: string
          media_namespace?: string
        }
        Relationships: [
          {
            foreignKeyName: "coach_public_media_namespaces_coach_user_id_fkey"
            columns: ["coach_user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      coach_public_profile_drafts: {
        Row: {
          biography: string
          coach_user_id: string
          instagram_url: string
          phone_number: string
          professional_headline: string
          profile_photo_object_path: string | null
          public_handle: string
          service_area: string
          show_instagram: boolean
          show_phone: boolean
          show_tiktok: boolean
          show_website: boolean
          show_whatsapp: boolean
          tiktok_url: string
          updated_at: string
          website_url: string
          whatsapp_number: string
        }
        Insert: {
          biography?: string
          coach_user_id: string
          instagram_url?: string
          phone_number?: string
          professional_headline?: string
          profile_photo_object_path?: string | null
          public_handle: string
          service_area?: string
          show_instagram?: boolean
          show_phone?: boolean
          show_tiktok?: boolean
          show_website?: boolean
          show_whatsapp?: boolean
          tiktok_url?: string
          updated_at?: string
          website_url?: string
          whatsapp_number?: string
        }
        Update: {
          biography?: string
          coach_user_id?: string
          instagram_url?: string
          phone_number?: string
          professional_headline?: string
          profile_photo_object_path?: string | null
          public_handle?: string
          service_area?: string
          show_instagram?: boolean
          show_phone?: boolean
          show_tiktok?: boolean
          show_website?: boolean
          show_whatsapp?: boolean
          tiktok_url?: string
          updated_at?: string
          website_url?: string
          whatsapp_number?: string
        }
        Relationships: [
          {
            foreignKeyName: "coach_public_profile_drafts_coach_user_id_fkey"
            columns: ["coach_user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      coach_public_profile_items: {
        Row: {
          body: string
          coach_user_id: string
          content_version: number
          id: string
          includes_third_party: boolean
          is_public: boolean
          item_kind: string
          media_object_path: string | null
          moderated_at: string | null
          moderated_by: string | null
          moderation_idempotency_key: string | null
          moderation_note: string | null
          moderation_status: string
          moderation_version: number
          permission_attested: boolean
          submitted_at: string
          title: string
        }
        Insert: {
          body?: string
          coach_user_id: string
          content_version?: number
          id?: string
          includes_third_party?: boolean
          is_public?: boolean
          item_kind: string
          media_object_path?: string | null
          moderated_at?: string | null
          moderated_by?: string | null
          moderation_idempotency_key?: string | null
          moderation_note?: string | null
          moderation_status?: string
          moderation_version?: number
          permission_attested?: boolean
          submitted_at?: string
          title: string
        }
        Update: {
          body?: string
          coach_user_id?: string
          content_version?: number
          id?: string
          includes_third_party?: boolean
          is_public?: boolean
          item_kind?: string
          media_object_path?: string | null
          moderated_at?: string | null
          moderated_by?: string | null
          moderation_idempotency_key?: string | null
          moderation_note?: string | null
          moderation_status?: string
          moderation_version?: number
          permission_attested?: boolean
          submitted_at?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "coach_public_profile_items_coach_user_id_fkey"
            columns: ["coach_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "coach_public_profile_items_moderated_by_fkey"
            columns: ["moderated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      coach_public_profiles: {
        Row: {
          biography: string | null
          coach_user_id: string
          display_name: string
          instagram_url: string | null
          is_verified: boolean
          phone_number: string | null
          photo_kind: string
          photo_reference: string
          professional_headline: string | null
          public_handle: string
          published_at: string
          service_area: string | null
          tiktok_url: string | null
          updated_at: string
          website_url: string | null
          whatsapp_number: string | null
        }
        Insert: {
          biography?: string | null
          coach_user_id: string
          display_name: string
          instagram_url?: string | null
          is_verified?: boolean
          phone_number?: string | null
          photo_kind: string
          photo_reference: string
          professional_headline?: string | null
          public_handle: string
          published_at?: string
          service_area?: string | null
          tiktok_url?: string | null
          updated_at?: string
          website_url?: string | null
          whatsapp_number?: string | null
        }
        Update: {
          biography?: string | null
          coach_user_id?: string
          display_name?: string
          instagram_url?: string | null
          is_verified?: boolean
          phone_number?: string | null
          photo_kind?: string
          photo_reference?: string
          professional_headline?: string | null
          public_handle?: string
          published_at?: string
          service_area?: string | null
          tiktok_url?: string | null
          updated_at?: string
          website_url?: string | null
          whatsapp_number?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "coach_public_profiles_coach_user_id_fkey"
            columns: ["coach_user_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "coach_public_profiles_public_handle_fkey"
            columns: ["public_handle"]
            isOneToOne: true
            referencedRelation: "coach_public_profile_drafts"
            referencedColumns: ["public_handle"]
          },
        ]
      }
      coach_store_products: {
        Row: {
          actual_price: number | null
          created_at: string
          currency_code: string | null
          environment: string
          id: string
          platform: string
          price_band: string
          product_id: string
          product_type: string
          provisioning_status: string
          updated_at: string
        }
        Insert: {
          actual_price?: number | null
          created_at?: string
          currency_code?: string | null
          environment: string
          id?: string
          platform: string
          price_band: string
          product_id: string
          product_type: string
          provisioning_status: string
          updated_at?: string
        }
        Update: {
          actual_price?: number | null
          created_at?: string
          currency_code?: string | null
          environment?: string
          id?: string
          platform?: string
          price_band?: string
          product_id?: string
          product_type?: string
          provisioning_status?: string
          updated_at?: string
        }
        Relationships: []
      }
      commerce_purchase_intents: {
        Row: {
          account_id: string
          app_account_token: string
          coach_application_id: string | null
          coach_id_snapshot: string | null
          coach_store_product_id: string | null
          created_at: string
          environment: string
          expires_at: string
          fulfilled_at: string | null
          fulfilled_transaction_id: string | null
          id: string
          idempotency_key: string
          last_error_code: string | null
          product_id: string
          program_id: string | null
          program_store_product_id: string | null
          provider: string
          status: string
          subject_kind: string
          updated_at: string
        }
        Insert: {
          account_id: string
          app_account_token: string
          coach_application_id?: string | null
          coach_id_snapshot?: string | null
          coach_store_product_id?: string | null
          created_at?: string
          environment: string
          expires_at: string
          fulfilled_at?: string | null
          fulfilled_transaction_id?: string | null
          id?: string
          idempotency_key: string
          last_error_code?: string | null
          product_id: string
          program_id?: string | null
          program_store_product_id?: string | null
          provider: string
          status?: string
          subject_kind: string
          updated_at?: string
        }
        Update: {
          account_id?: string
          app_account_token?: string
          coach_application_id?: string | null
          coach_id_snapshot?: string | null
          coach_store_product_id?: string | null
          created_at?: string
          environment?: string
          expires_at?: string
          fulfilled_at?: string | null
          fulfilled_transaction_id?: string | null
          id?: string
          idempotency_key?: string
          last_error_code?: string | null
          product_id?: string
          program_id?: string | null
          program_store_product_id?: string | null
          provider?: string
          status?: string
          subject_kind?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "commerce_purchase_intents_account_id_fkey"
            columns: ["account_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "commerce_purchase_intents_coach_application_id_fkey"
            columns: ["coach_application_id"]
            isOneToOne: false
            referencedRelation: "coach_applications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "commerce_purchase_intents_coach_id_snapshot_fkey"
            columns: ["coach_id_snapshot"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "commerce_purchase_intents_coach_store_product_id_fkey"
            columns: ["coach_store_product_id"]
            isOneToOne: false
            referencedRelation: "coach_store_products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "commerce_purchase_intents_fulfilled_transaction_fkey"
            columns: ["fulfilled_transaction_id"]
            isOneToOne: false
            referencedRelation: "commerce_transactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "commerce_purchase_intents_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "commerce_purchase_intents_program_store_product_id_fkey"
            columns: ["program_store_product_id"]
            isOneToOne: false
            referencedRelation: "program_store_products"
            referencedColumns: ["id"]
          },
        ]
      }
      commerce_transaction_events: {
        Row: {
          created_at: string
          decoded_fields: Json
          environment: string
          event_at: string
          event_type: string
          external_event_id: string
          id: string
          provider: string
          signed_payload_hash: string
          transaction_id: string | null
        }
        Insert: {
          created_at?: string
          decoded_fields?: Json
          environment: string
          event_at: string
          event_type: string
          external_event_id: string
          id?: string
          provider: string
          signed_payload_hash: string
          transaction_id?: string | null
        }
        Update: {
          created_at?: string
          decoded_fields?: Json
          environment?: string
          event_at?: string
          event_type?: string
          external_event_id?: string
          id?: string
          provider?: string
          signed_payload_hash?: string
          transaction_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "commerce_transaction_events_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "commerce_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      commerce_transactions: {
        Row: {
          app_account_token: string | null
          coach_application_id: string | null
          currency_code: string | null
          environment: string
          expires_at: string | null
          external_transaction_id: string
          id: string
          last_event_at: string | null
          original_transaction_id: string | null
          participant_id: string | null
          platform: string
          price_milliunits: number | null
          product_id: string
          product_type: string
          program_id: string | null
          provider: string
          purchase_intent_id: string | null
          purchased_at: string | null
          revocation_at: string | null
          revocation_reason: string | null
          signed_at: string | null
          signed_payload_hash: string
          status: string
          subject_kind: string
          updated_at: string
        }
        Insert: {
          app_account_token?: string | null
          coach_application_id?: string | null
          currency_code?: string | null
          environment: string
          expires_at?: string | null
          external_transaction_id: string
          id?: string
          last_event_at?: string | null
          original_transaction_id?: string | null
          participant_id?: string | null
          platform: string
          price_milliunits?: number | null
          product_id: string
          product_type?: string
          program_id?: string | null
          provider?: string
          purchase_intent_id?: string | null
          purchased_at?: string | null
          revocation_at?: string | null
          revocation_reason?: string | null
          signed_at?: string | null
          signed_payload_hash: string
          status: string
          subject_kind?: string
          updated_at?: string
        }
        Update: {
          app_account_token?: string | null
          coach_application_id?: string | null
          currency_code?: string | null
          environment?: string
          expires_at?: string | null
          external_transaction_id?: string
          id?: string
          last_event_at?: string | null
          original_transaction_id?: string | null
          participant_id?: string | null
          platform?: string
          price_milliunits?: number | null
          product_id?: string
          product_type?: string
          program_id?: string | null
          provider?: string
          purchase_intent_id?: string | null
          purchased_at?: string | null
          revocation_at?: string | null
          revocation_reason?: string | null
          signed_at?: string | null
          signed_payload_hash?: string
          status?: string
          subject_kind?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "commerce_transactions_coach_application_id_fkey"
            columns: ["coach_application_id"]
            isOneToOne: false
            referencedRelation: "coach_applications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "commerce_transactions_participant_id_fkey"
            columns: ["participant_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "commerce_transactions_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "commerce_transactions_purchase_intent_id_fkey"
            columns: ["purchase_intent_id"]
            isOneToOne: false
            referencedRelation: "commerce_purchase_intents"
            referencedColumns: ["id"]
          },
        ]
      }
      food_insight_corrections: {
        Row: {
          actor_id: string
          corrected_rating: number
          created_at: string
          id: string
          idempotency_key: string
          previous_rating: number
          reason: string
          result_id: string
        }
        Insert: {
          actor_id: string
          corrected_rating: number
          created_at?: string
          id?: string
          idempotency_key: string
          previous_rating: number
          reason: string
          result_id: string
        }
        Update: {
          actor_id?: string
          corrected_rating?: number
          created_at?: string
          id?: string
          idempotency_key?: string
          previous_rating?: number
          reason?: string
          result_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "food_insight_corrections_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "food_insight_corrections_result_id_fkey"
            columns: ["result_id"]
            isOneToOne: false
            referencedRelation: "food_insight_results"
            referencedColumns: ["id"]
          },
        ]
      }
      food_insight_jobs: {
        Row: {
          analysis_version: string
          answer_id: string
          attempt_count: number
          completed_at: string | null
          created_at: string
          id: string
          lease_expires_at: string | null
          lease_token: string | null
          max_attempts: number
          next_attempt_at: string
          question_id: string
          rubric: string | null
          rubric_version: string | null
          status: string
          submission_id: string
          terminal_error_code: string | null
          updated_at: string
        }
        Insert: {
          analysis_version: string
          answer_id: string
          attempt_count?: number
          completed_at?: string | null
          created_at?: string
          id?: string
          lease_expires_at?: string | null
          lease_token?: string | null
          max_attempts?: number
          next_attempt_at?: string
          question_id: string
          rubric?: string | null
          rubric_version?: string | null
          status?: string
          submission_id: string
          terminal_error_code?: string | null
          updated_at?: string
        }
        Update: {
          analysis_version?: string
          answer_id?: string
          attempt_count?: number
          completed_at?: string | null
          created_at?: string
          id?: string
          lease_expires_at?: string | null
          lease_token?: string | null
          max_attempts?: number
          next_attempt_at?: string
          question_id?: string
          rubric?: string | null
          rubric_version?: string | null
          status?: string
          submission_id?: string
          terminal_error_code?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "food_insight_jobs_answer_id_fkey"
            columns: ["answer_id"]
            isOneToOne: false
            referencedRelation: "step_submission_answers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "food_insight_jobs_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "program_questions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "food_insight_jobs_submission_id_fkey"
            columns: ["submission_id"]
            isOneToOne: false
            referencedRelation: "step_submissions"
            referencedColumns: ["id"]
          },
        ]
      }
      food_insight_results: {
        Row: {
          ai_rating: number
          analysis_version: string
          calorie_kcal: number | null
          carbohydrate_grams: number | null
          confidence: number
          created_at: string
          detected_kind: string
          effective_rating: number
          fat_grams: number | null
          id: string
          insight_sentences: string[]
          job_id: string
          model_alias: string
          output_policy_version: string
          policy_version: string
          protein_grams: number | null
          provider_name: string
          question_id: string
          reason_code: string
          submission_id: string
          updated_at: string
          version: number
        }
        Insert: {
          ai_rating: number
          analysis_version: string
          calorie_kcal?: number | null
          carbohydrate_grams?: number | null
          confidence: number
          created_at?: string
          detected_kind: string
          effective_rating: number
          fat_grams?: number | null
          id?: string
          insight_sentences: string[]
          job_id: string
          model_alias: string
          output_policy_version: string
          policy_version: string
          protein_grams?: number | null
          provider_name: string
          question_id: string
          reason_code: string
          submission_id: string
          updated_at?: string
          version?: number
        }
        Update: {
          ai_rating?: number
          analysis_version?: string
          calorie_kcal?: number | null
          carbohydrate_grams?: number | null
          confidence?: number
          created_at?: string
          detected_kind?: string
          effective_rating?: number
          fat_grams?: number | null
          id?: string
          insight_sentences?: string[]
          job_id?: string
          model_alias?: string
          output_policy_version?: string
          policy_version?: string
          protein_grams?: number | null
          provider_name?: string
          question_id?: string
          reason_code?: string
          submission_id?: string
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "food_insight_results_job_id_fkey"
            columns: ["job_id"]
            isOneToOne: true
            referencedRelation: "food_insight_jobs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "food_insight_results_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "program_questions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "food_insight_results_submission_id_fkey"
            columns: ["submission_id"]
            isOneToOne: false
            referencedRelation: "step_submissions"
            referencedColumns: ["id"]
          },
        ]
      }
      participant_coach_change_requests: {
        Row: {
          coach_id: string
          created_at: string
          id: string
          idempotency_key: string
          participant_id: string
        }
        Insert: {
          coach_id: string
          created_at?: string
          id?: string
          idempotency_key: string
          participant_id: string
        }
        Update: {
          coach_id?: string
          created_at?: string
          id?: string
          idempotency_key?: string
          participant_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "participant_coach_change_requests_coach_id_fkey"
            columns: ["coach_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "participant_coach_change_requests_participant_id_fkey"
            columns: ["participant_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      payment_destinations: {
        Row: {
          account_name: string
          account_reference: string
          bank_code: string
          bank_name: string
          created_at: string
          created_by: string
          effective_from: string
          effective_until: string | null
          id: string
          instructions: string
          qris_object_path: string | null
          status: string
          version: number
        }
        Insert: {
          account_name: string
          account_reference: string
          bank_code: string
          bank_name: string
          created_at?: string
          created_by: string
          effective_from: string
          effective_until?: string | null
          id?: string
          instructions?: string
          qris_object_path?: string | null
          status: string
          version: number
        }
        Update: {
          account_name?: string
          account_reference?: string
          bank_code?: string
          bank_name?: string
          created_at?: string
          created_by?: string
          effective_from?: string
          effective_until?: string | null
          id?: string
          instructions?: string
          qris_object_path?: string | null
          status?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "payment_destinations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      payment_events: {
        Row: {
          actor_id: string | null
          attempt_id: string | null
          created_at: string
          event_type: string
          id: number
          metadata: Json
          order_id: string
        }
        Insert: {
          actor_id?: string | null
          attempt_id?: string | null
          created_at?: string
          event_type: string
          id?: never
          metadata?: Json
          order_id: string
        }
        Update: {
          actor_id?: string | null
          attempt_id?: string | null
          created_at?: string
          event_type?: string
          id?: never
          metadata?: Json
          order_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_events_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "payment_events_attempt_id_fkey"
            columns: ["attempt_id"]
            isOneToOne: false
            referencedRelation: "payment_evidence_attempts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_events_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "payment_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_evidence_attempts: {
        Row: {
          attempt_number: number
          byte_size: number | null
          deleted_at: string | null
          id: string
          mime_type: string | null
          object_path: string
          order_id: string
          pixel_height: number | null
          pixel_width: number | null
          prepared_at: string
          rejection_reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          sha256_hex: string | null
          status: string
          submitted_at: string | null
          upload_idempotency_key: string
        }
        Insert: {
          attempt_number: number
          byte_size?: number | null
          deleted_at?: string | null
          id?: string
          mime_type?: string | null
          object_path: string
          order_id: string
          pixel_height?: number | null
          pixel_width?: number | null
          prepared_at?: string
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          sha256_hex?: string | null
          status: string
          submitted_at?: string | null
          upload_idempotency_key: string
        }
        Update: {
          attempt_number?: number
          byte_size?: number | null
          deleted_at?: string | null
          id?: string
          mime_type?: string | null
          object_path?: string
          order_id?: string
          pixel_height?: number | null
          pixel_width?: number | null
          prepared_at?: string
          rejection_reason?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          sha256_hex?: string | null
          status?: string
          submitted_at?: string | null
          upload_idempotency_key?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_evidence_attempts_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "payment_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_evidence_attempts_reviewed_by_fkey"
            columns: ["reviewed_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      payment_ledger: {
        Row: {
          amount_minor: number
          currency: string
          destination_version: number
          entry_kind: string
          id: string
          order_id: string
          reconciliation_reference: string
          related_ledger_id: string | null
          resolution_due_at: string | null
          resolution_note: string | null
          verified_at: string
          verified_by: string
        }
        Insert: {
          amount_minor: number
          currency: string
          destination_version: number
          entry_kind: string
          id?: string
          order_id: string
          reconciliation_reference: string
          related_ledger_id?: string | null
          resolution_due_at?: string | null
          resolution_note?: string | null
          verified_at?: string
          verified_by: string
        }
        Update: {
          amount_minor?: number
          currency?: string
          destination_version?: number
          entry_kind?: string
          id?: string
          order_id?: string
          reconciliation_reference?: string
          related_ledger_id?: string | null
          resolution_due_at?: string | null
          resolution_note?: string | null
          verified_at?: string
          verified_by?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_ledger_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "payment_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_ledger_related_ledger_id_fkey"
            columns: ["related_ledger_id"]
            isOneToOne: false
            referencedRelation: "payment_ledger"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_ledger_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      payment_orders: {
        Row: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        Insert: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id?: string | null
          coach_user_id_snapshot?: string | null
          correction_expires_at?: string | null
          created_at?: string
          currency?: string
          declared_method?: string
          destination_id: string
          destination_version: number
          evidence_submitted_at?: string | null
          id?: string
          idempotency_key: string
          instructions_snapshot?: string
          latest_rejection_reason?: string | null
          owner_user_id?: string | null
          pending_enrollment_id?: string | null
          program_id?: string | null
          purpose: string
          qris_object_path_snapshot?: string | null
          reservation_expires_at?: string | null
          reserved_at?: string | null
          retention_after?: string | null
          status: string
          timezone_snapshot: string
          updated_at?: string
          version?: number
        }
        Update: {
          account_name_snapshot?: string
          account_reference_snapshot?: string
          amount_minor?: number
          bank_code_snapshot?: string
          bank_name_snapshot?: string
          coach_application_id?: string | null
          coach_user_id_snapshot?: string | null
          correction_expires_at?: string | null
          created_at?: string
          currency?: string
          declared_method?: string
          destination_id?: string
          destination_version?: number
          evidence_submitted_at?: string | null
          id?: string
          idempotency_key?: string
          instructions_snapshot?: string
          latest_rejection_reason?: string | null
          owner_user_id?: string | null
          pending_enrollment_id?: string | null
          program_id?: string | null
          purpose?: string
          qris_object_path_snapshot?: string | null
          reservation_expires_at?: string | null
          reserved_at?: string | null
          retention_after?: string | null
          status?: string
          timezone_snapshot?: string
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "payment_order_destination_snapshot_fk"
            columns: ["destination_id", "destination_version"]
            isOneToOne: false
            referencedRelation: "payment_destinations"
            referencedColumns: ["id", "version"]
          },
          {
            foreignKeyName: "payment_orders_coach_application_id_fkey"
            columns: ["coach_application_id"]
            isOneToOne: false
            referencedRelation: "coach_applications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_orders_coach_user_id_snapshot_fkey"
            columns: ["coach_user_id_snapshot"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "payment_orders_destination_id_fkey"
            columns: ["destination_id"]
            isOneToOne: false
            referencedRelation: "payment_destinations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_orders_owner_user_id_fkey"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "payment_orders_pending_enrollment_id_fkey"
            columns: ["pending_enrollment_id"]
            isOneToOne: false
            referencedRelation: "program_enrollments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_orders_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          account_purpose: string
          city: string
          coach_biography: string
          coach_is_approved: boolean
          coach_is_public: boolean
          coach_qr_identifier: string | null
          created_at: string
          current_coach_id: string | null
          display_name: string
          finalized_at: string | null
          member_level: string | null
          onboarding_status: string
          onboarding_version: number
          phone_number: string | null
          profile_avatar_path: string | null
          provider_avatar_url: string | null
          provisional_expires_at: string | null
          public_profile_id: string
          role: string
          updated_at: string
          user_id: string
        }
        Insert: {
          account_purpose?: string
          city?: string
          coach_biography?: string
          coach_is_approved?: boolean
          coach_is_public?: boolean
          coach_qr_identifier?: string | null
          created_at?: string
          current_coach_id?: string | null
          display_name: string
          finalized_at?: string | null
          member_level?: string | null
          onboarding_status?: string
          onboarding_version?: number
          phone_number?: string | null
          profile_avatar_path?: string | null
          provider_avatar_url?: string | null
          provisional_expires_at?: string | null
          public_profile_id?: string
          role: string
          updated_at?: string
          user_id: string
        }
        Update: {
          account_purpose?: string
          city?: string
          coach_biography?: string
          coach_is_approved?: boolean
          coach_is_public?: boolean
          coach_qr_identifier?: string | null
          created_at?: string
          current_coach_id?: string | null
          display_name?: string
          finalized_at?: string | null
          member_level?: string | null
          onboarding_status?: string
          onboarding_version?: number
          phone_number?: string | null
          profile_avatar_path?: string | null
          provider_avatar_url?: string | null
          provisional_expires_at?: string | null
          public_profile_id?: string
          role?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "profiles_current_coach_fk"
            columns: ["current_coach_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      program_answer_keys: {
        Row: {
          accepted_text_values: string[]
          matching_mode: string
          number_value: number | null
          question_id: string
          selected_option_ids: string[]
        }
        Insert: {
          accepted_text_values?: string[]
          matching_mode?: string
          number_value?: number | null
          question_id: string
          selected_option_ids?: string[]
        }
        Update: {
          accepted_text_values?: string[]
          matching_mode?: string
          number_value?: number | null
          question_id?: string
          selected_option_ids?: string[]
        }
        Relationships: [
          {
            foreignKeyName: "program_answer_keys_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: true
            referencedRelation: "program_questions"
            referencedColumns: ["id"]
          },
        ]
      }
      program_days: {
        Row: {
          day_number: number
          id: string
          program_id: string
          scheduled_on: string
          summary: string | null
          title: string
        }
        Insert: {
          day_number: number
          id?: string
          program_id: string
          scheduled_on: string
          summary?: string | null
          title: string
        }
        Update: {
          day_number?: number
          id?: string
          program_id?: string
          scheduled_on?: string
          summary?: string | null
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_days_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      program_enrollments: {
        Row: {
          coach_id: string
          completed_at: string | null
          enrolled_at: string
          id: string
          participant_id: string
          program_id: string
          status: string
        }
        Insert: {
          coach_id: string
          completed_at?: string | null
          enrolled_at?: string
          id?: string
          participant_id: string
          program_id: string
          status: string
        }
        Update: {
          coach_id?: string
          completed_at?: string | null
          enrolled_at?: string
          id?: string
          participant_id?: string
          program_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_enrollments_coach_id_fkey"
            columns: ["coach_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "program_enrollments_participant_id_fkey"
            columns: ["participant_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "program_enrollments_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      program_entitlement_events: {
        Row: {
          created_at: string
          entitlement_id: string
          event_at: string
          event_type: string
          id: string
          transaction_id: string | null
        }
        Insert: {
          created_at?: string
          entitlement_id: string
          event_at: string
          event_type: string
          id?: string
          transaction_id?: string | null
        }
        Update: {
          created_at?: string
          entitlement_id?: string
          event_at?: string
          event_type?: string
          id?: string
          transaction_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "program_entitlement_events_entitlement_id_fkey"
            columns: ["entitlement_id"]
            isOneToOne: false
            referencedRelation: "program_entitlements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "program_entitlement_events_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "commerce_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      program_entitlements: {
        Row: {
          granted_at: string
          id: string
          participant_id: string
          program_id: string
          revoked_at: string | null
          status: string
          transaction_id: string | null
        }
        Insert: {
          granted_at?: string
          id?: string
          participant_id: string
          program_id: string
          revoked_at?: string | null
          status: string
          transaction_id?: string | null
        }
        Update: {
          granted_at?: string
          id?: string
          participant_id?: string
          program_id?: string
          revoked_at?: string | null
          status?: string
          transaction_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "program_entitlements_participant_id_fkey"
            columns: ["participant_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "program_entitlements_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "program_entitlements_transaction_id_fkey"
            columns: ["transaction_id"]
            isOneToOne: false
            referencedRelation: "commerce_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      program_question_options: {
        Row: {
          id: string
          media_alt_text: string | null
          media_path: string | null
          option_order: number
          question_id: string
          title: string
        }
        Insert: {
          id?: string
          media_alt_text?: string | null
          media_path?: string | null
          option_order: number
          question_id: string
          title: string
        }
        Update: {
          id?: string
          media_alt_text?: string | null
          media_path?: string | null
          option_order?: number
          question_id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_question_options_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "program_questions"
            referencedColumns: ["id"]
          },
        ]
      }
      program_questions: {
        Row: {
          analysis_mode: string
          analysis_rubric: string | null
          analysis_rubric_version: string | null
          id: string
          kind: string
          prompt: string
          question_order: number
          step_id: string
        }
        Insert: {
          analysis_mode?: string
          analysis_rubric?: string | null
          analysis_rubric_version?: string | null
          id?: string
          kind: string
          prompt: string
          question_order: number
          step_id: string
        }
        Update: {
          analysis_mode?: string
          analysis_rubric?: string | null
          analysis_rubric_version?: string | null
          id?: string
          kind?: string
          prompt?: string
          question_order?: number
          step_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_questions_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: false
            referencedRelation: "program_steps"
            referencedColumns: ["id"]
          },
        ]
      }
      program_scores: {
        Row: {
          activity_points: number
          adjustment_points: number
          enrollment_id: string
          progress_percentage: number
          public_id: string
          quiz_points: number
          rank: number | null
          recalculated_at: string
          weight_points: number
        }
        Insert: {
          activity_points?: number
          adjustment_points?: number
          enrollment_id: string
          progress_percentage?: number
          public_id?: string
          quiz_points?: number
          rank?: number | null
          recalculated_at?: string
          weight_points?: number
        }
        Update: {
          activity_points?: number
          adjustment_points?: number
          enrollment_id?: string
          progress_percentage?: number
          public_id?: string
          quiz_points?: number
          rank?: number | null
          recalculated_at?: string
          weight_points?: number
        }
        Relationships: [
          {
            foreignKeyName: "program_scores_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: true
            referencedRelation: "program_enrollments"
            referencedColumns: ["id"]
          },
        ]
      }
      program_steps: {
        Row: {
          completion_policy: string
          content_kind: string
          id: string
          instructions: string
          media_alt_text: string | null
          media_path: string | null
          program_day_id: string
          step_order: number
          title: string
          verification_mode: string
          video_autoplay: boolean
          video_required: boolean
          video_threshold: number | null
        }
        Insert: {
          completion_policy: string
          content_kind: string
          id?: string
          instructions?: string
          media_alt_text?: string | null
          media_path?: string | null
          program_day_id: string
          step_order: number
          title: string
          verification_mode: string
          video_autoplay?: boolean
          video_required?: boolean
          video_threshold?: number | null
        }
        Update: {
          completion_policy?: string
          content_kind?: string
          id?: string
          instructions?: string
          media_alt_text?: string | null
          media_path?: string | null
          program_day_id?: string
          step_order?: number
          title?: string
          verification_mode?: string
          video_autoplay?: boolean
          video_required?: boolean
          video_threshold?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "program_steps_program_day_id_fkey"
            columns: ["program_day_id"]
            isOneToOne: false
            referencedRelation: "program_days"
            referencedColumns: ["id"]
          },
        ]
      }
      program_store_products: {
        Row: {
          actual_price: number | null
          created_at: string
          currency_code: string | null
          environment: string
          external_product_id: string | null
          id: string
          platform: string
          product_id: string
          product_type: string
          program_id: string
          provisioning_status: string
          updated_at: string
        }
        Insert: {
          actual_price?: number | null
          created_at?: string
          currency_code?: string | null
          environment: string
          external_product_id?: string | null
          id?: string
          platform: string
          product_id: string
          product_type?: string
          program_id: string
          provisioning_status: string
          updated_at?: string
        }
        Update: {
          actual_price?: number | null
          created_at?: string
          currency_code?: string | null
          environment?: string
          external_product_id?: string | null
          id?: string
          platform?: string
          product_id?: string
          product_type?: string
          program_id?: string
          provisioning_status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "program_store_products_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      program_winners: {
        Row: {
          display_name: string
          id: string
          participant_id: string | null
          rank: number
          snapshot_id: string
          total_points: number
        }
        Insert: {
          display_name: string
          id?: string
          participant_id?: string | null
          rank: number
          snapshot_id: string
          total_points: number
        }
        Update: {
          display_name?: string
          id?: string
          participant_id?: string | null
          rank?: number
          snapshot_id?: string
          total_points?: number
        }
        Relationships: [
          {
            foreignKeyName: "program_winners_participant_id_fkey"
            columns: ["participant_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "program_winners_snapshot_id_fkey"
            columns: ["snapshot_id"]
            isOneToOne: false
            referencedRelation: "winner_snapshots"
            referencedColumns: ["id"]
          },
        ]
      }
      programs: {
        Row: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        Insert: {
          archive_idempotency_key?: string | null
          category?: string | null
          completion_idempotency_key?: string | null
          cover_alt_text?: string | null
          cover_path?: string | null
          created_at?: string
          created_by: string
          default_verification_mode?: string
          desired_price?: number | null
          draft_idempotency_key?: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id?: string
          pace: string
          participant_limit?: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key?: string | null
          published_at?: string | null
          quiz_passing_percentage: number
          registration_closes_at?: string | null
          reopen_idempotency_key?: string | null
          source_program_id?: string | null
          starts_on: string
          status: string
          summary?: string
          timezone: string
          title: string
          updated_at?: string
          wellness_disclaimer: string
        }
        Update: {
          archive_idempotency_key?: string | null
          category?: string | null
          completion_idempotency_key?: string | null
          cover_alt_text?: string | null
          cover_path?: string | null
          created_at?: string
          created_by?: string
          default_verification_mode?: string
          desired_price?: number | null
          draft_idempotency_key?: string | null
          duration_mode?: string
          ends_on?: string
          future_step_policy?: string
          id?: string
          pace?: string
          participant_limit?: number | null
          past_step_policy?: string
          points_per_activity?: number
          points_per_weight_kg?: number
          pricing_mode?: string
          publish_idempotency_key?: string | null
          published_at?: string | null
          quiz_passing_percentage?: number
          registration_closes_at?: string | null
          reopen_idempotency_key?: string | null
          source_program_id?: string | null
          starts_on?: string
          status?: string
          summary?: string
          timezone?: string
          title?: string
          updated_at?: string
          wellness_disclaimer?: string
        }
        Relationships: [
          {
            foreignKeyName: "programs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "programs_source_program_id_fkey"
            columns: ["source_program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
      quiz_attempt_results: {
        Row: {
          awarded_points: number
          correct_count: number
          id: string
          passed: boolean
          percentage: number
          reopen_idempotency_key: string | null
          reopen_reason: string | null
          reopened_at: string | null
          reopened_by: string | null
          submission_id: string
          total_count: number
        }
        Insert: {
          awarded_points: number
          correct_count: number
          id?: string
          passed: boolean
          percentage: number
          reopen_idempotency_key?: string | null
          reopen_reason?: string | null
          reopened_at?: string | null
          reopened_by?: string | null
          submission_id: string
          total_count: number
        }
        Update: {
          awarded_points?: number
          correct_count?: number
          id?: string
          passed?: boolean
          percentage?: number
          reopen_idempotency_key?: string | null
          reopen_reason?: string | null
          reopened_at?: string | null
          reopened_by?: string | null
          submission_id?: string
          total_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "quiz_attempt_results_reopened_by_fkey"
            columns: ["reopened_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "quiz_attempt_results_submission_id_fkey"
            columns: ["submission_id"]
            isOneToOne: true
            referencedRelation: "step_submissions"
            referencedColumns: ["id"]
          },
        ]
      }
      score_adjustments: {
        Row: {
          actor_id: string | null
          created_at: string
          enrollment_id: string
          id: string
          idempotency_key: string | null
          points: number
          reason: string
        }
        Insert: {
          actor_id?: string | null
          created_at?: string
          enrollment_id: string
          id?: string
          idempotency_key?: string | null
          points: number
          reason: string
        }
        Update: {
          actor_id?: string | null
          created_at?: string
          enrollment_id?: string
          id?: string
          idempotency_key?: string | null
          points?: number
          reason?: string
        }
        Relationships: [
          {
            foreignKeyName: "score_adjustments_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "score_adjustments_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: false
            referencedRelation: "program_enrollments"
            referencedColumns: ["id"]
          },
        ]
      }
      step_submission_answers: {
        Row: {
          id: string
          number_value: number | null
          private_photo_path: string | null
          question_id: string
          selected_option_ids: string[]
          submission_id: string
          text_value: string | null
        }
        Insert: {
          id?: string
          number_value?: number | null
          private_photo_path?: string | null
          question_id: string
          selected_option_ids?: string[]
          submission_id: string
          text_value?: string | null
        }
        Update: {
          id?: string
          number_value?: number | null
          private_photo_path?: string | null
          question_id?: string
          selected_option_ids?: string[]
          submission_id?: string
          text_value?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "step_submission_answers_question_id_fkey"
            columns: ["question_id"]
            isOneToOne: false
            referencedRelation: "program_questions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "step_submission_answers_submission_id_fkey"
            columns: ["submission_id"]
            isOneToOne: false
            referencedRelation: "step_submissions"
            referencedColumns: ["id"]
          },
        ]
      }
      step_submissions: {
        Row: {
          attempt_sequence: number
          enrollment_id: string
          finalized_at: string | null
          id: string
          idempotency_key: string | null
          review_idempotency_key: string | null
          review_note: string | null
          reviewed_at: string | null
          reviewer_id: string | null
          status: string
          step_id: string
          submitted_at: string
          supersedes_submission_id: string | null
        }
        Insert: {
          attempt_sequence?: number
          enrollment_id: string
          finalized_at?: string | null
          id?: string
          idempotency_key?: string | null
          review_idempotency_key?: string | null
          review_note?: string | null
          reviewed_at?: string | null
          reviewer_id?: string | null
          status: string
          step_id: string
          submitted_at?: string
          supersedes_submission_id?: string | null
        }
        Update: {
          attempt_sequence?: number
          enrollment_id?: string
          finalized_at?: string | null
          id?: string
          idempotency_key?: string | null
          review_idempotency_key?: string | null
          review_note?: string | null
          reviewed_at?: string | null
          reviewer_id?: string | null
          status?: string
          step_id?: string
          submitted_at?: string
          supersedes_submission_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "step_submissions_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: false
            referencedRelation: "program_enrollments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "step_submissions_reviewer_id_fkey"
            columns: ["reviewer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "step_submissions_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: false
            referencedRelation: "program_steps"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "step_submissions_supersedes_submission_id_fkey"
            columns: ["supersedes_submission_id"]
            isOneToOne: false
            referencedRelation: "step_submissions"
            referencedColumns: ["id"]
          },
        ]
      }
      web_push_outbox: {
        Row: {
          attempts: number
          created_at: string
          destination_path: string
          event_type: string
          id: string
          idempotency_key: string
          last_error_code: string | null
          next_attempt_at: string
          processed_at: string | null
          recipient_user_id: string | null
          status: string
        }
        Insert: {
          attempts?: number
          created_at?: string
          destination_path: string
          event_type: string
          id?: string
          idempotency_key: string
          last_error_code?: string | null
          next_attempt_at?: string
          processed_at?: string | null
          recipient_user_id?: string | null
          status?: string
        }
        Update: {
          attempts?: number
          created_at?: string
          destination_path?: string
          event_type?: string
          id?: string
          idempotency_key?: string
          last_error_code?: string | null
          next_attempt_at?: string
          processed_at?: string | null
          recipient_user_id?: string | null
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "web_push_outbox_recipient_user_id_fkey"
            columns: ["recipient_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      web_push_subscriptions: {
        Row: {
          auth_secret: string
          created_at: string
          endpoint: string
          endpoint_hash: string | null
          id: string
          last_seen_at: string
          p256dh: string
          permission_granted_at: string
          revoked_at: string | null
          user_agent_family: string
          user_id: string
        }
        Insert: {
          auth_secret: string
          created_at?: string
          endpoint: string
          endpoint_hash?: string | null
          id?: string
          last_seen_at?: string
          p256dh: string
          permission_granted_at?: string
          revoked_at?: string | null
          user_agent_family: string
          user_id: string
        }
        Update: {
          auth_secret?: string
          created_at?: string
          endpoint?: string
          endpoint_hash?: string | null
          id?: string
          last_seen_at?: string
          p256dh?: string
          permission_granted_at?: string
          revoked_at?: string | null
          user_agent_family?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "web_push_subscriptions_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
        ]
      }
      weigh_ins: {
        Row: {
          corrected_at: string | null
          corrected_by: string | null
          correction_idempotency_key: string | null
          correction_reason: string | null
          enrollment_id: string
          id: string
          idempotency_key: string | null
          kind: string
          recorded_at: string
          step_id: string
          weight_kg: number
        }
        Insert: {
          corrected_at?: string | null
          corrected_by?: string | null
          correction_idempotency_key?: string | null
          correction_reason?: string | null
          enrollment_id: string
          id?: string
          idempotency_key?: string | null
          kind: string
          recorded_at?: string
          step_id: string
          weight_kg: number
        }
        Update: {
          corrected_at?: string | null
          corrected_by?: string | null
          correction_idempotency_key?: string | null
          correction_reason?: string | null
          enrollment_id?: string
          id?: string
          idempotency_key?: string | null
          kind?: string
          recorded_at?: string
          step_id?: string
          weight_kg?: number
        }
        Relationships: [
          {
            foreignKeyName: "weigh_ins_corrected_by_fkey"
            columns: ["corrected_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "weigh_ins_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: false
            referencedRelation: "program_enrollments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "weigh_ins_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: false
            referencedRelation: "program_steps"
            referencedColumns: ["id"]
          },
        ]
      }
      winner_posters: {
        Row: {
          alt_text: string
          deleted_at: string | null
          id: string
          idempotency_key: string | null
          is_published: boolean
          media_path: string
          mutation_idempotency_key: string | null
          program_id: string
          published_at: string | null
          winner_snapshot_id: string
        }
        Insert: {
          alt_text: string
          deleted_at?: string | null
          id?: string
          idempotency_key?: string | null
          is_published?: boolean
          media_path: string
          mutation_idempotency_key?: string | null
          program_id: string
          published_at?: string | null
          winner_snapshot_id: string
        }
        Update: {
          alt_text?: string
          deleted_at?: string | null
          id?: string
          idempotency_key?: string | null
          is_published?: boolean
          media_path?: string
          mutation_idempotency_key?: string | null
          program_id?: string
          published_at?: string | null
          winner_snapshot_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "winner_posters_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "winner_posters_winner_snapshot_id_fkey"
            columns: ["winner_snapshot_id"]
            isOneToOne: false
            referencedRelation: "winner_snapshots"
            referencedColumns: ["id"]
          },
        ]
      }
      winner_snapshots: {
        Row: {
          id: string
          idempotency_key: string | null
          locked_at: string
          locked_by: string
          program_id: string
        }
        Insert: {
          id?: string
          idempotency_key?: string | null
          locked_at?: string
          locked_by: string
          program_id: string
        }
        Update: {
          id?: string
          idempotency_key?: string | null
          locked_at?: string
          locked_by?: string
          program_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "winner_snapshots_locked_by_fkey"
            columns: ["locked_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "winner_snapshots_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: true
            referencedRelation: "programs"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_adjust_score: {
        Args: {
          points: number
          reason: string
          request_idempotency_key: string
          target_enrollment_id: string
        }
        Returns: {
          activity_points: number
          adjustment_points: number
          enrollment_id: string
          progress_percentage: number
          public_id: string
          quiz_points: number
          rank: number | null
          recalculated_at: string
          weight_points: number
        }
        SetofOptions: {
          from: "*"
          to: "program_scores"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_correct_weigh_in: {
        Args: {
          corrected_weight_kg: number
          reason: string
          request_idempotency_key: string
          target_weigh_in_id: string
        }
        Returns: {
          corrected_at: string | null
          corrected_by: string | null
          correction_idempotency_key: string | null
          correction_reason: string | null
          enrollment_id: string
          id: string
          idempotency_key: string | null
          kind: string
          recorded_at: string
          step_id: string
          weight_kg: number
        }
        SetofOptions: {
          from: "*"
          to: "weigh_ins"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_enroll_participant: {
        Args: {
          reason: string
          target_participant_id: string
          target_program_id: string
        }
        Returns: {
          coach_id: string
          completed_at: string | null
          enrolled_at: string
          id: string
          participant_id: string
          program_id: string
          status: string
        }
        SetofOptions: {
          from: "*"
          to: "program_enrollments"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_transfer_coach: {
        Args: {
          reason: string
          target_coach_id: string
          target_participant_id: string
        }
        Returns: undefined
      }
      allocate_my_coach_public_media_path: {
        Args: { media_folder: string }
        Returns: string
      }
      apply_provider_profile_defaults: {
        Args: { provider_avatar_url?: string; provider_display_name?: string }
        Returns: {
          account_purpose: string
          city: string
          coach_biography: string
          coach_is_approved: boolean
          coach_is_public: boolean
          coach_qr_identifier: string | null
          created_at: string
          current_coach_id: string | null
          display_name: string
          finalized_at: string | null
          member_level: string | null
          onboarding_status: string
          onboarding_version: number
          phone_number: string | null
          profile_avatar_path: string | null
          provider_avatar_url: string | null
          provisional_expires_at: string | null
          public_profile_id: string
          role: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      approve_coach_payment_and_activate: {
        Args: {
          destination_matches: boolean
          expected_version: number
          reconciled_amount_minor: number
          reconciliation_reference: string
          request_idempotency_key: string
          target_order_id: string
        }
        Returns: Json
      }
      approve_payment_order: {
        Args: {
          destination_matches: boolean
          expected_version: number
          reconciled_amount_minor: number
          reconciliation_reference: string
          target_order_id: string
        }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      archive_admin_program: {
        Args: {
          reason: string
          request_idempotency_key: string
          target_program_id: string
        }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      archive_admin_winner_poster: {
        Args: {
          reason: string
          request_idempotency_key: string
          target_poster_id: string
        }
        Returns: {
          alt_text: string
          deleted_at: string | null
          id: string
          idempotency_key: string | null
          is_published: boolean
          media_path: string
          mutation_idempotency_key: string | null
          program_id: string
          published_at: string | null
          winner_snapshot_id: string
        }
        SetofOptions: {
          from: "*"
          to: "winner_posters"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      archive_program: {
        Args: {
          reason: string
          request_idempotency_key: string
          target_program_id: string
        }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      cancel_my_provisional_identity: { Args: never; Returns: boolean }
      cancel_payment_order: {
        Args: { target_order_id: string }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      claim_apple_commerce_reconciliation_batch: {
        Args: { batch_size?: number; target_environment: string }
        Returns: Json[]
      }
      claim_apple_identity_credential_for_account: {
        Args: { target_account_id: string }
        Returns: Json
      }
      claim_food_insight_job: {
        Args: { lease_seconds?: number; target_submission_id?: string }
        Returns: Json
      }
      claim_pending_apple_account_events: {
        Args: { batch_size?: number }
        Returns: Json[]
      }
      claim_pending_apple_identity_revocations: {
        Args: { batch_size?: number }
        Returns: Json[]
      }
      claim_provisional_cancellation: {
        Args: { target_receipt_id?: string }
        Returns: Json
      }
      cleanup_expired_payment_evidence: { Args: never; Returns: number }
      complete_apple_account_event: {
        Args: {
          error_code?: string
          requires_manual_action?: boolean
          succeeded: boolean
          target_event_jti: string
        }
        Returns: undefined
      }
      complete_apple_commerce_reconciliation: {
        Args: {
          error_code?: string
          succeeded: boolean
          target_environment: string
          target_external_transaction_id: string
        }
        Returns: undefined
      }
      complete_apple_identity_revocation: {
        Args: {
          error_code?: string
          succeeded: boolean
          target_credential_id: string
        }
        Returns: undefined
      }
      complete_apple_notification: {
        Args: {
          did_succeed: boolean
          target_error_code?: string
          target_notification_uuid: string
        }
        Returns: Json
      }
      complete_food_insight_job: {
        Args: {
          model_alias: string
          provider_name: string
          target_job_id: string
          target_lease_token: string
          validated_result: Json
        }
        Returns: string
      }
      complete_program: {
        Args: {
          reason: string
          request_idempotency_key: string
          target_program_id: string
        }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      complete_provisional_cancellation: {
        Args: { target_receipt_id: string }
        Returns: boolean
      }
      consume_commerce_rate_limit: {
        Args: { caller_account_id: string; target_operation: string }
        Returns: undefined
      }
      consume_web_rate_limit: {
        Args: { target_operation: string; target_subject_hash?: string }
        Returns: number
      }
      correct_food_insight_rating: {
        Args: {
          corrected_rating: number
          correction_reason: string
          expected_version: number
          request_idempotency_key: string
          target_result_id: string
        }
        Returns: {
          ai_rating: number
          analysis_version: string
          calorie_kcal: number | null
          carbohydrate_grams: number | null
          confidence: number
          created_at: string
          detected_kind: string
          effective_rating: number
          fat_grams: number | null
          id: string
          insight_sentences: string[]
          job_id: string
          model_alias: string
          output_policy_version: string
          policy_version: string
          protein_grams: number | null
          provider_name: string
          question_id: string
          reason_code: string
          submission_id: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "food_insight_results"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_coach_payment_order: {
        Args: { request_idempotency_key: string; target_application_id: string }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_coach_purchase_intent: {
        Args: {
          caller_account_id: string
          request_idempotency_key: string
          target_environment: string
        }
        Returns: Json
      }
      create_payment_destination: {
        Args: {
          destination_account_name: string
          destination_account_reference: string
          destination_bank_code: string
          destination_bank_name: string
          destination_instructions: string
          destination_qris_object_path?: string
          effective_at: string
        }
        Returns: {
          account_name: string
          account_reference: string
          bank_code: string
          bank_name: string
          created_at: string
          created_by: string
          effective_from: string
          effective_until: string | null
          id: string
          instructions: string
          qris_object_path: string | null
          status: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_destinations"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_program_payment_order: {
        Args: {
          coach_qr_payload: string
          payment_method: string
          request_idempotency_key: string
          target_program_id: string
        }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_program_purchase_intent: {
        Args: {
          caller_account_id: string
          request_idempotency_key: string
          target_environment: string
          target_program_id: string
        }
        Returns: Json
      }
      decide_coach_application: {
        Args: {
          decision: string
          decision_reason: string
          request_idempotency_key: string
          target_application_id: string
        }
        Returns: {
          applicant_user_id: string
          created_at: string
          decided_at: string | null
          decided_by: string | null
          decision_idempotency_key: string | null
          display_name_snapshot: string
          draft_idempotency_key: string
          has_completed_hom_sts: boolean
          has_completed_ict: boolean
          id: string
          member_level_snapshot: string
          participant_profile_id: string
          phone_number_snapshot: string
          rejection_reason: string | null
          status: string
          submit_idempotency_key: string | null
          submitted_at: string | null
          terms_version: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "coach_applications"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      duplicate_admin_program_as_draft: {
        Args: {
          request_idempotency_key: string
          source_program_id: string
          target_program_id: string
          target_start_date: string
          target_title: string
        }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      duplicate_program_as_draft: {
        Args: {
          request_idempotency_key: string
          source_target_id: string
          target_program_id: string
          target_starts_on: string
          target_title: string
        }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      enqueue_expired_provisional_cancellations: {
        Args: never
        Returns: number
      }
      enqueue_food_insight: {
        Args: { target_analysis_version?: string; target_submission_id: string }
        Returns: string
      }
      enroll_free_program: {
        Args: { scanned_coach_qr: string; target_program_id: string }
        Returns: {
          coach_id: string
          completed_at: string | null
          enrolled_at: string
          id: string
          participant_id: string
          program_id: string
          status: string
        }
        SetofOptions: {
          from: "*"
          to: "program_enrollments"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      ensure_repeatable_local_program_fixtures: {
        Args: never
        Returns: boolean
      }
      expire_commerce_state: { Args: never; Returns: Json }
      expire_payment_orders: { Args: never; Returns: number }
      fail_food_insight_job: {
        Args: {
          error_code: string
          retryable: boolean
          target_job_id: string
          target_lease_token: string
        }
        Returns: string
      }
      fail_provisional_cancellation: {
        Args: { failure_code: string; target_receipt_id: string }
        Returns: boolean
      }
      finalize_external_apple_account_deletion: {
        Args: { target_account_id: string }
        Returns: string
      }
      finalize_my_account_deletion: { Args: never; Returns: string }
      finalize_participant_onboarding: {
        Args: { coach_qr: string; expected_version?: number }
        Returns: {
          account_purpose: string
          city: string
          coach_biography: string
          coach_is_approved: boolean
          coach_is_public: boolean
          coach_qr_identifier: string | null
          created_at: string
          current_coach_id: string | null
          display_name: string
          finalized_at: string | null
          member_level: string | null
          onboarding_status: string
          onboarding_version: number
          phone_number: string | null
          profile_avatar_path: string | null
          provider_avatar_url: string | null
          provisional_expires_at: string | null
          public_profile_id: string
          role: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      fulfill_apple_purchase: {
        Args: {
          caller_account_id: string
          target_currency_code?: string
          target_expires_at?: string
          target_external_transaction_id: string
          target_original_transaction_id: string
          target_price_milliunits?: number
          target_purchase_intent_id: string
          target_purchased_at: string
          target_signed_at: string
          target_signed_payload_hash: string
          verified_app_account_token: string
          verified_environment: string
          verified_product_id: string
        }
        Returns: Json
      }
      get_admin_closure_preflight: {
        Args: { target_program_id: string }
        Returns: Json
      }
      get_admin_dashboard: { Args: never; Returns: Json }
      get_admin_person_detail: {
        Args: { target_user_id: string }
        Returns: Json
      }
      get_my_assigned_coach: {
        Args: never
        Returns: {
          city: string
          display_name: string
          is_approved: boolean
          is_public: boolean
          provider_avatar_url: string
          public_profile_id: string
          user_id: string
        }[]
      }
      get_my_coach_activity_feed: { Args: never; Returns: Json }
      get_my_coach_application: { Args: never; Returns: Json }
      get_my_coach_leaderboard: {
        Args: {
          result_limit?: number
          result_offset?: number
          target_program_id: string
        }
        Returns: Json[]
      }
      get_my_coach_participant_detail: {
        Args: { target_enrollment_id?: string; target_participant_id: string }
        Returns: Json
      }
      get_my_coach_participant_directory: { Args: never; Returns: Json }
      get_my_coach_public_profile_draft: { Args: never; Returns: Json }
      get_my_coach_workspace: { Args: never; Returns: Json }
      get_my_dashboard_summary: {
        Args: never
        Returns: {
          account_role: string
          active_enrollment_count: number
          assigned_participant_count: number
          completed_enrollment_count: number
          pending_submission_count: number
        }[]
      }
      get_my_provisional_onboarding_profile: { Args: never; Returns: Json }
      get_my_session_context: { Args: never; Returns: Json }
      get_program_closure_preflight: {
        Args: { target_program_id: string }
        Returns: Json
      }
      get_public_coach_profile: {
        Args: { target_handle: string }
        Returns: Json
      }
      get_purchase_intent_for_verification: {
        Args: { caller_account_id: string; target_purchase_intent_id: string }
        Returns: Json
      }
      list_admin_audit_events: {
        Args: { result_limit?: number }
        Returns: Json[]
      }
      list_admin_food_insight_operations: { Args: never; Returns: Json[] }
      list_admin_pending_evidence: { Args: never; Returns: Json[] }
      list_admin_people: { Args: never; Returns: Json[] }
      list_admin_profile_moderation_items: { Args: never; Returns: Json[] }
      list_coach_applications_for_admin: { Args: never; Returns: Json[] }
      list_my_assigned_participants: { Args: never; Returns: Json[] }
      list_my_commerce_history: { Args: never; Returns: Json[] }
      list_my_pending_reviews: { Args: never; Returns: Json[] }
      list_my_program_day_access: {
        Args: never
        Returns: {
          access_state: string
          day_number: number
          enrollment_id: string
          is_current_day: boolean
          program_day_id: string
          program_id: string
        }[]
      }
      list_orphan_question_photos: {
        Args: { older_than?: string }
        Returns: {
          object_name: string
        }[]
      }
      list_payment_evidence_orphans: {
        Args: { batch_size?: number; dry_run?: boolean; minimum_age?: string }
        Returns: {
          is_dry_run: boolean
          object_created_at: string
          object_name: string
        }[]
      }
      list_public_coaches: {
        Args: { result_limit?: number; result_offset?: number }
        Returns: Json[]
      }
      list_public_food_question_configs: {
        Args: { target_question_ids: string[] }
        Returns: Json[]
      }
      list_public_leaderboard: {
        Args: {
          result_limit?: number
          result_offset?: number
          target_program_id: string
        }
        Returns: Json[]
      }
      list_public_programs: {
        Args: {
          result_limit?: number
          result_offset?: number
          target_program_id?: string
        }
        Returns: Json[]
      }
      list_public_winner_posters: {
        Args: { result_limit?: number; result_offset?: number }
        Returns: Json[]
      }
      list_public_winners: {
        Args: {
          result_limit?: number
          result_offset?: number
          target_program_id: string
        }
        Returns: Json[]
      }
      lock_program_winners: {
        Args: { request_idempotency_key: string; target_program_id: string }
        Returns: {
          display_name: string
          id: string
          participant_id: string | null
          rank: number
          snapshot_id: string
          total_points: number
        }[]
        SetofOptions: {
          from: "*"
          to: "program_winners"
          isOneToOne: false
          isSetofReturn: true
        }
      }
      manage_winner_poster: {
        Args: {
          operation: string
          reason: string
          request_idempotency_key: string
          target_alt_text: string
          target_media_path: string
          target_poster_id: string
          target_program_id: string
          target_snapshot_id: string
        }
        Returns: {
          alt_text: string
          deleted_at: string | null
          id: string
          idempotency_key: string | null
          is_published: boolean
          media_path: string
          mutation_idempotency_key: string | null
          program_id: string
          published_at: string | null
          winner_snapshot_id: string
        }
        SetofOptions: {
          from: "*"
          to: "winner_posters"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      mark_purchase_intent_pending: {
        Args: { caller_account_id: string; target_purchase_intent_id: string }
        Returns: {
          account_id: string
          app_account_token: string
          coach_application_id: string | null
          coach_id_snapshot: string | null
          coach_store_product_id: string | null
          created_at: string
          environment: string
          expires_at: string
          fulfilled_at: string | null
          fulfilled_transaction_id: string | null
          id: string
          idempotency_key: string
          last_error_code: string | null
          product_id: string
          program_id: string | null
          program_store_product_id: string | null
          provider: string
          status: string
          subject_kind: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "commerce_purchase_intents"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      moderate_admin_coach_profile_item: {
        Args: {
          decision: string
          expected_version: number
          note: string
          request_idempotency_key: string
          target_item_id: string
        }
        Returns: {
          body: string
          coach_user_id: string
          content_version: number
          id: string
          includes_third_party: boolean
          is_public: boolean
          item_kind: string
          media_object_path: string | null
          moderated_at: string | null
          moderated_by: string | null
          moderation_idempotency_key: string | null
          moderation_note: string | null
          moderation_status: string
          moderation_version: number
          permission_attested: boolean
          submitted_at: string
          title: string
        }
        SetofOptions: {
          from: "*"
          to: "coach_public_profile_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      moderate_coach_public_profile_item: {
        Args: { decision: string; note: string; target_item_id: string }
        Returns: {
          body: string
          coach_user_id: string
          content_version: number
          id: string
          includes_third_party: boolean
          is_public: boolean
          item_kind: string
          media_object_path: string | null
          moderated_at: string | null
          moderated_by: string | null
          moderation_idempotency_key: string | null
          moderation_note: string | null
          moderation_status: string
          moderation_version: number
          permission_attested: boolean
          submitted_at: string
          title: string
        }
        SetofOptions: {
          from: "*"
          to: "coach_public_profile_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      pending_program_enrollment_availability: {
        Args: { target_program_id: string }
        Returns: string
      }
      prepare_coach_application_handoff: {
        Args: { expected_version?: number }
        Returns: {
          account_purpose: string
          city: string
          coach_biography: string
          coach_is_approved: boolean
          coach_is_public: boolean
          coach_qr_identifier: string | null
          created_at: string
          current_coach_id: string | null
          display_name: string
          finalized_at: string | null
          member_level: string | null
          onboarding_status: string
          onboarding_version: number
          phone_number: string | null
          profile_avatar_path: string | null
          provider_avatar_url: string | null
          provisional_expires_at: string | null
          public_profile_id: string
          role: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      prepare_external_apple_account_deletion: {
        Args: { target_account_id: string }
        Returns: Json
      }
      prepare_my_account_deletion: { Args: never; Returns: Json }
      prepare_payment_evidence_attempt: {
        Args: { request_idempotency_key: string; target_order_id: string }
        Returns: {
          attempt_number: number
          byte_size: number | null
          deleted_at: string | null
          id: string
          mime_type: string | null
          object_path: string
          order_id: string
          pixel_height: number | null
          pixel_width: number | null
          prepared_at: string
          rejection_reason: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          sha256_hex: string | null
          status: string
          submitted_at: string | null
          upload_idempotency_key: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_evidence_attempts"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      prepare_step_submission: {
        Args: {
          request_idempotency_key: string
          target_enrollment_id: string
          target_step_id: string
        }
        Returns: {
          attempt_sequence: number
          enrollment_id: string
          finalized_at: string | null
          id: string
          idempotency_key: string | null
          review_idempotency_key: string | null
          review_note: string | null
          reviewed_at: string | null
          reviewer_id: string | null
          status: string
          step_id: string
          submitted_at: string
          supersedes_submission_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "step_submissions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      preview_admin_program_winners: {
        Args: { target_program_id: string }
        Returns: Json[]
      }
      publish_my_coach_public_profile: { Args: never; Returns: Json }
      publish_program: {
        Args: { request_idempotency_key: string; target_program_id: string }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      publish_winner_poster: {
        Args: {
          alt_text: string
          media_path: string
          request_idempotency_key: string
          target_program_id: string
          target_snapshot_id: string
        }
        Returns: {
          alt_text: string
          deleted_at: string | null
          id: string
          idempotency_key: string | null
          is_published: boolean
          media_path: string
          mutation_idempotency_key: string | null
          program_id: string
          published_at: string | null
          winner_snapshot_id: string
        }
        SetofOptions: {
          from: "*"
          to: "winner_posters"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      reconcile_apple_commerce_event: {
        Args: {
          target_decoded_fields?: Json
          target_environment: string
          target_event_at: string
          target_event_type: string
          target_external_event_id: string
          target_external_transaction_id: string
          target_signed_payload_hash: string
        }
        Returns: Json
      }
      reconcile_food_insight_jobs: {
        Args: { target_analysis_version?: string }
        Returns: number
      }
      record_apple_account_event: {
        Args: {
          target_apple_subject_hash: string
          target_event_jti: string
          target_event_time: string
          target_event_type: string
        }
        Returns: Json
      }
      record_apple_notification: {
        Args: {
          target_decoded_fields?: Json
          target_environment: string
          target_notification_type: string
          target_notification_uuid: string
          target_original_transaction_id: string
          target_signed_at: string
          target_signed_payload_hash: string
          target_subtype: string
          target_transaction_id: string
        }
        Returns: Json
      }
      record_exceptional_reversal: {
        Args: {
          mark_completed?: boolean
          reconciliation_reference: string
          resolution_note: string
          target_order_id: string
        }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      record_orphan_question_photo_cleanup: {
        Args: { cleanup_reason: string; deleted_object_names: string[] }
        Returns: undefined
      }
      refresh_enrollment_score: {
        Args: { target_enrollment_id: string }
        Returns: {
          activity_points: number
          adjustment_points: number
          enrollment_id: string
          progress_percentage: number
          public_id: string
          quiz_points: number
          rank: number | null
          recalculated_at: string
          weight_points: number
        }
        SetofOptions: {
          from: "*"
          to: "program_scores"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      reject_coach_application_and_payment: {
        Args: {
          expected_version: number
          rejection_reason: string
          request_idempotency_key: string
          target_order_id: string
        }
        Returns: Json
      }
      reject_payment_evidence: {
        Args: {
          expected_version: number
          rejection_reason: string
          target_order_id: string
        }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      reopen_program: {
        Args: {
          reason: string
          request_idempotency_key: string
          target_program_id: string
        }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      reopen_quiz_attempt: {
        Args: {
          reason: string
          request_idempotency_key: string
          target_enrollment_id: string
          target_step_id: string
        }
        Returns: {
          awarded_points: number
          correct_count: number
          id: string
          passed: boolean
          percentage: number
          reopen_idempotency_key: string | null
          reopen_reason: string | null
          reopened_at: string | null
          reopened_by: string | null
          submission_id: string
          total_count: number
        }
        SetofOptions: {
          from: "*"
          to: "quiz_attempt_results"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      request_coach_payment_correction: {
        Args: {
          correction_reason: string
          expected_version: number
          request_idempotency_key: string
          target_order_id: string
        }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      request_my_provisional_cancellation: {
        Args: { request_idempotency_key: string }
        Returns: Json
      }
      resolve_coach_qr_for_enrollment: {
        Args: { scanned_coach_qr: string }
        Returns: Json
      }
      resolve_purchase_intent_for_restore: {
        Args: {
          caller_account_id: string
          target_environment: string
          verified_app_account_token: string
          verified_product_id: string
        }
        Returns: string
      }
      restore_expired_payment_order: {
        Args: { expected_version: number; target_order_id: string }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      review_step_submission: {
        Args: {
          request_idempotency_key: string
          review_decision: string
          review_reason: string
          target_submission_id: string
        }
        Returns: {
          attempt_sequence: number
          enrollment_id: string
          finalized_at: string | null
          id: string
          idempotency_key: string | null
          review_idempotency_key: string | null
          review_note: string | null
          reviewed_at: string | null
          reviewer_id: string | null
          status: string
          step_id: string
          submitted_at: string
          supersedes_submission_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "step_submissions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      revoke_provisional_cancellation_sessions: {
        Args: { target_receipt_id: string }
        Returns: boolean
      }
      save_admin_program_draft: {
        Args: { program_payload: Json; request_idempotency_key: string }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      save_my_coach_application_draft: {
        Args: {
          accepted_terms_version: string
          applicant_has_completed_hom_sts: boolean
          applicant_has_completed_ict: boolean
          member_level: string
          request_idempotency_key: string
        }
        Returns: {
          applicant_user_id: string
          created_at: string
          decided_at: string | null
          decided_by: string | null
          decision_idempotency_key: string | null
          display_name_snapshot: string
          draft_idempotency_key: string
          has_completed_hom_sts: boolean
          has_completed_ict: boolean
          id: string
          member_level_snapshot: string
          participant_profile_id: string
          phone_number_snapshot: string
          rejection_reason: string | null
          status: string
          submit_idempotency_key: string | null
          submitted_at: string | null
          terms_version: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "coach_applications"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      save_my_coach_public_profile_draft: {
        Args: {
          biography: string
          instagram_url: string
          phone_number: string
          photo_object_path: string
          professional_headline: string
          requested_handle: string
          service_area: string
          show_instagram: boolean
          show_phone: boolean
          show_tiktok: boolean
          show_website: boolean
          show_whatsapp: boolean
          tiktok_url: string
          website_url: string
          whatsapp_number: string
        }
        Returns: {
          biography: string
          coach_user_id: string
          instagram_url: string
          phone_number: string
          professional_headline: string
          profile_photo_object_path: string | null
          public_handle: string
          service_area: string
          show_instagram: boolean
          show_phone: boolean
          show_tiktok: boolean
          show_website: boolean
          show_whatsapp: boolean
          tiktok_url: string
          updated_at: string
          website_url: string
          whatsapp_number: string
        }
        SetofOptions: {
          from: "*"
          to: "coach_public_profile_drafts"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      save_my_provisional_onboarding_profile: {
        Args: {
          expected_version: number
          new_account_purpose: string
          new_display_name: string
          new_member_level: string
          new_phone_number: string
        }
        Returns: {
          account_purpose: string
          city: string
          coach_biography: string
          coach_is_approved: boolean
          coach_is_public: boolean
          coach_qr_identifier: string | null
          created_at: string
          current_coach_id: string | null
          display_name: string
          finalized_at: string | null
          member_level: string | null
          onboarding_status: string
          onboarding_version: number
          phone_number: string | null
          profile_avatar_path: string | null
          provider_avatar_url: string | null
          provisional_expires_at: string | null
          public_profile_id: string
          role: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      save_program_draft: {
        Args: { program_payload: Json; request_idempotency_key: string }
        Returns: {
          archive_idempotency_key: string | null
          category: string | null
          completion_idempotency_key: string | null
          cover_alt_text: string | null
          cover_path: string | null
          created_at: string
          created_by: string
          default_verification_mode: string
          desired_price: number | null
          draft_idempotency_key: string | null
          duration_mode: string
          ends_on: string
          future_step_policy: string
          id: string
          pace: string
          participant_limit: number | null
          past_step_policy: string
          points_per_activity: number
          points_per_weight_kg: number
          pricing_mode: string
          publish_idempotency_key: string | null
          published_at: string | null
          quiz_passing_percentage: number
          registration_closes_at: string | null
          reopen_idempotency_key: string | null
          source_program_id: string | null
          starts_on: string
          status: string
          summary: string
          timezone: string
          title: string
          updated_at: string
          wellness_disclaimer: string
        }
        SetofOptions: {
          from: "*"
          to: "programs"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      store_apple_identity_credential: {
        Args: {
          target_account_id: string
          target_apple_subject_hash: string
          target_encrypted_refresh_token: string
          target_encryption_nonce: string
        }
        Returns: string
      }
      submit_coach_onboarding_payment_evidence: {
        Args: {
          content_byte_size: number
          content_pixel_height: number
          content_pixel_width: number
          content_sha256_hex: string
          target_attempt_id: string
        }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      submit_my_coach_application: {
        Args: { request_idempotency_key: string; target_application_id: string }
        Returns: {
          applicant_user_id: string
          created_at: string
          decided_at: string | null
          decided_by: string | null
          decision_idempotency_key: string | null
          display_name_snapshot: string
          draft_idempotency_key: string
          has_completed_hom_sts: boolean
          has_completed_ict: boolean
          id: string
          member_level_snapshot: string
          participant_profile_id: string
          phone_number_snapshot: string
          rejection_reason: string | null
          status: string
          submit_idempotency_key: string | null
          submitted_at: string | null
          terms_version: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "coach_applications"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      submit_my_coach_public_profile_item: {
        Args: {
          body: string
          includes_third_party: boolean
          item_kind: string
          media_object_path: string
          permission_attested: boolean
          title: string
        }
        Returns: {
          body: string
          coach_user_id: string
          content_version: number
          id: string
          includes_third_party: boolean
          is_public: boolean
          item_kind: string
          media_object_path: string | null
          moderated_at: string | null
          moderated_by: string | null
          moderation_idempotency_key: string | null
          moderation_note: string | null
          moderation_status: string
          moderation_version: number
          permission_attested: boolean
          submitted_at: string
          title: string
        }
        SetofOptions: {
          from: "*"
          to: "coach_public_profile_items"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      submit_payment_evidence: {
        Args: {
          content_byte_size: number
          content_pixel_height: number
          content_pixel_width: number
          content_sha256_hex: string
          target_attempt_id: string
        }
        Returns: {
          account_name_snapshot: string
          account_reference_snapshot: string
          amount_minor: number
          bank_code_snapshot: string
          bank_name_snapshot: string
          coach_application_id: string | null
          coach_user_id_snapshot: string | null
          correction_expires_at: string | null
          created_at: string
          currency: string
          declared_method: string
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
          instructions_snapshot: string
          latest_rejection_reason: string | null
          owner_user_id: string | null
          pending_enrollment_id: string | null
          program_id: string | null
          purpose: string
          qris_object_path_snapshot: string | null
          reservation_expires_at: string | null
          reserved_at: string | null
          retention_after: string | null
          status: string
          timezone_snapshot: string
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "payment_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      submit_step_answers: {
        Args: {
          request_idempotency_key: string
          submitted_answers: Json
          target_submission_id: string
        }
        Returns: {
          attempt_sequence: number
          enrollment_id: string
          finalized_at: string | null
          id: string
          idempotency_key: string | null
          review_idempotency_key: string | null
          review_note: string | null
          reviewed_at: string | null
          reviewer_id: string | null
          status: string
          step_id: string
          submitted_at: string
          supersedes_submission_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "step_submissions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      submit_weigh_in: {
        Args: {
          request_idempotency_key: string
          target_enrollment_id: string
          target_step_id: string
          weigh_in_kind: string
          weight_kg: number
        }
        Returns: {
          corrected_at: string | null
          corrected_by: string | null
          correction_idempotency_key: string | null
          correction_reason: string | null
          enrollment_id: string
          id: string
          idempotency_key: string | null
          kind: string
          recorded_at: string
          step_id: string
          weight_kg: number
        }
        SetofOptions: {
          from: "*"
          to: "weigh_ins"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      update_coach_profile: {
        Args: {
          new_biography: string
          new_city: string
          new_display_name: string
          new_is_public: boolean
          reason?: string
          target_coach_user_id: string
        }
        Returns: {
          account_purpose: string
          city: string
          coach_biography: string
          coach_is_approved: boolean
          coach_is_public: boolean
          coach_qr_identifier: string | null
          created_at: string
          current_coach_id: string | null
          display_name: string
          finalized_at: string | null
          member_level: string | null
          onboarding_status: string
          onboarding_version: number
          phone_number: string | null
          profile_avatar_path: string | null
          provider_avatar_url: string | null
          provisional_expires_at: string | null
          public_profile_id: string
          role: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      update_my_profile: {
        Args: {
          new_account_purpose?: string
          new_display_name: string
          new_member_level: string
          new_phone_number: string
        }
        Returns: {
          account_purpose: string
          city: string
          coach_biography: string
          coach_is_approved: boolean
          coach_is_public: boolean
          coach_qr_identifier: string | null
          created_at: string
          current_coach_id: string | null
          display_name: string
          finalized_at: string | null
          member_level: string | null
          onboarding_status: string
          onboarding_version: number
          phone_number: string | null
          profile_avatar_path: string | null
          provider_avatar_url: string | null
          provisional_expires_at: string | null
          public_profile_id: string
          role: string
          updated_at: string
          user_id: string
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      validate_participant_onboarding_coach_qr: {
        Args: { coach_qr: string }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  storage: {
    Tables: {
      buckets: {
        Row: {
          allowed_mime_types: string[] | null
          avif_autodetection: boolean | null
          created_at: string | null
          file_size_limit: number | null
          id: string
          name: string
          owner: string | null
          owner_id: string | null
          public: boolean | null
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string | null
        }
        Insert: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id: string
          name: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string | null
        }
        Update: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id?: string
          name?: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string | null
        }
        Relationships: []
      }
      buckets_analytics: {
        Row: {
          created_at: string
          deleted_at: string | null
          format: string
          id: string
          name: string
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          format?: string
          id?: string
          name: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          format?: string
          id?: string
          name?: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Relationships: []
      }
      buckets_vectors: {
        Row: {
          created_at: string
          id: string
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          id: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Relationships: []
      }
      iceberg_namespaces: {
        Row: {
          bucket_name: string
          catalog_id: string
          created_at: string
          id: string
          metadata: Json
          name: string
          updated_at: string
        }
        Insert: {
          bucket_name: string
          catalog_id: string
          created_at?: string
          id?: string
          metadata?: Json
          name: string
          updated_at?: string
        }
        Update: {
          bucket_name?: string
          catalog_id?: string
          created_at?: string
          id?: string
          metadata?: Json
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "iceberg_namespaces_catalog_id_fkey"
            columns: ["catalog_id"]
            isOneToOne: false
            referencedRelation: "buckets_analytics"
            referencedColumns: ["id"]
          },
        ]
      }
      iceberg_tables: {
        Row: {
          bucket_name: string
          catalog_id: string
          created_at: string
          id: string
          location: string
          name: string
          namespace_id: string
          remote_table_id: string | null
          shard_id: string | null
          shard_key: string | null
          updated_at: string
        }
        Insert: {
          bucket_name: string
          catalog_id: string
          created_at?: string
          id?: string
          location: string
          name: string
          namespace_id: string
          remote_table_id?: string | null
          shard_id?: string | null
          shard_key?: string | null
          updated_at?: string
        }
        Update: {
          bucket_name?: string
          catalog_id?: string
          created_at?: string
          id?: string
          location?: string
          name?: string
          namespace_id?: string
          remote_table_id?: string | null
          shard_id?: string | null
          shard_key?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "iceberg_tables_catalog_id_fkey"
            columns: ["catalog_id"]
            isOneToOne: false
            referencedRelation: "buckets_analytics"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "iceberg_tables_namespace_id_fkey"
            columns: ["namespace_id"]
            isOneToOne: false
            referencedRelation: "iceberg_namespaces"
            referencedColumns: ["id"]
          },
        ]
      }
      migrations: {
        Row: {
          executed_at: string | null
          hash: string
          id: number
          name: string
        }
        Insert: {
          executed_at?: string | null
          hash: string
          id: number
          name: string
        }
        Update: {
          executed_at?: string | null
          hash?: string
          id?: number
          name?: string
        }
        Relationships: []
      }
      objects: {
        Row: {
          bucket_id: string | null
          created_at: string | null
          id: string
          last_accessed_at: string | null
          metadata: Json | null
          name: string | null
          owner: string | null
          owner_id: string | null
          path_tokens: string[] | null
          updated_at: string | null
          user_metadata: Json | null
          version: string | null
        }
        Insert: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          user_metadata?: Json | null
          version?: string | null
        }
        Update: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          user_metadata?: Json | null
          version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "objects_bucketId_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
        ]
      }
      s3_multipart_uploads: {
        Row: {
          bucket_id: string
          created_at: string
          id: string
          in_progress_size: number
          key: string
          metadata: Json | null
          owner_id: string | null
          upload_signature: string
          user_metadata: Json | null
          version: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          id: string
          in_progress_size?: number
          key: string
          metadata?: Json | null
          owner_id?: string | null
          upload_signature: string
          user_metadata?: Json | null
          version: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          id?: string
          in_progress_size?: number
          key?: string
          metadata?: Json | null
          owner_id?: string | null
          upload_signature?: string
          user_metadata?: Json | null
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "s3_multipart_uploads_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
        ]
      }
      s3_multipart_uploads_parts: {
        Row: {
          bucket_id: string
          created_at: string
          etag: string
          id: string
          key: string
          owner_id: string | null
          part_number: number
          size: number
          upload_id: string
          version: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          etag: string
          id?: string
          key: string
          owner_id?: string | null
          part_number: number
          size?: number
          upload_id: string
          version: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          etag?: string
          id?: string
          key?: string
          owner_id?: string | null
          part_number?: number
          size?: number
          upload_id?: string
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "s3_multipart_uploads_parts_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "s3_multipart_uploads_parts_upload_id_fkey"
            columns: ["upload_id"]
            isOneToOne: false
            referencedRelation: "s3_multipart_uploads"
            referencedColumns: ["id"]
          },
        ]
      }
      vector_indexes: {
        Row: {
          bucket_id: string
          created_at: string
          data_type: string
          dimension: number
          distance_metric: string
          id: string
          metadata_configuration: Json | null
          name: string
          updated_at: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          data_type: string
          dimension: number
          distance_metric: string
          id?: string
          metadata_configuration?: Json | null
          name: string
          updated_at?: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          data_type?: string
          dimension?: number
          distance_metric?: string
          id?: string
          metadata_configuration?: Json | null
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vector_indexes_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets_vectors"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      allow_any_operation: {
        Args: { expected_operations: string[] }
        Returns: boolean
      }
      allow_only_operation: {
        Args: { expected_operation: string }
        Returns: boolean
      }
      can_insert_object: {
        Args: { bucketid: string; metadata: Json; name: string; owner: string }
        Returns: undefined
      }
      extension: { Args: { name: string }; Returns: string }
      filename: { Args: { name: string }; Returns: string }
      foldername: { Args: { name: string }; Returns: string[] }
      get_common_prefix: {
        Args: { p_delimiter: string; p_key: string; p_prefix: string }
        Returns: string
      }
      get_size_by_bucket: {
        Args: never
        Returns: {
          bucket_id: string
          size: number
        }[]
      }
      list_multipart_uploads_with_delimiter: {
        Args: {
          bucket_id: string
          delimiter_param: string
          max_keys?: number
          next_key_token?: string
          next_upload_token?: string
          prefix_param: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
        }[]
      }
      list_objects_with_delimiter: {
        Args: {
          _bucket_id: string
          delimiter_param: string
          max_keys?: number
          next_token?: string
          prefix_param: string
          sort_order?: string
          start_after?: string
        }
        Returns: {
          created_at: string
          id: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      operation: { Args: never; Returns: string }
      search: {
        Args: {
          bucketname: string
          levels?: number
          limits?: number
          offsets?: number
          prefix: string
          search?: string
          sortcolumn?: string
          sortorder?: string
        }
        Returns: {
          created_at: string
          id: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      search_by_timestamp: {
        Args: {
          p_bucket_id: string
          p_level: number
          p_limit: number
          p_prefix: string
          p_sort_column: string
          p_sort_column_after: string
          p_sort_order: string
          p_start_after: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      search_v2: {
        Args: {
          bucket_name: string
          levels?: number
          limits?: number
          prefix: string
          sort_column?: string
          sort_column_after?: string
          sort_order?: string
          start_after?: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
    }
    Enums: {
      buckettype: "STANDARD" | "ANALYTICS" | "VECTOR"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
  storage: {
    Enums: {
      buckettype: ["STANDARD", "ANALYTICS", "VECTOR"],
    },
  },
} as const
