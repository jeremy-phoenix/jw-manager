namespace CongregationManager.Server.Web;

/// <summary>An expected API failure, rendered as <c>{ code, message }</c>.</summary>
public sealed class ApiException(int statusCode, string code, string message) : Exception(message)
{
    public int StatusCode { get; } = statusCode;

    public string Code { get; } = code;

    public static ApiException BadRequest(string message) =>
        new(StatusCodes.Status400BadRequest, "BAD_REQUEST", message);

    public static ApiException Unauthorized(string message = "Missing or invalid device token.") =>
        new(StatusCodes.Status401Unauthorized, "UNAUTHORIZED", message);

    public static ApiException Forbidden(string code, string message) =>
        new(StatusCodes.Status403Forbidden, code, message);

    public static ApiException NotFound(string message) =>
        new(StatusCodes.Status404NotFound, "NOT_FOUND", message);

    public static ApiException Conflict(string code, string message) =>
        new(StatusCodes.Status409Conflict, code, message);
}
