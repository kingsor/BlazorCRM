# Aggiornamento a .NET 10 e pacchetti NuGet

Data: 2026-11-02

## Esito

| Verifica | Risultato |
|---|---|
| Target framework | Tutti i 10 progetti su `net10.0` (SDK 10.0.403) |
| Pacchetti obsoleti | Nessuno tra le versioni stabili (`dotnet list package --outdated`) |
| Pacchetti vulnerabili | Nessuno, incluse le dipendenze transitive (`dotnet list package --vulnerable --include-transitive`) |
| Build | Riuscita, 0 errori |
| Test | 35/35 passati in `Crm.Web.Tests` (`Crm.Domain.Tests` e `Crm.Application.Tests` non contengono test) |
| Avvio `Crm.Web` | OK: `/`, `/login`, `/swagger` rispondono 200; `/health/live` e `/health/ready` sono "Healthy"; seed demo eseguito; scheduler Quartz 4.7 avviato con il job `RemindersSweep` |
| Avvio `Crm.Worker` | OK |

## Versioni dei pacchetti aggiornati

| Pacchetto | Da | A |
|---|---|---|
| Microsoft.* (ASP.NET Core, EF Core, Extensions) | 10.0.2 / 10.0.0 | 10.0.14 |
| Npgsql.EntityFrameworkCore.PostgreSQL | 10.0.0 | 10.0.3 |
| FluentValidation (+ DependencyInjectionExtensions) | 12.1.1 | 12.2.0 |
| Mapster | 7.4.0 | 10.0.14 |
| MediatR | 14.0.0 | 14.2.0 |
| Quartz, Quartz.Extensions.Hosting | 3.15.1 | 4.7.0 |
| Quartz.Serialization.Json | 3.15.1 | sostituito da Quartz.Serialization.Newtonsoft 4.7.0 |
| System.IdentityModel.Tokens.Jwt | 8.15.0 | 8.23.0 |
| Asp.Versioning.Http | 8.1.1 | 10.2.3 |
| Swashbuckle.AspNetCore | 10.1.0 | 10.3.1 |
| Serilog.Sinks.Seq | 9.0.0 | 9.1.0 |
| OpenTelemetry.* (stabili) | 1.14.0 | 1.20.1 |
| Microsoft.NET.Test.Sdk | 18.0.1 | 18.11.0 |
| xunit.runner.visualstudio | 3.1.5 | 4.0.1 |
| coverlet.collector | 6.0.4 | 10.1.0 |

## Correzioni per Quartz 4

Il passaggio da Quartz 3 a Quartz 4 rompeva la build e l'avvio.

1. **`src/Crm.Infrastructure/Jobs/RemindersSweepJob.cs`**: `Execute` usa la nuova firma
   `ValueTask Execute(IJobExecutionContext context, CancellationToken cancellationToken)`.
   Il token viene passato alle query EF (`ToListAsync`) e agli invii SignalR (`SendAsync`).

2. **`src/Presentation/Crm.Web/Program.cs`**: API rinominate in Quartz 4.
   - `s.UseProperties = true` → `s.ConfigureStore(o => o.StoreJobDataAsStrings = true)`
   - `s.PerformSchemaValidation = false` rimosso: torna attiva la validazione dello schema
     all'avvio (default `SchemaProvisioning.Validate` in Quartz 4).
   - `WithIntervalInMinutes(5)` → `WithInterval(TimeSpan.FromMinutes(5))`

3. **`src/Presentation/Crm.Web/Crm.Web.csproj`**: `Quartz.Serialization.Json` nella 4.x è un
   pacchetto vuoto, rinominato. Sostituito con `Quartz.Serialization.Newtonsoft` 4.7.0
   (`UseNewtonsoftJsonSerializer()` resta invariato).

4. **`src/Presentation/Crm.Web/sql/quartz_postgres.sql`**: lo script conteneva lo schema di
   Quartz 3 e, su un database nuovo, l'avvio falliva con
   `column t.misfire_orig_fire_time does not exist`. Sostituito con lo schema ufficiale di
   Quartz 4.7.0 (`Quartz.Impl.AdoJobStore.Schema.create_postgres.sql`, risorsa incorporata in
   `Quartz.dll`), con prefisso `qrtz_`. Lo script è idempotente: crea solo ciò che manca.

## Altro

- In `src/Presentation/Crm.Web` è servito `npm install`: mancava `node_modules` e lo step
  `npm run build:css` (Tailwind) del build falliva. Non dipende dall'aggiornamento.

## Come è stato verificato l'avvio

La PostgreSQL locale sulla porta 5432 rifiuta le credenziali di `appsettings.json`
(`postgres/postgres`). Per la prova è stato usato un container temporaneo, poi eliminato:

```powershell
docker run -d --name blazorcrm-pg-verify -e POSTGRES_PASSWORD=postgres -p 55432:5432 postgres:17
$env:ConnectionStrings__DefaultConnection = 'Host=localhost;Port=55432;Database=blazor_crm;Username=postgres;Password=postgres'
dotnet run --project src/Presentation/Crm.Web --launch-profile http
```

## Da fare / attenzione

- **Database esistenti con tabelle Quartz 3**: se il database ha già le tabelle `qrtz_*`
  create con Quartz 3, l'app non parte. Prima vanno eseguiti gli script di migrazione
  ufficiali di Quartz.NET (`database/migrations/4.0` e successivi, nel repository GitHub di
  Quartz.NET), che non sono inclusi nel pacchetto NuGet. La validazione dello schema indica
  nell'errore quale script manca.
- **Connection string locale**: per usare la PostgreSQL sulla porta 5432 aggiornare la
  connection string (ad esempio con `dotnet user-secrets`).
- **`OpenTelemetry.Instrumentation.EntityFrameworkCore`** è ancora `1.10.0-beta.1`. Esiste la
  `1.20.1-beta.1`, allineata agli altri pacchetti OpenTelemetry 1.20.1; non aggiornata perché
  anch'essa è una beta.
- **Licenza MediatR**: dalla versione 13 MediatR richiede una licenza commerciale in
  produzione (all'avvio compare un avviso). In sviluppo e test l'uso è consentito.
- Le modifiche non sono ancora state committate.
