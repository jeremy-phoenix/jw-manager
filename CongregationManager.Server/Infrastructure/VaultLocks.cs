using System.Collections.Concurrent;

namespace CongregationManager.Server.Infrastructure;

/// <summary>
/// Serializes writes per vault. Change-feed sequence numbers are assigned and
/// committed under this lock, so readers can never observe seq N+1 before N
/// and a pull cursor never skips a change. The server is designed to run as a
/// single instance.
/// </summary>
public sealed class VaultLocks
{
    private readonly ConcurrentDictionary<Guid, SemaphoreSlim> gates = new();

    public async Task<IDisposable> AcquireAsync(Guid vaultId, CancellationToken cancellationToken)
    {
        var gate = gates.GetOrAdd(vaultId, static _ => new SemaphoreSlim(1, 1));
        await gate.WaitAsync(cancellationToken);
        return new Releaser(gate);
    }

    private sealed class Releaser(SemaphoreSlim gate) : IDisposable
    {
        private int released;

        public void Dispose()
        {
            if (Interlocked.Exchange(ref released, 1) == 0)
            {
                gate.Release();
            }
        }
    }
}
