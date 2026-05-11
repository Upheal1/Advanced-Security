// Minimal Deno type declarations for VS Code TypeScript language server.
// The real types are provided by the Deno runtime at deploy time.

declare namespace Deno {
  function serve(handler: (req: Request) => Response | Promise<Response>): void;
  const env: {
    get(key: string): string | undefined;
  };
}
