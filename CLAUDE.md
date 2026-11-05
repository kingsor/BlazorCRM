# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All projects target `net10.0` (solution: `BlazorCrm.sln`). The README still says .NET 9; it is out of date.

```powershell
dotnet build BlazorCrm.sln
dotnet test BlazorCrm.sln
dotnet test tests/Crm.Web.Tests --filter "FullyQualifiedName~TenantIntegrationTests"   # one class
dotnet test tests/Crm.Web.Tests --filter "FullyQualifiedName~JwtLoginTests.MethodName"  # one test
dotnet run --project src/Presentation/Crm.Web --launch-profile http                     # http://localhost:5062
dotnet run --project src/Background/Crm.Worker
```

- **Tailwind is part of the build.** `Crm.Web.csproj` sets `RunTailwind=true` and runs `npm run build:css` before every Build/Publish. Run `npm install` in `src/Presentation/Crm.Web` once, or build with `-p:RunTailwind=false`. Use `npm run watch:css` there while editing styles (input: `assets/css/input.css`, output: `wwwroot/css/site.css`).
- **EF migrations** live in `Crm.Infrastructure`, with `Crm.Web` as the startup project:
  - `dotnet ef migrations add <Name> -p src/Crm.Infrastructure -s src/Presentation/Crm.Web`
  - `dotnet ef database update -p src/Crm.Infrastructure -s src/Presentation/Crm.Web`
- **Migrate only:** `dotnet Crm.Web.dll --migrate` (also read from the `MIGRATE`, `MIGRATE_ARGS` and `ASPNETCORE_ARGS` env vars) applies migrations and exits. Production keeps `Database:AutoMigrate=false`; see `ops.md`.
- **Database:** running the app needs PostgreSQL (`ConnectionStrings:DefaultConnection`, override with `ConnectionStrings__DefaultConnection`). In Development the app creates the database if it is missing, auto-migrates and seeds demo data. Default login: `admin@local` / `Admin123$`.

## Architecture

Clean-architecture layers: `Crm.Domain` (entities/enums) → `Crm.Application` → `Crm.Infrastructure` → `Presentation/Crm.Web` (Blazor Server host + minimal APIs). `Crm.UI` is a Razor class library of shared components, and `Crm.Contracts` holds API DTOs (auth, paging, search). `Crm.Worker` is a standalone placeholder `BackgroundService`; the real scheduled work runs in Quartz inside `Crm.Web`.

**Request flow.** Each write operation is a MediatR request in `Crm.Application/<Feature>/` that keeps the record, its FluentValidation validator and its handler in one file (see `Companies/CreateCompany.cs`). Handlers do not touch EF directly. They call service interfaces in `Crm.Application/Services` (`ICompanyService`, ...), implemented by `Ef*Service` in `Crm.Infrastructure/Services`. Blazor pages mostly inject those services directly; the `/api` minimal endpoints mostly go through MediatR.

**Pipeline behaviors.** `ValidationBehavior` is registered in `Crm.Application/DependencyInjection.cs`. `PermissionBehavior` lives in `Crm.Web/Infrastructure` and enforces `[RequiresPermission(Permissions.X)]` on the request type, throwing `PermissionDeniedException`. Permission names are in `Crm.Application/Security/Permissions.cs`, and the matching authorization policies are registered in `Program.cs`.

**Multi-tenancy** spans several pieces:
- `TenantResolutionMiddleware` calls `ITenantResolver`. `SubdomainTenantResolver` maps the host subdomain to a `Tenant.Slug`, using `Tenancy:BaseDomain`/`DevHostSuffix`; on plain `localhost` in Development it falls back to `Tenancy:DefaultTenantSlug`.
- The resolved `TenantContext` is cached in `HttpContext.Items` and in the scoped `ITenantContextAccessor`.
- `CrmDbContext` applies `HasQueryFilter(e => e.TenantId == _tenantProvider.TenantId)` to tenant-owned entities. Without an HTTP request `HttpTenantProvider` throws, so background code must set `ITenantContextAccessor.Current` itself. `RemindersSweepJob` does this per tenant and resets it in `finally`.
- Code that must bypass the filter builds a `CrmDbContext` with `NullTenantProvider`.

**`Program.cs` (~1300 lines)** holds nearly all composition and endpoints: DI, auth, the `/api` group (cookie for the web UI and JWT for the API, selected by a policy scheme on the Authorization header; CORS policy `maui`; rate limiting `api`; API version 1.0), form login, attachment download, health checks (`/health/live`, `/health/ready`) and local helpers such as `EnsurePostgresDatabaseExistsAsync` and `EnsureQuartzSchemaAsync`. Search here first when wiring something new.

**`Testing` environment.** Many branches check `IsEnvironment("Testing")`. In that environment the app skips Npgsql/Quartz/DbContext registration so tests can inject the EF InMemory or SQLite provider. It also relaxes form login (auto-creates the user, skips the password check), skips API versioning, disables output cache unless `OutputCache:EnableInTesting` is set, exposes `/_test/claims`, and lets the tenant resolver auto-create the default tenant. Keep these branches in mind when changing startup code. Tests in `tests/Crm.Web.Tests` are integration tests that use a per-class `WebApplicationFactory<Program>` with `UseEnvironment("Testing")` and in-memory config. `Crm.Domain.Tests` and `Crm.Application.Tests` currently contain no tests.

**Quartz (4.x)** uses a PostgreSQL persistent store with schema validation enabled. Before the scheduler is built, `EnsureQuartzSchemaAsync` applies `Crm.Web/sql/quartz_postgres.sql` if the `qrtz_job_details` table is missing. That script is the Quartz 4.7 schema; a database created with Quartz 3 needs the official Quartz.NET `database/migrations/4.0+` scripts. Jobs implement `ValueTask Execute(IJobExecutionContext, CancellationToken)`. See `update-projects.md` for the 3→4 upgrade notes.

**Search** uses PostgreSQL full-text search (stored `tsvector` columns, GIN indexes, `unaccent`/`pg_trgm`). List/search endpoints share the paging model in `Crm.Contracts/Paging` (`page`, `pageSize` capped at 200, `sortBy`, `sortDir`, `search`); every sort appends `Id` as a tie-breaker for deterministic ordering.

**Other conventions:** C# files put `using` directives inside the namespace block. Data Protection keys are stored in the database. Attachments are written to disk under `Attachments:UploadsRootPath`, and only relative paths are stored in the database. The CSP blocks inline scripts. In Blazor forms, `<AntiforgeryToken />` goes inside the form body.
