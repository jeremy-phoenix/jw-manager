using Microsoft.AspNetCore.Diagnostics;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace CongregationManager.Server.Web;

internal sealed class ApiExceptionHandler(ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext context,
        Exception exception,
        CancellationToken cancellationToken)
    {
        if (exception is OperationCanceledException && context.RequestAborted.IsCancellationRequested)
        {
            return true;
        }

        var (status, code, message) = exception switch
        {
            ApiException api => (api.StatusCode, api.Code, api.Message),
            BadHttpRequestException badRequest => (badRequest.StatusCode, "BAD_REQUEST", "Invalid request."),
            DbUpdateException { InnerException: var inner } when IsUniqueViolation(inner) =>
                (StatusCodes.Status409Conflict, "CONFLICT", "The resource already exists."),
            _ => (StatusCodes.Status500InternalServerError, "INTERNAL_ERROR", "Internal server error."),
        };

        if (status >= StatusCodes.Status500InternalServerError)
        {
            logger.LogError(exception, "Unhandled exception for request {RequestId}.", context.TraceIdentifier);
        }

        context.Response.StatusCode = status;
        context.Response.Headers.CacheControl = "no-store";
        await context.Response.WriteAsJsonAsync(new ApiError(code, message), cancellationToken);
        return true;
    }

    private static bool IsUniqueViolation(Exception? exception) => exception switch
    {
        SqliteException { SqliteErrorCode: 19 } => true,
        PostgresException { SqlState: PostgresErrorCodes.UniqueViolation } => true,
        _ => false,
    };
}

internal sealed record ApiError(string Code, string Message);
