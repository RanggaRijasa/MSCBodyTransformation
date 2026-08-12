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
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
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
          destination_id: string
          destination_version: number
          evidence_submitted_at?: string | null
          id?: string
          idempotency_key: string
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
          destination_id?: string
          destination_version?: number
          evidence_submitted_at?: string | null
          id?: string
          idempotency_key?: string
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
          id: string
          kind: string
          prompt: string
          question_order: number
          step_id: string
        }
        Insert: {
          id?: string
          kind: string
          prompt: string
          question_order: number
          step_id: string
        }
        Update: {
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
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
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
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
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
      change_my_coach_from_qr: {
        Args: { request_idempotency_key: string; scanned_coach_qr: string }
        Returns: Json
      }
      claim_apple_commerce_reconciliation_batch: {
        Args: { batch_size?: number; target_environment: string }
        Returns: Json[]
      }
      claim_apple_identity_credential_for_account: {
        Args: { target_account_id: string }
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
      consume_commerce_rate_limit: {
        Args: { caller_account_id: string; target_operation: string }
        Returns: undefined
      }
      consume_web_rate_limit: {
        Args: { target_operation: string; target_subject_hash?: string }
        Returns: number
      }
      create_coach_payment_order: {
        Args: { request_idempotency_key: string; target_application_id: string }
        Returns: Json
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
          request_idempotency_key: string
          target_program_id: string
        }
        Returns: Json
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
      expire_commerce_state: { Args: never; Returns: Json }
      expire_payment_orders: { Args: never; Returns: number }
      finalize_external_apple_account_deletion: {
        Args: { target_account_id: string }
        Returns: string
      }
      finalize_my_account_deletion: { Args: never; Returns: string }
      finalize_participant_onboarding: {
        Args: { coach_qr: string }
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
      get_my_coach_application: { Args: never; Returns: Json }
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
      get_my_participant_profile_context: { Args: never; Returns: Json }
      get_program_closure_preflight: {
        Args: { target_program_id: string }
        Returns: Json
      }
      get_purchase_intent_for_verification: {
        Args: { caller_account_id: string; target_purchase_intent_id: string }
        Returns: Json
      }
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
      list_public_coaches: {
        Args: { result_limit?: number; result_offset?: number }
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
      pending_program_enrollment_availability: {
        Args: { target_program_id: string }
        Returns: string
      }
      prepare_coach_application_handoff: {
        Args: never
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
        Returns: Json
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
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
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
      register_my_web_push_subscription: {
        Args: {
          target_auth_secret: string
          target_endpoint: string
          target_p256dh: string
          target_user_agent_family: string
        }
        Returns: string
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
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
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
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
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
      revoke_my_web_push_subscription: {
        Args: { target_endpoint: string }
        Returns: boolean
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
      submit_payment_evidence: {
        Args: {
          content_byte_size: number
          content_pixel_height: number
          content_pixel_width: number
          content_sha256_hex: string
          submitting_owner_user_id: string
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
          destination_id: string
          destination_version: number
          evidence_submitted_at: string | null
          id: string
          idempotency_key: string
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
      update_my_profile_avatar: {
        Args: { request_idempotency_key: string; target_path: string }
        Returns: string
      }
    }
    Enums: {
      [_ in never]: never
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
} as const

