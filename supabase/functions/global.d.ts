// Global type definitions for Supabase Edge Functions to satisfy standard IDE TypeScript compilers.
// These are only used for local IDE autocompletion/linting and are ignored when deployed to Supabase.

declare namespace Deno {
  export interface Env {
    get(key: string): string | undefined;
  }
  export const env: Env;
  
  export function serve(
    handler: (request: Request) => Response | Promise<Response>
  ): void;
}

declare module "standardwebhooks" {
  export class Webhook {
    constructor(secret: string);
    verify(payload: string, headers: Record<string, string>): any;
  }
}
