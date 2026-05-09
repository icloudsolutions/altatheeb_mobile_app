import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';

interface Delivery {
  id: number;
  delivery_id: string;
  event: string;
  resource: string | null;
  status: string;
  error: string | null;
  received_at: string;
}

export function WebhookDeliveriesPage() {
  const qc = useQueryClient();
  const { data } = useQuery<Delivery[]>({
    queryKey: ['deliveries'],
    queryFn: async () => (await api.get('/admin/v1/webhook-deliveries?limit=200')).data,
    refetchInterval: 5000,
  });
  const replay = useMutation({
    mutationFn: (id: number) => api.post(`/admin/v1/webhook-deliveries/${id}/replay`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['deliveries'] }),
  });

  return (
    <div className="space-y-4">
      <h2 className="text-xl font-semibold">Webhook deliveries</h2>
      <table className="w-full bg-white border border-slate-200 rounded">
        <thead className="bg-slate-100 text-left text-sm">
          <tr>
            <th className="p-2">Received</th>
            <th className="p-2">Event</th>
            <th className="p-2">Resource</th>
            <th className="p-2">Status</th>
            <th className="p-2">Delivery ID</th>
            <th className="p-2">Error</th>
            <th className="p-2"></th>
          </tr>
        </thead>
        <tbody className="text-sm font-mono">
          {(data ?? []).map((d) => (
            <tr key={d.id} className="border-t border-slate-100">
              <td className="p-2">{d.received_at}</td>
              <td className="p-2">{d.event}</td>
              <td className="p-2">{d.resource}</td>
              <td className="p-2">
                <span className={`px-2 py-1 rounded text-xs ${
                  d.status === 'processed' ? 'bg-green-100 text-green-800' :
                  d.status === 'duplicate' ? 'bg-slate-200 text-slate-700' :
                  d.status === 'error' ? 'bg-red-100 text-red-700' :
                  'bg-amber-100 text-amber-800'
                }`}>{d.status}</span>
              </td>
              <td className="p-2 truncate max-w-[200px]">{d.delivery_id}</td>
              <td className="p-2 text-red-600 text-xs">{d.error}</td>
              <td className="p-2">
                <button className="rounded bg-slate-900 text-white px-3 py-1 text-xs"
                        onClick={() => replay.mutate(d.id)}>Replay</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
