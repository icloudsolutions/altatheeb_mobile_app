import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';

interface AuditItem {
  id: number;
  action: string;
  actor_user_id: number | null;
  actor_role: string | null;
  target: string | null;
  created_at: string;
}

export function AuditPage() {
  const { data } = useQuery<AuditItem[]>({
    queryKey: ['audit'],
    queryFn: async () => (await api.get('/admin/v1/audit')).data,
  });
  return (
    <div className="space-y-4">
      <h2 className="text-xl font-semibold">Audit log</h2>
      <table className="w-full bg-white border border-slate-200 rounded">
        <thead className="bg-slate-100 text-left text-sm">
          <tr>
            <th className="p-2">When</th>
            <th className="p-2">Actor</th>
            <th className="p-2">Role</th>
            <th className="p-2">Action</th>
            <th className="p-2">Target</th>
          </tr>
        </thead>
        <tbody className="text-sm">
          {(data ?? []).map((a) => (
            <tr key={a.id} className="border-t border-slate-100">
              <td className="p-2">{a.created_at}</td>
              <td className="p-2">{a.actor_user_id ?? '—'}</td>
              <td className="p-2">{a.actor_role ?? '—'}</td>
              <td className="p-2">{a.action}</td>
              <td className="p-2">{a.target ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
