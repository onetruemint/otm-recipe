// PLACEHOLDER — regenerate with `npm run db:types` (see package.json).
//
// This file could not be generated from a running instance in this
// environment: `supabase start` needs Docker, which wasn't running here, and
// the Supabase CLI has no login/access token for remote generation. The
// shape below is the standard empty-schema output the CLI produces for a
// project with no tables yet (mint-recipe-prod currently has none). Once
// Phase 1's migration lands, regenerate this file for real and commit the
// output — see plan Section 5 ("DB types: Generated with the Supabase CLI
// and committed").

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = {
  public: {
    Tables: {
      [_ in never]: never;
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      [_ in never]: never;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};
